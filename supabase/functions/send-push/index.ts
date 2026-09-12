// ClickGas - send queued notifications through Firebase Cloud Messaging.
//
// The database decides who is told what: triggers write rows to
// public.notifications, then pg_net calls this function (and a pg_cron job
// retries every minute). This function only delivers:
//   1. push_claim()  - takes up to 100 queued notifications, in the
//                      recipient's language, with their device tokens
//   2. FCM HTTP v1   - one message per device
//   3. push_report() - marks each one sent / retried / failed and drops
//                      tokens Firebase says are gone
//
// Secrets (supabase secrets set ...), see docs/runbooks/push-notifications.md:
//   PUSH_WEBHOOK_SECRET  - shared with the database (Vault: clickgas_push_secret)
//   FCM_SERVICE_ACCOUNT  - the Firebase service-account JSON (one line)
// Provided by Supabase: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY.
//
// Deploy: npx supabase functions deploy send-push --no-verify-jwt

import { createClient } from "npm:@supabase/supabase-js@2";

type Claimed = {
  id: number;
  kind: string;
  title: string;
  body: string;
  data: Record<string, unknown>;
  tokens: string[];
};

type Report = { id: number; ok: boolean; sent_count: number; error?: string; invalid_tokens: string[] };

type ServiceAccount = { project_id: string; client_email: string; private_key: string };

const MAX_ROUNDS = 5;

const supabase = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
  { auth: { persistSession: false, autoRefreshToken: false } },
);

function serviceAccount(): ServiceAccount | null {
  try {
    const sa = JSON.parse(Deno.env.get("FCM_SERVICE_ACCOUNT") ?? "");
    return sa.project_id && sa.client_email && sa.private_key ? sa : null;
  } catch {
    return null;
  }
}

// ------------------------------------------------------------ Google OAuth
let cachedToken: { value: string; expiresAt: number } | null = null;

function base64url(input: ArrayBuffer | string): string {
  const bytes = typeof input === "string" ? new TextEncoder().encode(input) : new Uint8Array(input);
  let bin = "";
  for (const b of bytes) bin += String.fromCharCode(b);
  return btoa(bin).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

async function accessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cachedToken && cachedToken.expiresAt > now + 60) return cachedToken.value;

  const pem = sa.private_key.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const unsigned = `${base64url(JSON.stringify({ alg: "RS256", typ: "JWT" }))}.${
    base64url(JSON.stringify({
      iss: sa.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    }))
  }`;
  const signature = await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned));

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: `${unsigned}.${base64url(signature)}`,
    }),
  });
  if (!res.ok) throw new Error(`google oauth ${res.status}: ${await res.text()}`);
  const json = await res.json();
  cachedToken = { value: json.access_token, expiresAt: now + (json.expires_in ?? 3600) };
  return cachedToken.value;
}

// ------------------------------------------------------------ FCM
/** "sent" | "invalid" (token gone, delete it) | an error message (retry). */
async function sendOne(sa: ServiceAccount, token: string, n: Claimed): Promise<string> {
  // FCM data values must be strings.
  const data: Record<string, string> = { kind: n.kind, notification_id: String(n.id) };
  for (const [k, v] of Object.entries(n.data ?? {})) {
    if (v !== null && v !== undefined) data[k] = typeof v === "string" ? v : JSON.stringify(v);
  }
  const res = await fetch(`https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`, {
    method: "POST",
    headers: {
      authorization: `Bearer ${await accessToken(sa)}`,
      "content-type": "application/json",
    },
    body: JSON.stringify({
      message: {
        token,
        notification: { title: n.title, body: n.body },
        data,
        android: {
          priority: "HIGH",
          // Created by the apps (NotificationService.channelId): sound + heads-up.
          notification: { channel_id: "order_updates", sound: "default" },
        },
        apns: { payload: { aps: { sound: "default" } } },
      },
    }),
  });
  if (res.ok) return "sent";
  const text = await res.text();
  if (res.status === 404 || text.includes("UNREGISTERED") ||
      (res.status === 400 && /registration token/i.test(text))) {
    return "invalid";
  }
  return `fcm ${res.status}: ${text.slice(0, 300)}`;
}

async function deliver(sa: ServiceAccount, n: Claimed): Promise<Report> {
  const results = await Promise.all(n.tokens.map((t) => sendOne(sa, t, n).catch((e) => String(e))));
  const invalid = n.tokens.filter((_, i) => results[i] === "invalid");
  const errors = results.filter((r) => r !== "sent" && r !== "invalid");
  const sentCount = results.filter((r) => r === "sent").length;
  return {
    id: n.id,
    // Delivered to at least one phone, or no live phone left (nothing to
    // retry; the database records it as no_device).
    ok: sentCount > 0 || errors.length === 0,
    sent_count: sentCount,
    error: sentCount > 0 ? undefined : errors[0],
    invalid_tokens: invalid,
  };
}

// ------------------------------------------------------------ handler
function sameSecret(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  return diff === 0;
}

Deno.serve(async (req) => {
  const secret = Deno.env.get("PUSH_WEBHOOK_SECRET") ?? "";
  if (!secret || !sameSecret(req.headers.get("x-push-secret") ?? "", secret)) {
    return Response.json({ error: "unauthorized" }, { status: 401 });
  }
  const sa = serviceAccount();
  if (!sa) {
    // Leave everything queued; the database retries every minute.
    return Response.json({ error: "FCM_SERVICE_ACCOUNT is not set" }, { status: 503 });
  }

  let claimed = 0, sent = 0, failed = 0, tokensRemoved = 0;
  for (let round = 0; round < MAX_ROUNDS; round++) {
    const { data, error } = await supabase.rpc("push_claim", { p_limit: 100 });
    if (error) return Response.json({ error: error.message }, { status: 500 });
    const batch = (data ?? []) as Claimed[];
    if (batch.length === 0) break;
    claimed += batch.length;

    const reports = await Promise.all(batch.map((n) => deliver(sa, n)));
    sent += reports.filter((r) => r.ok).length;
    failed += reports.filter((r) => !r.ok).length;
    tokensRemoved += reports.reduce((s, r) => s + r.invalid_tokens.length, 0);

    const { error: reportError } = await supabase.rpc("push_report", { p_results: reports });
    if (reportError) return Response.json({ error: reportError.message }, { status: 500 });
    if (batch.length < 100) break;
  }

  const summary = { claimed, sent, failed, tokens_removed: tokensRemoved };
  console.log(JSON.stringify({ event: "send_push", ...summary }));
  return Response.json(summary);
});

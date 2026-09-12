// Shared helpers for the demo tools (seed, reset, simulate).
// Reads .secrets/supabase.env; demo accounts share one password kept in
// .secrets/demo.env (created on first use). Nothing here goes into the apps.
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

export const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');

function loadEnvFile(file) {
  if (!fs.existsSync(file)) return;
  for (const line of fs.readFileSync(file, 'utf8').split(/\r?\n/)) {
    const m = line.match(/^\s*([A-Z_]+)\s*=\s*(.+?)\s*$/);
    if (m && !process.env[m[1]]) process.env[m[1]] = m[2];
  }
}
loadEnvFile(path.join(root, '.secrets', 'supabase.env'));
loadEnvFile(path.join(root, '.secrets', 'demo.env'));

export const U = process.env.SUPABASE_URL;
export const PUB = process.env.SUPABASE_PUBLISHABLE_KEY;
export const SEC = process.env.SUPABASE_SECRET_KEY;
if (!U || !PUB || !SEC) {
  console.error('Missing SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY / SUPABASE_SECRET_KEY in .secrets/supabase.env');
  process.exit(2);
}

export const DEMO_DOMAIN = 'demo.clickgas.app';

/** The shared demo password, generated once and kept in .secrets/demo.env. */
export function demoPassword() {
  if (process.env.DEMO_PASSWORD) return process.env.DEMO_PASSWORD;
  const pw = `Demo-${crypto.randomBytes(5).toString('hex')}`;
  fs.appendFileSync(path.join(root, '.secrets', 'demo.env'), `DEMO_PASSWORD=${pw}\n`);
  process.env.DEMO_PASSWORD = pw;
  return pw;
}

export async function call(p, { method = 'GET', token, key = PUB, body, prefer } = {}) {
  const headers = { apikey: key, 'Content-Type': 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;
  if (prefer) headers.Prefer = prefer;
  const res = await fetch(U + p, { method, headers, body: body === undefined ? undefined : JSON.stringify(body) });
  const text = await res.text();
  let json;
  try { json = JSON.parse(text); } catch { json = text; }
  return { status: res.status, ok: res.status < 300, j: json };
}

/** Service-role call (bypasses RLS) - demo tooling only. */
export const admin = (p, opts = {}) => call(p, { ...opts, key: SEC });
export const rpc = (fn, body = {}, opts = {}) => call(`/rest/v1/rpc/${fn}`, { method: 'POST', body, ...opts });

export async function signIn(email, password = demoPassword()) {
  const r = await call('/auth/v1/token?grant_type=password', { method: 'POST', body: { email, password } });
  if (!r.j?.access_token) throw new Error(`sign-in failed for ${email}: ${JSON.stringify(r.j)}`);
  return { token: r.j.access_token, refresh: r.j.refresh_token, expiresAt: Date.now() + r.j.expires_in * 1000, id: r.j.user.id };
}

export async function refresh(session) {
  const r = await call('/auth/v1/token?grant_type=refresh_token', { method: 'POST', body: { refresh_token: session.refresh } });
  if (!r.j?.access_token) throw new Error(`refresh failed: ${JSON.stringify(r.j)}`);
  Object.assign(session, { token: r.j.access_token, refresh: r.j.refresh_token, expiresAt: Date.now() + r.j.expires_in * 1000 });
  return session;
}

export const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

export function distanceM(a, b) {
  const R = 6371000;
  const rad = (d) => (d * Math.PI) / 180;
  const dLat = rad(b[0] - a[0]);
  const dLng = rad(b[1] - a[1]);
  const h = Math.sin(dLat / 2) ** 2 + Math.cos(rad(a[0])) * Math.cos(rad(b[0])) * Math.sin(dLng / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(h));
}

export function bearing(a, b) {
  const rad = (d) => (d * Math.PI) / 180;
  const y = Math.sin(rad(b[1] - a[1])) * Math.cos(rad(b[0]));
  const x = Math.cos(rad(a[0])) * Math.sin(rad(b[0])) - Math.sin(rad(a[0])) * Math.cos(rad(b[0])) * Math.cos(rad(b[1] - a[1]));
  return ((Math.atan2(y, x) * 180) / Math.PI + 360) % 360;
}

/**
 * A driving route [[lat, lng], ...] between two points along real roads
 * (public OSRM demo server, light use only), or a straight line if it is
 * unreachable.
 */
export async function route(from, to) {
  try {
    const url = `https://router.project-osrm.org/route/v1/driving/${from[1]},${from[0]};${to[1]},${to[0]}?overview=full&geometries=geojson`;
    const res = await fetch(url, { signal: AbortSignal.timeout(8000), headers: { 'User-Agent': 'ClickGas-demo/1.0' } });
    const json = await res.json();
    const coords = json.routes?.[0]?.geometry?.coordinates;
    if (coords?.length >= 2) return coords.map(([lng, lat]) => [lat, lng]);
  } catch { /* fall back */ }
  const steps = 30;
  return Array.from({ length: steps + 1 }, (_, i) => [
    from[0] + ((to[0] - from[0]) * i) / steps,
    from[1] + ((to[1] - from[1]) * i) / steps,
  ]);
}

// ------------------------------------------------------------------ demo cast
// Fixed accounts so presenters can sign in with the same logins every time.
// Phones use the range 079 000 09xx.

export const OWNER = { key: 'owner', email: `owner@${DEMO_DOMAIN}`, name: 'مدير العرض', phone: '+962790000900' };

export const DISTRIBUTORS = [
  { key: 'd1', name: 'أبو خالد العمري', phone: '+962790000911', plate: '20-11451', type: 'pickup', agency: 'وكالة النور للغاز', base: [31.9460, 35.8840], area: 'Abdoun' },
  { key: 'd2', name: 'محمد الزعبي', phone: '+962790000912', plate: '21-33872', type: 'van', agency: 'وكالة الشرق للغاز', base: [31.9955, 35.8350], area: 'Khalda' },
  { key: 'd3', name: 'سامر الحياري', phone: '+962790000913', plate: '18-55013', type: 'small_truck', agency: 'وكالة النور للغاز', base: [32.0030, 35.9360], area: 'Tabarbour' },
  { key: 'd4', name: 'أحمد العبادي', phone: '+962790000914', plate: '22-40981', type: 'pickup', agency: 'وكالة الأردن للغاز', base: [31.9660, 35.9160], area: 'Jabal Al-Hussein' },
  // Waits for approval, so the approval flow can be shown.
  { key: 'd5', name: 'يوسف القضاة', phone: '+962790000915', plate: '19-77120', type: 'van', agency: 'وكالة الشرق للغاز', base: [31.9790, 35.9900], area: 'Marka', pending: true },
].map((d) => ({ ...d, email: `${d.key}@${DEMO_DOMAIN}` }));

export const CUSTOMERS = [
  { name: 'ليلى حداد', spot: [31.9505, 35.8795] },
  { name: 'عمر النسور', spot: [31.9570, 35.8610] },
  { name: 'رنا الخطيب', spot: [31.9690, 35.9000] },
  { name: 'خالد المومني', spot: [31.9930, 35.8410] },
  { name: 'سلمى الرفاعي', spot: [32.0240, 35.8750] },
  { name: 'فراس العزام', spot: [32.0060, 35.9300] },
  { name: 'هبة الشريف', spot: [31.9620, 35.9230] },
  { name: 'زيد الطراونة', spot: [31.9420, 35.8930] },
  { name: 'دانة بدران', spot: [31.9850, 35.9820] },
  { name: 'باسل الكردي', spot: [31.8780, 35.8330] },
  { name: 'نور الصمادي', spot: [32.0728, 36.0880], cityId: 2 },
  { name: 'مالك الجبور', spot: [32.0650, 36.0950], cityId: 2 },
].map((c, i) => ({
  ...c,
  key: `c${String(i + 1).padStart(2, '0')}`,
  email: `c${String(i + 1).padStart(2, '0')}@${DEMO_DOMAIN}`,
  phone: `+9627900009${String(20 + i).padStart(2, '0')}`,
  cityId: c.cityId ?? 1,
}));

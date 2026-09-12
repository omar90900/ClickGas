// Creates (or promotes) a staff account for the admin dashboard.
// Needs the secret key, so it runs only from a trusted machine.
//
//   node tools/admin/create-staff.mjs --email owner@clickgas.app --name "Omar" \
//        --phone 0791234567 --role owner [--password "..."]
//
// - If no account has that email, one is created (email already confirmed)
//   with the given name and phone; a password is generated unless given.
// - The account then gets role 'admin' and a staff_members row.
// Later staff can be added from the dashboard (Staff page) by the owner.
// Requires migration 20260912150000_admin_core.sql. Reads .secrets/supabase.env.
import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '../..');
const envFile = path.join(root, '.secrets', 'supabase.env');
if (fs.existsSync(envFile)) {
  for (const line of fs.readFileSync(envFile, 'utf8').split(/\r?\n/)) {
    const m = line.match(/^\s*([A-Z_]+)\s*=\s*(.+?)\s*$/);
    if (m && !process.env[m[1]]) process.env[m[1]] = m[2];
  }
}
const U = process.env.SUPABASE_URL;
const SEC = process.env.SUPABASE_SECRET_KEY;
if (!U || !SEC) {
  console.error('Missing SUPABASE_URL / SUPABASE_SECRET_KEY (.secrets/supabase.env)');
  process.exit(2);
}

const args = {};
for (let i = 2; i < process.argv.length; i += 2) {
  args[process.argv[i].replace(/^--/, '')] = process.argv[i + 1];
}
const email = (args.email || '').trim().toLowerCase();
const role = args.role || 'owner';
if (!email || !['owner', 'operations', 'support'].includes(role)) {
  console.error('Usage: --email <email> [--name <full name>] [--phone 07XXXXXXXX] [--role owner|operations|support] [--password <pw>]');
  process.exit(2);
}

function normalizePhone(input) {
  let d = String(input || '').replace(/\D/g, '');
  if (d.startsWith('00962')) d = d.slice(5);
  if (d.startsWith('962')) d = d.slice(3);
  if (d.startsWith('0')) d = d.slice(1);
  const e164 = `+962${d}`;
  return /^\+9627[789]\d{7}$/.test(e164) ? e164 : null;
}

async function call(p, { method = 'GET', body, prefer } = {}) {
  const headers = { apikey: SEC, 'Content-Type': 'application/json' };
  if (prefer) headers.Prefer = prefer;
  const res = await fetch(U + p, { method, headers, body: body ? JSON.stringify(body) : undefined });
  const text = await res.text();
  let json;
  try { json = JSON.parse(text); } catch { json = text; }
  return { status: res.status, j: json };
}

let profile = (await call(`/rest/v1/profiles?email=eq.${encodeURIComponent(email)}&select=id,full_name,role`)).j[0];
let password = null;

if (!profile) {
  const phone = normalizePhone(args.phone);
  if (!args.name || !phone) {
    console.error('No account with that email yet: give --name and a Jordanian --phone to create one.');
    process.exit(2);
  }
  password = args.password || `Cg-${crypto.randomBytes(9).toString('base64url')}`;
  const created = await call('/auth/v1/admin/users', {
    method: 'POST',
    body: { email, password, email_confirm: true, user_metadata: { full_name: args.name, phone, city_id: 1 } },
  });
  if (created.status >= 300) {
    console.error('Could not create the account:', JSON.stringify(created.j));
    process.exit(1);
  }
  profile = { id: created.j.id, full_name: args.name, role: 'customer' };
  console.log(`Created account ${email}`);
}

if (profile.role === 'driver') {
  console.error('Distributor accounts cannot be staff. Use another email.');
  process.exit(1);
}

const promoted = await call(`/rest/v1/profiles?id=eq.${profile.id}`, {
  method: 'PATCH', body: { role: 'admin', is_active: true },
});
const staff = await call('/rest/v1/staff_members?on_conflict=user_id', {
  method: 'POST', body: { user_id: profile.id, role }, prefer: 'resolution=merge-duplicates',
});
if (promoted.status >= 300 || staff.status >= 300) {
  console.error('Could not set the staff role:', JSON.stringify(promoted.j), JSON.stringify(staff.j));
  console.error('Is supabase/migrations/20260912150000_admin_core.sql applied?');
  process.exit(1);
}

console.log(`${profile.full_name} <${email}> is now staff with role "${role}".`);
if (password) {
  console.log(`Password (shown once - store it in a password manager): ${password}`);
}

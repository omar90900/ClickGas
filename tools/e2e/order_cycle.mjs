// End-to-end check of the customer <-> distributor order cycle against a real
// Supabase project. Creates temporary accounts and orders and deletes them all
// at the end, even when a check fails.
//
//   node tools/e2e/order_cycle.mjs            (reads .secrets/supabase.env)
//
// Needs: SUPABASE_URL, SUPABASE_PUBLISHABLE_KEY, SUPABASE_SECRET_KEY.
// Requires migrations up to 20260912090000_foundation.sql.
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
const PUB = process.env.SUPABASE_PUBLISHABLE_KEY;
const SEC = process.env.SUPABASE_SECRET_KEY;
if (!U || !PUB || !SEC) {
  console.error('Missing SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY / SUPABASE_SECRET_KEY');
  process.exit(2);
}

let failures = 0;
const check = (ok, what) => {
  if (!ok) failures++;
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${what}`);
};

async function call(p, { method = 'GET', token, key = PUB, body, prefer } = {}) {
  const headers = { apikey: key, 'Content-Type': 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;
  if (prefer) headers.Prefer = prefer;
  const res = await fetch(U + p, { method, headers, body: body ? JSON.stringify(body) : undefined });
  const text = await res.text();
  let json;
  try { json = JSON.parse(text); } catch { json = text; }
  return { status: res.status, j: json };
}
const rpc = (fn, token, body = {}) => call(`/rest/v1/rpc/${fn}`, { method: 'POST', token, body });
const errCode = (r) => JSON.stringify(r.j);

const stamp = Date.now().toString().slice(-6);
const users = [];
async function signup(tag, digit, extra = {}) {
  const email = `e2e.${tag}.${stamp}@clickgas.app`;
  const password = `E2e#${stamp}x`;
  const phone = `+9627${digit}${stamp}0`.slice(0, 13);
  const r = await call('/auth/v1/signup', {
    method: 'POST',
    body: { email, password, data: { full_name: `E2E ${tag}`, phone, city_id: 1, ...extra } },
  });
  const id = r.j.user?.id;
  if (id) users.push(id);
  return { id, token: r.j.access_token, phone, password, email };
}

const HERE = [31.9539, 35.9106];
const NEAR = [31.9580, 35.9150];

try {
  const drv = await signup('driver', 7, {
    account_type: 'driver', vehicle_plate: '12-34567', vehicle_type: 'pickup', agency_name: 'E2E Agency',
  });
  const cust = await signup('customer', 8);
  check(drv.token && cust.token, 'sign-up returns sessions for a distributor and a customer');

  // Phone login (ADR 0005)
  const good = await rpc('login_email_for_phone', null, { p_phone: cust.phone, p_password: cust.password });
  check(good.j === cust.email, 'phone login returns the email with the right password');
  const bad = await rpc('login_email_for_phone', null, { p_phone: cust.phone, p_password: 'wrong' });
  check(bad.j === null, 'phone login returns null with a wrong password');
  const old = await rpc('email_for_phone', null, { p_phone: cust.phone });
  check(old.status === 404, `old email_for_phone lookup is gone (HTTP ${old.status})`);

  // Fees in force
  const fees = await call('/rest/v1/current_fees?select=customer_fee,driver_fee');
  check(Number(fees.j[0]?.customer_fee) === 0.1 && Number(fees.j[0]?.driver_fee) === 0.05,
    'current fees are 0.100 (customer) + 0.050 (distributor)');

  // Distributor ready
  await call(`/rest/v1/drivers?id=eq.${drv.id}`, { method: 'PATCH', key: SEC, body: { is_verified: true } });
  await call(`/rest/v1/drivers?id=eq.${drv.id}`, {
    method: 'PATCH', token: drv.token,
    body: { is_online: true, lat: HERE[0], lng: HERE[1], cylinders_on_board: 5 },
  });

  // Customer orders 2 cylinders with a fake price
  const created = await call('/rest/v1/orders?select=id,order_number,total_price,service_fee,driver_fee,status', {
    method: 'POST', token: cust.token, prefer: 'return=representation',
    body: { customer_id: cust.id, service_id: 1, quantity: 2, payment_method: 'cash',
            delivery_lat: NEAR[0], delivery_lng: NEAR[1], total_price: 0.01 },
  });
  const order = created.j[0];
  check(order && Number(order.total_price) === 14.1 && Number(order.service_fee) === 0.1 && Number(order.driver_fee) === 0.05,
    `server sets total 14.100 = 2 × 7.000 + 0.100 fee (got ${order?.total_price})`);

  const direct = await call(`/rest/v1/orders?id=eq.${order.id}`, {
    method: 'PATCH', token: cust.token, body: { status: 'delivered' }, prefer: 'return=representation',
  });
  check(direct.status >= 400, `customer cannot change status directly (HTTP ${direct.status})`);

  const near = await rpc('nearby_orders', drv.token, { p_lat: HERE[0], p_lng: HERE[1] });
  check(Array.isArray(near.j) && near.j.some((o) => o.id === order.id), 'distributor sees the order nearby');

  const accepted = await rpc('accept_order', drv.token, { p_order_id: order.id });
  check(accepted.j?.status === 'accepted', 'distributor accepts');

  const skip = await rpc('complete_order', cust.token, { p_order_id: order.id });
  check(skip.status >= 400, 'customer cannot complete the order');

  const done = await rpc('complete_order', drv.token, { p_order_id: order.id });
  check(done.j?.status === 'delivered', 'distributor marks delivered');

  const ledger = await call(`/rest/v1/driver_ledger?select=kind,amount&order_id=eq.${order.id}`, { token: drv.token });
  check(ledger.j?.length === 1 && Number(ledger.j[0].amount) === 0.15 && ledger.j[0].kind === 'order_fee',
    'ledger books 0.150 for the delivery');
  const balance = await rpc('driver_balance', drv.token);
  check(Number(balance.j) === 0.15, `distributor owes 0.150 (got ${balance.j})`);

  const again = await rpc('start_delivery', drv.token, { p_order_id: order.id });
  check(errCode(again).includes('INVALID_TRANSITION'), 'delivered order cannot go back on the way');

  const conf = await rpc('confirm_delivery', cust.token, { p_order_id: order.id });
  check(!!conf.j?.customer_confirmed_at, 'customer confirms receipt');

  const stock = await call(`/rest/v1/drivers?id=eq.${drv.id}&select=cylinders_on_board`, { token: drv.token });
  check(stock.j[0]?.cylinders_on_board === 3, 'cylinders on board 5 -> 3');
} catch (e) {
  failures++;
  console.log('ERROR', e.message);
} finally {
  for (const id of users) await call(`/rest/v1/orders?customer_id=eq.${id}`, { method: 'DELETE', key: SEC });
  let deleted = 0;
  for (const id of users) {
    const r = await call(`/auth/v1/admin/users/${id}`, { method: 'DELETE', key: SEC });
    if (r.status === 200) deleted++;
  }
  console.log(`cleanup: ${deleted}/${users.length} test accounts deleted`);
  console.log(failures === 0 ? 'ALL CHECKS PASSED' : `${failures} CHECK(S) FAILED`);
  process.exit(failures === 0 ? 0 : 1);
}

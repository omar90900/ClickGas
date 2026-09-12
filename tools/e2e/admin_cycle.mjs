// End-to-end check of the staff functions (migration 20260912150000_admin_core)
// against a real Supabase project. Creates a temporary owner, support staff,
// customer and distributor, exercises the admin_* functions, then deletes
// everything it created (accounts, orders, audit rows). It never changes
// fees or prices; the settings it touches are written back unchanged.
//
//   node tools/e2e/admin_cycle.mjs            (reads .secrets/supabase.env)
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
const PUB = process.env.SUPABASE_PUBLISHABLE_KEY;
const SEC = process.env.SUPABASE_SECRET_KEY;
if (!U || !PUB || !SEC) {
  console.error('Missing SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY / SUPABASE_SECRET_KEY');
  process.exit(2);
}

let failures = 0;
const check = (ok, what, extra) => {
  if (!ok) failures++;
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${what}${!ok && extra !== undefined ? `\n      ${JSON.stringify(extra).slice(0, 400)}` : ''}`);
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
const code = (r) => JSON.stringify(r.j);

const stamp = Date.now().toString().slice(-6);
const users = [];

async function account(tag, digit, meta = {}) {
  const email = `e2e.admin.${tag}.${stamp}@clickgas.app`;
  const password = `E2e#${crypto.randomBytes(6).toString('hex')}`;
  // unique per account: +9627 + digit + 6-digit stamp + account index
  const phone = `+9627${digit}${stamp}${users.length}`;
  const created = await call('/auth/v1/admin/users', {
    method: 'POST', key: SEC,
    body: { email, password, email_confirm: true, user_metadata: { full_name: `E2E ${tag}`, phone, city_id: 1, ...meta } },
  });
  const id = created.j.id;
  if (!id) throw new Error(`could not create ${tag}: ${JSON.stringify(created.j)}`);
  users.push(id);
  const session = await call('/auth/v1/token?grant_type=password', { method: 'POST', body: { email, password } });
  return { id, token: session.j.access_token, email, phone };
}

async function makeStaff(user, role) {
  await call(`/rest/v1/profiles?id=eq.${user.id}`, { method: 'PATCH', key: SEC, body: { role: 'admin' } });
  await call('/rest/v1/staff_members', { method: 'POST', key: SEC, body: { user_id: user.id, role } });
}

try {
  const owner = await account('owner', 7);
  const support = await account('support', 7);
  const cust = await account('customer', 8);
  const drv = await account('driver', 9, {
    account_type: 'driver', vehicle_plate: '99-12345', vehicle_type: 'pickup', agency_name: 'E2E Agency',
  });
  await makeStaff(owner, 'owner');
  await makeStaff(support, 'support');
  check(owner.token && support.token && cust.token && drv.token, 'temporary owner, support, customer and distributor signed in');

  // ---------------------------------------------------------------- who is staff
  const me = await rpc('admin_whoami', owner.token);
  check(me.j?.[0]?.role === 'owner', 'whoami: owner', me.j);
  const notMe = await rpc('admin_whoami', cust.token);
  check(Array.isArray(notMe.j) && notMe.j.length === 0, 'whoami: empty for a customer', notMe.j);
  const denied = await rpc('admin_overview', cust.token);
  check(code(denied).includes('PERMISSION_DENIED'), 'customers cannot open the dashboard', denied.j);

  // ---------------------------------------------------------------- distributor approval
  // New distributors wait for approval unless app_config.auto_verify_drivers is on.
  const auto = (await call('/rest/v1/app_config?select=auto_verify_drivers', { key: SEC })).j?.[0]?.auto_verify_drivers === true;
  const drvRow = await call(`/rest/v1/drivers?id=eq.${drv.id}&select=status,is_verified`, { key: SEC });
  const expected = auto ? 'approved' : 'pending';
  check(drvRow.j?.[0]?.status === expected && drvRow.j[0].is_verified === auto,
    `new distributor is ${expected} (auto-approve ${auto ? 'on' : 'off'})`, drvRow.j);
  if (auto) {
    // Put them back in the queue so the approval steps below are real.
    await call(`/rest/v1/drivers?id=eq.${drv.id}`, { method: 'PATCH', key: SEC, body: { status: 'pending' } });
  }
  const supApprove = await rpc('admin_set_driver_status', support.token, { p_driver_id: drv.id, p_status: 'approved' });
  check(code(supApprove).includes('PERMISSION_DENIED'), 'support cannot approve', supApprove.j);
  const noReason = await rpc('admin_set_driver_status', owner.token, { p_driver_id: drv.id, p_status: 'rejected' });
  check(code(noReason).includes('REASON_REQUIRED'), 'rejecting needs a reason', noReason.j);

  // documents: upload a tiny file and register it
  const png = Buffer.from('89504e470d0a1a0a0000000d4948445200000001000000010806000000'
    + '1f15c4890000000d49444154789c6300010000050001', 'hex');
  const filePath = `${drv.id}/national_id-${stamp}.jpg`;
  const up = await fetch(`${U}/storage/v1/object/driver-docs/${filePath}`, {
    method: 'POST',
    headers: { apikey: PUB, Authorization: `Bearer ${drv.token}`, 'Content-Type': 'image/jpeg' },
    body: png,
  });
  check(up.status === 200, `distributor uploads to driver-docs (HTTP ${up.status})`);
  const other = await fetch(`${U}/storage/v1/object/driver-docs/${cust.id}/x-${stamp}.jpg`, {
    method: 'POST',
    headers: { apikey: PUB, Authorization: `Bearer ${drv.token}`, 'Content-Type': 'image/jpeg' },
    body: png,
  });
  check(other.status >= 400, `nobody writes into another folder (HTTP ${other.status})`);
  const doc = await rpc('submit_driver_document', drv.token, { p_kind: 'national_id', p_file_path: filePath });
  check(doc.j?.status === 'pending', 'document registered as pending', doc.j);
  const signed = await call(`/storage/v1/object/sign/driver-docs/${filePath}`, {
    method: 'POST', token: owner.token, body: { expiresIn: 60 },
  });
  check(!!(signed.j?.signedURL || signed.j?.signedUrl), 'staff get a private link to the document', signed.j);
  const review = await rpc('admin_review_document', owner.token, { p_document_id: doc.j?.id, p_approve: true });
  check(review.j?.status === 'approved', 'owner approves the document', review.j);

  const approve = await rpc('admin_set_driver_status', owner.token, { p_driver_id: drv.id, p_status: 'approved' });
  check(approve.j?.status === 'approved' && approve.j?.is_verified === true, 'owner approves the distributor', approve.j);

  const list = await rpc('admin_list_drivers', owner.token, { p_driver_id: drv.id });
  check(list.j?.[0]?.id === drv.id && list.j[0].documents_total === 1, 'distributor list (one distributor)', list.j);
  const all = await rpc('admin_list_drivers', support.token, {});
  check(Array.isArray(all.j), 'support can read the distributor list', all.j);

  // ---------------------------------------------------------------- orders
  await call(`/rest/v1/drivers?id=eq.${drv.id}`, {
    method: 'PATCH', token: drv.token, body: { is_online: true, lat: 31.9539, lng: 35.9106, cylinders_on_board: 1 },
  });
  const created = await call('/rest/v1/orders?select=id,order_number', {
    method: 'POST', token: cust.token, prefer: 'return=representation',
    body: { customer_id: cust.id, service_id: 1, quantity: 2, payment_method: 'cash', delivery_lat: 31.958, delivery_lng: 35.915 },
  });
  const order = created.j?.[0];
  check(!!order?.id, 'customer places an order', created.j);

  const overview = await rpc('admin_overview', support.token);
  check(overview.j?.orders_today >= 1 && overview.j?.last_14_days?.length === 14, 'overview: today and 14 days', overview.j);
  const live = await rpc('admin_live_map', owner.token);
  check(live.j?.orders?.some((o) => o.id === order.id) && live.j?.drivers?.some((d) => d.id === drv.id),
    'live map shows the order and the distributor', live.j);

  const tooMany = await rpc('admin_assign_order', owner.token, { p_order_id: order.id, p_driver_id: drv.id, p_reason: 'closest' });
  check(code(tooMany).includes('NOT_ENOUGH_CYLINDERS'), 'assigning checks cylinders on board', tooMany.j);
  await call(`/rest/v1/drivers?id=eq.${drv.id}`, { method: 'PATCH', token: drv.token, body: { cylinders_on_board: 5 } });
  const assigned = await rpc('admin_assign_order', owner.token, { p_order_id: order.id, p_driver_id: drv.id, p_reason: 'closest' });
  check(assigned.j?.status === 'accepted' && assigned.j?.driver_id === drv.id, 'owner assigns the order', assigned.j);
  const back = await rpc('admin_assign_order', owner.token, { p_order_id: order.id, p_driver_id: null, p_reason: 'truck broke down' });
  check(back.j?.status === 'pending' && back.j?.driver_id === null, 'owner puts it back in the queue', back.j);

  const found = await rpc('admin_search_orders', support.token, { p_search: String(order.order_number) });
  check(found.j?.length === 1 && found.j[0].total_count === 1, 'search by order number', found.j);
  const byPhone = await rpc('admin_search_orders', support.token, { p_search: cust.phone, p_statuses: ['pending'] });
  check(byPhone.j?.length === 1, 'search by customer phone and status', byPhone.j);

  const supCancel = await rpc('admin_cancel_order', support.token, { p_order_id: order.id, p_reason: 'test' });
  check(code(supCancel).includes('PERMISSION_DENIED'), 'support cannot cancel orders', supCancel.j);
  const cancelled = await rpc('admin_cancel_order', owner.token, { p_order_id: order.id, p_reason: 'customer called' });
  check(cancelled.j?.status === 'cancelled', 'owner cancels with a reason', cancelled.j);

  const detail = await rpc('admin_order_detail', owner.token, { p_order_id: order.id });
  check(detail.j?.events?.length >= 4 && detail.j?.actions?.length === 3,
    `inspector: ${detail.j?.events?.length} events, ${detail.j?.actions?.length} staff actions`, detail.j);

  // ---------------------------------------------------------------- customers
  const customers = await rpc('admin_list_customers', support.token, { p_search: cust.phone });
  check(customers.j?.[0]?.id === cust.id && customers.j[0].cancelled === 1, 'customer list with order counts', customers.j);
  const block = await rpc('admin_set_account_active', support.token, { p_user_id: cust.id, p_active: false, p_reason: 'e2e test' });
  check(block.j?.is_active === false, 'support blocks a customer', block.j);
  const blockedOrder = await call('/rest/v1/orders', {
    method: 'POST', token: cust.token,
    body: { customer_id: cust.id, service_id: 1, quantity: 1, payment_method: 'cash', delivery_lat: 31.95, delivery_lng: 35.91 },
  });
  check(blockedOrder.status >= 400, `a blocked customer cannot order (HTTP ${blockedOrder.status})`);
  const unblock = await rpc('admin_set_account_active', support.token, { p_user_id: cust.id, p_active: true });
  check(unblock.j?.is_active === true, 'support unblocks', unblock.j);
  const blockDrv = await rpc('admin_set_account_active', support.token, { p_user_id: drv.id, p_active: false, p_reason: 'e2e test' });
  check(code(blockDrv).includes('PERMISSION_DENIED'), 'support cannot block distributors', blockDrv.j);

  // ---------------------------------------------------------------- money
  const supPay = await rpc('record_driver_payment', support.token, { p_driver_id: drv.id, p_amount: 1 });
  check(code(supPay).includes('PERMISSION_DENIED'), 'support cannot record payments', supPay.j);
  const pay = await rpc('record_driver_payment', owner.token, { p_driver_id: drv.id, p_amount: 2.5, p_note: 'e2e' });
  check(Number(pay.j?.amount) === -2.5, 'payment stored as -2.500', pay.j);
  const balances = await rpc('admin_balances', owner.token);
  const mine = balances.j?.find?.((b) => b.driver_id === drv.id);
  check(mine && Number(mine.balance) === -2.5 && Number(mine.payments) === 2.5, 'balances show the payment', mine ?? balances.j);

  // ---------------------------------------------------------------- settings (no real change)
  const cfg = (await call('/rest/v1/app_config?select=driver_radius_km', { token: owner.token })).j?.[0];
  const bad = await rpc('admin_update_config', owner.token, { p_changes: { nope: 1 } });
  check(code(bad).includes('INVALID_SETTING'), 'unknown settings are refused', bad.j);
  const same = await rpc('admin_update_config', owner.token, { p_changes: { driver_radius_km: Number(cfg.driver_radius_km) } });
  check(Number(same.j?.driver_radius_km) === Number(cfg.driver_radius_km), 'owner saves settings (unchanged value)', same.j);
  const supCfg = await rpc('admin_update_config', support.token, { p_changes: { driver_radius_km: 2 } });
  check(code(supCfg).includes('PERMISSION_DENIED'), 'support cannot change settings', supCfg.j);
  const badFees = await rpc('admin_set_fees', owner.token, { p_customer_fee: 9, p_driver_fee: 0 });
  check(code(badFees).includes('INVALID_AMOUNT'), 'fees above 5 JOD are refused (nothing saved)', badFees.j);

  // ---------------------------------------------------------------- staff
  const lastOwner = await rpc('admin_save_staff', owner.token, { p_login: drv.email, p_role: 'support' });
  check(code(lastOwner).includes('INVALID_TARGET'), 'distributors cannot become staff', lastOwner.j);
  const staffList = await call('/rest/v1/staff_members?select=user_id,role,profiles(full_name)', { token: support.token });
  check(Array.isArray(staffList.j) && staffList.j.some((s) => s.user_id === owner.id), 'staff list with names', staffList.j);
  const audit = await call(`/rest/v1/admin_actions?actor_id=in.(${owner.id},${support.id})&select=action`, { token: owner.token });
  check(audit.j?.length >= 9, `every staff action is audited (${audit.j?.length} rows)`, audit.j);
  const custAudit = await call('/rest/v1/admin_actions?select=id&limit=1', { token: cust.token });
  check(Array.isArray(custAudit.j) && custAudit.j.length === 0, 'customers cannot read the audit log', custAudit.j);
} catch (e) {
  failures++;
  console.log('ERROR', e.message);
} finally {
  // Audit rows, orders, uploaded files, then the accounts (profiles, drivers,
  // staff rows, ledger and documents go with them).
  for (const id of users) {
    await call(`/rest/v1/admin_actions?actor_id=eq.${id}`, { method: 'DELETE', key: SEC });
    await call(`/rest/v1/orders?customer_id=eq.${id}`, { method: 'DELETE', key: SEC });
  }
  const files = await call('/storage/v1/object/list/driver-docs', {
    method: 'POST', key: SEC, body: { prefix: users[3] ?? 'none', limit: 100 },
  });
  if (Array.isArray(files.j) && files.j.length) {
    await call('/storage/v1/object/driver-docs', {
      method: 'DELETE', key: SEC, body: { prefixes: files.j.map((f) => `${users[3]}/${f.name}`) },
    });
  }
  let deleted = 0;
  for (const id of users) {
    const r = await call(`/auth/v1/admin/users/${id}`, { method: 'DELETE', key: SEC });
    if (r.status === 200) deleted++;
  }
  console.log(`cleanup: ${deleted}/${users.length} test accounts deleted`);
  console.log(failures === 0 ? 'ALL CHECKS PASSED' : `${failures} CHECK(S) FAILED`);
  process.exit(failures === 0 ? 0 : 1);
}

// Fills the project with a small, clearly marked demo world:
//   1 owner, 5 distributors (4 approved + 1 awaiting approval), 12 customers,
//   15 past orders over the last 14 days, 2 charges, 3 coverage gaps.
// Everything is flagged is_demo and removed by `node tools/demo/reset.mjs`.
// Kept small on purpose (Supabase free tier).
//
//   node tools/demo/seed.mjs
//
// Logins are written to .secrets/demo-accounts.md (git-ignored).
import fs from 'node:fs';
import path from 'node:path';

import { admin, CUSTOMERS, demoPassword, DISTRIBUTORS, OWNER, root, rpc, SEC } from './lib.mjs';

const password = demoPassword();

const existing = await admin(`/rest/v1/profiles?email=eq.${encodeURIComponent(OWNER.email)}&select=id`);
if (existing.j?.length) {
  console.error('Demo data already exists. Run `node tools/demo/reset.mjs` first (or reset.mjs --reseed).');
  process.exit(1);
}

async function createAccount(person, meta = {}) {
  const r = await admin('/auth/v1/admin/users', {
    method: 'POST',
    body: {
      email: person.email,
      password,
      email_confirm: true,
      user_metadata: { full_name: person.name, phone: person.phone, city_id: person.cityId ?? 1, ...meta },
    },
  });
  if (!r.j?.id) throw new Error(`could not create ${person.email}: ${JSON.stringify(r.j)}`);
  return r.j.id;
}

const ids = {};
try {
  // ---------------------------------------------------------------- accounts
  ids.owner = await createAccount(OWNER);
  for (const d of DISTRIBUTORS) {
    ids[d.key] = await createAccount(d, {
      account_type: 'driver', vehicle_plate: d.plate, vehicle_type: d.type, agency_name: d.agency,
    });
  }
  for (const c of CUSTOMERS) ids[c.key] = await createAccount(c);
  const all = Object.values(ids);
  await admin(`/rest/v1/profiles?id=in.(${all.join(',')})`, { method: 'PATCH', body: { is_demo: true } });
  await admin(`/rest/v1/profiles?id=eq.${ids.owner}`, { method: 'PATCH', body: { role: 'admin' } });
  await admin('/rest/v1/staff_members', { method: 'POST', body: { user_id: ids.owner, role: 'owner' } });
  for (const d of DISTRIBUTORS) {
    await admin(`/rest/v1/drivers?id=eq.${ids[d.key]}`, {
      method: 'PATCH',
      body: {
        status: d.pending ? 'pending' : 'approved',
        lat: d.base[0], lng: d.base[1], location_updated_at: new Date().toISOString(),
        cylinders_on_board: 12, is_online: false,
      },
    });
  }
  console.log(`accounts: 1 owner, ${DISTRIBUTORS.length} distributors, ${CUSTOMERS.length} customers`);

  // ---------------------------------------------------------------- order history
  const approved = DISTRIBUTORS.filter((d) => !d.pending);
  const minutes = (n) => n * 60000;
  const orderIds = [];
  for (let i = 0; i < 15; i++) {
    const customer = CUSTOMERS[i % CUSTOMERS.length];
    const driver = approved[i % approved.length];
    const day = new Date();
    day.setDate(day.getDate() - (14 - i));
    day.setHours(9 + ((i * 5) % 11), (i * 17) % 60, 0, 0);
    const created = day.getTime();
    const base = {
      customer_id: ids[customer.key],
      service_id: i === 7 ? 2 : 1,
      quantity: i % 3 === 0 ? 2 : 1,
      lat: customer.spot[0] + ((i % 5) - 2) * 0.0012,
      lng: customer.spot[1] + ((i % 3) - 1) * 0.0012,
      city_id: customer.cityId,
      created_at: new Date(created).toISOString(),
    };
    let order;
    if (i === 3 || i === 9) {
      order = { ...base, status: 'cancelled', cancelled_at: new Date(created + minutes(3)).toISOString(), cancel_reason: 'غيّرت الموعد' };
    } else if (i === 6 || i === 12) {
      order = { ...base, status: 'expired' };
    } else {
      order = {
        ...base,
        status: 'delivered',
        driver_id: ids[driver.key],
        accepted_at: new Date(created + minutes(1 + (i % 5))).toISOString(),
        delivered_at: new Date(created + minutes(18 + (i % 4) * 5)).toISOString(),
        rating: i % 4 === 1 ? 4 : 5,
      };
    }
    const r = await rpc('demo_seed_order', { p: order }, { key: SEC });
    if (!r.ok) throw new Error(`order ${i}: ${JSON.stringify(r.j)}`);
    orderIds.push({ id: r.j, driver: order.driver_id });
  }
  console.log('orders: 15 over the last 14 days (11 delivered, 2 cancelled, 2 expired)');

  // ---------------------------------------------------------------- charges and gaps
  const lateOrder = orderIds.find((o) => o.driver === ids.d2);
  const now = Date.now();
  await admin('/rest/v1/driver_charges', {
    method: 'POST',
    body: [
      {
        driver_id: ids.d2, order_id: lateOrder?.id ?? null, kind: 'fine', title: 'تأخير في التوصيل',
        note: 'وصل الطلب بعد أكثر من ساعة من قبوله دون إبلاغ العميل.', amount: 1, created_by: ids.owner,
        created_at: new Date(now - minutes(60 * 30)).toISOString(),
      },
      {
        driver_id: ids.d1, kind: 'item_fee', title: 'استبدال صمام', note: 'صمام جرة تالف استُبدل من مخزون المنصة.',
        amount: 2.5, status: 'paid', created_by: ids.owner, settled_by: ids.owner,
        created_at: new Date(now - minutes(60 * 72)).toISOString(),
        settled_at: new Date(now - minutes(60 * 48)).toISOString(),
      },
    ],
  });
  await admin('/rest/v1/coverage_gaps', {
    method: 'POST',
    body: [
      { customer_id: ids.c11, lat: 32.0728, lng: 36.0880, city_id: 2, is_demo: true, created_at: new Date(now - minutes(60 * 20)).toISOString() },
      { customer_id: ids.c12, lat: 32.0650, lng: 36.0950, city_id: 2, is_demo: true, created_at: new Date(now - minutes(60 * 44)).toISOString() },
      { customer_id: ids.c10, lat: 31.8780, lng: 35.8330, city_id: 1, is_demo: true, created_at: new Date(now - minutes(60 * 70)).toISOString() },
    ],
  });
  console.log('charges: 2 (1 open, 1 paid); coverage gaps: 3');
} catch (e) {
  console.error('Seeding failed:', e.message);
  console.error('Run `node tools/demo/reset.mjs` to remove what was created, then try again.');
  process.exit(1);
}

// ---------------------------------------------------------------- logins
const lines = [
  '# ClickGas demo accounts',
  '',
  `Password for every demo account: \`${password}\``,
  '',
  '| Role | Name | Email | Phone |',
  '|---|---|---|---|',
  `| Owner (dashboard) | ${OWNER.name} | ${OWNER.email} | 079 000 0900 |`,
  ...DISTRIBUTORS.map((d) => `| Distributor${d.pending ? ' (awaiting approval)' : ''} | ${d.name} | ${d.email} | 0${d.phone.slice(4)} |`),
  ...CUSTOMERS.map((c) => `| Customer | ${c.name} | ${c.email} | 0${c.phone.slice(4)} |`),
  '',
  'Created by tools/demo/seed.mjs. Remove with tools/demo/reset.mjs.',
];
fs.writeFileSync(path.join(root, '.secrets', 'demo-accounts.md'), lines.join('\n') + '\n');
console.log('logins written to .secrets/demo-accounts.md');
console.log('done');

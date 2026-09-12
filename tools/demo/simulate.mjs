// Drives the approved demo distributors around Amman so the maps look alive
// during a presentation. Each simulated distributor goes online, cruises near
// its base, accepts orders near it (real or demo), drives there along real
// roads, delivers, and carries on. Uses the same app functions as the phone
// app, so every rule (radius, slots, stock) applies.
//
//   node tools/demo/simulate.mjs [--minutes 30] [--drivers 4] [--orders 0] [--demo-orders-only] [--speed 3]
//
//   --orders N          also place N demo customer orders, one every 90 s
//   --demo-orders-only  leave real customers' orders to real distributors
//   --speed             how many times faster than real driving (default 3)
//
// Ctrl+C takes everyone offline before exiting. Writes one position per
// distributor every 5 seconds (well within the free tier).
import { bearing, call, CUSTOMERS, distanceM, DISTRIBUTORS, refresh, route, rpc, signIn, sleep } from './lib.mjs';

const arg = (name, fallback) => {
  const i = process.argv.indexOf(`--${name}`);
  return i > 0 ? Number(process.argv[i + 1]) : fallback;
};
const MINUTES = arg('minutes', 30);
const DRIVERS = arg('drivers', 4);
const ORDERS = arg('orders', 0);
const SPEED = arg('speed', 3);
const DEMO_ONLY = process.argv.includes('--demo-orders-only');
const TICK_MS = 5000;
const KMH = 35 * SPEED;

const log = (who, msg) => console.log(`${new Date().toLocaleTimeString()}  ${who.padEnd(16)} ${msg}`);

// ---------------------------------------------------------------- set up
const cast = DISTRIBUTORS.filter((d) => !d.pending).slice(0, DRIVERS);
const trucks = [];
for (const d of cast) {
  const session = await signIn(d.email);
  trucks.push({
    ...d, session, pos: [...d.base], path: [], state: 'cruise', order: null, pauseUntil: 0,
    label: `${d.key} ${d.area}`,
  });
}

async function update(t, fields) {
  if (Date.now() > t.session.expiresAt - 5 * 60000) await refresh(t.session);
  return call(`/rest/v1/drivers?id=eq.${t.session.id}`, { method: 'PATCH', token: t.session.token, body: fields });
}

async function driverRpc(t, fn, body) {
  return rpc(fn, body, { token: t.session.token });
}

for (const t of trucks) {
  await update(t, {
    is_online: true, cylinders_on_board: 12, lat: t.pos[0], lng: t.pos[1],
    location_updated_at: new Date().toISOString(),
  });
  log(t.label, 'online');
}

let stopping = false;
async function stop() {
  if (stopping) return;
  stopping = true;
  for (const t of trucks) {
    if (t.order) await driverRpc(t, 'release_order', { p_order_id: t.order.id, p_reason: 'simulation ended' });
    await update(t, { is_online: false });
  }
  console.log('all simulated distributors are offline');
  process.exit(0);
}
process.on('SIGINT', stop);

// ---------------------------------------------------------------- driving
function advance(t, meters) {
  while (meters > 0 && t.path.length) {
    const next = t.path[0];
    const d = distanceM(t.pos, next);
    if (d <= meters) {
      t.heading = bearing(t.pos, next);
      t.pos = next;
      t.path.shift();
      meters -= d;
    } else {
      const f = meters / d;
      t.heading = bearing(t.pos, next);
      t.pos = [t.pos[0] + (next[0] - t.pos[0]) * f, t.pos[1] + (next[1] - t.pos[1]) * f];
      meters = 0;
    }
  }
}

async function cruise(t) {
  // A short loop within ~1.2 km of the base.
  const angle = Math.random() * 2 * Math.PI;
  const r = 0.004 + Math.random() * 0.007;
  const target = [t.base[0] + r * Math.cos(angle), t.base[1] + r * Math.sin(angle)];
  t.path = await route(t.pos, target);
}

async function tryAccept(t) {
  const near = await driverRpc(t, 'nearby_orders', { p_lat: t.pos[0], p_lng: t.pos[1] });
  if (!Array.isArray(near.j)) return false;
  for (const o of near.j) {
    if (DEMO_ONLY && !o.customer_name?.trim()) continue;
    if (DEMO_ONLY && !CUSTOMERS.some((c) => c.name === o.customer_name)) continue;
    const a = await driverRpc(t, 'accept_order', { p_order_id: o.id });
    if (a.j?.status !== 'accepted') continue;
    await driverRpc(t, 'start_delivery', { p_order_id: o.id });
    t.order = { id: o.id, number: o.order_number, to: [o.delivery_lat, o.delivery_lng] };
    t.state = 'delivering';
    t.path = await route(t.pos, t.order.to);
    log(t.label, `accepted #${o.order_number} (${Math.round(o.distance_m)} m away), on the way`);
    return true;
  }
  return false;
}

async function tick(t) {
  const now = Date.now();
  if (now < t.pauseUntil) return;
  if (t.state === 'cruise') {
    if (await tryAccept(t)) return;
    if (!t.path.length) await cruise(t);
  }
  advance(t, (KMH * 1000 * TICK_MS) / 3600000);
  if (t.state === 'delivering' && !t.path.length) {
    // Arrived: hand over the cylinder, then deliver.
    await sleep(1000);
    const done = await driverRpc(t, 'complete_order', { p_order_id: t.order.id });
    log(t.label, done.j?.status === 'delivered' ? `delivered #${t.order.number}` : `could not deliver #${t.order.number}: ${JSON.stringify(done.j)}`);
    t.order = null;
    t.state = 'cruise';
    t.pauseUntil = now + 20000;
    const me = await call(`/rest/v1/drivers?id=eq.${t.session.id}&select=cylinders_on_board`, { token: t.session.token });
    if ((me.j?.[0]?.cylinders_on_board ?? 12) < 4) {
      await update(t, { cylinders_on_board: 12 });
      log(t.label, 'reloaded 12 cylinders');
    }
  }
  await update(t, {
    lat: t.pos[0], lng: t.pos[1], heading: t.heading ?? null, location_updated_at: new Date().toISOString(),
  });
}

// ---------------------------------------------------------------- demo orders
const customers = [];
let placed = 0;
let nextOrderAt = Date.now() + 20000;
async function maybePlaceOrder() {
  if (placed >= ORDERS || Date.now() < nextOrderAt) return;
  nextOrderAt = Date.now() + 90000;
  const c = CUSTOMERS.filter((x) => x.cityId === 1)[placed % 10];
  if (!customers[placed]) customers[placed] = await signIn(c.email);
  const s = customers[placed];
  const r = await call('/rest/v1/orders?select=order_number', {
    method: 'POST', token: s.token, prefer: 'return=representation',
    body: { customer_id: s.id, service_id: 1, quantity: 1, payment_method: 'cash', delivery_lat: c.spot[0], delivery_lng: c.spot[1] },
  });
  placed++;
  log('customer', r.ok ? `${c.name} ordered #${r.j[0].order_number}` : `${c.name} could not order: ${JSON.stringify(r.j)}`);
}

// ---------------------------------------------------------------- run
const endAt = Date.now() + MINUTES * 60000;
console.log(`simulating ${trucks.length} distributors for ${MINUTES} min (x${SPEED} speed). Ctrl+C to stop.`);
while (Date.now() < endAt && !stopping) {
  const started = Date.now();
  await maybePlaceOrder().catch((e) => log('customer', e.message));
  await Promise.all(trucks.map((t) => tick(t).catch((e) => log(t.label, `error: ${e.message}`))));
  await sleep(Math.max(0, TICK_MS - (Date.now() - started)));
}
await stop();

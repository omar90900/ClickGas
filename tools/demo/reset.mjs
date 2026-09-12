// Removes all demo data (is_demo) and nothing else: demo orders, gaps and
// staff actions (database function demo_reset_data), then the demo
// accounts, which takes their profiles, distributor rows, charges and
// documents with them. Real accounts and their orders are untouched.
//
//   node tools/demo/reset.mjs            remove demo data
//   node tools/demo/reset.mjs --reseed   remove, then seed again
import { spawnSync } from 'node:child_process';
import path from 'node:path';

import { admin, root, rpc, SEC } from './lib.mjs';

const r = await rpc('demo_reset_data', {}, { key: SEC });
if (!r.ok) {
  console.error('demo_reset_data failed:', JSON.stringify(r.j));
  console.error('Is supabase/migrations/20260913090000_coverage_and_demo.sql applied?');
  process.exit(1);
}
console.log(`removed: ${r.j.orders} orders, ${r.j.coverage_gaps} gaps, ${r.j.admin_actions} staff actions`);

const people = await admin('/rest/v1/profiles?is_demo=eq.true&select=id,role');
let deleted = 0;
for (const p of people.j ?? []) {
  if (p.role === 'driver') {
    const files = await admin('/storage/v1/object/list/driver-docs', { method: 'POST', body: { prefix: p.id, limit: 100 } });
    if (Array.isArray(files.j) && files.j.length) {
      await admin('/storage/v1/object/driver-docs', { method: 'DELETE', body: { prefixes: files.j.map((f) => `${p.id}/${f.name}`) } });
    }
  }
  const d = await admin(`/auth/v1/admin/users/${p.id}`, { method: 'DELETE' });
  if (d.ok) deleted++;
  else console.warn(`could not delete ${p.id}: ${JSON.stringify(d.j)}`);
}
console.log(`removed: ${deleted}/${people.j?.length ?? 0} demo accounts`);

if (process.argv.includes('--reseed')) {
  const seed = spawnSync(process.execPath, [path.join(root, 'tools', 'demo', 'seed.mjs')], { stdio: 'inherit' });
  process.exit(seed.status ?? 1);
}

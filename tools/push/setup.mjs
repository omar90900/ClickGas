#!/usr/bin/env node
// Prepares push delivery (docs/runbooks/push-notifications.md) from the
// Firebase service-account file, without printing any secret:
//
//   node tools/push/setup.mjs [path/to/service-account.json]
//
// Writes, inside .secrets/ (git-ignored):
//   push.env        FCM_SERVICE_ACCOUNT (one line) + PUSH_WEBHOOK_SECRET,
//                   for: npx supabase secrets set --env-file .secrets/push.env
//   push-vault.sql  tells the database where send-push is and the shared
//                   secret (run once in the SQL Editor)
// Running it again keeps the existing PUSH_WEBHOOK_SECRET.

import crypto from 'node:crypto';
import fs from 'node:fs';
import path from 'node:path';

const root = path.resolve(import.meta.dirname, '..', '..');
const secrets = path.join(root, '.secrets');
const saPath = path.resolve(process.argv[2] ?? path.join(secrets, 'firebase-service-account.json'));

function readEnv(file) {
  if (!fs.existsSync(file)) return {};
  const out = {};
  for (const line of fs.readFileSync(file, 'utf8').split(/\r?\n/)) {
    const m = line.match(/^([A-Z0-9_]+)=(.*)$/);
    if (m) out[m[1]] = m[2];
  }
  return out;
}

if (!fs.existsSync(saPath)) {
  console.error(`Service-account file not found: ${saPath}
Firebase console > Project settings > Service accounts > Generate new private key,
save it as .secrets/firebase-service-account.json and run this again.`);
  process.exit(1);
}
const sa = JSON.parse(fs.readFileSync(saPath, 'utf8'));
for (const key of ['project_id', 'client_email', 'private_key']) {
  if (!sa[key]) {
    console.error(`${saPath} has no "${key}": is it a service-account key?`);
    process.exit(1);
  }
}

const supabaseUrl = readEnv(path.join(secrets, 'supabase.env')).SUPABASE_URL;
if (!supabaseUrl) {
  console.error('SUPABASE_URL missing in .secrets/supabase.env');
  process.exit(1);
}
const functionUrl = `${supabaseUrl.replace(/\/$/, '')}/functions/v1/send-push`;

const envFile = path.join(secrets, 'push.env');
const secret = readEnv(envFile).PUSH_WEBHOOK_SECRET || crypto.randomBytes(32).toString('hex');

fs.writeFileSync(envFile,
  `# Edge Function secrets for send-push. Do not commit.\n` +
  `PUSH_WEBHOOK_SECRET=${secret}\n` +
  `FCM_SERVICE_ACCOUNT=${JSON.stringify(sa)}\n`);

const sql = (s) => `'${s.replace(/'/g, "''")}'`;
fs.writeFileSync(path.join(secrets, 'push-vault.sql'),
  `-- Run once in Supabase > SQL Editor. Safe to run again (updates the values).\n` +
  `do $$\n` +
  `declare\n` +
  `  v_url constant text := ${sql(functionUrl)};\n` +
  `  v_secret constant text := ${sql(secret)};\n` +
  `begin\n` +
  `  if exists (select 1 from vault.secrets where name = 'clickgas_push_url') then\n` +
  `    perform vault.update_secret((select id from vault.secrets where name = 'clickgas_push_url'), v_url);\n` +
  `  else\n` +
  `    perform vault.create_secret(v_url, 'clickgas_push_url', 'ClickGas: URL of the send-push Edge Function');\n` +
  `  end if;\n` +
  `  if exists (select 1 from vault.secrets where name = 'clickgas_push_secret') then\n` +
  `    perform vault.update_secret((select id from vault.secrets where name = 'clickgas_push_secret'), v_secret);\n` +
  `  else\n` +
  `    perform vault.create_secret(v_secret, 'clickgas_push_secret', 'ClickGas: shared secret checked by send-push');\n` +
  `  end if;\n` +
  `end $$;\n`);

console.log(`Firebase project: ${sa.project_id}
Function URL:     ${functionUrl}

Written: .secrets/push.env and .secrets/push-vault.sql

Next:
  npx supabase login
  npx supabase link --project-ref ${new URL(supabaseUrl).hostname.split('.')[0]}
  npx supabase secrets set --env-file .secrets/push.env
  npx supabase functions deploy send-push --no-verify-jwt
Then run .secrets/push-vault.sql in the SQL Editor.`);

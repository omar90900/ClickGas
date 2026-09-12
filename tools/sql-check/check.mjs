// Syntax-checks a migration with the PostgreSQL parser (libpg_query), plus the
// PL/pgSQL function bodies. It does not run the SQL.
//
//   cd tools/sql-check && npm install
//   node check.mjs ../../supabase/migrations/20260912090000_foundation.sql
import fs from 'node:fs';
import path from 'node:path';
import * as parser from 'pgsql-parser';

const file = process.argv[2];
if (!file) {
  console.error('usage: node check.mjs <file.sql>');
  process.exit(2);
}
const sql = fs.readFileSync(file, 'utf8');
const name = path.basename(file);

try {
  if (parser.loadModule) await parser.loadModule();
  const tree = await parser.parse(sql);
  const count = (tree.stmts ?? tree).length;

  let plpgsql = 'skipped';
  try {
    let lib = await import('libpg-query');
    lib = lib.default ?? lib;
    if (lib.loadModule) await lib.loadModule();
    const fn = lib.parsePlPgSQL ?? lib.parsePlPgSQLSync;
    if (fn) {
      await fn(sql);
      plpgsql = 'ok';
    }
  } catch (e) {
    throw new Error(`PL/pgSQL: ${e.message}`);
  }

  console.log(`OK  ${name}: ${count} statements, PL/pgSQL ${plpgsql}`);
} catch (e) {
  console.error(`ERR ${name}: ${e.message}${e.cursorPosition ? ` (at ${e.cursorPosition})` : ''}`);
  process.exit(1);
}

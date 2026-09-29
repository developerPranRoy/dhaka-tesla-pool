import fs from "node:fs/promises";
import path from "node:path";
import { pool } from "./db";

// Works from both src/ (tsx) and dist/ (compiled): migrations sit next to them.
const MIGRATIONS_DIR = path.resolve(__dirname, "../migrations");
const LOCK_ID = 727274;

/**
 * Applies every unapplied .sql file in filename order, each in its own
 * transaction. An advisory lock stops two API instances migrating at once.
 */
export async function runMigrations(): Promise<void> {
  const client = await pool.connect();
  try {
    await client.query("SELECT pg_advisory_lock($1)", [LOCK_ID]);
    await client.query(`
      CREATE TABLE IF NOT EXISTS schema_migrations (
        filename   text PRIMARY KEY,
        applied_at timestamptz NOT NULL DEFAULT now()
      )`);

    const { rows } = await client.query<{ filename: string }>("SELECT filename FROM schema_migrations");
    const applied = new Set(rows.map((r) => r.filename));
    const files = (await fs.readdir(MIGRATIONS_DIR)).filter((f) => f.endsWith(".sql")).sort();

    for (const file of files) {
      if (applied.has(file)) continue;
      const sql = await fs.readFile(path.join(MIGRATIONS_DIR, file), "utf8");
      try {
        await client.query("BEGIN");
        await client.query(sql);
        await client.query("INSERT INTO schema_migrations (filename) VALUES ($1)", [file]);
        await client.query("COMMIT");
        console.log(JSON.stringify({ level: "info", msg: "migration applied", file }));
      } catch (err) {
        await client.query("ROLLBACK");
        throw new Error(`Migration ${file} failed: ${String(err)}`);
      }
    }
  } finally {
    await client.query("SELECT pg_advisory_unlock($1)", [LOCK_ID]).catch(() => undefined);
    client.release();
  }
}

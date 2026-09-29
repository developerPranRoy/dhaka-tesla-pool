import { pool } from "./db";
import { runMigrations } from "./migrate";
import { seedDemoData } from "./seed";

async function main() {
  const cmd = process.argv[2];
  if (cmd === "migrate") {
    await runMigrations();
  } else if (cmd === "seed") {
    await runMigrations();
    await seedDemoData();
  } else {
    console.error("usage: cli <migrate|seed>");
    process.exitCode = 1;
  }
  await pool.end();
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});

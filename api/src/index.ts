import { createApp } from "./app";
import { config } from "./config";
import { pool } from "./db";
import { runMigrations } from "./migrate";
import { seedDemoData } from "./seed";

async function main() {
  await runMigrations();
  if (config.seedDemoData) await seedDemoData();

  const server = createApp().listen(config.port, () => {
    console.log(JSON.stringify({ level: "info", msg: "api listening", port: config.port }));
  });

  const shutdown = () => {
    server.close(async () => {
      await pool.end();
      process.exit(0);
    });
  };
  process.on("SIGTERM", shutdown);
  process.on("SIGINT", shutdown);
}

main().catch((err) => {
  console.error(JSON.stringify({ level: "error", msg: "startup failed", err: String(err) }));
  process.exit(1);
});

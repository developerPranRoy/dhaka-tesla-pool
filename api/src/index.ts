import { createApp } from "./app";
import { config } from "./config";
import { pool } from "./db";

const server = createApp().listen(config.port, () => {
  console.log(JSON.stringify({ level: "info", msg: "api listening", port: config.port }));
});

function shutdown() {
  server.close(async () => {
    await pool.end();
    process.exit(0);
  });
}
process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);

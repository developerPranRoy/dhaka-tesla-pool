import cors from "cors";
import express from "express";
import helmet from "helmet";
import { config } from "./config";
import { pool } from "./db";

export function createApp() {
  const app = express();
  app.use(helmet());
  app.use(cors({ origin: config.webOrigin }));
  app.use(express.json());

  app.get("/health", async (_req, res) => {
    try {
      await pool.query("SELECT 1");
      res.json({ status: "ok", db: "up" });
    } catch (err) {
      console.error(JSON.stringify({ level: "error", msg: "health check failed", err: String(err) }));
      res.status(503).json({ status: "degraded", db: "down" });
    }
  });

  return app;
}

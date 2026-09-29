import bcrypt from "bcryptjs";
import { pool } from "./db";

// Demo credentials, documented in the README. Never use these outside a demo.
export const DEMO_PASSWORD = "password123";

const CAST = [
  { name: "Jashim", email: "jashim@tesla.pool", role: "DRIVER" },
  { name: "Nusrat", email: "nusrat@tesla.pool", role: "PASSENGER" },
  { name: "Rafiq", email: "rafiq@tesla.pool", role: "PASSENGER" },
  { name: "Shirin", email: "shirin@tesla.pool", role: "PASSENGER" },
];

/** Idempotent: safe to run on every startup. */
export async function seedDemoData(): Promise<void> {
  const hash = await bcrypt.hash(DEMO_PASSWORD, 10);
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    for (const u of CAST) {
      await client.query(
        `INSERT INTO users (name, email, password_hash, role)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT ((lower(email))) DO NOTHING`,
        [u.name, u.email, hash, u.role],
      );
    }
    // Bullet: Jashim's three-seat, battery-powered, entirely unaffiliated "Tesla".
    await client.query(
      `INSERT INTO vehicles (driver_id, name, capacity)
       SELECT id, 'Bullet', 3 FROM users WHERE lower(email) = 'jashim@tesla.pool'
       ON CONFLICT (driver_id) DO NOTHING`,
    );
    await client.query("COMMIT");
    console.log(JSON.stringify({ level: "info", msg: "demo data seeded" }));
  } catch (err) {
    await client.query("ROLLBACK");
    throw err;
  } finally {
    client.release();
  }
}

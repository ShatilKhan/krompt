// Turso client via drizzle-orm/libsql adapter.
// Install:  npm install drizzle-orm @libsql/client
//           npm install -D drizzle-kit
// Env:      TURSO_DATABASE_URL=libsql://your-db.turso.io
//           TURSO_AUTH_TOKEN=...

import { drizzle } from "drizzle-orm/libsql";
import { createClient } from "@libsql/client";
import * as schema from "./schema";

const url = process.env.TURSO_DATABASE_URL;
const authToken = process.env.TURSO_AUTH_TOKEN;

if (!url) throw new Error("TURSO_DATABASE_URL is not set");

const client = createClient({ url, authToken });

export const db = drizzle(client, { schema });

// drizzle.config.ts for libSQL:
//   import { defineConfig } from "drizzle-kit";
//   export default defineConfig({
//     schema: "./lib/schema.ts",
//     out: "./drizzle",
//     dialect: "turso",
//     dbCredentials: { url: process.env.TURSO_DATABASE_URL!, authToken: process.env.TURSO_AUTH_TOKEN! },
//   });
//
// Scripts:  bun drizzle-kit generate
//           bun drizzle-kit push   # dev
//           bun drizzle-kit migrate

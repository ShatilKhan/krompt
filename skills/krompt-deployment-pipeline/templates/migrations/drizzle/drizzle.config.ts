// Drizzle config for Postgres (Supabase or any Postgres).
// For Turso/libSQL, see ../vercel/lib-db-drizzle-libsql.ts comment block.

import { defineConfig } from "drizzle-kit";

export default defineConfig({
  schema: "./src/db/schema",
  out: "./drizzle",
  dialect: "postgresql",
  dbCredentials: {
    url: process.env.DATABASE_URL!,
  },
});

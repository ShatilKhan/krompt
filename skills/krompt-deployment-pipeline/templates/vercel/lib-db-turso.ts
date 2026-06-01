// Turso client — direct @libsql/client.
// Install:  npm install @libsql/client
// Env:      TURSO_DATABASE_URL=libsql://your-db.turso.io
//           TURSO_AUTH_TOKEN=...
// Set via:  vercel env add TURSO_DATABASE_URL
//           vercel env add TURSO_AUTH_TOKEN

import { createClient } from "@libsql/client";

const url = process.env.TURSO_DATABASE_URL;
const authToken = process.env.TURSO_AUTH_TOKEN;

if (!url) throw new Error("TURSO_DATABASE_URL is not set");

export const db = createClient({
  url,
  authToken,
});

// Schema deployment:
//   turso db create your-db
//   turso db shell your-db < src/db/schema.sql

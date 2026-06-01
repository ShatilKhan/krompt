// src/db/migrate.ts — manual migration runner for Drizzle + Postgres.
// Invoked via: bun src/db/migrate.ts  (or  npx tsx src/db/migrate.ts)
//
// Package scripts to add:
//   "db:generate": "drizzle-kit generate",
//   "db:migrate":  "bun src/db/migrate.ts",
//   "db:push":     "drizzle-kit push",
//   "db:studio":   "drizzle-kit studio"

import { drizzle } from "drizzle-orm/postgres-js";
import { migrate } from "drizzle-orm/postgres-js/migrator";
import postgres from "postgres";

const connectionString = process.env.DATABASE_URL;
if (!connectionString) throw new Error("DATABASE_URL is not defined");

const run = async () => {
  console.log("running migrations...");
  const migrationClient = postgres(connectionString, { max: 1 });
  const db = drizzle(migrationClient);

  try {
    await migrate(db, { migrationsFolder: "drizzle" });
    console.log("migration completed successfully");
  } catch (error) {
    console.error("Migration failed", error);
    process.exit(1);
  } finally {
    await migrationClient.end();
  }
};

run();

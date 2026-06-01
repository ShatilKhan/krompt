// Vercel serverless function shape — /api/example.ts
// Substitute the body for your real handler. Uses the Web Fetch API style
// (Vercel supports both Node-style req/res and Web standard Request/Response).

import { db } from "../lib/db";

export const config = {
  runtime: "nodejs",
};

export default async function handler(req: Request): Promise<Response> {
  if (req.method !== "GET") {
    return new Response("Method Not Allowed", { status: 405 });
  }

  const rows = await db.execute("SELECT id, name FROM example LIMIT 10");

  return new Response(JSON.stringify({ data: rows.rows }), {
    status: 200,
    headers: { "Content-Type": "application/json" },
  });
}

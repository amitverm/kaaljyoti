// ============================================================================
// edge.ts — tiny runtime helpers shared by all edge functions
// ============================================================================
// * getSql()               — lazily-created postgres-js client (direct DB access).
// * corsHeaders/json       — consistent CORS + JSON responses.
// * requireInternal        — guard for internal-only functions (request-matching).
// * requireInternalOrAdmin — guard for functions also callable by an in-app
//                            admin (moderate-request, moderate-chart-report).
// * HttpError              — throwable error carrying an HTTP status.
//
// Design note — why postgres-js instead of a `supabase.rpc()` SQL-executor:
// the shared filter compiler already produces *parameterized* SQL ($1, $2 …
// plus a params array). Executing that through an RPC function would require
// a SECURITY DEFINER plpgsql function that EXECUTEs caller-supplied SQL text,
// which is an injection foothold by construction. Connecting directly with
// postgres-js keeps the parameters as real bind parameters end-to-end, so
// user values never touch SQL text. RLS is bypassed on this connection
// (it authenticates as the postgres role), so every query in these functions
// MUST re-apply visibility rules (status = 'active', never select
// contributor_id into a client-facing payload, etc.).
// ============================================================================

import postgres from "https://deno.land/x/postgresjs@v3.4.5/mod.js";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

export type Sql = ReturnType<typeof postgres>;

let _sql: Sql | null = null;

/**
 * Module-level singleton so warm invocations reuse the connection pool.
 *
 * Secrets:
 *   SUPABASE_DB_URL — provided automatically to hosted edge functions
 *                     (direct connection). If your environment needs the
 *                     Supavisor pooler instead (e.g. IPv4-only egress), set
 *                     the custom secret DB_POOL_URL — it takes precedence.
 *                     (Custom secrets may not start with SUPABASE_, hence
 *                     the separate name.)
 */
export function getSql(): Sql {
  if (_sql) return _sql;
  const url = Deno.env.get("DB_POOL_URL") ?? Deno.env.get("SUPABASE_DB_URL");
  if (!url) {
    throw new Error(
      "database URL missing: set the DB_POOL_URL secret (or rely on the built-in SUPABASE_DB_URL)",
    );
  }
  _sql = postgres(url, {
    max: 2, // edge isolates are small & short-lived; keep the pool tiny
    prepare: false, // required when going through a transaction-mode pooler
    idle_timeout: 30,
    connect_timeout: 10,
  });
  return _sql;
}

// --- HTTP helpers ------------------------------------------------------------

export const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type, x-internal-token",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

/** JSON response with CORS headers applied. */
export function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

/** Error that maps 1:1 to an HTTP response. */
export class HttpError extends Error {
  status: number;
  constructor(status: number, message: string) {
    super(message);
    this.name = "HttpError";
    this.status = status;
  }
}

/** Parse a JSON object body or throw a 400. */
export async function readJsonBody(req: Request): Promise<Record<string, unknown>> {
  let body: unknown;
  try {
    body = await req.json();
  } catch {
    throw new HttpError(400, "request body must be valid JSON");
  }
  if (body === null || typeof body !== "object" || Array.isArray(body)) {
    throw new HttpError(400, "request body must be a JSON object");
  }
  return body as Record<string, unknown>;
}

// --- internal-caller guard ----------------------------------------------------

/** Constant-time-ish string compare (avoids trivially timing the token). */
function safeEqual(a: string, b: string): boolean {
  const enc = new TextEncoder();
  const ba = enc.encode(a);
  const bb = enc.encode(b);
  if (ba.length !== bb.length) return false;
  let diff = 0;
  for (let i = 0; i < ba.length; i++) diff |= ba[i] ^ bb[i];
  return diff === 0;
}

/**
 * Guard for internal-only functions. Accepts EITHER:
 *   * Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>   (server-to-server), or
 *   * X-Internal-Token: <INTERNAL_TOKEN>                  (cron / webhooks).
 * Throws 401 otherwise. These functions must be deployed with
 * verify_jwt = false (see config.toml) so the X-Internal-Token path is
 * reachable — this guard is then the ONLY authentication layer.
 */
export function requireInternal(req: Request): void {
  const auth = req.headers.get("Authorization") ?? "";
  const bearer = auth.startsWith("Bearer ") ? auth.slice("Bearer ".length) : "";
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? "";
  if (serviceKey && bearer && safeEqual(bearer, serviceKey)) return;

  const token = req.headers.get("X-Internal-Token") ?? "";
  const internal = Deno.env.get("INTERNAL_TOKEN") ?? "";
  if (internal && token && safeEqual(token, internal)) return;

  throw new HttpError(401, "internal function: service-role key or X-Internal-Token required");
}

/**
 * Guard for functions callable EITHER by trusted ops tooling (service-role
 * key / X-Internal-Token, same as requireInternal) OR by a signed-in admin
 * using their own session from inside the app (the in-app Admin section —
 * see supabase/migrations/0008_admin_role.sql).
 *
 * The admin path never trusts anything the client asserts about itself: it
 * verifies the caller's JWT is genuine against the project's own auth
 * server, then asks the database's is_admin() function — SECURITY DEFINER,
 * scoped to auth.uid() — whether that specific user is on the admins
 * allowlist. The service-role key itself is never sent to or held by the
 * client; this is what lets an in-app Admin section exist without
 * exposing privileged credentials. A non-admin's perfectly valid JWT still
 * gets a 403 here.
 *
 * Returns the admin's user id, or null when authenticated via the
 * ops-tooling path (no user attached to that path).
 */
export async function requireInternalOrAdmin(req: Request): Promise<string | null> {
  try {
    requireInternal(req);
    return null;
  } catch {
    // Not ops tooling — fall through to the admin-JWT path below.
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) throw new HttpError(401, "missing Authorization header");

  // supabase-js here is used ONLY to verify the JWT and call is_admin()
  // under the caller's own session — it never sees or uses the
  // service-role key.
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false, autoRefreshToken: false },
    },
  );
  const { data: userData, error: userError } = await supabase.auth.getUser();
  if (userError || !userData?.user) throw new HttpError(401, "invalid or expired token");

  const { data: isAdmin, error: adminError } = await supabase.rpc("is_admin");
  if (adminError) throw new HttpError(500, `admin check failed: ${adminError.message}`);
  if (!isAdmin) throw new HttpError(403, "admin privileges required");

  return userData.user.id;
}

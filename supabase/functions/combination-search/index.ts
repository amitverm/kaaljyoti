// ============================================================================
// combination-search — POST { filters, limit?, offset? }
// ============================================================================
// Searches ACTIVE Mahakosh charts by planetary-combination criteria.
//
//   POST /functions/v1/combination-search
//   Authorization: Bearer <user JWT>            (any signed-in app user)
//   { "filters": <FilterNode>, "limit": 25, "offset": 0 }
//
//   -> { "total": 137, "limit": 25, "offset": 0,
//        "results": [ { "mk_code": "MK-4831", "birth_year": 1984,
//                       "location_general": "North India", "ayanamsa_id": 1,
//                       "created_at": "...", "yoga_count": 3,
//                       "life_event_count": 2 }, ... ] }
//
// Security:
//   * JWT is verified via supabase-js (anon key + caller's Authorization
//     header); anonymous callers get 401. (config.toml also sets
//     verify_jwt = true for this function as a first gate.)
//   * The query itself runs over a direct postgres-js connection (service
//     level, bypasses RLS) — see _shared/edge.ts for why this is safer than a
//     dynamic-SQL RPC. Because RLS is bypassed, this function re-applies the
//     visibility rule (status = 'active') itself and NEVER selects
//     contributor_id — results are anonymized mk_code summaries only.
//   * It also re-applies the hidden_mahakosh_charts filter (App Store
//     Guideline 1.2 "hide from my view", §2.7a) for the requesting user —
//     the mahakosh_charts_select RLS policy already excludes hidden charts
//     for RLS-governed reads, but this function bypasses RLS entirely, so
//     the exclusion has to be re-stated here explicitly.
//   * All user-supplied filter values are bind parameters produced by the
//     shared filter compiler; none are interpolated into SQL text.
//
// Secrets: SUPABASE_DB_URL (built-in) or DB_POOL_URL — see README.md.
// ============================================================================

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { compileFilter, FilterValidationError } from "../_shared/filter_compiler.ts";
import { corsHeaders, getSql, HttpError, json, readJsonBody } from "../_shared/edge.ts";

const DEFAULT_LIMIT = 25;
const MAX_LIMIT = 100;
const MAX_OFFSET = 10_000; // deep pagination over anonymized data is a scraping smell

/** 401 unless the Authorization header carries a valid user JWT. Returns the caller's user id. */
async function requireUser(req: Request): Promise<string> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) throw new HttpError(401, "missing Authorization header");

  // supabase-js is used ONLY for auth verification; queries go via postgres-js.
  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false, autoRefreshToken: false },
    },
  );
  const { data, error } = await supabase.auth.getUser();
  if (error || !data?.user) throw new HttpError(401, "invalid or expired token");
  return data.user.id;
}

/** Clamp an optional integer body field into [min, max], with a default. */
function intField(value: unknown, name: string, def: number, min: number, max: number): number {
  if (value === undefined || value === null) return def;
  if (typeof value !== "number" || !Number.isInteger(value)) {
    throw new HttpError(400, `${name} must be an integer`);
  }
  if (value < min || value > max) {
    throw new HttpError(400, `${name} must be in [${min}, ${max}]`);
  }
  return value;
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method not allowed" }, 405);

  try {
    const userId = await requireUser(req);

    const body = await readJsonBody(req);
    if (body.filters === undefined) {
      throw new HttpError(400, "'filters' is required");
    }
    const limit = intField(body.limit, "limit", DEFAULT_LIMIT, 1, MAX_LIMIT);
    const offset = intField(body.offset, "offset", 0, 0, MAX_OFFSET);

    // $1 is reserved for the caller's user id (hidden-charts exclusion
    // below); the compiled filter tree's own placeholders start at $2.
    const compiled = compileFilter(body.filters, "c", 2);
    const where = `c.status = 'active'
      and not exists (
        select 1 from public.hidden_mahakosh_charts h
        where h.chart_id = c.id and h.user_id = $1
      )
      and (${compiled.sql})`;
    const params = [userId, ...compiled.params];

    const sql = getSql();

    // Total first (for pagination UI), then the page itself.
    const totalRows = await sql.unsafe(
      `select count(*)::int as total from public.mahakosh_charts c where ${where}`,
      params as never[],
    ) as unknown as { total: number }[];
    const total = totalRows[0]?.total ?? 0;

    // Summary fields only — NEVER contributor_id or chart_payload.
    // limit/offset are appended after params, so their placeholders
    // continue the numbering.
    const n = params.length;
    const results = total === 0 ? [] : await sql.unsafe(
      `select c.mk_code,
              c.birth_year,
              c.location_general,
              c.ayanamsa_id,
              c.created_at,
              (select count(*)::int from public.chart_yogas cy
                where cy.chart_id = c.id)                       as yoga_count,
              (select count(*)::int from public.life_events le
                where le.chart_id = c.id)                       as life_event_count
       from public.mahakosh_charts c
       where ${where}
       order by c.created_at desc, c.id
       limit $${n + 1} offset $${n + 2}`,
      [...params, limit, offset] as never[],
    );

    return json({ total, limit, offset, results });
  } catch (e) {
    if (e instanceof FilterValidationError) return json({ error: e.message }, 400);
    if (e instanceof HttpError) return json({ error: e.message }, e.status);
    console.error("combination-search failed:", e);
    return json({ error: "internal error" }, 500);
  }
});

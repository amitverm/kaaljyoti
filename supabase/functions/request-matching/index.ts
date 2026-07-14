// ============================================================================
// request-matching — internal fan-out for match events
// ============================================================================
//   POST /functions/v1/request-matching
//   Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>
//     -- or --
//   X-Internal-Token: <INTERNAL_TOKEN>
//
//   { "kind": "new_chart",   "chart_id":   "<uuid>" }   -- a chart was contributed
//   { "kind": "new_request", "request_id": "<uuid>" }   -- a request went live
//
// This is an INTERNAL function (no end-user calls it): it is invoked by
// moderate-request, by database webhooks, or by ops tooling. It is deployed
// with verify_jwt = false (config.toml) so the X-Internal-Token path works;
// requireInternal() is therefore the sole authentication layer.
//
// All matching logic (idempotent upserts + notifications) lives in
// _shared/matching.ts so moderate-request can run the same code inline.
//
// Secrets: INTERNAL_TOKEN, SUPABASE_DB_URL / DB_POOL_URL — see README.md.
// ============================================================================

import { corsHeaders, getSql, HttpError, json, readJsonBody, requireInternal } from "../_shared/edge.ts";
import { matchNewChart, matchNewRequest } from "../_shared/matching.ts";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function requireUuid(value: unknown, name: string): string {
  if (typeof value !== "string" || !UUID_RE.test(value)) {
    throw new HttpError(400, `${name} must be a UUID string`);
  }
  return value;
}

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method not allowed" }, 405);

  try {
    requireInternal(req);

    const body = await readJsonBody(req);
    const sql = getSql();

    switch (body.kind) {
      case "new_request": {
        const requestId = requireUuid(body.request_id, "request_id");
        const summary = await matchNewRequest(sql, requestId);
        return json({ kind: "new_request", ...summary });
      }
      case "new_chart": {
        const chartId = requireUuid(body.chart_id, "chart_id");
        const summary = await matchNewChart(sql, chartId);
        return json({ kind: "new_chart", ...summary });
      }
      default:
        throw new HttpError(400, "kind must be 'new_chart' or 'new_request'");
    }
  } catch (e) {
    if (e instanceof HttpError) return json({ error: e.message }, e.status);
    console.error("request-matching failed:", e);
    return json({ error: "internal error" }, 500);
  }
});

// ============================================================================
// matching.ts — shared request<->chart matching engine
// ============================================================================
// Used by:
//   * request-matching  — the internal fan-out function ('new_chart' /
//                         'new_request' events).
//   * moderate-request  — runs matchNewRequest() inline right after a request
//                         is approved, so the requester gets their first
//                         batch of matches immediately.
//
// Both entry points share the exact same rules:
//   * Only ACTIVE mahakosh charts are ever matched.
//   * Only LIVE research requests are ever matched.
//   * request_matches is upserted with ON CONFLICT DO NOTHING, and
//     notifications are emitted only for NEWLY inserted matches, so re-running
//     matching is idempotent (no duplicate rows, no duplicate notifications).
//   * Notifications:
//       'request_match_new'  -> the requester (summarizes the new matches)
//       'your_chart_matched' -> each matched chart's contributor, but ONLY
//                               when that chart has notify_on_match = true.
//   * contributor_id never leaves the database in a client-facing payload;
//     the requester only ever sees mk_codes.
// ============================================================================

import { compileFilter, FilterValidationError } from "./filter_compiler.ts";
import { HttpError, type Sql } from "./edge.ts";

/** Cap the number of mk_codes embedded in a 'request_match_new' payload. */
const MAX_MK_CODES_IN_PAYLOAD = 10;

interface ChartRow {
  id: string;
  mk_code: string;
  contributor_id: string;
  notify_on_match: boolean;
}

interface RequestRow {
  id: string;
  requester_id: string;
  title: string;
  criteria: unknown;
}

export interface RequestMatchSummary {
  request_id: string;
  new_matches: number;
  contributors_notified: number;
}

/** Row shape for the postgres-js insert helper on public.notifications. */
function notification(userId: string, type: string, payload: Record<string, unknown>) {
  // payload is stringified explicitly; Postgres coerces the text parameter to
  // jsonb because the target column type is known in the INSERT.
  return { user_id: userId, type, payload: JSON.stringify(payload) };
}

/**
 * Insert request_matches for a (request, charts[]) pair and emit notifications
 * for the newly inserted ones. Returns the summary. Shared by both flows.
 */
async function recordMatches(
  sql: Sql,
  request: RequestRow,
  charts: ChartRow[],
): Promise<RequestMatchSummary> {
  const summary: RequestMatchSummary = {
    request_id: request.id,
    new_matches: 0,
    contributors_notified: 0,
  };
  if (charts.length === 0) return summary;

  // Upsert matches; RETURNING tells us which ones are actually new.
  const matchRows = charts.map((ch) => ({
    request_id: request.id,
    chart_id: ch.id,
    source: "auto",
  }));
  const inserted = await sql`
    insert into public.request_matches ${sql(matchRows, "request_id", "chart_id", "source")}
    on conflict (request_id, chart_id) do nothing
    returning chart_id
  ` as unknown as { chart_id: string }[];

  const newChartIds = new Set(inserted.map((r) => r.chart_id));
  if (newChartIds.size === 0) return summary; // everything already matched earlier

  const newCharts = charts.filter((ch) => newChartIds.has(ch.id));
  summary.new_matches = newCharts.length;

  // One summary notification for the requester...
  const notifications = [
    notification(request.requester_id, "request_match_new", {
      request_id: request.id,
      title: request.title,
      new_matches: newCharts.length,
      mk_codes: newCharts.slice(0, MAX_MK_CODES_IN_PAYLOAD).map((ch) => ch.mk_code),
    }),
  ];

  // ...and one per newly matched chart whose contributor opted in.
  for (const ch of newCharts) {
    if (!ch.notify_on_match) continue;
    notifications.push(
      notification(ch.contributor_id, "your_chart_matched", {
        request_id: request.id,
        title: request.title,
        chart_id: ch.id,
        mk_code: ch.mk_code,
      }),
    );
    summary.contributors_notified++;
  }

  await sql`
    insert into public.notifications ${sql(notifications, "user_id", "type", "payload")}
  `;

  return summary;
}

/**
 * 'new_request' flow — a research request just went LIVE: find every active
 * chart matching its criteria, record matches, notify.
 */
export async function matchNewRequest(sql: Sql, requestId: string): Promise<RequestMatchSummary> {
  const requests = await sql`
    select id, requester_id, title, criteria, status
    from public.research_requests
    where id = ${requestId}
  ` as unknown as (RequestRow & { status: string })[];
  const request = requests[0];
  if (!request) throw new HttpError(404, `research request ${requestId} not found`);
  if (request.status !== "live") {
    throw new HttpError(409, `research request ${requestId} is '${request.status}', not 'live'`);
  }

  // No criteria (0026) — the requester doesn't know the combination yet;
  // the request collects charts through manual responses only.
  if (request.criteria == null) {
    return { request_id: request.id, new_matches: 0, contributors_notified: 0 };
  }

  // criteria is contributor-supplied jsonb — compile (and re-validate) it.
  let compiled;
  try {
    compiled = compileFilter(request.criteria, "c", 1);
  } catch (e) {
    if (e instanceof FilterValidationError) {
      // A live request with invalid criteria means moderation let something
      // odd through; surface it loudly rather than silently matching nothing.
      throw new HttpError(422, `request ${requestId} has invalid criteria: ${e.message}`);
    }
    throw e;
  }

  const charts = await sql.unsafe(
    `select c.id, c.mk_code, c.contributor_id, c.notify_on_match
     from public.mahakosh_charts c
     where c.status = 'active' and (${compiled.sql})`,
    compiled.params as never[],
  ) as unknown as ChartRow[];

  return await recordMatches(sql, request, charts);
}

export interface ChartMatchSummary {
  chart_id: string;
  mk_code: string;
  requests_evaluated: number;
  matched: RequestMatchSummary[];
}

/**
 * 'new_chart' flow — a chart was just contributed: evaluate it against every
 * LIVE research request. Each request's criteria is compiled with an extra
 * `c.id = $1` conjunct so the query tests only this one chart.
 *
 * v1 scale note: this loops requests sequentially (one indexed point query
 * each). Fine for hundreds of live requests; revisit with a batched approach
 * if that assumption breaks.
 */
export async function matchNewChart(sql: Sql, chartId: string): Promise<ChartMatchSummary> {
  const chartRows = await sql`
    select id, mk_code, contributor_id, notify_on_match, status
    from public.mahakosh_charts
    where id = ${chartId}
  ` as unknown as (ChartRow & { status: string })[];
  const chart = chartRows[0];
  if (!chart) throw new HttpError(404, `mahakosh chart ${chartId} not found`);
  if (chart.status !== "active") {
    throw new HttpError(409, `chart ${chartId} is '${chart.status}', not 'active'`);
  }

  const liveRequests = await sql`
    select id, requester_id, title, criteria
    from public.research_requests
    where status = 'live'
  ` as unknown as RequestRow[];

  const result: ChartMatchSummary = {
    chart_id: chart.id,
    mk_code: chart.mk_code,
    requests_evaluated: liveRequests.length,
    matched: [],
  };

  for (const request of liveRequests) {
    // Criteria-less requests (0026) never auto-match.
    if (request.criteria == null) continue;

    // $1 is reserved for the chart id, so compiled params start at $2.
    let compiled;
    try {
      compiled = compileFilter(request.criteria, "c", 2);
    } catch (e) {
      if (e instanceof FilterValidationError) {
        // Don't let one bad live request block matching against the rest.
        console.warn(`skipping request ${request.id}: invalid criteria: ${e.message}`);
        continue;
      }
      throw e;
    }

    const hit = await sql.unsafe(
      `select 1
       from public.mahakosh_charts c
       where c.id = $1 and c.status = 'active' and (${compiled.sql})
       limit 1`,
      [chartId, ...compiled.params] as never[],
    );
    if (hit.length === 0) continue;

    const summary = await recordMatches(sql, request, [chart]);
    if (summary.new_matches > 0) result.matched.push(summary);
  }

  return result;
}

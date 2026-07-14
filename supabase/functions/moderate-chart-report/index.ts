// ============================================================================
// moderate-chart-report — internal moderation action on a chart report
// ============================================================================
//   POST /functions/v1/moderate-chart-report
//   Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>          (ops tooling)
//     -- or --
//   X-Internal-Token: <INTERNAL_TOKEN>                         (ops tooling)
//     -- or --
//   Authorization: Bearer <a signed-in admin's own JWT>        (in-app Admin section)
//
//   { "report_id": "<uuid>", "action": "action" | "dismiss", "note": "..." }
//
// Callable by ops tooling OR by an admin from inside the app (§ Admin,
// 0008_admin_role.sql), mirroring moderate-request. RLS gives
// 'authenticated' no UPDATE on chart_reports at all, so this function is
// the only path for status transitions either way. requireInternalOrAdmin()
// verifies either the service-role key / X-Internal-Token, or that the
// caller's own JWT belongs to a user on the admins allowlist — the
// service-role key itself never touches the client. Deployed with
// verify_jwt = false; requireInternalOrAdmin() is the sole authentication
// layer.
//
//   action ('actioned'):   the report was valid — the chart is withdrawn
//                          (mahakosh_charts.status = 'withdrawn'), pulling
//                          it for EVERY user, not just the reporter. This
//                          is what distinguishes reporting from hiding
//                          (§2.7a): hiding only ever affects the hider.
//   dismiss ('dismissed'): the report was reviewed and the chart stays
//                          active — no change to mahakosh_charts.
//
// Either way the reporter is notified via the existing notifications
// table (a new 'report_actioned' / 'report_dismissed' type), same pattern
// moderate-request uses for request_approved / request_rejected.
//
// Secrets: INTERNAL_TOKEN, SUPABASE_DB_URL / DB_POOL_URL — see README.md.
// ============================================================================

import { corsHeaders, getSql, HttpError, json, readJsonBody, requireInternalOrAdmin } from "../_shared/edge.ts";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const MAX_NOTE_LENGTH = 2000;

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method not allowed" }, 405);

  try {
    await requireInternalOrAdmin(req);

    // ---- validate body -----------------------------------------------------
    const body = await readJsonBody(req);
    const reportId = body.report_id;
    if (typeof reportId !== "string" || !UUID_RE.test(reportId)) {
      throw new HttpError(400, "report_id must be a UUID string");
    }
    const action = body.action;
    if (action !== "action" && action !== "dismiss") {
      throw new HttpError(400, "action must be 'action' or 'dismiss'");
    }
    const note = body.note === undefined || body.note === null ? null : body.note;
    if (note !== null && (typeof note !== "string" || note.length > MAX_NOTE_LENGTH)) {
      throw new HttpError(400, `note must be a string of at most ${MAX_NOTE_LENGTH} characters`);
    }

    const sql = getSql();

    // ---- transition the report (guarded by current status) -----------------
    // The status predicate makes this atomic: a concurrent double-moderation
    // simply finds zero rows the second time.
    const newStatus = action === "action" ? "actioned" : "dismissed";
    const updated = await sql`
      update public.chart_reports
      set status      = ${newStatus},
          reviewed_at = now(),
          review_note = ${note}
      where id = ${reportId}
        and status = 'pending_review'
      returning id, chart_id, reporter_id, reason
    ` as unknown as { id: string; chart_id: string; reporter_id: string; reason: string }[];

    if (updated.length === 0) {
      const existing = await sql`
        select status from public.chart_reports where id = ${reportId}
      ` as unknown as { status: string }[];
      if (existing.length === 0) throw new HttpError(404, `chart report ${reportId} not found`);
      throw new HttpError(409, `chart report ${reportId} is '${existing[0].status}', not 'pending_review'`);
    }
    const report = updated[0];

    // ---- action: withdraw the chart for everyone ----------------------------
    let mkCode: string | null = null;
    if (action === "action") {
      const rows = await sql`
        update public.mahakosh_charts
        set status       = 'withdrawn',
            withdrawn_at = now()
        where id = ${report.chart_id}
        returning mk_code
      ` as unknown as { mk_code: string }[];
      mkCode = rows[0]?.mk_code ?? null;
    } else {
      const rows = await sql`
        select mk_code from public.mahakosh_charts where id = ${report.chart_id}
      ` as unknown as { mk_code: string }[];
      mkCode = rows[0]?.mk_code ?? null;
    }

    // ---- notify the reporter -------------------------------------------------
    const payload: Record<string, unknown> = { report_id: report.id, mk_code: mkCode, reason: report.reason };
    if (note) payload.review_note = note;
    await sql`
      insert into public.notifications (user_id, type, payload)
      values (${report.reporter_id},
              ${action === "action" ? "report_actioned" : "report_dismissed"},
              ${JSON.stringify(payload)})
    `;

    return json({
      report_id: report.id,
      status: newStatus,
      chart_withdrawn: action === "action",
      mk_code: mkCode,
    });
  } catch (e) {
    if (e instanceof HttpError) return json({ error: e.message }, e.status);
    console.error("moderate-chart-report failed:", e);
    return json({ error: "internal error" }, 500);
  }
});

// ============================================================================
// moderate-request — internal moderation action on a research request
// ============================================================================
//   POST /functions/v1/moderate-request
//   Authorization: Bearer <SUPABASE_SERVICE_ROLE_KEY>          (ops tooling)
//     -- or --
//   X-Internal-Token: <INTERNAL_TOKEN>                         (ops tooling)
//     -- or --
//   Authorization: Bearer <a signed-in admin's own JWT>        (in-app Admin section)
//
//   { "request_id": "<uuid>", "action": "approve" | "reject", "note": "..." }
//
// Callable by ops tooling OR by an admin from inside the app (§ Admin,
// 0008_admin_role.sql) — RLS gives 'authenticated' no UPDATE on
// research_requests at all, so this function is the only path for status
// transitions either way. requireInternalOrAdmin() verifies either the
// service-role key / X-Internal-Token, or that the caller's own JWT
// belongs to a user on the admins allowlist — the service-role key itself
// never touches the client. Deployed with verify_jwt = false;
// requireInternalOrAdmin() is the sole authentication layer.
//
//   approve: pending_review -> live, reviewed_at = now(), review_note = note,
//            notify requester ('request_approved'), then run the matching
//            pass inline (same code path as request-matching, via
//            _shared/matching.ts) so the requester gets their first batch of
//            matches immediately.
//   reject:  pending_review -> rejected, reviewed_at = now(),
//            review_note = note, notify requester ('request_rejected').
//
// Secrets: INTERNAL_TOKEN, SUPABASE_DB_URL / DB_POOL_URL — see README.md.
// ============================================================================

import { corsHeaders, getSql, HttpError, json, readJsonBody, requireInternalOrAdmin } from "../_shared/edge.ts";
import { matchNewRequest, type RequestMatchSummary } from "../_shared/matching.ts";

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
const MAX_NOTE_LENGTH = 2000;

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return json({ error: "method not allowed" }, 405);

  try {
    await requireInternalOrAdmin(req);

    // ---- validate body -----------------------------------------------------
    const body = await readJsonBody(req);
    const requestId = body.request_id;
    if (typeof requestId !== "string" || !UUID_RE.test(requestId)) {
      throw new HttpError(400, "request_id must be a UUID string");
    }
    const action = body.action;
    if (action !== "approve" && action !== "reject") {
      throw new HttpError(400, "action must be 'approve' or 'reject'");
    }
    const note = body.note === undefined || body.note === null ? null : body.note;
    if (note !== null && (typeof note !== "string" || note.length > MAX_NOTE_LENGTH)) {
      throw new HttpError(400, `note must be a string of at most ${MAX_NOTE_LENGTH} characters`);
    }

    const sql = getSql();

    // ---- transition the request (guarded by current status) ----------------
    // The status predicate in the UPDATE makes the transition atomic: a
    // concurrent double-moderation simply finds zero rows the second time.
    const newStatus = action === "approve" ? "live" : "rejected";
    const updated = await sql`
      update public.research_requests
      set status      = ${newStatus},
          reviewed_at = now(),
          review_note = ${note}
      where id = ${requestId}
        and status = 'pending_review'
      returning id, requester_id, title
    ` as unknown as { id: string; requester_id: string; title: string }[];

    if (updated.length === 0) {
      // Distinguish "not found" from "already moderated" for a useful error.
      const existing = await sql`
        select status from public.research_requests where id = ${requestId}
      ` as unknown as { status: string }[];
      if (existing.length === 0) throw new HttpError(404, `research request ${requestId} not found`);
      throw new HttpError(409, `research request ${requestId} is '${existing[0].status}', not 'pending_review'`);
    }
    const request = updated[0];

    // ---- notify the requester ----------------------------------------------
    const payload: Record<string, unknown> = { request_id: request.id, title: request.title };
    if (note) payload.review_note = note;
    await sql`
      insert into public.notifications (user_id, type, payload)
      values (${request.requester_id},
              ${action === "approve" ? "request_approved" : "request_rejected"},
              ${JSON.stringify(payload)})
    `;

    if (action === "reject") {
      return json({ request_id: request.id, status: "rejected" });
    }

    // ---- approve: run the matching pass inline ------------------------------
    // The request is already live and the requester notified; a matching
    // failure here should not roll that back, so report it instead of 500-ing.
    let matching: RequestMatchSummary | null = null;
    let matchingError: string | null = null;
    try {
      matching = await matchNewRequest(sql, request.id);
    } catch (e) {
      console.error(`matching after approval of ${request.id} failed:`, e);
      matchingError = e instanceof Error ? e.message : String(e);
    }

    return json({
      request_id: request.id,
      status: "live",
      matching, // { request_id, new_matches, contributors_notified } | null
      ...(matchingError ? { matching_error: matchingError } : {}),
    });
  } catch (e) {
    if (e instanceof HttpError) return json({ error: e.message }, e.status);
    console.error("moderate-request failed:", e);
    return json({ error: "internal error" }, 500);
  }
});

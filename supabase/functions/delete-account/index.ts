// ============================================================================
// delete-account — the caller deletes their OWN account (App Store
// Guideline 5.1.1(v) / Play account-deletion policy require this to be
// possible from inside the app).
// ============================================================================
// Flow:
//   1. Verify the caller's JWT against the auth server (anon-key client +
//      the caller's own Authorization header — same pattern as the admin
//      path in _shared/edge.ts). The service-role key is never derived
//      from anything the client asserts.
//   2. Detach the caller's Mahakosh contributions: contributor_id → NULL,
//      notify_on_match → false. Contributed charts are anonymized research
//      data and stay in the pool per the published deletion policy
//      (kaaljyoti.com/delete-account.html); withdrawal on request remains
//      a support path. The FK's ON DELETE RESTRICT makes this step
//      mandatory — deleteUser fails if any chart is still attached.
//   3. auth.admin.deleteUser — every other user-owned row (profile,
//      synced kundlis, notifications, device tokens, blocks, reports,
//      research requests) cascades from auth.users.
//
// Discussion comments are deliberately NOT touched: the rows outlive
// the profile via the SET NULL author FK (0024) and stay visible,
// rendered as authored by a deleted account — only the identity link
// is removed, so discussions keep their content. Users who want a
// comment gone delete it in the app (no time window) before deleting
// the account; the confirmation dialog says so.
//
// The body must carry { "confirm": "DELETE" } so a stray invoke with a
// valid session can never wipe an account.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { corsHeaders, getSql, HttpError, json, readJsonBody } from "../_shared/edge.ts";

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });

  try {
    if (req.method !== "POST") throw new HttpError(405, "POST only");

    const body = await readJsonBody(req);
    if (body.confirm !== "DELETE") {
      throw new HttpError(400, 'confirmation missing: body must be {"confirm":"DELETE"}');
    }

    const authHeader = req.headers.get("Authorization");
    if (!authHeader) throw new HttpError(401, "missing Authorization header");

    const asCaller = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      {
        global: { headers: { Authorization: authHeader } },
        auth: { persistSession: false, autoRefreshToken: false },
      },
    );
    const { data: userData, error: userError } = await asCaller.auth.getUser();
    if (userError || !userData?.user) throw new HttpError(401, "invalid or expired token");
    const uid = userData.user.id;

    // Detach contributions BEFORE deleteUser (see header comment).
    const sql = getSql();
    await sql`
      update public.mahakosh_charts
         set contributor_id = null, notify_on_match = false
       where contributor_id = ${uid}`;

    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
      { auth: { persistSession: false, autoRefreshToken: false } },
    );
    const { error: deleteError } = await admin.auth.admin.deleteUser(uid);
    if (deleteError) throw new HttpError(500, `deletion failed: ${deleteError.message}`);

    return json({ ok: true });
  } catch (e) {
    if (e instanceof HttpError) return json({ error: e.message }, e.status);
    console.error("delete-account:", e);
    return json({ error: "internal error" }, 500);
  }
});

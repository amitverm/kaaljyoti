// ============================================================================
// send-notification — push (+ selective email) fan-out for one notification
// ============================================================================
//   POST /functions/v1/send-notification
//   X-Internal-Token: <INTERNAL_TOKEN>
//   { "record": { id, user_id, type, payload, ... } }   (webhook body shape)
//
// Wired as a Supabase DATABASE WEBHOOK on INSERT into public.notifications
// (Dashboard → Database → Webhooks → this function, with the
// X-Internal-Token header). Every in-app notification row therefore also:
//   * pushes to each of the user's registered devices (device_tokens, 0021)
//     via FCM HTTP v1 — invalid/rotated tokens are deleted on the way;
//   * emails the user via Resend for MODERATION OUTCOMES only
//     (comment_held / comment_removed / comment_restored / report_actioned /
//     report_dismissed) — rare, important events; everything else stays
//     push + bell to avoid becoming spam.
//
// Payload text mirrors AppNotification.title (lib/mahakosh/models.dart) —
// keep the two in sync when adding types.
//
// Secrets:
//   INTERNAL_TOKEN       — webhook auth (same guard as request-matching)
//   FCM_SERVICE_ACCOUNT  — full JSON of a Firebase service account with
//                          the cloudmessaging scope (skipped if unset)
//   RESEND_API_KEY       — Resend key for moderation emails (skipped if unset)
//   EMAIL_FROM           — e.g. "Kaal Jyoti <notify@kaaljyoti.app>"
// ============================================================================

import { corsHeaders, getSql, HttpError, json, readJsonBody, requireInternal } from "../_shared/edge.ts";

// --- notification copy (keep in sync with AppNotification.title) -------------

function titleFor(type: string, payload: Record<string, unknown>): string {
  switch (type) {
    case "request_match_new":
      return "New matches for your research request";
    case "your_chart_matched":
      return "Your chart matched a research request";
    case "request_approved":
      return "Your research request is live";
    case "request_rejected":
      return "Your research request was not approved";
    case "report_actioned":
      return "A chart you reported was removed";
    case "report_dismissed":
      return "A chart you reported was reviewed";
    case "comment_reply":
      return `${payload.author_name ?? "Someone"} replied to your comment`;
    case "chart_comment":
      return `New comment on your chart ${payload.mk_code ?? ""}`.trim();
    case "comment_held":
      return "Your comment is hidden pending review";
    case "comment_removed":
      return "Your comment was removed by moderators";
    case "comment_restored":
      return "Your comment was reviewed and restored";
    default:
      return "Kaal Jyoti";
  }
}

const EMAIL_TYPES = new Set([
  "comment_held",
  "comment_removed",
  "comment_restored",
  "report_actioned",
  "report_dismissed",
]);

// --- FCM HTTP v1 --------------------------------------------------------------

type ServiceAccount = { client_email: string; private_key: string; project_id: string };

let _accessToken: { token: string; exp: number } | null = null;

/** OAuth2 token via RS256 JWT assertion — cached until ~5 min before expiry. */
async function fcmAccessToken(sa: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (_accessToken && _accessToken.exp - 300 > now) return _accessToken.token;

  const enc = (obj: unknown) =>
    btoa(JSON.stringify(obj)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
  const header = enc({ alg: "RS256", typ: "JWT" });
  const claims = enc({
    iss: sa.client_email,
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: now,
    exp: now + 3600,
  });
  const signingInput = `${header}.${claims}`;

  const pem = sa.private_key.replace(/-----[A-Z ]+-----/g, "").replace(/\s/g, "");
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    der,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const sig = new Uint8Array(
    await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(signingInput)),
  );
  const jwt = `${signingInput}.${btoa(String.fromCharCode(...sig))
    .replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "")}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion: jwt,
    }),
  });
  if (!res.ok) throw new HttpError(502, `FCM token exchange failed: ${await res.text()}`);
  const body = await res.json();
  _accessToken = { token: body.access_token, exp: now + (body.expires_in ?? 3600) };
  return _accessToken.token;
}

/** Send one push; returns false when the token is dead and should be pruned. */
async function sendPush(
  sa: ServiceAccount,
  token: string,
  title: string,
  body: string,
  data: Record<string, string>,
): Promise<boolean> {
  const accessToken = await fcmAccessToken(sa);
  const res = await fetch(
    `https://fcm.googleapis.com/v1/projects/${sa.project_id}/messages:send`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: {
          token,
          notification: { title, body },
          data,
          apns: { payload: { aps: { sound: "default" } } },
        },
      }),
    },
  );
  if (res.ok) return true;
  const text = await res.text();
  // UNREGISTERED / INVALID_ARGUMENT on a stale token → prune it.
  if (res.status === 404 || text.includes("UNREGISTERED")) return false;
  console.error(`FCM send failed (${res.status}): ${text}`);
  return true; // transient — keep the token
}

// --- handler -------------------------------------------------------------------

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  try {
    requireInternal(req);
    const body = await readJsonBody(req);
    const record = body?.record as
      | { id?: string; user_id?: string; type?: string; payload?: Record<string, unknown> }
      | undefined;
    if (!record?.user_id || !record?.type) {
      throw new HttpError(400, "record.user_id and record.type required");
    }
    const payload = record.payload ?? {};
    const title = titleFor(record.type, payload);
    const snippet = typeof payload.snippet === "string" ? payload.snippet : "";

    const sql = getSql();
    let pushed = 0, pruned = 0, emailed = false;

    // ---- push to registered devices ---------------------------------------
    const saJson = Deno.env.get("FCM_SERVICE_ACCOUNT");
    if (saJson) {
      const sa = JSON.parse(saJson) as ServiceAccount;
      const tokens = await sql`
        select token from public.device_tokens where user_id = ${record.user_id}
      `;
      for (const row of tokens) {
        const ok = await sendPush(sa, row.token as string, title, snippet, {
          type: record.type,
          mk_code: String(payload.mk_code ?? ""),
          request_id: String(payload.request_id ?? ""),
        });
        if (ok) pushed++;
        else {
          await sql`delete from public.device_tokens where token = ${row.token as string}`;
          pruned++;
        }
      }
    }

    // ---- email for moderation outcomes only --------------------------------
    const resendKey = Deno.env.get("RESEND_API_KEY");
    const from = Deno.env.get("EMAIL_FROM");
    if (resendKey && from && EMAIL_TYPES.has(record.type)) {
      const users = await sql`
        select email from auth.users where id = ${record.user_id}
      `;
      const email = users[0]?.email as string | undefined;
      if (email) {
        const res = await fetch("https://api.resend.com/emails", {
          method: "POST",
          headers: {
            Authorization: `Bearer ${resendKey}`,
            "Content-Type": "application/json",
          },
          body: JSON.stringify({
            from,
            to: [email],
            subject: `Kaal Jyoti — ${title}`,
            text: [
              title,
              "",
              snippet ? `"${snippet}"` : "",
              payload.review_note ? `Moderator note: ${payload.review_note}` : "",
              "",
              "Open Kaal Jyoti to see the details.",
            ].filter((l) => l !== "").join("\n"),
          }),
        });
        emailed = res.ok;
        if (!res.ok) console.error(`Resend failed (${res.status}): ${await res.text()}`);
      }
    }

    return json({ pushed, pruned, emailed });
  } catch (e) {
    if (e instanceof HttpError) return json({ error: e.message }, e.status);
    console.error(e);
    return json({ error: "internal error" }, 500);
  }
});

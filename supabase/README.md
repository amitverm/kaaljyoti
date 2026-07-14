# Kaal Jyoti — Supabase backend

Postgres schema + edge functions for Mahakosh (the consent-governed community
chart repository), combination search, research requests, and matching.

## Layout

```
supabase/
├── config.toml                       # CLI config (per-function verify_jwt)
├── migrations/
│   └── 0001_init.sql                 # full schema + RLS + triggers
└── functions/
    ├── _shared/
    │   ├── filter_compiler.ts        # FilterNode tree -> parameterized SQL
    │   ├── matching.ts               # request<->chart matching + notifications
    │   └── edge.ts                   # postgres-js client, CORS, internal guard
    ├── combination-search/           # user-facing search (JWT required)
    ├── request-matching/             # internal: new_chart / new_request fan-out
    └── moderate-request/             # internal: approve/reject + inline matching
```

There is deliberately **no** dynamic-SQL RPC function in the database: the
filter compiler emits parameterized SQL, and the edge functions execute it
over a direct postgres-js connection, so user values stay bind parameters
end-to-end (an `EXECUTE`-based `SECURITY DEFINER` RPC would reintroduce an
injection surface).

## Setup

```sh
# 1. Create a project at https://supabase.com/dashboard, then link it:
supabase login
supabase link --project-ref <PROJECT_REF>

# 2. Apply migrations:
supabase db push

# 3. Deploy the edge functions:
supabase functions deploy combination-search
supabase functions deploy request-matching
supabase functions deploy moderate-request
```

## Secrets (edge functions)

```sh
supabase secrets set INTERNAL_TOKEN=<long-random-string>
# Optional: only if the built-in direct connection doesn't work for your
# network (e.g. IPv4-only egress) — point at the Supavisor pooler:
supabase secrets set DB_POOL_URL='postgresql://postgres.<ref>:<pwd>@...pooler.supabase.com:6543/postgres'
```

- `SUPABASE_DB_URL` is **provided automatically** to hosted edge functions and
  is what `combination-search` / `request-matching` / `moderate-request` use
  by default. `DB_POOL_URL` (custom secrets cannot start with `SUPABASE_`)
  takes precedence when set.
- `INTERNAL_TOKEN` guards the two internal functions via the
  `X-Internal-Token` header; the service-role key in `Authorization: Bearer`
  also works. Never ship either to the client.

## Flutter client

The app reads its Supabase endpoint from `--dart-define`:

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://<PROJECT_REF>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon key>
```

The anon key is safe to embed — RLS in `0001_init.sql` is the enforcement
layer.

## Testing notes

- **Free-tier pause:** free Supabase projects are paused after ~7 days of
  inactivity. During testing, hit the project occasionally or restore it from
  the dashboard before a demo — a paused project fails all app calls.
- **Internal functions locally:** `supabase functions serve` reads
  `verify_jwt` from `config.toml`; call `request-matching` /
  `moderate-request` with `X-Internal-Token` (set `INTERNAL_TOKEN` in
  `supabase/functions/.env`).

## Design boundaries (v1)

- **No public API and no bulk export — by design.** The app is the only
  client; charts are anonymized (mk_code, birth year, coarse region) and
  consent-governed, and keeping access app-only is part of that promise.
- Moderation (`moderate-request`) is an internal/admin action in v1; there is
  no in-app moderator role.

## Custom SMTP via Resend (removes the 2/hour email limit)

1. **Resend** (resend.com) → sign up → Domains → Add Domain → enter the
   brand domain (e.g. `kaaljyoti.app`). Add the DNS records Resend
   shows (DKIM + SPF/MX for the `send` subdomain) at your DNS provider
   and wait for "Verified" (usually minutes).
2. Resend → API Keys → Create ("supabase-smtp", Sending access).
3. Supabase dashboard → Authentication → SMTP Settings → enable Custom
   SMTP:
   - Host: `smtp.resend.com`
   - Port: `465`
   - Username: `resend`
   - Password: the API key from step 2
   - Sender email: `login@<your-domain>` · Sender name: `Kaal Jyoti`
4. Supabase → Authentication → Rate Limits: after custom SMTP is on,
   the email rate limit becomes editable — raise it (e.g. 100/hour)
   for internal testing.
5. Send yourself a code from the app to verify end-to-end (check the
   OTP templates still contain {{ .Token }} — see the OTP section).

Resend free tier: 3,000 emails/month, 100/day — ample for testing and
early production. The sender address never receives mail; if you want
replies, set a Reply-To in the templates later.

## Email OTP sign-in (no passwords)

The app signs users in with a 6-digit emailed code (`signInWithOtp` →
`verifyOTP`). First sign-in creates the account — there is no separate
signup. Two dashboard settings matter:

1. **Auth → Email Templates → Magic Link**: the template must contain
   `{{ .Token }}` so the email carries the 6-digit code (the default
   template only has the `{{ .ConfirmationURL }}` link).
2. **Custom SMTP before launch**: Supabase's built-in email service is
   heavily rate-limited (a handful of emails/hour) and fine only for
   testing. Configure your own SMTP (Auth → SMTP settings) before any
   real users.

Google sign-in (and Apple, iOS-only) can be added later as Supabase
OAuth providers without changing this flow.

## Google & Apple sign-in (native)

The app uses the native flows (`google_sign_in` / `sign_in_with_apple`)
and exchanges the resulting ID token via `signInWithIdToken` — no
browser redirect. One-time setup:

### Google
1. Google Cloud console → APIs & Services → Credentials, in ONE project
   create OAuth clients:
   - **Web application** → this is `GOOGLE_WEB_CLIENT_ID` (required on
     BOTH platforms; it's the audience Supabase validates).
   - **iOS** (bundle id `com.kaaljyoti`) → this is
     `GOOGLE_IOS_CLIENT_ID`. Add its REVERSED client id to
     ios/Runner/Info.plist under CFBundleURLTypes.
   - **Android** (package name + SHA-1 of your signing keys, debug AND
     release) — no id needed in the app, but the client must exist.
2. Supabase dashboard → Auth → Providers → Google: enable, and add the
   web client ID (and iOS client ID) to "Authorized Client IDs".
3. Put both ids in env.json.

### Apple (iOS only)
1. Apple Developer portal: enable the "Sign in with Apple" capability
   on the App ID, and add the capability to the Runner target in Xcode
   (Signing & Capabilities → + Capability → Sign in with Apple).
2. Supabase dashboard → Auth → Providers → Apple: enable, and add the
   app's bundle id (`com.kaaljyoti`) to the client IDs.
   For the native flow no service secret is needed.

Email OTP remains the fallback and works with zero extra setup.

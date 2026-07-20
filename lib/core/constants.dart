/// App-wide constants and configuration.
library;

/// Kaal Jyoti is free software (AGPL-3.0) — no paid tier, no kundli cap.
/// The public source repo is linked from the Menu footer per AGPL §13
/// (users interacting with the app must be offered the Corresponding
/// Source).
const String kSourceRepoUrl = 'https://github.com/amitverm/kaaljyoti';

/// The license the app is released under (Menu footer link).
const String kLicenseUrl = 'https://www.gnu.org/licenses/agpl-3.0.html';

/// Copyright holder line — Menu footer, license dialog, and the PDF
/// export footer (there suffixed with the website).
const String kCopyrightLine = '© 2026 Amit Verma';

/// Author contact — the Menu footer credit links here. The app is
/// fully free; this is how consulting/custom-work referrals reach the
/// author.
const String kAuthorLinkedInUrl = 'https://in.linkedin.com/in/amitverm';

/// Public website — shown on exported PDFs next to the copyright and
/// linked from the Menu footer.
const String kWebsite = 'kaaljyoti.com';
const String kWebsiteUrl = 'https://kaaljyoti.com';

/// Legal pages, shown at sign-in (App Store Guideline 1.2 expects the
/// terms to be presented before registering) and linked from the site.
const String kTermsUrl = 'https://kaaljyoti.com/terms.html';
const String kPrivacyUrl = 'https://kaaljyoti.com/privacy.html';

/// Supabase configuration — injected at build time:
/// flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
///
/// SUPABASE_ANON_KEY takes the project's client key: on new Supabase
/// projects that's the PUBLISHABLE key (sb_publishable_...), which
/// replaced the legacy anon JWT. Both are low-privilege, RLS-governed,
/// and safe to embed client-side. Never use the secret (sb_secret_) /
/// service_role key here.
const String kSupabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String kSupabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

bool get kBackendConfigured =>
    kSupabaseUrl.isNotEmpty && kSupabaseAnonKey.isNotEmpty;

/// Google OAuth client IDs (Google Cloud console). The WEB client id
/// is required on both platforms (it's what Supabase validates the
/// idToken against); the iOS client id is additionally needed on iOS.
const String kGoogleWebClientId =
    String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
const String kGoogleIosClientId =
    String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');

bool get kGoogleSignInConfigured => kGoogleWebClientId.isNotEmpty;

/// Open-Meteo geocoding endpoint (free, keyless) — place typeahead that
/// resolves name → lat/long + IANA timezone.
const String kGeocodingEndpoint =
    'https://geocoding-api.open-meteo.com/v1/search';

const String kAppName = 'Kaal Jyoti';

/// Sentry crash reporting — injected at build time like the Supabase
/// config; EMPTY (the default) disables Sentry entirely, so the public
/// repo, contributors and local dev builds run with no telemetry at
/// all. Only official builds carry a DSN. Crash reports contain stack
/// traces + device model, never kundli or birth data.
const String kSentryDsn = String.fromEnvironment('SENTRY_DSN');

/// Firebase Cloud Messaging — push delivery pipe only (no Firebase
/// Analytics is linked). Same build-time gating: values empty (the
/// default) means no Firebase code ever runs and notifications stay
/// in-app-bell only.
///
/// API key + app id are PER-APP (Firebase console → Project settings →
/// General → Your apps, one iOS app + one Android app); sender id +
/// project id are project-wide. PushService picks the right pair for
/// the running platform.
const String kFirebaseApiKeyIos =
    String.fromEnvironment('FIREBASE_API_KEY_IOS');
const String kFirebaseApiKeyAndroid =
    String.fromEnvironment('FIREBASE_API_KEY_ANDROID');
const String kFirebaseAppIdIos = String.fromEnvironment('FIREBASE_APP_ID_IOS');
const String kFirebaseAppIdAndroid =
    String.fromEnvironment('FIREBASE_APP_ID_ANDROID');
const String kFirebaseSenderId =
    String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
const String kFirebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');

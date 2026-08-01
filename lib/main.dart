import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// latest_all, matching place_lookup_service — see the note there on why
// the trimmed zone set is not safe.
import 'package:timezone/data/latest_all.dart' as tzdata;

import 'app.dart';
import 'charts/chart_tuning.dart';
import 'core/astro/ephemeris_service.dart';
import 'core/constants.dart';
import 'data/settings_repository.dart';

Future<void> main() async {
  // Crash reporting is OPT-IN AT BUILD TIME: without a SENTRY_DSN
  // (--dart-define), no Sentry code runs at all — the public AGPL
  // build instructions produce a telemetry-free app, and only official
  // store builds carry a DSN. Reports are stack traces + device info;
  // kundli/birth data never leaves the device through this path.
  // Debug builds never report: dev/simulator sessions were filling the
  // dashboard with debug-only assertions (e.g. RenderFlex overflow
  // banners, KAALJYOTI-STAGING-A) that cannot occur in release.
  if (kSentryDsn.isNotEmpty && !kDebugMode) {
    await SentryFlutter.init(
      (options) {
        options.dsn = kSentryDsn;
        // Crashes only — no performance tracing, no session replay,
        // no PII (defaults: sendDefaultPii = false).
        options.tracesSampleRate = 0;
        // Being offline is an everyday state for this audience, not a
        // crash: drop retryable network errors (Supabase auth refresh,
        // DNS lookup failures) that escape from library-internal loops
        // we can't wrap (KAALJYOTI-PROD-A and family). App-level call
        // sites still handle offline themselves for the UX.
        options.beforeSend = (event, hint) {
          final t = event.throwable;
          final offlineNoise = t is SocketException ||
              t is AuthRetryableFetchException ||
              (t != null && t.toString().contains('SocketException'));
          return offlineNoise ? null : event;
        };
      },
      appRunner: _run,
    );
  } else {
    await _run();
  }
}

Future<void> _run() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Type faces are bundled under google_fonts/ (see pubspec assets), so
  // never reach for the network — render from the static assets only.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Swiss Ephemeris bindings — one-time init.
  await EphemerisService.init();

  // tz database. Already loaded lazily inside place_lookup_service for
  // birth-place offsets, but scheduling a local notification needs it
  // before that path is ever taken — zonedSchedule resolves the
  // device's zone through tz.local. Idempotent; ~2ms.
  tzdata.initializeTimeZones();

  // Chart text settings (Settings > Chart text) — seed the notifier the
  // chart painters read before the first frame paints.
  chartTuning.value = await SettingsRepository().chartText();

  // Backend is optional: the app is fully functional offline; Mahakosh,
  // research board, sync and auth simply show their signed-out states
  // when unconfigured.
  if (kBackendConfigured) {
    await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseAnonKey);
  }

  runApp(const ProviderScope(child: KaalJyotiApp()));
}

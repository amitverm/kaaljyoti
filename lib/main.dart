import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  if (kSentryDsn.isNotEmpty) {
    await SentryFlutter.init(
      (options) {
        options.dsn = kSentryDsn;
        // Crashes only — no performance tracing, no session replay,
        // no PII (defaults: sendDefaultPii = false).
        options.tracesSampleRate = 0;
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

  // Chart text settings (Settings > Chart text) — seed the notifier the
  // chart painters read before the first frame paints.
  chartTuning.value = await SettingsRepository().chartText();

  // Backend is optional: the app is fully functional offline; Mahakosh,
  // research board, sync and auth simply show their signed-out states
  // when unconfigured.
  if (kBackendConfigured) {
    await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseAnonKey);
  }

  runApp(const ProviderScope(child: ThirdEyeApp()));
}

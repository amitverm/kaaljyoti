/// The Scheduled kundli alerts screen — what the last pass handed to the
/// OS, plus the diagnostics that interrogate it. Providers are
/// overridden so nothing touches the DB, the ephemeris, or a platform
/// channel.
///
/// Any RenderFlex overflow fails these tests automatically.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/data/settings_repository.dart';
import 'package:kaaljyoti/l10n/astro_l10n.dart';
import 'package:kaaljyoti/screens/scheduled_alerts_screen.dart';
import 'package:kaaljyoti/services/kundli_alert_service.dart';
import 'package:kaaljyoti/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal scheduler: the screen only ever asks it for a pending count.
class _StubScheduler implements AlertScheduler {
  _StubScheduler([this.pending]);
  final int? pending;

  @override
  Future<int?> pendingCount() async => pending;
  @override
  Future<void> init({required void Function(String payload) onTap}) async {}
  @override
  Future<String?> launchPayload() async => null;
  @override
  Future<bool> requestPermissions() async => true;
  @override
  Future<bool> notificationsEnabled() async => true;
  @override
  Future<void> cancelAll() async {}
  @override
  Future<void> schedule(PendingAlert alert) async {}
}

ScheduledAlertRecord _rec(DateTime when, String title, String body,
        {int id = 0}) =>
    ScheduledAlertRecord(
        when: when, title: title, body: body, kundliId: 'k1', id: id);

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    );

Future<AppLocalizations> _pump(
  WidgetTester tester, {
  List<ScheduledAlertRecord> scheduled = const [],
  DateTime? computedAt,
  int? pending,
}) async {
  SharedPreferences.setMockInitialValues({});
  if (computedAt != null) {
    await SettingsRepository().setAlertScheduleSummary(
        AlertScheduleSummary(computedAt: computedAt, alerts: scheduled));
  }
  await tester.pumpWidget(ProviderScope(
    overrides: [
      supabaseClientProvider.overrideWithValue(null),
      kundliAlertServiceProvider.overrideWithValue(
        KundliAlertService(
          scheduler: _StubScheduler(pending),
          events: ({
            required kundli,
            required defaultAyanamsaId,
            required l10n,
            required settings,
            required from,
            required to,
          }) =>
              const [],
        ),
      ),
    ],
    child: _wrap(const ScheduledAlertsScreen()),
  ));
  await tester.pumpAndSettle();
  return lookupAppLocalizations(const Locale('en'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final soon = DateTime.now().add(const Duration(days: 3, hours: 2));
  final later = DateTime.now().add(const Duration(days: 5, hours: 4));
  final gone = DateTime.now().subtract(const Duration(days: 2));

  group('upcomingAlerts', () {
    test('keeps only what is still ahead, soonest first', () {
      final summary = AlertScheduleSummary(
        computedAt: DateTime(2026, 8, 1),
        alerts: [
          _rec(later, 'b', 'y'),
          _rec(gone, 'x', 'z'),
          _rec(soon, 'a', 'w')
        ],
      );
      final out = upcomingAlerts(summary);
      expect(out.map((a) => a.title), ['a', 'b']);
    });

    test('a null summary is empty, not an error', () {
      expect(upcomingAlerts(null), isEmpty);
    });
  });

  testWidgets('lists upcoming alerts grouped by day', (tester) async {
    await _pump(
      tester,
      computedAt: DateTime(2026, 8, 1, 7),
      scheduled: [
        _rec(soon, 'Asha', 'MD ends: Venus · Dasha', id: 1),
        _rec(later, 'Bhanu', 'Saturn enters Kumbha · Transit', id: 2),
      ],
    );
    expect(find.text('Asha'), findsOneWidget);
    expect(find.text('MD ends: Venus · Dasha'), findsOneWidget);
    expect(find.text('Bhanu'), findsOneWidget);
  });

  testWidgets('header states when the pass ran and how many', (tester) async {
    final l10n = await _pump(
      tester,
      computedAt: DateTime(2026, 8, 1, 7),
      scheduled: [_rec(soon, 'Asha', 'x', id: 1)],
    );
    expect(find.text(l10n.saComputedLine('1 Aug 2026, 7:00 AM', '1')),
        findsOneWidget);
  });

  testWidgets('an alert whose moment has passed is not listed', (tester) async {
    // The persisted summary records a pass and is not trimmed as entries
    // age out; this screen shows what is still ahead.
    await _pump(
      tester,
      computedAt: DateTime(2026, 8, 1, 7),
      scheduled: [
        _rec(gone, 'Gone', 'already happened', id: 9),
        _rec(soon, 'Asha', 'still ahead', id: 1),
      ],
    );
    expect(find.text('still ahead'), findsOneWidget);
    expect(find.text('already happened'), findsNothing);
  });

  testWidgets('nothing scheduled shows the empty state', (tester) async {
    final l10n = await _pump(tester, computedAt: DateTime(2026, 8, 1, 7));
    expect(find.text(l10n.naEmpty), findsOneWidget);
  });

  testWidgets('Rebuild now is offered', (tester) async {
    final l10n = await _pump(tester, computedAt: DateTime(2026, 8, 1, 7));
    expect(find.byTooltip(l10n.saRebuildNow), findsOneWidget);
  });

  group('diagnostics (non-release only)', () {
    // kReleaseMode is a compile-time const and cannot be faked from a
    // test — `flutter test` always runs in debug, so these assert the
    // debug/profile side. The release side is guaranteed structurally:
    // `kReleaseMode ? null : ...` and `!kReleaseMode && ...` const-fold
    // away, leaving no runtime path that could show either.
    testWidgets('the test-alert button is here, not on Notifications',
        (tester) async {
      final l10n = await _pump(tester, computedAt: DateTime(2026, 8, 1, 7));
      expect(find.text(l10n.saSendTest), findsOneWidget);
      expect(find.text(l10n.saSendTestNote('${kTestAlertDelay.inSeconds}')),
          findsOneWidget);
    });

    testWidgets('a count mismatch is surfaced with both numbers',
        (tester) async {
      final l10n = await _pump(
        tester,
        computedAt: DateTime(2026, 8, 1, 7),
        scheduled: [_rec(soon, 'Asha', 'x', id: 1)],
        pending: 4,
      );
      expect(find.text(l10n.saCountMismatch('1', '4')), findsOneWidget);
    });

    testWidgets('agreeing counts show no mismatch note', (tester) async {
      final l10n = await _pump(
        tester,
        computedAt: DateTime(2026, 8, 1, 7),
        scheduled: [_rec(soon, 'Asha', 'x', id: 1)],
        pending: 1,
      );
      expect(find.text(l10n.saCountMismatch('1', '1')), findsNothing);
    });
  });
}

/// The unified Notifications screen: Scheduled + a single mixed Past
/// list. Providers are overridden so nothing touches the DB, the
/// ephemeris, or a platform channel.
///
/// The point of the screen is that a user cannot tell which mechanism
/// produced a row, so most of these tests assert exactly that: same
/// treatment, one chronological order, no sign-in wall, no source
/// labels.
///
/// Any RenderFlex overflow fails these tests automatically.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/data/settings_repository.dart';
import 'package:kaaljyoti/l10n/astro_l10n.dart';
import 'package:kaaljyoti/mahakosh/models.dart';
import 'package:kaaljyoti/screens/notifications_screen.dart';
import 'package:kaaljyoti/services/kundli_alert_service.dart';
import 'package:kaaljyoti/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Minimal scheduler: the screen asks it for a pending count and for
/// whether the OS would show anything at all.
class _StubScheduler implements AlertScheduler {
  _StubScheduler({this.pending, this.enabled = true, this.grants = true});
  final int? pending;

  /// What the "OS" reports about the app's notification switch. A
  /// granted request flips it, exactly as the real one would.
  bool enabled;

  /// Whether a permission request is answered yes.
  final bool grants;

  int permissionRequests = 0;

  @override
  Future<int?> pendingCount() async => pending;
  @override
  Future<void> init({required void Function(String payload) onTap}) async {}
  @override
  Future<String?> launchPayload() async => null;
  @override
  Future<bool> requestPermissions() async {
    permissionRequests++;
    if (grants) enabled = true;
    return grants;
  }

  @override
  Future<bool> notificationsEnabled() async => enabled;
  @override
  Future<void> cancelAll() async {}
  @override
  Future<void> schedule(PendingAlert alert) async {}
}

ScheduledAlertRecord _rec(DateTime when, String title, String body,
        {int id = 0, String kundliId = 'k1'}) =>
    ScheduledAlertRecord(
        when: when, title: title, body: body, kundliId: kundliId, id: id);

AppNotification _notif(String id, DateTime at,
        {String type = 'request_match_new'}) =>
    AppNotification(
        id: id,
        type: type,
        payload: const {'request_id': 'r1'},
        read: false,
        createdAt: at);

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    );

Future<AppLocalizations> _pump(
  WidgetTester tester, {
  List<ScheduledAlertRecord> scheduled = const [],
  List<ScheduledAlertRecord> history = const [],
  List<AppNotification> server = const [],
  DateTime? computedAt,
  int? pending,
  bool notificationsEnabled = true,
  bool grantsPermission = true,
}) async {
  SharedPreferences.setMockInitialValues({});
  final repo = SettingsRepository();
  if (computedAt != null) {
    await repo.setAlertScheduleSummary(
        AlertScheduleSummary(computedAt: computedAt, alerts: scheduled));
  }
  if (history.isNotEmpty) await repo.setAlertHistory(history);

  await tester.pumpWidget(ProviderScope(
    overrides: [
      // No Supabase client → mahakoshRepoProvider is null, which is the
      // signed-out / unconfigured shape. Server rows are supplied
      // directly so they can be tested without a backend.
      supabaseClientProvider.overrideWithValue(null),
      notificationsProvider.overrideWith((ref) async => server),
      kundliAlertServiceProvider.overrideWithValue(
        KundliAlertService(
          scheduler: _StubScheduler(
              pending: pending,
              enabled: notificationsEnabled,
              grants: grantsPermission),
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
    child: _wrap(const NotificationsScreen()),
  ));
  await tester.pumpAndSettle();
  return lookupAppLocalizations(const Locale('en'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final soon = DateTime.now().add(const Duration(days: 3, hours: 2));
  final later = DateTime.now().add(const Duration(days: 5, hours: 4));
  final recent = DateTime.now().subtract(const Duration(hours: 6));
  final older = DateTime.now().subtract(const Duration(days: 3));
  final oldest = DateTime.now().subtract(const Duration(days: 9));

  group('Past list — one mixed list', () {
    testWidgets('interleaves both sources strictly by time, newest first',
        (tester) async {
      await _pump(
        tester,
        computedAt: DateTime(2026, 8, 1, 7),
        history: [
          _rec(recent, 'Recent alert', 'body a', id: 1),
          _rec(oldest, 'Oldest alert', 'body b', id: 2),
        ],
        server: [_notif('s1', older)],
      );

      final l10n = lookupAppLocalizations(const Locale('en'));
      final serverTitle = notificationTitle(l10n, _notif('s1', older));

      // Vertical order must be recent(alert) → older(server) → oldest(alert),
      // which is only true if the two sources were merged, not concatenated.
      double y(String text) => tester.getTopLeft(find.text(text)).dy;
      expect(y('Recent alert'), lessThan(y(serverTitle)));
      expect(y(serverTitle), lessThan(y('Oldest alert')));
    });

    testWidgets('carries no source labels', (tester) async {
      await _pump(
        tester,
        computedAt: DateTime(2026, 8, 1, 7),
        history: [_rec(recent, 'Alert', 'body', id: 1)],
        server: [_notif('s1', older)],
      );
      for (final banned in ['Local', 'local', 'Server', 'server', 'Device']) {
        expect(find.textContaining(banned), findsNothing, reason: banned);
      }
    });

    testWidgets('never claims delivery', (tester) async {
      // The OS gives no receipt. Copy that asserts one would be telling
      // the user something the app cannot know.
      final l10n = await _pump(
        tester,
        computedAt: DateTime(2026, 8, 1, 7),
        history: [_rec(recent, 'Alert', 'body', id: 1)],
      );
      expect(find.text(l10n.kaPastNote), findsOneWidget);
      for (final s in [l10n.kaPast, l10n.kaPastNote, l10n.naEmpty]) {
        expect(s.toLowerCase(), isNot(contains('delivered')));
        expect(s.toLowerCase(), isNot(contains('received')));
      }
    });

    testWidgets('a summary entry that has aged out is swept into Past',
        (tester) async {
      // No pass has run since it fired — the sweep-on-read is what makes
      // the list right, and alerts fire while the app is closed.
      await _pump(
        tester,
        computedAt: DateTime(2026, 8, 1, 7),
        scheduled: [_rec(older, 'Asha', 'aged out', id: 5)],
      );
      expect(find.text('aged out'), findsOneWidget);
    });
  });

  group('notifications switched off', () {
    testWidgets('warns above the Past list instead of the preface',
        (tester) async {
      final l10n = await _pump(
        tester,
        computedAt: DateTime(2026, 8, 1, 7),
        history: [_rec(recent, 'Alert', 'body', id: 1)],
        notificationsEnabled: false,
      );
      expect(find.text(l10n.naNotificationsOff), findsOneWidget);
      expect(find.text(l10n.naEnableNotifications), findsOneWidget);
      expect(find.text(l10n.kaPastNote), findsNothing);
      // The history is still there — the warning explains it, not hides it.
      expect(find.text('Alert'), findsOneWidget);
    });

    testWidgets('warns on an empty history too', (tester) async {
      // Notifications off is an excellent reason for an empty list, and
      // this is exactly the person who needs telling.
      final l10n = await _pump(tester, notificationsEnabled: false);
      expect(find.text(l10n.naNotificationsOff), findsOneWidget);
      expect(find.text(l10n.naEnableNotifications), findsOneWidget);
      expect(find.text(l10n.naEmpty), findsOneWidget);
    });

    testWidgets('Enable asks the OS and the banner goes once granted',
        (tester) async {
      final l10n = await _pump(
        tester,
        computedAt: DateTime(2026, 8, 1, 7),
        history: [_rec(recent, 'Alert', 'body', id: 1)],
        notificationsEnabled: false,
      );
      await tester.tap(find.text(l10n.naEnableNotifications));
      await tester.pumpAndSettle();

      expect(find.text(l10n.naNotificationsOff), findsNothing);
      expect(find.text(l10n.naEnableNotifications), findsNothing);
      expect(find.text(l10n.kaPastNote), findsOneWidget);
    });

    testWidgets('a refusal spells out the settings path', (tester) async {
      // Android cannot be handed the notification settings pane, so the
      // banner has to say where they are.
      final l10n = await _pump(
        tester,
        computedAt: DateTime(2026, 8, 1, 7),
        history: [_rec(recent, 'Alert', 'body', id: 1)],
        notificationsEnabled: false,
        grantsPermission: false,
      );
      expect(find.text(l10n.naNotificationsOffPath), findsNothing);

      await tester.tap(find.text(l10n.naEnableNotifications));
      await tester.pumpAndSettle();

      expect(find.text(l10n.naNotificationsOffPath), findsOneWidget);
      expect(find.text(l10n.naNotificationsOff), findsOneWidget);
      // The button is gone: the OS will not ask again.
      expect(find.text(l10n.naEnableNotifications), findsNothing);
    });

    testWidgets('enabled, the preface is one plain line and no banner',
        (tester) async {
      final l10n = await _pump(
        tester,
        computedAt: DateTime(2026, 8, 1, 7),
        history: [_rec(recent, 'Alert', 'body', id: 1)],
      );
      expect(find.text(l10n.kaPastNote), findsOneWidget);
      expect(find.text(l10n.naNotificationsOff), findsNothing);
      expect(find.text(l10n.naEnableNotifications), findsNothing);
    });
  });

  group('dismissal', () {
    testWidgets('swiping a kundli alert removes it from persisted history',
        (tester) async {
      await _pump(
        tester,
        computedAt: DateTime(2026, 8, 1, 7),
        history: [_rec(recent, 'Alert', 'swipe me', id: 42)],
      );
      expect(find.text('swipe me'), findsOneWidget);

      await tester.drag(find.text('swipe me'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('swipe me'), findsNothing);
      expect(await SettingsRepository().alertHistory(), isEmpty);
    });

    testWidgets('swiping a server item persists a device-local dismissal',
        (tester) async {
      // The server has no delete (RLS is select+update only), so the
      // only removal available is to remember it here.
      final l10n = await _pump(
        tester,
        computedAt: DateTime(2026, 8, 1, 7),
        server: [_notif('s1', older)],
      );
      final title = notificationTitle(l10n, _notif('s1', older));
      expect(find.text(title), findsOneWidget);

      await tester.drag(find.text(title), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text(title), findsNothing);
      expect(await SettingsRepository().dismissedNotificationIds(), ['s1']);
    });

    testWidgets('dismissal offers Undo', (tester) async {
      final l10n = await _pump(
        tester,
        computedAt: DateTime(2026, 8, 1, 7),
        history: [_rec(recent, 'Alert', 'swipe me', id: 42)],
      );
      await tester.drag(find.text('swipe me'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text(l10n.naDismissed), findsOneWidget);
      expect(find.text(l10n.rdUndo), findsOneWidget);
    });
  });

  group('no sign-in wall', () {
    testWidgets('signed out, the screen asks for nothing', (tester) async {
      final l10n = await _pump(
        tester,
        computedAt: DateTime(2026, 8, 1, 7),
        history: [_rec(recent, 'Asha', 'x', id: 1)],
      );
      expect(find.text(l10n.signIn), findsNothing);
      expect(find.text(l10n.ntSignInPrompt), findsNothing);
      expect(find.text(l10n.ntBackendMissing), findsNothing);
      // …and the local content is right there.
      expect(find.text('Asha'), findsOneWidget);
    });

    testWidgets('the empty state mentions following, not accounts',
        (tester) async {
      final l10n = await _pump(tester);
      expect(find.text(l10n.naEmpty), findsOneWidget);
      expect(l10n.naEmpty.toLowerCase(), isNot(contains('sign in')));
      expect(l10n.naEmpty.toLowerCase(), isNot(contains('account')));
      expect(find.text(l10n.signIn), findsNothing);
    });
  });

  group('the pinned Scheduled option', () {
    testWidgets('shows the count of what is still ahead', (tester) async {
      final l10n = await _pump(
        tester,
        computedAt: DateTime(2026, 8, 1, 7),
        scheduled: [
          _rec(soon, 'Asha', 'x', id: 1),
          _rec(later, 'Bhanu', 'y', id: 2),
          // Already passed — must not be counted as scheduled.
          _rec(older, 'Gone', 'z', id: 3),
        ],
      );
      expect(find.text(l10n.naScheduledCount('2')), findsOneWidget);
    });

    testWidgets('shows zero rather than disappearing', (tester) async {
      // With nothing scheduled this is still the way to Rebuild now,
      // which is exactly what you want when the count is zero.
      final l10n = await _pump(tester);
      expect(find.text(l10n.naScheduledCount('0')), findsOneWidget);
    });

    testWidgets('no scheduled rows appear inline', (tester) async {
      await _pump(
        tester,
        computedAt: DateTime(2026, 8, 1, 7),
        scheduled: [_rec(soon, 'Future Asha', 'not here', id: 1)],
      );
      expect(find.text('not here'), findsNothing);
      expect(find.text('Future Asha'), findsNothing);
    });

    testWidgets('is not gated out of release builds', (tester) async {
      // User content, unlike the diagnostics on the screen it opens.
      final l10n = await _pump(tester);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.text(l10n.naScheduledCount('0')), findsOneWidget);
    });

    testWidgets('the test-alert bar is no longer on this screen',
        (tester) async {
      // Diagnostics live with the schedule they interrogate.
      final l10n = await _pump(tester);
      expect(find.text(l10n.saSendTest), findsNothing);
    });
  });
}

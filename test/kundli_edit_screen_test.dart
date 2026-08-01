/// Kundli Details (edit): the pinned Save bar and its live resolution
/// summary, and the regression that matters most here — editing the
/// birth data of a SYNCED chart must still write through the repository
/// with sync intact, because that write is what stamps updated_at and
/// what last-write-wins reconciles against.
///
/// Any RenderFlex overflow fails these tests automatically.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/date_format.dart';
import 'package:kaaljyoti/data/kundli_repository.dart';
import 'package:kaaljyoti/data/models.dart';
import 'package:kaaljyoti/data/settings_repository.dart';
import 'package:kaaljyoti/l10n/astro_l10n.dart';
import 'package:kaaljyoti/screens/kundli_edit_screen.dart';
import 'package:kaaljyoti/state/providers.dart';
import 'package:kaaljyoti/ui/birth_form.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Records what the screen asked to be written, without a database.
class _RecordingRepo implements KundliRepository {
  _RecordingRepo(this.stored);
  Kundli stored;
  final List<Kundli> updates = [];
  final List<String> deletes = [];

  @override
  Future<Kundli?> byId(String id) async => id == stored.id ? stored : null;

  @override
  Future<void> update(Kundli kundli) async {
    updates.add(kundli);
    stored = kundli;
  }

  @override
  Future<void> delete(String id) async => deletes.add(id);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Kundli _kundli({
  bool syncEnabled = false,
  bool ephemeral = false,
  String placeName = 'Kolkata, West Bengal, India',
  String tz = 'Asia/Kolkata',
}) =>
    Kundli(
      id: 'k1',
      name: 'Asha',
      relationTag: 'Client',
      // 9 June 1943, 23:02 in Kolkata — war time, +06:30.
      birthUtc: DateTime.utc(1943, 6, 9, 16, 32),
      latitude: 22.5726,
      longitude: 88.3639,
      timezoneName: tz,
      utcOffsetMinutes: 390,
      placeName: placeName,
      syncEnabled: syncEnabled,
      isEphemeral: ephemeral,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 1),
    );

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    );

Future<(AppLocalizations, _RecordingRepo)> _pump(
  WidgetTester tester, {
  Kundli? kundli,
  bool resetPrefs = true,
}) async {
  if (resetPrefs) SharedPreferences.setMockInitialValues({});
  KJDate.pref = DateFormatPref.dMMMy;
  final repo = _RecordingRepo(kundli ?? _kundli());
  // The form is a plain ListView, so off-screen rows never get elements
  // and find.text cannot see them.
  tester.view.physicalSize = const Size(900, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      supabaseClientProvider.overrideWithValue(null),
      kundliRepoProvider.overrideWithValue(repo),
    ],
    child: _wrap(const KundliEditScreen(kundliId: 'k1')),
  ));
  await tester.pumpAndSettle();
  return (lookupAppLocalizations(const Locale('en')), repo);
}

/// For the cases that seed prefs (an existing follow) before pumping.
Future<(AppLocalizations, _RecordingRepo)> _pumpKeepingPrefs(
        WidgetTester tester,
        {Kundli? kundli}) =>
    _pump(tester, kundli: kundli, resetPrefs: false);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the pinned Save bar', () {
    testWidgets('holds Save, and the AppBar no longer does', (tester) async {
      final (l10n, _) = await _pump(tester);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text(l10n.save),
        ),
        findsNothing,
      );
      expect(find.widgetWithText(FilledButton, l10n.save), findsOneWidget);
    });

    testWidgets('shows the stored resolution before anything is touched',
        (tester) async {
      // The point of putting it here: opening this screen is how you
      // check a chart cast years ago. 1943 Kolkata is war time, +06:30,
      // and nothing in the app said so until now.
      await _pump(tester);
      expect(
        find.text('Wed, 9 Jun 1943 · 23:02 (11:02 PM) · Kolkata · +06:30'),
        findsOneWidget,
      );
    });

    testWidgets('recomputes live as the time is edited', (tester) async {
      final (l10n, _) = await _pump(tester);
      await tester.tap(find.byType(TimeFieldTile));
      await tester.pumpAndSettle();
      final picker = find.descendant(
        of: find.byType(TimePickerDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(picker.at(0), '6');
      await tester.enterText(picker.at(1), '15');
      await tester.tap(find.text('AM'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(
        find.text('Wed, 9 Jun 1943 · 06:15 (6:15 AM) · Kolkata · +06:30'),
        findsOneWidget,
      );
      expect(l10n.save, isNotEmpty);
    });

    testWidgets('the summary disappears if the name is cleared',
        (tester) async {
      await _pump(tester);
      expect(find.byKey(const Key('birthSummary')), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Asha'), '');
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('birthSummary')), findsNothing);
    });
  });

  group('the time control', () {
    testWidgets('is the same shared form field the entry screen uses',
        (tester) async {
      await _pump(tester);
      expect(find.byType(TimeFieldTile), findsOneWidget);
      expect(find.byType(OutlinedButton), findsNothing);
    });

    testWidgets('is prefilled from the stored birth time', (tester) async {
      await _pump(tester);
      final tile = tester.widget<TimeFieldTile>(find.byType(TimeFieldTile));
      expect(tile.time, const TimeOfDay(hour: 23, minute: 2));
    });
  });

  group('delete', () {
    testWidgets('lives in the header menu, not beside Save', (tester) async {
      // A destructive button directly above the pinned primary one, under
      // the same thumb, is a misclick trap.
      final (l10n, _) = await _pump(tester);
      expect(find.text(l10n.deleteKundli), findsNothing);

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      expect(find.text(l10n.deleteKundli), findsOneWidget);
    });

    testWidgets('still confirms before deleting', (tester) async {
      final (l10n, repo) = await _pump(tester);
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.deleteKundli));
      await tester.pumpAndSettle();

      expect(find.text(l10n.keDeleteTitle), findsOneWidget);
      await tester.tap(find.text(l10n.cancel));
      await tester.pumpAndSettle();
      expect(repo.deletes, isEmpty);
    });
  });

  group('the Kundli alerts row', () {
    /// The switch inside the alerts card — scoped by its title, so it
    /// cannot accidentally match the cloud-sync one.
    Finder alertSwitchOf(AppLocalizations l10n) => find.descendant(
          of: find.ancestor(
            of: find.text(l10n.beFollowAlertsTitle),
            matching: find.byType(Card),
          ),
          matching: find.byType(Switch),
        );

    Switch alertSwitch(WidgetTester tester, AppLocalizations l10n) =>
        tester.widget<Switch>(alertSwitchOf(l10n));

    testWidgets('is off for a chart that is not followed', (tester) async {
      final (l10n, _) = await _pump(tester);
      expect(
          find.text(l10n.stSectionKundliAlerts.toUpperCase()), findsOneWidget);
      expect(alertSwitch(tester, l10n).value, isFalse);
    });

    testWidgets('reflects an existing follow', (tester) async {
      SharedPreferences.setMockInitialValues({
        'kundli_followed_ids': ['k1'],
      });
      final (l10n, _) = await _pumpKeepingPrefs(tester);
      expect(alertSwitch(tester, l10n).value, isTrue);
    });

    testWidgets('toggling on adds to the follow set immediately',
        (tester) async {
      // Live-bound, not save-bound: no Save is pressed anywhere here.
      final (l10n, repo) = await _pump(tester);
      await tester.tap(alertSwitchOf(l10n));
      await tester.pumpAndSettle();

      expect(alertSwitch(tester, l10n).value, isTrue);
      expect(await SettingsRepository().followedKundliIds(), ['k1']);
      expect(repo.updates, isEmpty, reason: 'the kundli row is untouched');
    });

    testWidgets('toggling off removes it again', (tester) async {
      SharedPreferences.setMockInitialValues({
        'kundli_followed_ids': ['k1'],
      });
      final (l10n, _) = await _pumpKeepingPrefs(tester);
      await tester.tap(alertSwitchOf(l10n));
      await tester.pumpAndSettle();

      expect(alertSwitch(tester, l10n).value, isFalse);
      expect(await SettingsRepository().followedKundliIds(), isEmpty);
    });

    testWidgets('is hidden for an ephemeral chart', (tester) async {
      // The scheduling pass skips these, so a follow would be an id that
      // can never produce an alert.
      final (l10n, _) = await _pump(tester, kundli: _kundli(ephemeral: true));
      expect(find.text(l10n.stSectionKundliAlerts.toUpperCase()), findsNothing);
      expect(find.text(l10n.beFollowAlertsTitle), findsNothing);
    });

    testWidgets('sits outside Sharing & sync', (tester) async {
      // Established policy on this branch: sync is a server feature
      // behind an account, alerts are local and need none. Housing them
      // together is the conflation the rename undid.
      final (l10n, _) = await _pump(tester);
      double y(String t) => tester.getTopLeft(find.text(t)).dy;
      expect(y(l10n.keSectionSharing.toUpperCase()),
          lessThan(y(l10n.stSectionKundliAlerts.toUpperCase())));
      expect(y(l10n.cloudSync),
          lessThan(y(l10n.stSectionKundliAlerts.toUpperCase())));
    });
  });

  group('required-field validation', () {
    testWidgets('a cleared name is marked inline and blocks the save',
        (tester) async {
      final (l10n, repo) = await _pump(tester);
      await tester.enterText(find.widgetWithText(TextField, 'Asha'), '');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, l10n.save));
      await tester.pumpAndSettle();

      expect(find.text(l10n.beFieldRequired), findsOneWidget);
      expect(repo.updates, isEmpty, reason: 'nothing was written');
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('the error clears as soon as the field is refilled',
        (tester) async {
      final (l10n, _) = await _pump(tester);
      await tester.enterText(find.widgetWithText(TextField, 'Asha'), '');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, l10n.save));
      await tester.pumpAndSettle();
      expect(find.text(l10n.beFieldRequired), findsOneWidget);

      await tester.enterText(
          find.byKey(birthFieldKey(BirthField.name)), 'Asha');
      await tester.pumpAndSettle();
      expect(find.text(l10n.beFieldRequired), findsNothing);
    });

    testWidgets('a retyped place that was never picked is caught',
        (tester) async {
      // The silent bug this replaces: the birth block was skipped, the
      // old coordinates stayed, and the field claimed otherwise.
      final (l10n, repo) = await _pump(tester);
      await tester.enterText(
          find.byKey(birthFieldKey(BirthField.place)), 'Mumbai');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, l10n.save));
      await tester.pumpAndSettle();

      expect(find.text(l10n.bePlaceNotChosen), findsOneWidget);
      expect(repo.updates, isEmpty);
    });

    testWidgets('leaving the stored place untouched is not "missing"',
        (tester) async {
      // The box holds the stored name and no new place was picked; that
      // is the ordinary case of editing only a name.
      final (l10n, repo) = await _pump(tester);
      await tester.tap(find.widgetWithText(FilledButton, l10n.save));
      await tester.pumpAndSettle();

      expect(find.text(l10n.beFieldRequired), findsNothing);
      expect(find.text(l10n.bePlaceNotChosen), findsNothing);
      expect(repo.updates, hasLength(1));
    });

    testWidgets('an emptied place says Required, not "pick one"',
        (tester) async {
      final (l10n, _) = await _pump(tester);
      await tester.enterText(find.byKey(birthFieldKey(BirthField.place)), '');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, l10n.save));
      await tester.pumpAndSettle();

      expect(find.text(l10n.beFieldRequired), findsOneWidget);
      expect(find.text(l10n.bePlaceNotChosen), findsNothing);
    });
  });

  group('saving edited birth data', () {
    testWidgets('a synced chart stays synced and is written through',
        (tester) async {
      // The regression that matters: repo.update is what stamps
      // updated_at, and last-write-wins reconciles against it. A save
      // that skipped the write, or dropped syncEnabled on the way, would
      // leave the other devices holding the OLD birth data with no
      // signal that anything changed.
      final (l10n, repo) =
          await _pump(tester, kundli: _kundli(syncEnabled: true));

      await tester.tap(find.byType(TimeFieldTile));
      await tester.pumpAndSettle();
      final picker = find.descendant(
        of: find.byType(TimePickerDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(picker.at(0), '6');
      await tester.enterText(picker.at(1), '15');
      await tester.tap(find.text('AM'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, l10n.save));
      await tester.pumpAndSettle();

      expect(repo.updates, hasLength(1));
      final written = repo.updates.single;
      expect(written.syncEnabled, isTrue, reason: 'sync must survive an edit');
      // 06:15 local at +06:30 → 23:45 UTC the previous day.
      expect(written.birthUtc, DateTime.utc(1943, 6, 8, 23, 45));
      expect(written.utcOffsetMinutes, 390);
    });

    testWidgets('editing only the name leaves the birth instant alone',
        (tester) async {
      final (l10n, repo) =
          await _pump(tester, kundli: _kundli(syncEnabled: true));
      await tester.enterText(find.widgetWithText(TextField, 'Asha'), 'Asha R');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, l10n.save));
      await tester.pumpAndSettle();

      final written = repo.updates.single;
      expect(written.name, 'Asha R');
      expect(written.birthUtc, DateTime.utc(1943, 6, 9, 16, 32));
      expect(written.syncEnabled, isTrue);
    });
  });
}

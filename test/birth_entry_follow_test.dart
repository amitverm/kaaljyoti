/// "Alert me about this kundli" on the creation form.
///
/// Default ON, per-creation, and never applied to a Prashna — the alert
/// pass skips ephemeral charts, so following one would put an id in the
/// set that can never produce an alert. The invariant is enforced at
/// both ends and pinned here at both ends too.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/l10n/astro_l10n.dart';
import 'package:kaaljyoti/screens/birth_entry_screen.dart';
import 'package:kaaljyoti/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: child,
    );

/// Signed out (no Supabase client), prefs mocked. Enough to render the
/// form; the save path needs a router and is covered by the pure
/// invariant below rather than by driving the whole form.
Future<AppLocalizations> _pump(WidgetTester tester,
    {bool prashna = false}) async {
  SharedPreferences.setMockInitialValues({});
  // The form is a plain ListView, so off-screen rows never get elements
  // and find.text cannot see them. A tall viewport builds the whole
  // form, which also lets the Prashna case assert ABSENCE — something
  // scrollUntilVisible cannot do.
  tester.view.physicalSize = const Size(900, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [supabaseClientProvider.overrideWithValue(null)],
    child: _wrap(BirthEntryScreen(prashna: prashna)),
  ));
  await tester.pumpAndSettle();
  return lookupAppLocalizations(const Locale('en'));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('shouldFollowNewKundli', () {
    test('follows an ordinary new kundli when the toggle is on', () {
      expect(
        shouldFollowNewKundli(
            toggleOn: true, prashna: false, isEphemeral: false),
        isTrue,
      );
    });

    test('does not follow when the toggle is off', () {
      expect(
        shouldFollowNewKundli(
            toggleOn: false, prashna: false, isEphemeral: false),
        isFalse,
      );
    });

    test('never follows a Prashna, toggle or not', () {
      for (final on in [true, false]) {
        expect(
          shouldFollowNewKundli(
              toggleOn: on, prashna: true, isEphemeral: false),
          isFalse,
          reason: 'toggleOn=$on',
        );
      }
    });

    test('never follows an ephemeral chart, toggle or not', () {
      // The scheduling pass skips these, so a follow would be an id that
      // can never produce an alert.
      for (final on in [true, false]) {
        expect(
          shouldFollowNewKundli(
              toggleOn: on, prashna: false, isEphemeral: true),
          isFalse,
          reason: 'toggleOn=$on',
        );
      }
    });

    test('the two exclusions are independent', () {
      // A Prashna cast from THIS form is saved and non-ephemeral, while
      // an unkept instant Prashna from the list screen is ephemeral but
      // arrives by another path — so neither flag implies the other and
      // both must be checked.
      expect(
        shouldFollowNewKundli(
            toggleOn: true, prashna: true, isEphemeral: false),
        isFalse,
      );
      expect(
        shouldFollowNewKundli(
            toggleOn: true, prashna: false, isEphemeral: true),
        isFalse,
      );
    });
  });

  group('the toggle on the form', () {
    testWidgets('is shown and defaults ON', (tester) async {
      final l10n = await _pump(tester);
      final tile = tester.widget<SwitchListTile>(
        find.ancestor(
          of: find.text(l10n.beFollowAlertsTitle),
          matching: find.byType(SwitchListTile),
        ),
      );
      expect(tile.value, isTrue);
    });

    testWidgets('is offered signed out', (tester) async {
      // Unlike Cloud sync, which needs an account. Alerts are computed
      // on this device, so sign-in has nothing to do with them.
      final l10n = await _pump(tester);
      expect(find.text(l10n.beFollowAlertsTitle), findsOneWidget);
      expect(find.text(l10n.beSyncTitle), findsNothing);
    });

    testWidgets('sits under its own Kundli alerts heading', (tester) async {
      final l10n = await _pump(tester);
      expect(
          find.text(l10n.stSectionKundliAlerts.toUpperCase()), findsOneWidget);
    });

    testWidgets('is absent from the Prashna form', (tester) async {
      final l10n = await _pump(tester, prashna: true);
      expect(find.text(l10n.beFollowAlertsTitle), findsNothing);
      expect(find.text(l10n.stSectionKundliAlerts.toUpperCase()), findsNothing);
    });

    testWidgets('can be switched off', (tester) async {
      final l10n = await _pump(tester);
      await tester.tap(find.text(l10n.beFollowAlertsTitle));
      await tester.pumpAndSettle();
      final tile = tester.widget<SwitchListTile>(
        find.ancestor(
          of: find.text(l10n.beFollowAlertsTitle),
          matching: find.byType(SwitchListTile),
        ),
      );
      expect(tile.value, isFalse);
    });
  });

  group('the follow-set side of the save', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    ProviderContainer container() {
      final c = ProviderContainer();
      addTearDown(c.dispose);
      return c;
    }

    test('adding the new id makes it followed and persists', () async {
      final c = container();
      c.read(followedKundlisProvider.notifier).addAll(['new-kundli']);
      expect(c.read(followedKundlisProvider), {'new-kundli'});
      await Future<void>.delayed(Duration.zero);
      expect(await c.read(settingsRepoProvider).followedKundliIds(),
          ['new-kundli']);
    });

    test('creating without following leaves the set untouched', () {
      final c = container();
      expect(c.read(followedKundlisProvider), isEmpty);
    });

    test('following one chart does not disturb earlier follows', () {
      final c = container();
      final n = c.read(followedKundlisProvider.notifier);
      n.addAll(['older']);
      n.addAll(['new-kundli']);
      expect(c.read(followedKundlisProvider), {'older', 'new-kundli'});
    });
  });
}

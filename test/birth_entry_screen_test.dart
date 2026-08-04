/// The birth entry form: the live resolution summary and pinned Cast
/// bar, required-field validation, and the after-casting switches.
///
/// The screen is where a wrong chart is most cheaply prevented, so most
/// of what is asserted here is error-proofing rather than layout.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/date_format.dart';
import 'package:kaaljyoti/data/models.dart';
import 'package:kaaljyoti/l10n/astro_l10n.dart';
import 'package:kaaljyoti/services/place_lookup_service.dart';
import 'package:kaaljyoti/ui/birth_form.dart';
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
    {bool prashna = false, List<Kundli> library = const []}) async {
  SharedPreferences.setMockInitialValues({});
  // The form is a plain ListView, so off-screen rows never get elements
  // and find.text cannot see them. A tall viewport builds the whole
  // form, which also lets the Prashna case assert ABSENCE — something
  // scrollUntilVisible cannot do.
  tester.view.physicalSize = const Size(900, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      supabaseClientProvider.overrideWithValue(null),
      kundlisProvider.overrideWith((ref) async => library),
    ],
    child: _wrap(BirthEntryScreen(prashna: prashna)),
  ));
  await tester.pumpAndSettle();
  return lookupAppLocalizations(const Locale('en'));
}

Kundli _kundliAt(String place, DateTime created,
        {double lat = 18.52,
        double lon = 73.86,
        String tz = 'Asia/Kolkata',
        List<String> labels = const [],
        bool isArchived = false}) =>
    Kundli(
      id: place,
      name: place,
      relationTag: 'Client',
      labels: labels,
      birthUtc: DateTime.utc(1990, 1, 1),
      latitude: lat,
      longitude: lon,
      timezoneName: tz,
      utcOffsetMinutes: 330,
      placeName: place,
      isArchived: isArchived,
      createdAt: created,
      updatedAt: created,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('offset + zone formatting', () {
    test('offsets are signed and zero-padded', () {
      expect(formatUtcOffset(330), '+05:30');
      expect(formatUtcOffset(390), '+06:30');
      expect(formatUtcOffset(0), '+00:00');
      expect(formatUtcOffset(-150), '-02:30');
      expect(formatUtcOffset(-240), '-04:00');
      expect(formatUtcOffset(525), '+08:45');
      expect(formatUtcOffset(840), '+14:00');
    });

    test('an abbreviation prefixes the offset when there is one', () {
      expect(formatZoneLabel(330, 'IST'), 'IST +05:30');
      expect(formatZoneLabel(-240, 'EDT'), 'EDT -04:00');
    });

    test('no abbreviation means the offset alone, never an invented name', () {
      expect(formatZoneLabel(390, null), '+06:30');
      expect(formatZoneLabel(525, null), '+08:45');
    });

    test('zoneAbbreviation rejects the numeric stand-ins tz returns', () {
      // tz reports "+0630" for zones with no letter form. Showing that
      // as an abbreviation would render "+0630 +06:30".
      expect(zoneAbbreviation('IST'), 'IST');
      expect(zoneAbbreviation('GMT'), 'GMT');
      expect(zoneAbbreviation('+0630'), isNull);
      expect(zoneAbbreviation('-0330'), isNull);
      expect(zoneAbbreviation(''), isNull);
      expect(zoneAbbreviation('   '), isNull);
    });
  });

  group('composeBirthSummary', () {
    setUp(() => KJDate.pref = DateFormatPref.dMMMy);

    test('states the time in BOTH notations, after the weekday', () {
      // The whole point: a 24-hour time typed as if it were 12-hour is
      // invisible until the chart is inexplicable.
      final line = composeBirthSummary(
        weekday: 'Sat',
        date: DateTime(1990, 6, 9),
        hour: 23,
        minute: 2,
        placeShortName: 'Kolkata',
        offsetMinutes: 330,
        abbreviation: 'IST',
      );
      expect(line, 'Sat, 9 Jun 1990 · 23:02 (11:02 PM) · Kolkata · IST +05:30');
    });

    test('binds the weekday to the date with a comma, not a middot', () {
      // It is a property OF the date, not a fifth independent fact.
      final line = composeBirthSummary(
        weekday: 'Thu',
        date: DateTime(1947, 8, 14),
        hour: 9,
        minute: 0,
        placeShortName: 'Pune',
        offsetMinutes: 330,
        abbreviation: 'IST',
      );
      expect(line, startsWith('Thu, 14 Aug 1947 · '));
      expect(line.split(' · ').first, 'Thu, 14 Aug 1947');
    });

    test('a morning time reads unambiguously too', () {
      final line = composeBirthSummary(
        weekday: 'Sat',
        date: DateTime(1990, 6, 9),
        hour: 6,
        minute: 5,
        placeShortName: 'Pune',
        offsetMinutes: 330,
        abbreviation: 'IST',
      );
      expect(line, contains('06:05 (6:05 AM)'));
    });

    test('war-time Kolkata shows +06:30 with no invented abbreviation', () {
      // Global-births audit item (c): the app always resolved this
      // correctly and never said so. A 1943 Kolkata birth is +06:30.
      final svc = PlaceLookupService();
      final resolved =
          svc.resolveLocalTime('Asia/Kolkata', DateTime(1943, 6, 1, 12, 0));
      expect(resolved.offsetMinutes, 390);
      expect(resolved.abbreviation, isNull, reason: 'tz gives "+0630"');

      final line = composeBirthSummary(
        // 2 June 1943 was a Wednesday.
        weekday: 'Wed',
        date: DateTime(1943, 6, 2),
        hour: 12,
        minute: 0,
        placeShortName: 'Kolkata',
        offsetMinutes: resolved.offsetMinutes,
        abbreviation: resolved.abbreviation,
      );
      expect(line, 'Wed, 2 Jun 1943 · 12:00 (12:00 PM) · Kolkata · +06:30');
      expect(line, isNot(contains('IST')));
    });

    test('the same place today resolves to IST +05:30', () {
      // The contrast is the feature: same city, different era, and the
      // line says so.
      final svc = PlaceLookupService();
      final now =
          svc.resolveLocalTime('Asia/Kolkata', DateTime(1990, 8, 15, 10, 30));
      expect(
          formatZoneLabel(now.offsetMinutes, now.abbreviation), 'IST +05:30');
    });

    test('the weekday is CIVIL, not the sunrise-bounded vara', () {
      // A 3 a.m. birth on Wednesday belongs to Tuesday's vara, but the
      // user typed Wednesday and this line exists to confirm what they
      // typed. If someone ever "corrects" this to vara, a correctly
      // entered pre-sunrise birth starts looking mistyped — and that is
      // the exact bug this test is here to fail on.
      final date = DateTime(1943, 6, 2);
      expect(date.weekday, DateTime.wednesday);
      final line = composeBirthSummary(
        weekday: 'Wed',
        date: date,
        hour: 3,
        minute: 0,
        placeShortName: 'Kolkata',
        offsetMinutes: 390,
      );
      expect(line, startsWith('Wed, '));
      expect(line, contains('03:00 (3:00 AM)'));
    });

    test('weekday names come from the app l10n, in both languages', () {
      // Not intl's own date symbols — the app curates these.
      final en = lookupAppLocalizations(const Locale('en'));
      final hi = lookupAppLocalizations(const Locale('hi'));
      expect(weekdayAbbrLabel(en, DateTime(1943, 6, 2).weekday), 'Wed');
      expect(weekdayAbbrLabel(hi, DateTime(1943, 6, 2).weekday), 'बुध');
      expect(weekdayAbbrLabel(en, DateTime(1990, 6, 9).weekday), 'Sat');
      expect(weekdayAbbrLabel(hi, DateTime(1990, 6, 9).weekday), 'शनि');
    });

    test('the short set covers all seven days and wraps like the full one', () {
      final en = lookupAppLocalizations(const Locale('en'));
      expect(
        [for (var d = 1; d <= 7; d++) weekdayAbbrLabel(en, d)],
        ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      );
      // Sunday is 7; the modulo must not fall off the end.
      expect(weekdayAbbrLabel(en, 7), 'Sun');
    });

    test('short day names are their own keys, not aliases of planets', () {
      // Hindi day names derive from the grahas, so मंगल/बुध/गुरु/शुक्र/शनि
      // coincide with planet labels. They are separate keys on purpose:
      // a day is not a planet, and aliasing would break the first time a
      // graha is retitled. सोम and रवि do not even match (चंद्र, सूर्य).
      final hi = lookupAppLocalizations(const Locale('hi'));
      expect(weekdayAbbrLabel(hi, DateTime.monday), 'सोम');
      expect(hi.planetMoon, 'चंद्र');
      expect(weekdayAbbrLabel(hi, DateTime.sunday), 'रवि');
      expect(hi.planetSun, 'सूर्य');
    });

    test('the full names are untouched — Today and Muhurta still use them', () {
      final en = lookupAppLocalizations(const Locale('en'));
      final hi = lookupAppLocalizations(const Locale('hi'));
      expect(weekdayLabel(en, DateTime(1943, 6, 2).weekday), 'Wednesday');
      expect(weekdayLabel(hi, DateTime(1943, 6, 2).weekday), 'बुधवार');
    });

    test('follows the app-wide date format preference', () {
      KJDate.pref = DateFormatPref.ddMMyyyy;
      final line = composeBirthSummary(
        weekday: 'Sat',
        date: DateTime(1990, 6, 9),
        hour: 1,
        minute: 0,
        placeShortName: 'X',
        offsetMinutes: 0,
        abbreviation: 'GMT',
      );
      expect(line, startsWith('Sat, 09/06/1990 · '));
    });
  });

  group('required-field validation', () {
    const aDate = null;

    test('a blank form is missing all four', () {
      expect(
        missingBirthFields(name: '', date: aDate, time: null, place: null),
        BirthField.values.toSet(),
      );
    });

    test('whitespace is not a name', () {
      expect(
        missingBirthFields(name: '   ', date: aDate, time: null, place: null),
        contains(BirthField.name),
      );
    });

    test('a complete form is missing nothing', () {
      expect(
        missingBirthFields(
          name: 'Asha',
          date: DateTime(1990, 6, 9),
          time: const TimeOfDay(hour: 6, minute: 0),
          place: 'anything non-null',
        ),
        isEmpty,
      );
    });

    test('flags exactly the empty ones', () {
      expect(
        missingBirthFields(
          name: 'Asha',
          date: DateTime(1990, 6, 9),
          time: null,
          place: null,
        ),
        {BirthField.time, BirthField.place},
      );
    });

    test('the first offender is the topmost in form order', () {
      // Scrolling to the LAST empty box when three above it are also
      // empty is worse than not scrolling at all.
      expect(firstMissingBirthField({BirthField.place, BirthField.name}),
          BirthField.name);
      expect(firstMissingBirthField({BirthField.place, BirthField.time}),
          BirthField.time);
      expect(firstMissingBirthField({BirthField.place}), BirthField.place);
      expect(firstMissingBirthField({}), isNull);
    });

    testWidgets('Cast on a blank form marks every required field inline',
        (tester) async {
      final l10n = await _pump(tester);
      expect(find.text(l10n.beFieldRequired), findsNothing,
          reason: 'nothing is flagged before Cast is pressed');

      await tester.tap(find.text(l10n.castKundli));
      await tester.pumpAndSettle();

      // Name, date, time and place — four inline messages, no snackbar.
      expect(find.text(l10n.beFieldRequired), findsNWidgets(4));
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('filling a field clears its error immediately', (tester) async {
      final l10n = await _pump(tester);
      await tester.tap(find.text(l10n.castKundli));
      await tester.pumpAndSettle();
      expect(find.text(l10n.beFieldRequired), findsNWidgets(4));

      await tester.enterText(
          find.byKey(const GlobalObjectKey(BirthField.name)), 'Asha');
      await tester.pumpAndSettle();

      // Three left: the name's went the moment it was typed, without
      // waiting for another press of Cast.
      expect(find.text(l10n.beFieldRequired), findsNWidgets(3));
    });

    testWidgets('typed-but-unchosen place gets its own message',
        (tester) async {
      final l10n = await _pump(tester);
      await tester.enterText(
          find.byKey(const GlobalObjectKey(BirthField.place)), 'Kolk');
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.castKundli));
      await tester.pumpAndSettle();

      // The box looks filled in, so "Required" would read as a bug.
      expect(find.text(l10n.bePlaceNotChosen), findsOneWidget);
    });
  });

  group('the time control', () {
    testWidgets('is a form field, not a button', (tester) async {
      // It sits under the date row holding the other half of the same
      // fact; reading as a different kind of control made the pair look
      // unrelated.
      final l10n = await _pump(tester);
      expect(
        find.descendant(
          of: find.byKey(const GlobalObjectKey(BirthField.time)),
          matching: find.byType(InputDecorator),
        ),
        findsOneWidget,
      );
      expect(find.widgetWithText(OutlinedButton, l10n.timeLabel), findsNothing);
    });

    testWidgets('carries a label like every other input', (tester) async {
      final l10n = await _pump(tester);
      expect(
        find.descendant(
          of: find.byKey(const GlobalObjectKey(BirthField.time)),
          matching: find.text(l10n.timeLabel),
        ),
        findsOneWidget,
      );
    });

    testWidgets('shows its error inline, in the decoration', (tester) async {
      final l10n = await _pump(tester);
      await tester.tap(find.text(l10n.castKundli));
      await tester.pumpAndSettle();

      final decorator = tester.widget<InputDecorator>(
        find.descendant(
          of: find.byKey(const GlobalObjectKey(BirthField.time)),
          matching: find.byType(InputDecorator),
        ),
      );
      expect(decorator.decoration.errorText, l10n.beFieldRequired);
      expect(decorator.isEmpty, isTrue);
    });

    testWidgets('the Prashna form prefills it, so it is not empty',
        (tester) async {
      final decorator = await _pump(tester, prashna: true)
          .then((_) => tester.widget<InputDecorator>(
                find.descendant(
                  of: find.byKey(const GlobalObjectKey(BirthField.time)),
                  matching: find.byType(InputDecorator),
                ),
              ));
      expect(decorator.isEmpty, isFalse);
    });
  });

  group('recentBirthPlaces', () {
    Kundli k(String id, String place, DateTime created,
            {double lat = 18.52,
            double lon = 73.86,
            String tz = 'Asia/Kolkata'}) =>
        Kundli(
          id: id,
          name: id,
          relationTag: 'Client',
          birthUtc: DateTime.utc(1990, 1, 1),
          latitude: lat,
          longitude: lon,
          timezoneName: tz,
          utcOffsetMinutes: 330,
          placeName: place,
          createdAt: created,
          updatedAt: created,
        );

    test('is newest first', () {
      final out = recentBirthPlaces([
        k('a', 'Pune, Maharashtra, India', DateTime(2026, 1, 1)),
        k('b', 'Delhi, India', DateTime(2026, 6, 1)),
      ]);
      expect(out.map((p) => p.displayName),
          ['Delhi, India', 'Pune, Maharashtra, India']);
    });

    test('dedupes by place, keeping the most recent use', () {
      final out = recentBirthPlaces([
        k('a', 'Pune, Maharashtra, India', DateTime(2026, 1, 1)),
        k('b', 'Pune, Maharashtra, India', DateTime(2026, 6, 1)),
        k('c', 'Delhi, India', DateTime(2026, 3, 1)),
      ]);
      expect(out.map((p) => p.displayName),
          ['Pune, Maharashtra, India', 'Delhi, India']);
    });

    test('caps at three by default', () {
      final out = recentBirthPlaces([
        for (var i = 0; i < 8; i++)
          k('$i', 'City$i, India', DateTime(2026, 1, 1 + i)),
      ]);
      expect(out, hasLength(3));
      expect(out.first.displayName, 'City7, India');
    });

    test('skips charts with no place', () {
      final out = recentBirthPlaces([
        k('a', '   ', DateTime(2026, 6, 1)),
        k('b', 'Delhi, India', DateTime(2026, 1, 1)),
      ]);
      expect(out.map((p) => p.displayName), ['Delhi, India']);
    });

    test('an empty library offers nothing', () {
      expect(recentBirthPlaces([]), isEmpty);
    });

    test('carries the coordinates and zone through, not just the label', () {
      // A chip has to fill the field exactly as a search hit would, or
      // the chart it produces would be wrong in a way nobody could see.
      final out = recentBirthPlaces([
        k('a', 'Yangon, Myanmar', DateTime(2026, 6, 1),
            lat: 16.8, lon: 96.15, tz: 'Asia/Yangon'),
      ]);
      expect(out.single.latitude, 16.8);
      expect(out.single.longitude, 96.15);
      expect(out.single.timezoneName, 'Asia/Yangon');
    });
  });

  group('placeFromStoredName', () {
    test('round-trips the stored string exactly', () {
      // Re-picking a recent place must save the same text the earlier
      // chart carries, or two charts would disagree about one place.
      for (final stored in [
        'Kolkata, West Bengal, India',
        'Pune, India',
        'Nowhere',
        'A, B, C, D',
      ]) {
        final p = placeFromStoredName(
          placeName: stored,
          latitude: 0,
          longitude: 0,
          timezoneName: 'UTC',
        );
        expect(p.displayName, stored, reason: stored);
      }
    });

    test('the short name is the city, for the summary line', () {
      final p = placeFromStoredName(
        placeName: 'Kolkata, West Bengal, India',
        latitude: 0,
        longitude: 0,
        timezoneName: 'UTC',
      );
      expect(p.name, 'Kolkata');
    });

    test('displayName drops empty parts rather than dangling a comma', () {
      const p = PlaceResult(
        name: 'Pune',
        admin: '',
        country: '',
        latitude: 0,
        longitude: 0,
        timezoneName: 'UTC',
      );
      expect(p.displayName, 'Pune');
    });
  });

  group('the After casting section', () {
    testWidgets('holds both switches under one heading', (tester) async {
      final l10n = await _pump(tester);
      expect(
          find.text(l10n.beSectionAfterCasting.toUpperCase()), findsOneWidget);
      // Signed out: alerts only, because sync genuinely needs an account.
      expect(find.text(l10n.beFollowAlertsTitle), findsOneWidget);
      expect(find.text(l10n.beSyncTitle), findsNothing);
    });

    testWidgets('the alerts row is still offered with no account',
        (tester) async {
      // The regression this guards: sharing a heading with a
      // sign-in-gated row must not quietly re-gate the ungated one.
      final l10n = await _pump(tester);
      final tile = tester.widget<SwitchListTile>(
        find.ancestor(
          of: find.text(l10n.beFollowAlertsTitle),
          matching: find.byType(SwitchListTile),
        ),
      );
      expect(tile.value, isTrue);
      expect(tile.onChanged, isNotNull);
    });

    testWidgets('neither switch appears on the Prashna form', (tester) async {
      final l10n = await _pump(tester, prashna: true);
      expect(find.text(l10n.beSectionAfterCasting.toUpperCase()), findsNothing);
      expect(find.text(l10n.beFollowAlertsTitle), findsNothing);
    });
  });

  group('speed', () {
    /// The recent-place chips only. The form also carries an add-label
    /// ActionChip, so a bare byType finder counts the wrong things.
    final placeChips = find.descendant(
      of: find.byKey(kRecentPlaceChipsKey),
      matching: find.byType(ActionChip),
    );

    testWidgets('the name field takes focus on open', (tester) async {
      await _pump(tester);
      final field = tester.widget<TextField>(
        find.byKey(const GlobalObjectKey(BirthField.name)),
      );
      expect(field.autofocus, isTrue);
      // …and Enter moves on rather than dismissing the keyboard.
      expect(field.textInputAction, TextInputAction.next);
    });

    testWidgets('no recent-place chips when the library is empty',
        (tester) async {
      await _pump(tester);
      expect(placeChips, findsNothing);
    });

    testWidgets('offers the three most recent places as chips', (tester) async {
      await _pump(tester, library: [
        _kundliAt('Pune, Maharashtra, India', DateTime(2026, 1, 1)),
        _kundliAt('Delhi, India', DateTime(2026, 2, 1)),
        _kundliAt('Chennai, Tamil Nadu, India', DateTime(2026, 3, 1)),
        _kundliAt('Jaipur, Rajasthan, India', DateTime(2026, 4, 1)),
      ]);
      expect(find.text('Jaipur, Rajasthan, India'), findsOneWidget);
      expect(find.text('Chennai, Tamil Nadu, India'), findsOneWidget);
      expect(find.text('Delhi, India'), findsOneWidget);
      // Capped at three: the oldest drops off.
      expect(find.text('Pune, Maharashtra, India'), findsNothing);
    });

    testWidgets('tapping a chip fills the place exactly like a search hit',
        (tester) async {
      final l10n = await _pump(tester, library: [
        _kundliAt('Yangon, Myanmar', DateTime(2026, 4, 1),
            lat: 16.8, lon: 96.15, tz: 'Asia/Yangon'),
      ]);
      await tester.tap(find.text('Yangon, Myanmar'));
      await tester.pumpAndSettle();

      // The field is filled, the chips are gone, and the helper line
      // shows the coordinates and zone the chip carried — the same
      // things a search hit would have set.
      expect(placeChips, findsNothing);
      expect(find.text('16.8000, 96.1500 · Asia/Yangon'), findsOneWidget);

      // …and the place no longer counts as missing.
      await tester.tap(find.text(l10n.castKundli));
      await tester.pumpAndSettle();
      expect(find.text(l10n.bePlaceNotChosen), findsNothing);
      expect(find.text(l10n.beFieldRequired), findsNWidgets(3));
    });

    testWidgets('chips hide as soon as something is typed', (tester) async {
      await _pump(tester, library: [
        _kundliAt('Delhi, India', DateTime(2026, 2, 1)),
      ]);
      expect(placeChips, findsOneWidget);
      await tester.enterText(
          find.byKey(const GlobalObjectKey(BirthField.place)), 'Kol');
      await tester.pump();
      // A shortcut past the search, not a filter on it.
      expect(placeChips, findsNothing);
    });
  });

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

  group('the pinned Cast bar', () {
    testWidgets('holds the Cast button, and the scroll no longer does',
        (tester) async {
      final l10n = await _pump(tester);
      expect(find.text(l10n.castKundli), findsOneWidget);
      // Inside the Scaffold's bottom slot, not the ListView.
      expect(
        find.descendant(
          of: find.byType(ListView),
          matching: find.text(l10n.castKundli),
        ),
        findsNothing,
      );
    });

    testWidgets('shows no summary line while the form is incomplete',
        (tester) async {
      await _pump(tester);
      // Nothing is filled in, so there is nothing to confirm.
      expect(find.byKey(const Key('birthSummary')), findsNothing);
    });

    testWidgets('the summary appears once all four fields are set',
        (tester) async {
      // End to end through the real controls, because the summary is a
      // claim about what will be SAVED — a pure-function test cannot
      // catch the form wiring the wrong value into it.
      final l10n = await _pump(tester, library: [
        _kundliAt('Kolkata, West Bengal, India', DateTime(2026, 4, 1),
            lat: 22.57, lon: 88.36, tz: 'Asia/Kolkata'),
      ]);
      KJDate.pref = DateFormatPref.dMMMy;

      await tester.enterText(
          find.byKey(const GlobalObjectKey(BirthField.name)), 'Asha');
      await tester.enterText(find.widgetWithText(TextField, l10n.dfDay), '9');
      await tester.enterText(
          find.widgetWithText(TextField, l10n.dfYear), '1943');
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DropdownButtonFormField<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('June').last);
      await tester.pumpAndSettle();

      // The time picker opens in keypad mode: hour and minute fields.
      // Scoped to the DIALOG — a bare find.byType(TextField) also matches
      // the form's own fields underneath and silently types into those.
      await tester.tap(find.byKey(const GlobalObjectKey(BirthField.time)));
      await tester.pumpAndSettle();
      final picker = find.descendant(
        of: find.byType(TimePickerDialog),
        matching: find.byType(TextField),
      );
      // en locale opens the picker in 12-hour mode, where "23" is not a
      // valid hour — enter it the way the control actually accepts, then
      // check the summary echoes it back in BOTH notations.
      await tester.enterText(picker.at(0), '11');
      await tester.enterText(picker.at(1), '02');
      await tester.tap(find.text('PM'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kolkata, West Bengal, India'));
      await tester.pumpAndSettle();

      // 1943 Kolkata is war time: +06:30, and tz offers no abbreviation
      // for it, so the line says the offset alone.
      expect(
        find.text('Wed, 9 Jun 1943 · 23:02 (11:02 PM) · Kolkata · +06:30'),
        findsOneWidget,
      );
    });

    testWidgets('Prashna moves to the header, out of the scroll',
        (tester) async {
      final l10n = await _pump(tester);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text(l10n.bePrashnaAction),
        ),
        findsOneWidget,
      );
      // The old long label under the button is gone.
      expect(find.text(l10n.prashnaHint), findsNothing);
    });

    testWidgets('the Prashna form offers no Prashna action', (tester) async {
      final l10n = await _pump(tester, prashna: true);
      expect(find.text(l10n.bePrashnaAction), findsNothing);
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

    testWidgets('is absent from the Prashna form', (tester) async {
      final l10n = await _pump(tester, prashna: true);
      expect(find.text(l10n.beFollowAlertsTitle), findsNothing);
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

  group('the labels section', () {
    Kundli labelled(String place, List<String> labels,
            {bool isArchived = false}) =>
        _kundliAt(place, DateTime(2026, 1, 1),
            labels: labels, isArchived: isArchived);

    FilterChip chipFor(WidgetTester tester, String label) =>
        tester.widget<FilterChip>(find.widgetWithText(FilterChip, label));

    testWidgets('shows every label already in use, for one-tap reuse',
        (tester) async {
      // The point of the section: labels only group anything if the same
      // string is reused, and recall is what produces "2026 clients",
      // "2026 Clients" and "clients 2026" as three separate groups.
      final l10n = await _pump(tester, library: [
        labelled('Pune', const ['2026 clients']),
        labelled('Delhi', const ['matchmaking', '2026 clients']),
      ]);

      expect(find.text(l10n.klLabels.toUpperCase()), findsOneWidget);
      expect(find.widgetWithText(FilterChip, '2026 clients'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'matchmaking'), findsOneWidget);
      // De-duplicated across charts, not one chip per use.
      expect(find.byType(FilterChip), findsNWidgets(2));
    });

    testWidgets('starts with nothing selected and toggles on tap',
        (tester) async {
      await _pump(tester, library: [
        labelled('Pune', const ['2026 clients', 'matchmaking']),
      ]);

      expect(chipFor(tester, '2026 clients').selected, isFalse);

      await tester.tap(find.widgetWithText(FilterChip, '2026 clients'));
      await tester.pumpAndSettle();
      expect(chipFor(tester, '2026 clients').selected, isTrue);
      expect(chipFor(tester, 'matchmaking').selected, isFalse,
          reason: 'multi-select, so one pick does not displace another');

      // …and off again.
      await tester.tap(find.widgetWithText(FilterChip, '2026 clients'));
      await tester.pumpAndSettle();
      expect(chipFor(tester, '2026 clients').selected, isFalse);
    });

    testWidgets('more than one label can be selected at once', (tester) async {
      await _pump(tester, library: [
        labelled('Pune', const ['2026 clients', 'matchmaking']),
      ]);

      await tester.tap(find.widgetWithText(FilterChip, '2026 clients'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilterChip, 'matchmaking'));
      await tester.pumpAndSettle();

      expect(chipFor(tester, '2026 clients').selected, isTrue);
      expect(chipFor(tester, 'matchmaking').selected, isTrue);
    });

    testWidgets('offers the add affordance with an empty library',
        (tester) async {
      // Nothing to reuse yet, so the section is just the way to coin the
      // first one — the heading still names what the button is for.
      final l10n = await _pump(tester);
      expect(find.text(l10n.klLabels.toUpperCase()), findsOneWidget);
      expect(find.byType(FilterChip), findsNothing);
      expect(find.widgetWithText(ActionChip, l10n.klAddLabel), findsOneWidget);
    });

    testWidgets('a newly coined label is added and pre-selected',
        (tester) async {
      final l10n = await _pump(tester);
      await tester.tap(find.widgetWithText(ActionChip, l10n.klAddLabel));
      await tester.pumpAndSettle();

      // The dialog offers no existing-label list here: every one of them
      // is already a chip on the form behind it.
      expect(find.text(l10n.klExistingLabels.toUpperCase()), findsNothing);

      await tester.enterText(
          find.widgetWithText(TextField, l10n.klLabelHint), 'court cases');
      await tester.tap(find.widgetWithText(TextButton, l10n.add));
      await tester.pumpAndSettle();

      expect(chipFor(tester, 'court cases').selected, isTrue);
    });

    testWidgets('labels living only on archived charts are not offered',
        (tester) async {
      // Same rule as the edit screen, which reads the same provider: the
      // archive is out of the working vocabulary until asked for.
      await _pump(tester, library: [
        labelled('Pune', const ['2026 clients']),
        labelled('Delhi', const ['retired'], isArchived: true),
      ]);

      expect(find.widgetWithText(FilterChip, '2026 clients'), findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'retired'), findsNothing);
    });

    testWidgets('sits between relation and note, as on the edit screen',
        (tester) async {
      final l10n = await _pump(tester, library: [
        labelled('Pune', const ['2026 clients']),
      ]);
      double y(String t) => tester.getTopLeft(find.text(t)).dy;
      expect(y(l10n.beSectionRelation.toUpperCase()),
          lessThan(y(l10n.klLabels.toUpperCase())));
      expect(y(l10n.klLabels.toUpperCase()),
          lessThan(y(l10n.beSectionNoteOptional.toUpperCase())));
    });

    testWidgets('a Prashna cast from this form gets labels too',
        (tester) async {
      // It is a SAVED chart that lands in the list like any other — the
      // ephemeral one comes from the list's long-press instead. The note
      // field above it sets the same precedent.
      final l10n = await _pump(tester, prashna: true, library: [
        labelled('Pune', const ['2026 clients']),
      ]);
      expect(find.text(l10n.klLabels.toUpperCase()), findsOneWidget);
      expect(find.widgetWithText(FilterChip, '2026 clients'), findsOneWidget);
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

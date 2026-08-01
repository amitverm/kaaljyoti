/// The Panchang card: the half-span geometry it must survive, and the
/// Vedic-day readings the enriched card added (sunrise/sunset with the
/// post-midnight date qualifier, day/night birth, hora lord, and the
/// maasa under either naming convention).
///
/// The geometric claim: label + value must survive ~163pt of content
/// width. The card defaults to full span now, but any widget can be
/// resized to half, and the longest limb values ("Shatabhisha · 3 ·
/// Rahu") do not fit on one line beside the label — so the value column
/// has to wrap. If the row ever goes rigid again Flutter emits an
/// overflow error, which fails this test.
///
/// No ephemeris/FFI: a fixed snapshot is built from chosen longitudes
/// and chosen rise/set times, as in the other module render tests.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kaaljyoti/charts/chart_style.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/data/models.dart';
import 'package:kaaljyoti/l10n/gen/app_localizations.dart';
import 'package:kaaljyoti/modules/panchang_module.dart';
import 'package:kaaljyoti/widgetsystem/astro_module.dart';

/// A half-span card's content width on a 402pt phone:
/// (402 - 2*16 outer - 10 gutter) * 3/6 - 2*14 card padding.
const _halfSpanContentWidth = 163.0;

/// A full-span card's content width on the same phone.
const _fullSpanContentWidth = 342.0;

final _kundli = Kundli(
  id: 'k1',
  name: 'Test Chart',
  relationTag: 'Self',
  birthUtc: DateTime.utc(1990, 1, 1, 6),
  latitude: 18.52,
  longitude: 73.86,
  timezoneName: 'Asia/Kolkata',
  utcOffsetMinutes: 330,
  placeName: 'Pune',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

// Moon at Aquarius 15°16' — Shatabhisha pada 3.
const _longitudes = <Planet, double>{
  Planet.sun: 15,
  Planet.mercury: 20,
  Planet.moon: 315.2667,
  Planet.mars: 45,
  Planet.venus: 10,
  Planet.jupiter: 195,
  Planet.saturn: 285,
  Planet.rahu: 135,
  Planet.ketu: 315,
};

/// Rise/set times are built with [DateTime.utc] on purpose: the app
/// carries place-local wall clocks as offset-shifted UTC instants (see
/// [BirthData.localDateTime]), and mixing in a machine-local DateTime
/// here would compare against whatever zone the test host sits in.
AstroSnapshot _snapshot({
  DateTime? birthUtc,
  PanchangData? panchang,
}) =>
    AstroSnapshot(
      birth: BirthData(
        dateTimeUtc: birthUtc ?? DateTime.utc(1990, 1, 1, 6),
        latitude: 18.52,
        longitude: 73.86,
        timezoneName: 'Asia/Kolkata',
        utcOffsetMinutes: 330,
      ),
      ayanamsaId: 1,
      ayanamsaValue: 24,
      positions: {
        for (final e in _longitudes.entries)
          e.key: PlanetPosition(
              planet: e.key, longitude: e.value, latitude: 0, speed: 1),
      },
      ascendant: 15,
      houseCusps: List<double>.generate(12, (i) => (15 + i * 30) % 360),
      panchang: panchang ??
          const PanchangData(
            tithiIndex: 0,
            tithiName: 'Pratipada',
            paksha: 'Shukla',
            nakshatra: Nakshatra.shatabhisha,
            pada: 3,
            yogaIndex: 0,
            yogaName: 'Vishkambha',
            karanaIndex: 1,
            karanaName: 'Bava',
            varaIndex: 6,
            vara: 'Sunday',
          ),
      yogas: const [],
    );

/// A birth at 00:30 IST on Tue 2 Jan 1990 — AFTER midnight but BEFORE
/// sunrise, so its Vedic day is the one that opened at Monday's
/// sunrise. Every derived reading has to follow that day, not the
/// civil date on the clock.
PanchangData _postMidnightPanchang({int tithiIndex = 0}) => PanchangData(
      tithiIndex: tithiIndex,
      tithiName: 'Pratipada',
      paksha: tithiIndex < 15 ? 'Shukla' : 'Krishna',
      nakshatra: Nakshatra.shatabhisha,
      pada: 3,
      yogaIndex: 0,
      yogaName: 'Vishkambha',
      karanaIndex: 1,
      karanaName: 'Bava',
      // Monday — the sunrise that opened the Vedic day, not Tuesday.
      varaIndex: 0,
      vara: 'Somavara',
      sunrise: DateTime.utc(1990, 1, 1, 7, 11),
      sunset: DateTime.utc(1990, 1, 1, 18, 10),
      nextSunrise: DateTime.utc(1990, 1, 2, 7, 11),
      amantaMonthIndex: 9, // Pausha
      isAdhikMaasa: false,
      samvatYear: 2046,
    );

ModuleContext _ctx({
  AstroSnapshot? snapshot,
  Map<String, dynamic> config = const {},
}) =>
    ModuleContext(
      kundli: _kundli,
      snapshot: snapshot ?? _snapshot(),
      chartStyle: ChartStyle.north,
      config: config,
    );

Future<void> _pumpCard(
  WidgetTester tester,
  ModuleContext ctx, {
  double width = _fullSpanContentWidth,
}) async {
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: Builder(
            builder: (context) => const PanchangModule().cardView(context, ctx),
          ),
        ),
      ),
    ),
  ));
  // Bundled faces load asynchronously; without this the rows measure
  // in Ahem and the widths mean nothing.
  await tester.runAsync(GoogleFonts.pendingFonts);
  await tester.pumpAndSettle();
}

void main() {
  // Mirrors main.dart: type faces ship as assets, so nothing is fetched
  // at runtime — and a test that fetched would measure Ahem instead.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('the longest nakshatra fits a half-span card without overflow',
      (tester) async {
    await _pumpCard(tester, _ctx(), width: _halfSpanContentWidth);

    // Pumping is the assertion — an overflowing Row raises a Flutter
    // error, which fails the test. These just pin that the row under
    // test is the one that actually rendered.
    expect(find.text('Nakshatra'), findsOneWidget);
    expect(find.text('Shatabhisha · 3 · Rahu'), findsOneWidget);
  });

  testWidgets('a snapshot with no rise/set shows dashes and drops the '
      'readings that need a Vedic day', (tester) async {
    // The circumpolar path: sunrise came back null, so the limbs still
    // read but sunrise/sunset have nothing to print and day/night and
    // the hora are absent rather than guessed.
    await _pumpCard(tester, _ctx());

    expect(find.text('Sunrise'), findsOneWidget);
    expect(find.text('Sunset'), findsOneWidget);
    expect(find.text('—'), findsNWidgets(2));
    expect(find.text('Day / Night'), findsNothing);
    expect(find.text('Hora lord'), findsNothing);
    expect(find.text('Maasa'), findsNothing);
  });

  testWidgets('a daytime birth shows bare times and reads as a day birth',
      (tester) async {
    // The ordinary case: 11:30 IST on 1 Jan, between that morning's
    // sunrise and that evening's sunset — no date qualifier earned.
    await _pumpCard(
      tester,
      _ctx(snapshot: _snapshot(panchang: _postMidnightPanchang())),
    );
    expect(find.text('07:11'), findsOneWidget);
    expect(find.text('18:10'), findsOneWidget);
    expect(find.text('Day birth'), findsOneWidget);
  });

  group('a post-midnight, pre-sunrise birth', () {
    ModuleContext ctx({Map<String, dynamic> config = const {}, int tithi = 0}) =>
        _ctx(
          snapshot: _snapshot(
            // 00:30 IST on 2 Jan 1990.
            birthUtc: DateTime.utc(1990, 1, 1, 19, 0),
            panchang: _postMidnightPanchang(tithiIndex: tithi),
          ),
          config: config,
        );

    testWidgets('qualifies the sunrise with its own (earlier) date',
        (tester) async {
      await _pumpCard(tester, ctx());
      // Bare "07:11" would read as hours AFTER a 00:30 birth; the date
      // is what makes it legible as the sunrise that came before.
      expect(find.text('07:11 (1 Jan 1990)'), findsOneWidget);
      expect(find.text('18:10 (1 Jan 1990)'), findsOneWidget);
    });

    testWidgets('reads as a night birth', (tester) async {
      await _pumpCard(tester, ctx());
      expect(find.text('Day / Night'), findsOneWidget);
      expect(find.text('Night birth'), findsOneWidget);
      expect(find.text('Day birth'), findsNothing);
    });

    testWidgets('keeps the previous weekday and names its lord',
        (tester) async {
      await _pumpCard(tester, ctx());
      // 1 Jan 1990 was a Monday; the civil date on the clock is
      // Tuesday. (The sunrise-bounding itself is pinned by
      // vedic_day_window_test.dart and vara_sunrise_test.dart.)
      expect(find.text('Somavara · Moon'), findsOneWidget);
    });

    testWidgets('names the hora ruling the birth instant', (tester) async {
      await _pumpCard(tester, ctx());
      // Monday's first hora is the Moon's; 00:30 falls in the 6th hora
      // of the night, which the continuous Chaldean cycle gives to Mars.
      expect(find.text('Hora lord'), findsOneWidget);
      expect(find.text('Mars'), findsOneWidget);
    });
  });

  group('the maasa row', () {
    ModuleContext ctx({Map<String, dynamic> config = const {}, int tithi = 0}) =>
        _ctx(
          snapshot: _snapshot(
            birthUtc: DateTime.utc(1990, 1, 1, 19, 0),
            panchang: _postMidnightPanchang(tithiIndex: tithi),
          ),
          config: config,
        );

    testWidgets('shows the month and the Vikram Samvat year', (tester) async {
      await _pumpCard(tester, ctx());
      expect(find.text('Maasa'), findsOneWidget);
      expect(find.text('Pausha · V.S. 2046'), findsOneWidget);
    });

    testWidgets('a Krishna paksha renames under purnimanta but not amanta',
        (tester) async {
      // The stored index is always amanta (Pausha). Purnimanta labels
      // the waning fortnight with the FOLLOWING month, Magha.
      await _pumpCard(tester, ctx(tithi: 20));
      expect(find.text('Magha · V.S. 2046'), findsOneWidget);

      await _pumpCard(
          tester, ctx(tithi: 20, config: {'masa_system': 'amanta'}));
      expect(find.text('Pausha · V.S. 2046'), findsOneWidget);
    });

    test('only the non-default convention earns a title suffix', () {
      final l10n = lookupAppLocalizations(const Locale('en'));
      const module = PanchangModule();
      expect(module.configSummary(const {}, l10n), isNull);
      expect(module.configSummary(const {'masa_system': 'purnimanta'}, l10n),
          isNull);
      expect(
          module.configSummary(const {'masa_system': 'amanta'}, l10n), 'Amanta');
    });
  });
}

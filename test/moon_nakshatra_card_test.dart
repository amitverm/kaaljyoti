/// The Moon & Nakshatra card at full span, and the Vimshottari balance
/// arithmetic behind its headline reading.
///
/// No ephemeris/FFI: a fixed snapshot is built from chosen longitudes,
/// as in the other module render tests. The Vimshottari tree is pure
/// Dart, so the balance is genuinely computed here rather than stubbed.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kaaljyoti/charts/chart_style.dart';
import 'package:kaaljyoti/charts/moon_phase_painter.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/data/models.dart';
import 'package:kaaljyoti/l10n/gen/app_localizations.dart';
import 'package:kaaljyoti/modules/moon_nakshatra_module.dart';
import 'package:kaaljyoti/widgetsystem/astro_module.dart';

/// A full-span card's content width on a 402pt phone.
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

/// Moon at Aquarius 15°16' — Shatabhisha (star lord Rahu) pada 3, and a
/// 300° elongation from the Sun, i.e. a waning crescent.
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

AstroSnapshot _snapshot([Map<Planet, double>? longitudes]) => AstroSnapshot(
      birth: BirthData(
        dateTimeUtc: DateTime.utc(1990, 1, 1, 6),
        latitude: 18.52,
        longitude: 73.86,
        timezoneName: 'Asia/Kolkata',
        utcOffsetMinutes: 330,
      ),
      ayanamsaId: 1,
      ayanamsaValue: 24,
      positions: {
        for (final e in (longitudes ?? _longitudes).entries)
          e.key: PlanetPosition(
              planet: e.key, longitude: e.value, latitude: 0, speed: 1),
      },
      ascendant: 15,
      houseCusps: List<double>.generate(12, (i) => (15 + i * 30) % 360),
      panchang: const PanchangData(
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

Future<void> _pumpCard(WidgetTester tester, ModuleContext ctx) async {
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: _fullSpanContentWidth,
          child: Builder(
            builder: (context) =>
                const MoonNakshatraModule().cardView(context, ctx),
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

  ModuleContext ctx([Map<Planet, double>? longitudes]) => ModuleContext(
        kundli: _kundli,
        snapshot: _snapshot(longitudes),
        chartStyle: ChartStyle.north,
      );

  testWidgets('the card carries the nakshatra, its lord and the dasha '
      'balance', (tester) async {
    await _pumpCard(tester, ctx());

    expect(find.text('Shatabhisha'), findsOneWidget);
    expect(find.text('Pada 3'), findsOneWidget);
    expect(find.text('Nakshatra lord'), findsOneWidget);
    expect(find.text('Rahu'), findsOneWidget);

    // Shatabhisha's lord is Rahu (18 years); the Moon sits 8.6° into
    // the 13°20' star, so ~64.5% of the mahadasha was already spent
    // before birth.
    expect(find.text('Dasha balance at birth'), findsOneWidget);
    expect(find.text('Rahu · 6y 4m 20d'), findsOneWidget);
  });

  testWidgets('the attribute strip names all six readings', (tester) async {
    await _pumpCard(tester, ctx());

    expect(find.text('Gana'), findsOneWidget);
    expect(find.text('Rakshasa'), findsOneWidget);
    expect(find.text('Yoni'), findsOneWidget);
    expect(find.text('Horse'), findsOneWidget);
    expect(find.text('Nadi'), findsOneWidget);
    expect(find.text('Adi'), findsOneWidget);
    // Varna comes from the Moon's RASHI (Aquarius = air = Shudra), not
    // from its nakshatra.
    expect(find.text('Varna'), findsOneWidget);
    expect(find.text('Shudra'), findsOneWidget);
    expect(find.text('Deity'), findsOneWidget);
    expect(find.text('Varuna'), findsOneWidget);
    expect(find.text('Symbol'), findsOneWidget);
    expect(find.text('Empty circle'), findsOneWidget);
  });

  testWidgets('the Moon column draws the phase and names the navamsa',
      (tester) async {
    await _pumpCard(tester, ctx());

    expect(find.byType(MoonPhaseDisc), findsOneWidget);
    expect(find.text('Moon in Aquarius'), findsOneWidget);
    // Aquarius is fixed, so its navamsas count from the 9th (Libra);
    // 15.2667° in is the 5th navamsa — Aquarius.
    expect(find.text('Navamsa · Aquarius'), findsOneWidget);
  });

  testWidgets('dignity prints only when there is one', (tester) async {
    await _pumpCard(tester, ctx());
    // Moon in Aquarius has no dignity — the line is absent, not blank.
    expect(find.text('Exalted'), findsNothing);
    expect(find.text('Debilitated'), findsNothing);
    expect(find.text('Own sign'), findsNothing);

    // Moon at Taurus 3° is exalted.
    await _pumpCard(tester, ctx({..._longitudes, Planet.moon: 33.0}));
    expect(find.text('Exalted'), findsOneWidget);
  });

  group('balanceText', () {
    final l10n = lookupAppLocalizations(const Locale('en'));

    test('splits a balance into years, months and days', () {
      // Two Julian years to the second — the split is arithmetic on a
      // 365.25-day year and a 30-day month, as a printed balance is.
      expect(balanceText(l10n, const Duration(days: 730, hours: 12)), '2y');
      expect(balanceText(l10n, const Duration(days: 761)), '2y 1m');
    });

    test('drops the components that are zero', () {
      expect(balanceText(l10n, const Duration(days: 45)), '1m 14d');
      expect(balanceText(l10n, const Duration(days: 366)), '1y 1d');
    });

    test('a balance under a month still shows a number', () {
      // Nothing but days left — the row must not come back empty.
      expect(balanceText(l10n, const Duration(days: 3)), '3d');
      expect(balanceText(l10n, Duration.zero), '0d');
    });
  });
}

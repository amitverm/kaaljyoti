/// The Panchang card at HALF span on a phone — the narrowest box it is
/// ever laid out in.
///
/// The claim is geometric: label + value must survive ~163pt of content
/// width. The longest nakshatra names ("Shatabhisha", "Uttara
/// Bhadrapada") next to their pada do not fit on one line beside the
/// label, so the value column has to wrap. If the row ever goes rigid
/// again Flutter emits an overflow error, which fails this test.
///
/// No ephemeris/FFI: a fixed snapshot is built from chosen longitudes,
/// as in the other module render tests.
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

AstroSnapshot _snapshot() => AstroSnapshot(
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
        for (final e in _longitudes.entries)
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

ModuleContext _ctx() => ModuleContext(
      kundli: _kundli,
      snapshot: _snapshot(),
      chartStyle: ChartStyle.north,
    );

void main() {
  // Mirrors main.dart: type faces ship as assets, so nothing is fetched
  // at runtime — and a test that fetched would measure Ahem instead.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('the longest nakshatra fits a half-span card without overflow',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: _halfSpanContentWidth,
            child: Builder(
              builder: (context) => const PanchangModule().cardView(
                context,
                _ctx(),
              ),
            ),
          ),
        ),
      ),
    ));
    // Bundled faces load asynchronously; without this the rows measure
    // in Ahem and the widths mean nothing.
    await tester.runAsync(GoogleFonts.pendingFonts);
    await tester.pumpAndSettle();

    // Pumping is the assertion — an overflowing Row raises a Flutter
    // error, which fails the test. These just pin that the row under
    // test is the one that actually rendered.
    expect(find.text('Nakshatra'), findsOneWidget);
    expect(find.text('Shatabhisha · 3'), findsOneWidget);
  });
}

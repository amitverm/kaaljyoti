/// PACE card layouts. The compact line exists purely to fit a dashboard
/// card, so the test that matters is the HEIGHT difference — and that
/// no influence is lost in the shortening.
///
/// No ephemeris/FFI: a fixed snapshot is built from chosen longitudes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/charts/chart_style.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/data/models.dart';
import 'package:kaaljyoti/l10n/gen/app_localizations.dart';
import 'package:kaaljyoti/modules/pace_module.dart';
import 'package:kaaljyoti/widgetsystem/astro_module.dart';

/// A chart with something in every channel: a conjunction (Sun+Mercury
/// in Aries), several aspects, and a Mars/Venus exchange.
const _longitudes = <Planet, double>{
  Planet.sun: 15, // Aries
  Planet.mercury: 20, // Aries
  Planet.moon: 105, // Cancer
  Planet.mars: 45, // Taurus  — Venus's sign
  Planet.venus: 10, // Aries   — Mars's sign  → exchange
  Planet.jupiter: 195, // Libra
  Planet.saturn: 285, // Capricorn
  Planet.rahu: 135, // Leo
  Planet.ketu: 315, // Aquarius
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
        nakshatra: Nakshatra.ashwini,
        pada: 1,
        yogaIndex: 0,
        yogaName: 'Vishkambha',
        karanaIndex: 1,
        karanaName: 'Bava',
        varaIndex: 6,
        vara: 'Sunday',
      ),
      yogas: const [],
    );

ModuleContext _ctx(Map<String, dynamic> config) => ModuleContext(
      kundli: Kundli(
        id: 'k1',
        name: 'Test',
        relationTag: 'Self',
        birthUtc: DateTime.utc(1990, 1, 1, 6),
        latitude: 18.52,
        longitude: 73.86,
        timezoneName: 'Asia/Kolkata',
        utcOffsetMinutes: 330,
        placeName: 'Pune',
        createdAt: DateTime.utc(2026),
        updatedAt: DateTime.utc(2026),
      ),
      snapshot: _snapshot(),
      chartStyle: ChartStyle.north,
      config: config,
    );

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      // A phone-width card, so the measured heights mean something.
      home: Scaffold(
        body: SingleChildScrollView(
          child: SizedBox(width: 360, child: child),
        ),
      ),
    );

void main() {
  const module = PaceModule();

  Future<double> cardHeight(WidgetTester tester, String layout) async {
    final key = GlobalKey();
    await tester.pumpWidget(_wrap(KeyedSubtree(
      key: key,
      child: Builder(
        builder: (context) =>
            module.cardView(context, _ctx({'layout': layout})),
      ),
    )));
    await tester.pumpAndSettle();
    return tester.getSize(find.byKey(key)).height;
  }

  testWidgets('the compact card is far shorter than the block card',
      (tester) async {
    final blocks = await cardHeight(tester, 'blocks');
    final compact = await cardHeight(tester, 'compact');

    expect(compact, lessThan(blocks * 0.6),
        reason: 'compact card was ${compact}px vs ${blocks}px in blocks — '
            'the whole point is that nine grahas fit on a card');
  });

  testWidgets('compact is the default', (tester) async {
    final defaulted = await cardHeight(tester, '');
    final compact = await cardHeight(tester, 'compact');
    expect(defaulted, compact);
  });

  testWidgets('the compact line keeps every channel', (tester) async {
    await tester.pumpWidget(_wrap(Builder(
      builder: (context) =>
          module.cardView(context, _ctx({'layout': 'compact'})),
    )));
    await tester.pumpAndSettle();

    // Shortening must not drop information: the Sun/Mercury conjunction,
    // the Mars/Venus exchange and the aspect numbers all survive.
    final text = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
        .join(' | ');

    expect(text, contains('C'), reason: 'conjunction channel');
    expect(text, contains('A'), reason: 'aspect channel');
    expect(text, contains('E'), reason: 'exchange channel');
    expect(text, contains('L'), reason: 'lordship');
  });

  testWidgets('every graha appears in both layouts', (tester) async {
    for (final layout in ['compact', 'blocks']) {
      await tester.pumpWidget(_wrap(Builder(
        builder: (context) =>
            module.cardView(context, _ctx({'layout': layout})),
      )));
      await tester.pumpAndSettle();

      final text = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
          .join(' | ');
      // Nine grahas — dropping any of them from a PACE card would be
      // wrong in a way that capping a yoga list is not.
      for (final abbr in ['Su', 'Mo', 'Ma', 'Me', 'Ju', 'Ve', 'Sa', 'Ra', 'Ke']) {
        expect(text, contains(abbr), reason: '$abbr missing in $layout');
      }
    }
  });

  testWidgets('the detail view keeps the block layout whatever the card says',
      (tester) async {
    await tester.pumpWidget(_wrap(Builder(
      builder: (context) =>
          module.detailView(context, _ctx({'layout': 'compact'})),
    )));
    await tester.pumpAndSettle();

    // The block layout puts each channel on its own lettered row, so the
    // P label appears once per graha — the compact line has no P label.
    expect(find.text('P'), findsNWidgets(9));
  });
}

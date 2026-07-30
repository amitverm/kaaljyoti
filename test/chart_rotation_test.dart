/// Chart rotation gestures. [ChartView] only becomes rotatable when a
/// caller passes `onSignSelect` — the transit charts shipped without it,
/// so double-tap and long-press did nothing there while the rashi and
/// varga charts rotated fine.
///
/// No ephemeris/FFI: placements are a fixed map, like the other module
/// tests.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/charts/chart_style.dart';
import 'package:kaaljyoti/charts/chart_view.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/l10n/gen/app_localizations.dart';

const _placements = <ZodiacSign, List<Planet>>{
  ZodiacSign.aries: [Planet.sun],
  ZodiacSign.cancer: [Planet.moon],
  ZodiacSign.libra: [Planet.mars],
  ZodiacSign.capricorn: [Planet.saturn],
};

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Scaffold(body: Center(child: child)),
    );

/// A spread of probe points inside the chart square. Which one lands in
/// a house differs per style (the circular chart has a dead hub, the
/// north chart has diamond edges), so a gesture test asserts that SOME
/// probe reports rather than hard-coding geometry that would then break
/// every time a painter is tuned.
List<Offset> _probes(double side) => [
      for (final fx in [0.5, 0.25, 0.75, 0.5, 0.5])
        for (final fy in [0.25, 0.5, 0.5, 0.75, 0.35])
          Offset(side * fx, side * fy),
    ];

void main() {
  const side = 300.0;

  Future<List<ZodiacSign>> gestureReports(
    WidgetTester tester,
    ChartStyle style, {
    required bool longPress,
  }) async {
    final reported = <ZodiacSign>[];
    await tester.pumpWidget(_wrap(ChartView(
      placements: _placements,
      lagna: ZodiacSign.aries,
      style: style,
      size: side,
      onSignSelect: reported.add,
    )));
    await tester.pumpAndSettle();

    final topLeft = tester.getTopLeft(find.byType(ChartView));
    for (final probe in _probes(side)) {
      if (reported.isNotEmpty) break;
      if (longPress) {
        await tester.longPressAt(topLeft + probe);
      } else {
        await tester.tapAt(topLeft + probe);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tapAt(topLeft + probe);
      }
      await tester.pumpAndSettle();
    }
    return reported;
  }

  for (final style in ChartStyle.values) {
    testWidgets('${style.name}: long-press reports a sign', (tester) async {
      expect(await gestureReports(tester, style, longPress: true), isNotEmpty);
    });

    testWidgets('${style.name}: double-tap reports a sign', (tester) async {
      expect(await gestureReports(tester, style, longPress: false), isNotEmpty);
    });
  }

  testWidgets('without onSignSelect the chart has no gesture detector',
      (tester) async {
    // This is the state the transit charts were in: a plain CustomPaint,
    // so neither gesture had anything to hit.
    await tester.pumpWidget(_wrap(const ChartView(
      placements: _placements,
      lagna: ZodiacSign.aries,
      style: ChartStyle.north,
      size: side,
    )));
    await tester.pumpAndSettle();

    expect(find.byType(GestureDetector), findsNothing);
  });

  testWidgets('with onSignSelect the chart gains a gesture detector',
      (tester) async {
    await tester.pumpWidget(_wrap(ChartView(
      placements: _placements,
      lagna: ZodiacSign.aries,
      style: ChartStyle.north,
      size: side,
      onSignSelect: (_) {},
    )));
    await tester.pumpAndSettle();

    expect(find.byType(GestureDetector), findsWidgets);
  });

  testWidgets('the lagna argument is what rotates the chart', (tester) async {
    // Rotation is expressed by handing the painter a different `lagna`
    // while `trueAscendantSign` keeps the real ascendant — that split is
    // what lets the Asc marker stay put as the houses turn.
    Future<void> pumpWith(ZodiacSign viewFrom) => tester.pumpWidget(_wrap(
          ChartView(
            placements: _placements,
            lagna: viewFrom,
            trueAscendantSign: ZodiacSign.aries,
            style: ChartStyle.north,
            size: side,
          ),
        ));

    await pumpWith(ZodiacSign.aries);
    await tester.pumpAndSettle();
    final unrotated = tester.widget<ChartView>(find.byType(ChartView));
    expect(unrotated.lagna, ZodiacSign.aries);
    expect(unrotated.trueAscendantSign, ZodiacSign.aries);

    await pumpWith(ZodiacSign.cancer);
    await tester.pumpAndSettle();
    final rotated = tester.widget<ChartView>(find.byType(ChartView));
    expect(rotated.lagna, ZodiacSign.cancer);
    expect(rotated.trueAscendantSign, ZodiacSign.aries,
        reason: 'the real ascendant must not move with the rotation');
  });
}

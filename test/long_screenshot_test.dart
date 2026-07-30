/// The long-screenshot capture path: the whole board, not the screenful
/// the OS would give you.
///
/// The claim worth pinning is geometric — [DashboardCaptureView] inside
/// a scroll viewport must lay out (and rasterize) at its FULL content
/// height, past the bottom of the surface. If that ever regresses the
/// feature silently degrades into an ordinary screenshot, which no
/// other test would notice.
///
/// The scale that capture runs at is the other half: the ladder that
/// picks it can't be exercised against a real GPU here, but it is pure
/// arithmetic, so the chosen ratios are pinned directly.
///
/// No ephemeris/FFI: a fixed snapshot is built from chosen longitudes,
/// as in the other module render tests.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kaaljyoti/charts/chart_style.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/data/dashboard_repository.dart';
import 'package:kaaljyoti/data/models.dart';
import 'package:kaaljyoti/l10n/gen/app_localizations.dart';
import 'package:kaaljyoti/services/long_screenshot.dart';
import 'package:kaaljyoti/ui/dashboard_capture.dart';
import 'package:kaaljyoti/ui/dashboard_layout.dart';
import 'package:kaaljyoti/widgetsystem/astro_module.dart';

const _longitudes = <Planet, double>{
  Planet.sun: 15,
  Planet.mercury: 20,
  Planet.moon: 105,
  Planet.mars: 45,
  Planet.venus: 10,
  Planet.jupiter: 195,
  Planet.saturn: 285,
  Planet.rahu: 135,
  Planet.ketu: 315,
};

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

ModuleContext _ctx() => ModuleContext(
      kundli: _kundli,
      snapshot: _snapshot(),
      chartStyle: ChartStyle.north,
    );

/// The starter board, every card forced to full width so the result is
/// unambiguously taller than one surface.
List<PlacedWidget> _placed() => [
      for (var i = 0; i < DashboardRepository.defaultOverview.length; i++)
        PlacedWidget(
          instanceId: 'i$i',
          viewId: 'v1',
          widgetId: DashboardRepository.defaultOverview[i].widgetId,
          position: i,
          span: CardSpan.full,
          config: DashboardRepository.defaultOverview[i].config,
        ),
    ];

PlacedWidget _pw(String id, CardSpan span) => PlacedWidget(
      instanceId: id,
      viewId: 'v1',
      widgetId: 'panchang',
      position: 0,
      span: span,
    );

/// Big-endian IHDR width/height — enough to check the capture's shape
/// without pulling in an image decoder.
({int width, int height}) _pngSize(Uint8List bytes) {
  final d = ByteData.sublistView(bytes);
  return (width: d.getUint32(16), height: d.getUint32(20));
}

void main() {
  // Mirrors main.dart: type faces ship as assets, so nothing is fetched
  // at runtime — and a test that fetched would render Ahem instead.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('packDashboardRows', () {
    test('two halves share a row; a full one takes its own', () {
      final rows = packDashboardRows(
        [
          _pw('a', CardSpan.half),
          _pw('b', CardSpan.half),
          _pw('c', CardSpan.full),
          _pw('d', CardSpan.half),
        ],
        isWide: false,
      );
      expect(rows.map((r) => r.length), [2, 1, 1]);
      expect(rows[0].map((p) => p.instanceId), ['a', 'b']);
      expect(rows[1].single.instanceId, 'c');
    });

    test('a card that does not fit starts a new row, order preserved', () {
      final rows = packDashboardRows(
        [
          _pw('a', CardSpan.half),
          _pw('b', CardSpan.full),
        ],
        isWide: false,
      );
      expect(rows.length, 2);
      expect(rows[0].single.instanceId, 'a');
      expect(rows[1].single.instanceId, 'b');
    });

    test('thirds pack three to a row only on a wide screen', () {
      final thirds = [
        _pw('a', CardSpan.third),
        _pw('b', CardSpan.third),
        _pw('c', CardSpan.third),
      ];
      expect(packDashboardRows(thirds, isWide: true).map((r) => r.length), [3]);
      // On a phone a third is really a half — two per row, then a
      // leftover row of one.
      expect(packDashboardRows(thirds, isWide: false).map((r) => r.length),
          [2, 1]);
    });

    test('empty in, empty out', () {
      expect(packDashboardRows(const [], isWide: false), isEmpty);
    });

    test('spanUnits: only "third" depends on width', () {
      expect(spanUnits(CardSpan.full, isWide: false), 6);
      expect(spanUnits(CardSpan.half, isWide: true), 3);
      expect(spanUnits(CardSpan.third, isWide: true), 2);
      expect(spanUnits(CardSpan.third, isWide: false), 3);
    });

    test('rowUnits reports the remainder an incomplete row leaves', () {
      final row = [_pw('a', CardSpan.half)];
      expect(rowUnits(row, isWide: false), 3);
    });
  });

  group('captureRatioLadder', () {
    // closeTo everywhere: these are cap/height divisions, not round
    // numbers, and the claim is the value not the float spelling.
    void expectLadder(List<double> actual, List<double> expected) {
      expect(actual.length, expected.length,
          reason: 'ladder was $actual, expected $expected');
      for (var i = 0; i < expected.length; i++) {
        expect(actual[i], closeTo(expected[i], 1e-6));
      }
    }

    test('even a board that fits keeps a fallback below it', () {
      // 2390 * 3 = 7170px, inside the optimistic cap — but a part that
      // silently crops at 4096 would hand back half a board, and the
      // rung under it is the only way out of that.
      expectLadder(captureRatioLadder(2390, 3), [3.0, 4096 / 2390]);
    });

    test('a low-dpr device is never scaled up to fill the cap', () {
      expectLadder(captureRatioLadder(2390, 2), [2.0, 4096 / 2390]);
      // Every cap leaves 1.5 intact here, so all three rungs collapse.
      expectLadder(captureRatioLadder(2390, 3, maxPixelRatio: 1.5), [1.5]);
    });

    test('a long board steps down one cap at a time', () {
      expectLadder(captureRatioLadder(6000, 3), [
        16384 / 6000, // 2.731 — the device ratio no longer fits
        8192 / 6000, // 1.365
        1.0, // 4096/6000 = 0.683, floored on the last rung
      ]);
    });

    test('the last rung is floored even when every cap is hopeless', () {
      expectLadder(captureRatioLadder(20000, 3), [
        16384 / 20000, // 0.819
        8192 / 20000, // 0.410
        1.0, // floored, and left to fail into the null path
      ]);
    });

    test('a rung the floor duplicates is dropped', () {
      // 8192: the middle cap already lands exactly on 1.0, and the
      // floored last rung would only ask for the same pixels again.
      expectLadder(captureRatioLadder(8192, 3), [2.0, 1.0]);
    });

    test('the silent-crop case: a rung that fits 8192 exactly', () {
      // The simulator board that exposed the crop. Rung one asks for
      // 16384 tall and comes back 8192 tall — footer gone — so what
      // matters is that the ladder still offers a rung sized to land
      // inside 8192 rather than giving up.
      const side = 9600.0;
      final ladder = captureRatioLadder(side, 3);
      expectLadder(ladder, [16384 / side, 8192 / side, 1.0]);
      expect((side * ladder[0]).round(), 16384,
          reason: 'rung one is the request the engine crops');
      expect((side * ladder[1]).round(), 8192,
          reason: 'rung two must land exactly on the cap that works');
    });

    test('no rung repeats the one before it', () {
      for (final side in [500.0, 2390.0, 4097.0, 6000.0, 8192.0, 20000.0]) {
        final ladder = captureRatioLadder(side, 3);
        expect(ladder, isNotEmpty);
        for (var i = 1; i < ladder.length; i++) {
          expect(ladder[i], isNot(ladder[i - 1]),
              reason: 'a repeated rung re-rasterizes the same image: $ladder');
        }
        expect(ladder.length, lessThanOrEqualTo(captureTextureCaps.length));
      }
    });

    test('captureRatioFor takes the smaller of want and what the cap fits', () {
      expect(captureRatioFor(2390, 3, 16384), closeTo(3.0, 1e-6));
      expect(captureRatioFor(6000, 3, 8192), closeTo(1.365333, 1e-6));
      // Unfloored on purpose: the ladder decides what to do with a
      // sub-1.0 rung, this one only reports it.
      expect(captureRatioFor(20000, 3, 4096), closeTo(0.2048, 1e-6));
      expect(captureRatioFor(1000, 3, 16384, maxPixelRatio: 2),
          closeTo(2.0, 1e-6));
    });
  });

  group('captureDimsMatch', () {
    // The measured simulator case: a 402 x 9600pt board, rung one at
    // 16384/9600 asking for 686 x 16384.
    const board = Size(402, 9600);
    const cropped = 16384 / 9600;
    const fits = 8192 / 9600;

    test('a crop to the texture cap is caught', () {
      // What the engine actually returned: full width, half the height,
      // no throw, and a 330KB PNG that looks fine until you scroll it.
      expect(captureDimsMatch(686, 8192, board, cropped), isFalse);
    });

    test('the rung that fits is honoured', () {
      expect(captureDimsMatch(343, 8192, board, fits), isTrue);
    });

    test('a uniform resize in either direction is caught', () {
      expect(captureDimsMatch(343, 8192, board, cropped), isFalse);
      expect(captureDimsMatch(686, 16384, board, fits), isFalse);
    });

    test('rounding slack is two pixels, not more', () {
      expect(captureDimsMatch(688, 16384, board, cropped), isTrue);
      expect(captureDimsMatch(686, 16382, board, cropped), isTrue);
      expect(captureDimsMatch(689, 16384, board, cropped), isFalse);
      expect(captureDimsMatch(686, 16381, board, cropped), isFalse);
    });
  });

  testWidgets('the board rasterizes at full length, past the surface bottom',
      (tester) async {
    const captureWidth = 390.0;
    final key = GlobalKey();

    // The capture view itself watches nothing, but the module cards it
    // renders do — in the app the capture overlay sits under the root
    // ProviderScope, so the test mirrors that.
    await tester.pumpWidget(ProviderScope(
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          // The same shape captureLongWidget mounts offscreen: a viewport
          // handing the boundary unbounded height.
          body: SingleChildScrollView(
            child: RepaintBoundary(
              key: key,
              child: DashboardCaptureView(
                kundli: _kundli,
                moduleCtx: _ctx(),
                placed: _placed(),
                width: captureWidth,
              ),
            ),
          ),
        ),
      ),
    ));
    // Bundled faces load asynchronously; without this the cards measure
    // in Ahem and the heights mean nothing.
    await tester.runAsync(GoogleFonts.pendingFonts);
    await tester.pumpAndSettle();

    final surfaceHeight = tester.view.physicalSize.height /
        tester.view.devicePixelRatio; // 600 logical by default
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    expect(boundary.size.width, captureWidth);
    expect(boundary.size.height, greaterThan(surfaceHeight),
        reason: 'the six-card board should not fit one screenful — '
            'otherwise this test proves nothing about long capture');

    late Uint8List bytes;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      bytes = data!.buffer.asUint8List();
    });

    expect(
        bytes.sublist(0, 8), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
        reason: 'not a PNG');
    final size = _pngSize(bytes);
    expect(size.width, captureWidth.round());
    expect(size.height, greaterThan(surfaceHeight),
        reason: 'the captured image is only ${size.height}px tall — '
            'the capture stopped at the visible screenful');
    expect(size.height, boundary.size.height.round());
  });
}

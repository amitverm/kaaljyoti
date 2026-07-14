// 5-level lazy dasha engine tests (pure Dart, no plugins / FFI).
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/dasha/dasha.dart';
import 'package:kaaljyoti/core/astro/dasha/jaimini.dart';
import 'package:kaaljyoti/core/astro/dasha/vimshottari.dart';
import 'package:kaaljyoti/core/astro/dasha/yogini.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/core/astro/panchang.dart';

AstroSnapshot _snapshot(DateTime birth) {
  const longs = {
    Planet.sun: 10.0,
    Planet.moon: 100.0, // Pushya → Vimshottari starts in Saturn
    Planet.mars: 220.0,
    Planet.mercury: 25.0,
    Planet.jupiter: 130.0,
    Planet.venus: 355.0,
    Planet.saturn: 300.0,
    Planet.rahu: 180.0,
    Planet.ketu: 0.0,
  };
  return AstroSnapshot(
    birth: BirthData(
      dateTimeUtc: birth,
      latitude: 28.6,
      longitude: 77.2,
      timezoneName: 'Asia/Kolkata',
      utcOffsetMinutes: 330,
    ),
    ayanamsaId: 1,
    ayanamsaValue: 24.1,
    positions: {
      for (final e in longs.entries)
        e.key: PlanetPosition(
            planet: e.key, longitude: e.value, latitude: 0, speed: 1),
    },
    ascendant: 95.0,
    houseCusps: List.filled(12, 0.0),
    panchang: computePanchang(
        sunLongitude: 10, moonLongitude: 100, localDateTime: DateTime(1992)),
    yogas: const [],
  );
}

void main() {
  final birth = DateTime.utc(1992, 3, 14, 6, 30);
  final snap = _snapshot(birth);
  final probe = birth.add(const Duration(days: 365 * 20));

  final calcs = <DashaCalculator>[
    VimshottariCalculator(),
    YoginiCalculator(),
    JaiminiCharaCalculator(),
  ];
  final expectedBranch = {
    DashaSystem.vimshottari: 9,
    DashaSystem.yogini: 8,
    DashaSystem.jaimini: 12,
  };

  for (final calc in calcs) {
    final name = calc.system.displayName;

    test('$name: chain reaches pran level with proper nesting', () {
      final chain = calc.calculate(snap).chainAt(probe);
      expect(chain.length, kDashaMaxLevel);
      for (var i = 0; i < chain.length; i++) {
        expect(chain[i].level, i + 1);
        expect(chain[i].contains(probe), true, reason: 'level ${i + 1}');
        if (i > 0) {
          expect(chain[i].start.isBefore(chain[i - 1].start), false);
          expect(chain[i].end.isAfter(chain[i - 1].end), false);
        }
      }
      // Pran periods don't drill further.
      expect(chain[4].children, isEmpty);
      expect(chain[4].hasChildren, false);
      // Pran shorter than sookshma but non-degenerate.
      expect(chain[4].length < chain[3].length, true);
      expect(chain[4].length > const Duration(minutes: 1), true);
    });

    test('$name: children partition their parent exactly', () {
      final chain = calc.calculate(snap).chainAt(probe);
      for (final parent in [chain[0], chain[1], chain[3]]) {
        final kids = parent.children;
        expect(kids.length, expectedBranch[calc.system],
            reason: 'level ${parent.level}');
        expect(kids.first.start, parent.start);
        expect(kids.last.end, parent.end,
            reason: 'level ${parent.level} snap-to-parent-end');
        for (var i = 1; i < kids.length; i++) {
          expect(kids[i].start, kids[i - 1].end,
              reason: 'level ${parent.level} gap at $i');
        }
      }
    });

    test('$name: lazy + memoized children, cheap calculate()', () {
      final sw = Stopwatch()..start();
      final result = calc.calculate(snap);
      expect(sw.elapsedMilliseconds, lessThan(100));
      final maha = result.periods.first;
      expect(identical(maha.children, maha.children), true);
    });

    test('$name: activeAt agrees with chainAt', () {
      final result = calc.calculate(snap);
      final chain = result.chainAt(probe);
      final (m, a, p) = result.activeAt(probe);
      expect(identical(m, chain[0]), true);
      expect(identical(a, chain[1]), true);
      expect(identical(p, chain[2]), true);
    });
  }

  test('Vimshottari golden: Moon in Pushya → Saturn balance, Mercury @ +20y',
      () {
    final result = VimshottariCalculator().calculate(snap);
    // Moon 100° → Pushya (nak index 7), half elapsed → Saturn maha
    // with 9.5y balance: runs ~Sep 1982 – Sep 2001; Mercury follows
    // until Sep 2018, so probe (Mar 2012) sits in Mercury.
    expect(result.periods.first.planet, Planet.saturn);
    expect(result.chainAt(probe).first.planet, Planet.mercury);
  });

  test('chainAt outside computed range is empty', () {
    final result = VimshottariCalculator().calculate(snap);
    expect(result.chainAt(DateTime.utc(1900)), isEmpty);
  });
}

/// Yogini dasha — nakshatra-based (Moon's nakshatra); 8 Yogini periods
/// across a 36-year cycle. Structurally similar to Vimshottari, so it
/// shares the same balance-of-first-period input handling.
library;

import '../models.dart';
import 'dasha.dart';

class YoginiCalculator implements DashaCalculator {
  @override
  DashaSystem get system => DashaSystem.yogini;

  /// (Yogini name, ruling planet, years). Total = 36.
  static const List<(String, Planet, double)> sequence = [
    ('Mangala', Planet.moon, 1),
    ('Pingala', Planet.sun, 2),
    ('Dhanya', Planet.jupiter, 3),
    ('Bhramari', Planet.mars, 4),
    ('Bhadrika', Planet.mercury, 5),
    ('Ulka', Planet.saturn, 6),
    ('Siddha', Planet.venus, 7),
    ('Sankata', Planet.rahu, 8),
  ];

  static const double totalYears = 36;

  @override
  DashaResult calculate(AstroSnapshot snapshot) {
    final moon = snapshot.positions[Planet.moon]!.longitude;
    final birth = snapshot.birth.dateTimeUtc;

    // Classical rule: remainder of (nakshatra number + 3) / 8 gives the
    // starting Yogini with remainder 1 = Mangala … remainder 0 = Sankata.
    // Sequence index is therefore (remainder - 1) mod 8.
    final nakNumber = (moon / Nakshatra.span).floor() % 27 + 1; // 1–27
    final startIdx = ((nakNumber + 3) % 8 + 7) % 8;
    final fractionElapsed = (moon % Nakshatra.span) / Nakshatra.span;

    final (_, _, firstYears) = sequence[startIdx];
    final balanceYears = firstYears * (1 - fractionElapsed);
    var cursor = addYears(birth, -(firstYears - balanceYears));

    final mahadashas = <DashaPeriod>[];
    // Two full 36-year cycles ≈ 72 years of coverage; extend to ~108
    // with a third so long lifespans stay covered.
    for (var cycle = 0; cycle < 3; cycle++) {
      for (var i = 0; i < 8; i++) {
        final (name, planet, years) = sequence[(startIdx + i) % 8];
        final start = cursor;
        final end = addYears(start, years);
        mahadashas.add(_buildPeriod(name, planet, years, start, end, 1));
        cursor = end;
      }
    }

    return DashaResult(system: system, periods: mahadashas);
  }

  /// Children attached as a LAZY builder down to [kDashaMaxLevel] (pran).
  DashaPeriod _buildPeriod(
    String name,
    Planet planet,
    double years,
    DateTime start,
    DateTime end,
    int level,
  ) {
    return DashaPeriod(
      lordLabel: '$name (${planet.displayName})',
      planet: planet,
      start: start,
      end: end,
      level: level,
      childBuilder: level >= kDashaMaxLevel
          ? null
          : (parent) {
              final parentIdx = sequence.indexWhere((e) => e.$1 == name);
              final children = <DashaPeriod>[];
              var cursor = parent.start;
              for (var i = 0; i < 8; i++) {
                final (subName, subPlanet, subYears) =
                    sequence[(parentIdx + i) % 8];
                final subLength = years * (subYears / totalYears);
                final subEnd = addYears(cursor, subLength);
                children.add(_buildPeriod(
                    subName, subPlanet, subLength, cursor, subEnd, level + 1));
                cursor = subEnd;
              }
              // Snap the final child to the parent's end (rounding drift).
              children.add(children.removeLast().withEnd(parent.end));
              return children;
            },
    );
  }
}

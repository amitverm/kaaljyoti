/// Vimshottari dasha — nakshatra-based, from the Moon's position at
/// birth; 120-year cycle across 9 planetary lords. Default system.
library;

import '../models.dart';
import 'dasha.dart';

class VimshottariCalculator implements DashaCalculator {
  @override
  DashaSystem get system => DashaSystem.vimshottari;

  /// Lord sequence starting at Ashwini, with period lengths in years.
  static const List<(Planet, double)> sequence = [
    (Planet.ketu, 7),
    (Planet.venus, 20),
    (Planet.sun, 6),
    (Planet.moon, 10),
    (Planet.mars, 7),
    (Planet.rahu, 18),
    (Planet.jupiter, 16),
    (Planet.saturn, 19),
    (Planet.mercury, 17),
  ];

  static const double totalYears = 120;

  @override
  DashaResult calculate(AstroSnapshot snapshot) {
    final moon = snapshot.positions[Planet.moon]!.longitude;
    final birth = snapshot.birth.dateTimeUtc;

    final nakIndex = (moon / Nakshatra.span).floor() % 27;
    final startLordIdx = nakIndex % 9;
    final fractionElapsed = (moon % Nakshatra.span) / Nakshatra.span;

    // Balance of the first mahadasha at birth.
    final (_, firstYears) = sequence[startLordIdx];
    final balanceYears = firstYears * (1 - fractionElapsed);

    // The first mahadasha started before birth.
    var cursor = addYears(birth, -(firstYears - balanceYears));

    final mahadashas = <DashaPeriod>[];
    // Cover the full 120-year cycle from the pre-birth start.
    for (var i = 0; i < 9; i++) {
      final (lord, years) = sequence[(startLordIdx + i) % 9];
      final start = cursor;
      final end = addYears(start, years);
      mahadashas.add(_buildPeriod(lord, years, start, end, 1));
      cursor = end;
    }

    return DashaResult(system: system, periods: mahadashas);
  }

  /// Sub-periods follow the same 9-lord sequence starting from the
  /// parent lord, each proportional to its own years / 120. Children
  /// are attached as a LAZY builder down to [kDashaMaxLevel] (pran).
  DashaPeriod _buildPeriod(
    Planet lord,
    double years,
    DateTime start,
    DateTime end,
    int level,
  ) {
    return DashaPeriod(
      lordLabel: lord.displayName,
      planet: lord,
      start: start,
      end: end,
      level: level,
      childBuilder: level >= kDashaMaxLevel
          ? null
          : (parent) {
              final parentIdx = sequence.indexWhere((e) => e.$1 == lord);
              final children = <DashaPeriod>[];
              var cursor = parent.start;
              for (var i = 0; i < 9; i++) {
                final (subLord, subYears) = sequence[(parentIdx + i) % 9];
                final subLength = years * (subYears / totalYears);
                final subEnd = addYears(cursor, subLength);
                children.add(_buildPeriod(
                    subLord, subLength, cursor, subEnd, level + 1));
                cursor = subEnd;
              }
              // Snap the final child to the parent's end (rounding drift).
              children.add(children.removeLast().withEnd(parent.end));
              return children;
            },
    );
  }
}

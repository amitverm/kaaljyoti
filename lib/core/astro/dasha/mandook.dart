/// Jaimini Mandook dasha — SIGN-based, the "frog" (mandook) dasha: each
/// period leaps to the 4th sign from the last, so the four kendras from
/// the start sign run first, then the four panapharas, then the four
/// apoklimas.
///
/// Implementation follows K.N. Rao, "Predicting through Karakamsha &
/// Jaimini's Mandook Dasha" (Vani Publications; the Bharatiya Vidya
/// Bhawan school our Chara and Sthira dashas follow), Section II
/// chapters 2–6 and its twelve lagna-by-lagna worked examples. The
/// book's choices, all of which ship here:
///
/// - APPLICABILITY (ch. 2–3): four or more of the seven grahas (never
///   Rahu/Ketu) in kendras from lagna — 1st, 4th, 7th, 10th — in any
///   distribution. Every chart computes regardless; the surface prints
///   the kendra count as a plain fact and draws no verdict — whether to
///   use the dasha is the astrologer's call ([MandookContext.applicable]
///   is available to callers but nothing in the UI acts on it).
/// - START AND ORDER (ch. 4, Table I): an ODD lagna starts from the
///   lagna itself in direct order; an EVEN lagna starts from the 7th
///   house in indirect order. Parity is the LAGNA's, even though the 7th
///   from an even sign is itself odd. No graha/rashi bala is computed —
///   the book explicitly rejects the "stronger of lagna/7th" reading.
/// - SEQUENCE: from the start sign leap to the 4th, 7th and 10th signs
///   in the chosen direction, then step ONE sign further in that same
///   direction and leap again, then once more — 12 signs, each once
///   (Table I is exactly this for all twelve lagnas).
/// - YEARS (ch. 6): count INCLUSIVELY from the sign to the sign its lord
///   occupies — direct for odd signs, indirect for even signs (plain
///   zodiacal parity, not Chara's ninth-house grouping). NO deduction of
///   a year. Lord in its own sign → 12 years. Lord in the 7th sign from
///   it → 10 years, not 7 (the book's "special rule", confirmed by its
///   Vrisha, Dhanu and Mithuna examples). Scorpio counts to Mars and
///   Aquarius to Saturn only — "ignore Ketu's dual ownership of
///   Vrischika and Rahu's joint ownership of Kumbha" (p. 74). Years
///   therefore span 2–12; the 7th-house case is the only non-inclusive
///   count.
/// - SUB-PERIODS (ch. 4 Savya/Apasavya, and every worked table): twelve
///   equal parts, the same frog-leap pattern starting from the
///   mahadasha's OWN sign, in the mahadasha's direction — the lagna's
///   parity, NOT the maha sign's (its Makar antardashas in the Mesha
///   example, and Meena's in the Dhanu example, run direct). Pratyantars
///   and deeper levels repeat the same shape.
/// - ARITHMETIC: calendar, like Sthira — the book's periods run
///   birthday to birthday ("Mesha 1962 to 1972") and its antardashas
///   month-day to month-day ("Tula from February 1978 to June 1978").
///   No balance at birth. Cycles repeat up to the app-wide horizon.
///
/// Every year, date and sub-period table the book prints for its nine
/// worked charts reproduces under these rules (test/mandook_dasha_test).
library;

import '../models.dart';
import 'dasha.dart';

/// The seven grahas that count towards the applicability test.
const List<Planet> kMandookGrahas = [
  Planet.sun,
  Planet.moon,
  Planet.mars,
  Planet.mercury,
  Planet.jupiter,
  Planet.venus,
  Planet.saturn,
];

/// Minimum grahas in kendras for the dasha to apply (book p. 56, 59).
const int kMandookMinKendraGrahas = 4;

/// What the dasha is anchored on for one chart: the applicability count
/// and the start sign + direction that Table I would give.
class MandookContext {
  const MandookContext({
    required this.kendraGrahas,
    required this.startSign,
    required this.direct,
  });

  /// Of the seven grahas, how many sit in the 1st/4th/7th/10th from lagna.
  final int kendraGrahas;

  /// Lagna for odd lagnas, the 7th house for even ones.
  final ZodiacSign startSign;

  /// Direct (zodiacal) order for odd lagnas, indirect for even ones.
  final bool direct;

  bool get applicable => kendraGrahas >= kMandookMinKendraGrahas;
}

MandookContext computeMandookContext(AstroSnapshot snapshot) {
  final lagna = snapshot.lagnaSign;
  var inKendra = 0;
  for (final p in kMandookGrahas) {
    final pos = snapshot.positions[p];
    if (pos == null) continue;
    final house = ((pos.sign.index - lagna.index + 12) % 12) + 1;
    if ((house - 1) % 3 == 0) inKendra++;
  }
  final direct = lagna.isOdd;
  return MandookContext(
    kendraGrahas: inKendra,
    startSign: direct ? lagna : ZodiacSign.values[(lagna.index + 6) % 12],
    direct: direct,
  );
}

/// The frog-leap order from [start]: three groups of four, each group
/// leaping by three signs, successive groups one sign further along in
/// the direction of motion. Used for mahadashas (from the chart's start
/// sign) and for every sub-period level (from the parent's own sign).
List<ZodiacSign> mandookOrder(ZodiacSign start, {required bool direct}) {
  final step = direct ? 1 : -1;
  return [
    for (var group = 0; group < 3; group++)
      for (var leap = 0; leap < 4; leap++)
        ZodiacSign.values[(start.index + step * (group + 3 * leap) + 144) % 12],
  ];
}

/// Mandook years for [sign]: inclusive count to its lord, direct for
/// odd signs and indirect for even; own sign 12; 7th sign 10.
int mandookYears(ZodiacSign sign, AstroSnapshot snapshot) {
  // ZodiacSign.lord is already Mars for Scorpio and Saturn for
  // Aquarius — the book's "ignore the node co-lords" rule for free.
  final lordSign = snapshot.positions[sign.lord]!.sign;
  if (lordSign == sign) return 12;
  final distance = sign.isOdd
      ? (lordSign.index - sign.index + 12) % 12
      : (sign.index - lordSign.index + 12) % 12;
  if (distance == 6) return 10; // lord in the 7th from the sign
  return distance + 1; // inclusive: the sign itself counts as 1
}

class MandookDashaCalculator implements DashaCalculator {
  @override
  DashaSystem get system => DashaSystem.mandook;

  @override
  DashaResult calculate(AstroSnapshot snapshot) {
    final birth = snapshot.birth.dateTimeUtc;
    final ctx = computeMandookContext(snapshot);
    final signs = mandookOrder(ctx.startSign, direct: ctx.direct);
    final cycleYears = [for (final s in signs) mandookYears(s, snapshot)];

    // Whole calendar months from birth (see the library comment). The
    // cycle repeats until no mahadasha starts at or past the horizon;
    // years are never below 2, so a cycle is at least 24 years and the
    // loop always ends.
    var monthsFromBirth = 0;
    var i = 0;
    final periods = <DashaPeriod>[];
    while (monthsFromBirth < kDashaHorizonYears * 12) {
      final sign = signs[i % 12];
      final years = cycleYears[i % 12];
      final start = addCalendarMonths(birth, monthsFromBirth);
      final end = addCalendarMonths(birth, monthsFromBirth + years * 12);
      periods.add(_buildPeriod(sign, years, start, end, 1, ctx.direct));
      monthsFromBirth += years * 12;
      i++;
    }
    return DashaResult(system: system, periods: periods);
  }

  /// Sub-periods: the frog-leap order from the parent's OWN sign in the
  /// chart's direction, twelve equal parts. Antardashas are whole
  /// calendar months (a 10-year maha → twelve 10-month antars, month-day
  /// to month-day like the book's tables); deeper levels have no
  /// calendar unit left and split the real parent into twelfths.
  DashaPeriod _buildPeriod(
    ZodiacSign sign,
    int years,
    DateTime start,
    DateTime end,
    int level,
    bool direct,
  ) {
    return DashaPeriod(
      lordLabel: '${sign.sanskrit} (${sign.western})',
      sign: sign,
      start: start,
      end: end,
      level: level,
      childBuilder: level >= kDashaMaxLevel
          ? null
          : (parent) {
              final subs = mandookOrder(sign, direct: direct);
              final children = <DashaPeriod>[];
              if (level == 1) {
                for (var i = 0; i < 12; i++) {
                  final subStart = addCalendarMonths(parent.start, i * years);
                  final subEnd = i == 11
                      ? parent.end
                      : addCalendarMonths(parent.start, (i + 1) * years);
                  children.add(_buildPeriod(
                      subs[i], years, subStart, subEnd, level + 1, direct));
                }
              } else {
                final twelfth = parent.length ~/ 12;
                var cursor = parent.start;
                for (var i = 0; i < 12; i++) {
                  final subEnd = i == 11 ? parent.end : cursor.add(twelfth);
                  children.add(_buildPeriod(
                      subs[i], years, cursor, subEnd, level + 1, direct));
                  cursor = subEnd;
                }
              }
              return children;
            },
    );
  }
}

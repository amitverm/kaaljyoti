/// Jaimini Chara dasha — SIGN-based, not nakshatra-based (brief §2.3).
/// Derived from the ascendant and each sign's lord placement, so its
/// input shape differs from Vimshottari/Yogini — but it emits the same
/// period-tree output.
///
/// Implementation follows K.N. Rao, "Predicting through Jaimini's Chara
/// Dasha" (Vani Publications), chapters 3, 4 and 6. Two DISTINCT
/// direct/indirect groupings are in play and must not be conflated:
///
/// - ORDER grouping (ch. 3, from the 9th house of each rashi): Aries,
///   Leo, Virgo, Libra, Aquarius, Pisces are "direct lagna" rashis —
///   their mahadasha sequence runs zodiacally forward, the remaining
///   six run backward. The same grouping (of the running mahadasha
///   rashi) sets the antardasha direction (ch. 4).
/// - COUNTING grouping (ch. 6): Aries, Taurus, Gemini, Libra, Scorpio,
///   Sagittarius count forward from themselves to their lord; the rest
///   count backward. Inclusive count minus one = dasha years; lord in
///   its own rashi → 12 years (so years span 1–12, never 0).
///
/// Sub-periods (ch. 4): the 12 rashis from the one AFTER the mahadasha
/// rashi, own rashi LAST, each an equal 1/12 of the parent.
///
/// Scorpio (Mars/Ketu) and Aquarius (Saturn/Rahu) dual lordship
/// (ch. 6 special rules): a co-lord placed in the rashi itself is
/// ignored and the count goes to the other; both in the rashi → 12
/// years; both outside → the stronger one counts (more planets
/// associated, then higher degrees in sign).
library;

import '../models.dart';
import 'dasha.dart';

class JaiminiCharaCalculator implements DashaCalculator {
  @override
  DashaSystem get system => DashaSystem.jaimini;

  /// ORDER grouping (ch. 3): mahadasha/antardasha sequence direction.
  static const _orderDirect = {
    ZodiacSign.aries,
    ZodiacSign.leo,
    ZodiacSign.virgo,
    ZodiacSign.libra,
    ZodiacSign.aquarius,
    ZodiacSign.pisces,
  };

  /// COUNTING grouping (ch. 6): direction of the count to the lord.
  static const _countDirect = {
    ZodiacSign.aries,
    ZodiacSign.taurus,
    ZodiacSign.gemini,
    ZodiacSign.libra,
    ZodiacSign.scorpio,
    ZodiacSign.sagittarius,
  };

  @override
  DashaResult calculate(AstroSnapshot snapshot) {
    final birth = snapshot.birth.dateTimeUtc;
    final lagna = snapshot.lagnaSign;

    // Sequence of 12 signs from lagna; direction from lagna's ORDER group.
    final forward = _orderDirect.contains(lagna);
    final signs = <ZodiacSign>[
      for (var i = 0; i < 12; i++)
        ZodiacSign.values[(lagna.index + (forward ? i : -i) + 144) % 12],
    ];

    var cursor = birth;
    final periods = <DashaPeriod>[];
    for (final sign in signs) {
      final years = _charaYears(sign, snapshot);
      final start = cursor;
      final end = addYears(start, years.toDouble());
      periods
          .add(_buildPeriod(sign, years.toDouble(), start, end, 1, snapshot));
      cursor = end;
    }
    return DashaResult(system: system, periods: periods);
  }

  /// Chara years for [sign]: distance to its lord, counted forward for
  /// COUNTING-direct signs and backward for the rest, exclusive of the
  /// sign itself (the classical inclusive-count-minus-one); lord in own
  /// sign → 12.
  int _charaYears(ZodiacSign sign, AstroSnapshot snapshot) {
    final lord = _effectiveLord(sign, snapshot);
    final lordSign = snapshot.positions[lord]!.sign;
    if (lordSign == sign) return 12;

    final forward = _countDirect.contains(sign);
    final int count;
    if (forward) {
      count = (lordSign.index - sign.index + 12) % 12;
    } else {
      count = (sign.index - lordSign.index + 12) % 12;
    }
    // Exclusive counting: distance measured, minus nothing further —
    // count already excludes the starting sign; classical rule then
    // uses count (signs traversed) as years, with the lord's own sign
    // handled above. Zero can't occur here (lordSign != sign).
    return count;
  }

  /// Scorpio: Mars/Ketu; Aquarius: Saturn/Rahu (ch. 6 special rules).
  /// (a)/(b) a co-lord sitting in the rashi itself is ignored — count
  /// goes to the OTHER lord; (c) both in the rashi → either (12 years);
  /// (d) both outside → stronger co-lord: the one placed with more
  /// planets, tie → higher degrees in sign.
  Planet _effectiveLord(ZodiacSign sign, AstroSnapshot snapshot) {
    final (Planet a, Planet b)? pair = switch (sign) {
      ZodiacSign.scorpio => (Planet.mars, Planet.ketu),
      ZodiacSign.aquarius => (Planet.saturn, Planet.rahu),
      _ => null,
    };
    if (pair == null) return sign.lord;

    final aInSign = snapshot.positions[pair.$1]!.sign == sign;
    final bInSign = snapshot.positions[pair.$2]!.sign == sign;
    if (aInSign && bInSign) return pair.$1; // (c) → own sign → 12 years
    if (aInSign) return pair.$2; // (a) ignore occupant, count to other
    if (bInSign) return pair.$1; // (b)

    int companions(Planet p) {
      final s = snapshot.positions[p]!.sign;
      return snapshot.positions.values
          .where((pos) => pos.sign == s && pos.planet != p)
          .length;
    }

    final ca = companions(pair.$1);
    final cb = companions(pair.$2);
    if (ca != cb) return ca > cb ? pair.$1 : pair.$2;
    final da = snapshot.positions[pair.$1]!.degreesInSign;
    final db = snapshot.positions[pair.$2]!.degreesInSign;
    return da >= db ? pair.$1 : pair.$2;
  }

  /// Antardashas: the 12 signs starting from the sign AFTER the
  /// mahadasha sign, own sign last (ch. 4), each equal to
  /// parentYears/12; direction follows the mahadasha sign's ORDER group.
  /// Children attached as a LAZY builder down to [kDashaMaxLevel] (pran).
  DashaPeriod _buildPeriod(
    ZodiacSign sign,
    double years,
    DateTime start,
    DateTime end,
    int level,
    AstroSnapshot snapshot,
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
              final forward = _orderDirect.contains(sign);
              final subLength = years / 12;
              final children = <DashaPeriod>[];
              var cursor = parent.start;
              for (var i = 1; i <= 12; i++) {
                final sub = ZodiacSign
                    .values[(sign.index + (forward ? i : -i) + 144) % 12];
                final subEnd =
                    i == 12 ? parent.end : addYears(cursor, subLength);
                children.add(_buildPeriod(
                    sub, subLength, cursor, subEnd, level + 1, snapshot));
                cursor = subEnd;
              }
              return children;
            },
    );
  }
}

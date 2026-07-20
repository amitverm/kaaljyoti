/// Jaimini Chara dasha — SIGN-based, not nakshatra-based (brief §2.3).
/// Derived from the ascendant and each sign's lord placement, so its
/// input shape differs from Vimshottari/Yogini — but it emits the same
/// period-tree output.
///
/// Implementation follows the widely used K.N. Rao variant:
/// - Dasha sequence starts from the lagna sign.
/// - Direction: counted zodiacally (forward) if the 9th from lagna is
///   an odd-footed sign group, reverse otherwise. Odd-footed groups:
///   Aries–Virgo forward logic per classical rule — here we use the
///   standard rule that signs Aries, Taurus, Gemini, Libra, Scorpio,
///   Sagittarius are "savya" (forward) and the rest "apasavya".
/// - Period length of a sign = count (exclusive) from the sign to its
///   lord, forward for odd (savya) signs and reverse for even, minus 1;
///   if the lord is in the sign itself → 12 years. Scorpio uses the
///   stronger of Mars/Ketu, Aquarius the stronger of Saturn/Rahu
///   (v1 strength rule: the co-lord accompanied by more planets, then
///   the one with higher degrees in its sign).
library;

import '../models.dart';
import 'dasha.dart';

class JaiminiCharaCalculator implements DashaCalculator {
  @override
  DashaSystem get system => DashaSystem.jaimini;

  static const _savya = {
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

    // Sequence of 12 signs from lagna; direction from lagna's group.
    final forward = _savya.contains(lagna);
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
  /// savya signs and reverse for apasavya, exclusive of the sign itself;
  /// lord in own sign → 12.
  int _charaYears(ZodiacSign sign, AstroSnapshot snapshot) {
    final lord = _effectiveLord(sign, snapshot);
    final lordSign = snapshot.positions[lord]!.sign;
    if (lordSign == sign) return 12;

    final forward = _savya.contains(sign);
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

  /// Scorpio: Mars/Ketu; Aquarius: Saturn/Rahu. Stronger co-lord =
  /// the one placed with more planets; tie → higher degrees in sign.
  Planet _effectiveLord(ZodiacSign sign, AstroSnapshot snapshot) {
    final (Planet a, Planet b)? pair = switch (sign) {
      ZodiacSign.scorpio => (Planet.mars, Planet.ketu),
      ZodiacSign.aquarius => (Planet.saturn, Planet.rahu),
      _ => null,
    };
    if (pair == null) return sign.lord;

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
  /// mahadasha sign (classical Chara sub-period scheme), each equal
  /// to parentYears/12; direction follows the mahadasha sign's group.
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
              final forward = _savya.contains(sign);
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

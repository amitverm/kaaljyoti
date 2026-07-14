/// Jaimini Rashi Drishti (sign-based aspects) — a different scheme from
/// the Parashari, planet-based graha drishti already used elsewhere.
/// Here the SIGN itself casts the aspect, based on its modality:
///
/// - A movable (chara) sign aspects all three fixed signs EXCEPT the
///   one immediately following it.
/// - A fixed (sthira) sign aspects all three movable signs EXCEPT the
///   one immediately preceding it.
/// - A dual (dwiswabhava) sign aspects the other three dual signs.
///
/// By construction this relation is symmetric (movable ⟷ fixed pairs
/// and the dual foursome both work out to mutual aspects), so it's
/// modeled here as one undirected sign-aspect graph.
library;

import 'models.dart';

const _movable = {
  ZodiacSign.aries,
  ZodiacSign.cancer,
  ZodiacSign.libra,
  ZodiacSign.capricorn,
};

const _fixed = {
  ZodiacSign.taurus,
  ZodiacSign.leo,
  ZodiacSign.scorpio,
  ZodiacSign.aquarius,
};

const _dual = {
  ZodiacSign.gemini,
  ZodiacSign.virgo,
  ZodiacSign.sagittarius,
  ZodiacSign.pisces,
};

/// The set of signs [sign] casts a Rashi Drishti aspect onto.
Set<ZodiacSign> jaiminiRashiDrishti(ZodiacSign sign) {
  if (_movable.contains(sign)) {
    final excluded = ZodiacSign.values[(sign.index + 1) % 12];
    return _fixed.where((s) => s != excluded).toSet();
  }
  if (_fixed.contains(sign)) {
    final excluded = ZodiacSign.values[(sign.index - 1 + 12) % 12];
    return _movable.where((s) => s != excluded).toSet();
  }
  // Dual sign.
  return _dual.where((s) => s != sign).toSet();
}

/// One planet-to-planet Rashi Drishti relationship — [from] sits in a
/// sign that aspects the sign [to] sits in.
class JaiminiAspect {
  const JaiminiAspect(this.from, this.to, this.fromSign, this.toSign);
  final Planet from;
  final Planet to;
  final ZodiacSign fromSign;
  final ZodiacSign toSign;
}

/// All planet-pair Rashi Drishti aspects present in [positions].
/// Planets sharing a sign are in conjunction, not aspect, and are
/// skipped — Rashi Drishti is only ever cast between different signs.
List<JaiminiAspect> jaiminiAspects(Map<Planet, PlanetPosition> positions) {
  final out = <JaiminiAspect>[];
  final entries = positions.values.toList();
  for (final a in entries) {
    final aspected = jaiminiRashiDrishti(a.sign);
    for (final b in entries) {
      if (a.planet == b.planet) continue;
      if (a.sign == b.sign) continue; // conjunction, not aspect
      if (aspected.contains(b.sign)) {
        out.add(JaiminiAspect(a.planet, b.planet, a.sign, b.sign));
      }
    }
  }
  return out;
}

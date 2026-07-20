/// The Tajika Sahams — sensitive points of the annual chart — per
/// Charak, "A Textbook of Varshaphala" ch. XI (all 41 of the book's
/// list, Tajika Neelakanthi lineage), golden-tested against the
/// worked Punya/Raja examples.
///
/// Every saham is a − b + c with the ESSENTIAL correction: if c does
/// not fall inside the forward zodiacal arc from b to a, add one sign
/// (30°). Day formulas flip a/b for a night Varshapravesha where the
/// book flips them; sahams marked "same for day and night" don't.
///
/// Convention notes:
///  • Cusp-based sahams (Mrityu, Deshantara, Artha, Santaapa, Labha)
///    read the snapshot's computed house cusps (Placidus). Software
///    differs here (equal-house from the lagna is a common variant);
///    isolated in [_cusp] for easy switching.
///  • "Lord of X" refers to the LONGITUDE of that sign's lord in the
///    same chart.
///  • Roga follows the book's numbered formula (Asc − Moon + Asc);
///    Charak notes an alternative (Saturn − Moon + Asc) "giving better
///    results" — that variant is Paneeya-Paata's formula and is
///    already in the list under that name.
library;

import 'models.dart';

enum _Ref {
  asc,
  sun,
  moon,
  mars,
  mercury,
  jupiter,
  venus,
  saturn,
  punya,
  guru,
  vidya,
  ascLord,
  sunSignLord,
  moonSignLord,
  cusp2,
  cusp6,
  cusp8,
  cusp9,
  cusp11,
  lord2,
  lord9,
  lord11,
  cancer15,
}

class _Def {
  const _Def(this.key, this.dayA, this.dayB, this.dayC,
      {_Ref? nightA, _Ref? nightB, _Ref? nightC})
      : nightA = nightA ?? dayA,
        nightB = nightB ?? dayB,
        nightC = nightC ?? dayC;

  /// Day formula a − b + c; night defaults to the same (the "same for
  /// day as well as night" sahams).
  final String key;
  final _Ref dayA, dayB, dayC;
  final _Ref nightA, nightB, nightC;

  /// Flipped a/b for night, keeping c — the common day/night pattern.
  const _Def.flip(String key, _Ref a, _Ref b, _Ref c)
      : this(key, a, b, c, nightA: b, nightB: a, nightC: c);
}

/// The 41 sahams in the book's order (ch. XI). Kshama shares Kali's
/// formula and Raja shares Pitri's — both are listed separately, as in
/// the book, because their significations differ.
const List<_Def> _defs = [
  _Def.flip('punya', _Ref.moon, _Ref.sun, _Ref.asc),
  _Def.flip('guru', _Ref.sun, _Ref.moon, _Ref.asc),
  _Def.flip('vidya', _Ref.sun, _Ref.moon, _Ref.asc),
  _Def.flip('yasha', _Ref.jupiter, _Ref.punya, _Ref.asc),
  _Def.flip('mitra', _Ref.guru, _Ref.punya, _Ref.venus),
  _Def.flip('mahatmya', _Ref.punya, _Ref.mars, _Ref.asc),
  _Def.flip('asha', _Ref.saturn, _Ref.venus, _Ref.asc),
  _Def.flip('samartha', _Ref.mars, _Ref.ascLord, _Ref.asc),
  _Def('bhratri', _Ref.jupiter, _Ref.saturn, _Ref.asc),
  _Def.flip('gaurava', _Ref.sun, _Ref.moon, _Ref.jupiter),
  _Def.flip('pitri', _Ref.saturn, _Ref.sun, _Ref.asc),
  _Def.flip('raja', _Ref.saturn, _Ref.sun, _Ref.asc),
  _Def.flip('matri', _Ref.moon, _Ref.venus, _Ref.asc),
  _Def('putra', _Ref.jupiter, _Ref.moon, _Ref.asc),
  _Def.flip('jeeva', _Ref.saturn, _Ref.jupiter, _Ref.asc),
  _Def('roga', _Ref.asc, _Ref.moon, _Ref.asc),
  _Def.flip('karma', _Ref.mars, _Ref.mercury, _Ref.asc),
  _Def.flip('manmatha', _Ref.moon, _Ref.ascLord, _Ref.asc),
  _Def.flip('kali', _Ref.jupiter, _Ref.mars, _Ref.asc),
  _Def.flip('kshama', _Ref.jupiter, _Ref.mars, _Ref.asc),
  _Def.flip('shastra', _Ref.jupiter, _Ref.saturn, _Ref.mercury),
  _Def('bandhu', _Ref.mercury, _Ref.moon, _Ref.asc),
  _Def('mrityu', _Ref.cusp8, _Ref.moon, _Ref.saturn),
  _Def('deshantara', _Ref.cusp9, _Ref.lord9, _Ref.asc),
  _Def('artha', _Ref.cusp2, _Ref.lord2, _Ref.asc),
  _Def('paradara', _Ref.venus, _Ref.sun, _Ref.asc),
  _Def.flip('anyakarma', _Ref.moon, _Ref.saturn, _Ref.asc),
  _Def('vanika', _Ref.moon, _Ref.mercury, _Ref.asc),
  _Def('karyasiddhi', _Ref.saturn, _Ref.sun, _Ref.sunSignLord,
      nightA: _Ref.saturn, nightB: _Ref.moon, nightC: _Ref.moonSignLord),
  _Def('vivaha', _Ref.venus, _Ref.saturn, _Ref.asc),
  _Def.flip('prasava', _Ref.jupiter, _Ref.mercury, _Ref.asc),
  _Def('santaapa', _Ref.saturn, _Ref.moon, _Ref.cusp6),
  _Def('shraddha', _Ref.venus, _Ref.mars, _Ref.asc),
  _Def('preeti', _Ref.vidya, _Ref.punya, _Ref.asc),
  _Def.flip('jadya', _Ref.mars, _Ref.saturn, _Ref.mercury),
  _Def('vyapara', _Ref.mars, _Ref.mercury, _Ref.asc),
  _Def.flip('paneeyapaata', _Ref.saturn, _Ref.moon, _Ref.asc),
  _Def.flip('shatru', _Ref.mars, _Ref.saturn, _Ref.asc),
  _Def.flip('jalapatha', _Ref.cancer15, _Ref.saturn, _Ref.asc),
  _Def.flip('bandhana', _Ref.punya, _Ref.saturn, _Ref.asc),
  _Def('labha', _Ref.cusp11, _Ref.lord11, _Ref.asc),
];

/// Stable keys of every saham, in the book's order.
List<String> get sahamKeys => [for (final d in _defs) d.key];

class SahamResult {
  const SahamResult({required this.key, required this.longitude});
  final String key;
  final double longitude;
  ZodiacSign get sign => ZodiacSign.fromLongitude(longitude);
}

double _norm(double x) => ((x % 360) + 360) % 360;

/// a − b + c with the correction: c must lie in the forward arc b → a,
/// else one sign is added (the book's "essential consideration").
double sahamValue(double a, double b, double c) {
  final v = _norm(a - b + c);
  final between = _norm(c - b) < _norm(a - b);
  return between ? v : _norm(v + 30);
}

List<SahamResult> sahams(AstroSnapshot chart, {required bool day}) {
  double planet(Planet p) => chart.positions[p]!.longitude;
  double lordOf(ZodiacSign s) => planet(s.lord);
  double cusp(int house) => chart.houseCusps[house - 1];

  final values = <String, double>{};
  double resolve(_Ref r) => switch (r) {
        _Ref.asc => chart.ascendant,
        _Ref.sun => planet(Planet.sun),
        _Ref.moon => planet(Planet.moon),
        _Ref.mars => planet(Planet.mars),
        _Ref.mercury => planet(Planet.mercury),
        _Ref.jupiter => planet(Planet.jupiter),
        _Ref.venus => planet(Planet.venus),
        _Ref.saturn => planet(Planet.saturn),
        // Dependent sahams appear later in the list than what they
        // reference, so these lookups are always resolved.
        _Ref.punya => values['punya']!,
        _Ref.guru => values['guru']!,
        _Ref.vidya => values['vidya']!,
        _Ref.ascLord => lordOf(chart.lagnaSign),
        _Ref.sunSignLord => lordOf(chart.positions[Planet.sun]!.sign),
        _Ref.moonSignLord => lordOf(chart.positions[Planet.moon]!.sign),
        _Ref.cusp2 => cusp(2),
        _Ref.cusp6 => cusp(6),
        _Ref.cusp8 => cusp(8),
        _Ref.cusp9 => cusp(9),
        _Ref.cusp11 => cusp(11),
        _Ref.lord2 =>
          lordOf(ZodiacSign.values[(chart.lagnaSign.index + 1) % 12]),
        _Ref.lord9 =>
          lordOf(ZodiacSign.values[(chart.lagnaSign.index + 8) % 12]),
        _Ref.lord11 =>
          lordOf(ZodiacSign.values[(chart.lagnaSign.index + 10) % 12]),
        _Ref.cancer15 => 105,
      };

  final out = <SahamResult>[];
  for (final d in _defs) {
    final a = resolve(day ? d.dayA : d.nightA);
    final b = resolve(day ? d.dayB : d.nightB);
    final c = resolve(day ? d.dayC : d.nightC);
    final v = sahamValue(a, b, c);
    values[d.key] = v;
    out.add(SahamResult(key: d.key, longitude: v));
  }
  return out;
}

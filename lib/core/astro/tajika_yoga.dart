/// The sixteen Tajika yogas — per Charak, "A Textbook of Varshaphala"
/// ch. X, calibrated against the chapter's worked charts
/// (test/tajika_yoga_test.dart). VERDICT-FREE: the scan reports which
/// combinations exist with their orbs and qualifiers; interpretation
/// stays with the practitioner.
///
/// Core mechanics (book pp. 116-121):
///  • Relative speed, fastest first: Moon, Mercury, Venus, Sun, Mars,
///    Jupiter, Saturn. "Ahead/behind" compares IN-SIGN degrees.
///  • Deeptamshas: Sun 15, Moon 12, Mars 8, Mercury 7, Jupiter 9,
///    Venus 7, Saturn 9. An Ithasala needs the pair within the MEAN of
///    their deeptamshas; mutual Tajika aspect (friendly or inimical
///    alike) is prerequisite.
///  • A retrograde fast-mover forms no Ithasala; a retrograde
///    slow-mover intensifies one.
///  • Rashyanta: a planet at 29°+ operates from the next sign.
library;

import 'dignity.dart';
import 'divisional.dart';
import 'models.dart';
import 'shadbala.dart' show PlanetaryRel, naturalRelOf;
import 'tajika.dart';
import 'varshphal_bala.dart' show huddaLordOf, panchavargiyaDrekkanaLordOf;

/// Fastest → slowest.
const List<Planet> kTajikaSpeedOrder = [
  Planet.moon,
  Planet.mercury,
  Planet.venus,
  Planet.sun,
  Planet.mars,
  Planet.jupiter,
  Planet.saturn,
];

const Map<Planet, double> kDeeptamsha = {
  Planet.sun: 15,
  Planet.moon: 12,
  Planet.mars: 8,
  Planet.mercury: 7,
  Planet.jupiter: 9,
  Planet.venus: 7,
  Planet.saturn: 9,
};

enum TajikaYogaType {
  ikabala,
  ikabalaPartial,
  induvara,
  induvaraPartial,
  vartamanaIthasala,
  poornaIthasala,
  bhavishyatIthasala,
  rashyantaIthasala,
  ishrafa,
  nakta,
  yamaya,
  manau,
  kamboola,
  gairiKamboola,
  khallasara,
  rudda,
  duhphaliKuttha,
  dutthotthaDavira,
  tambira,
  kuttha,
  durpaha,
}

/// One detected combination. [planets] are the participants in
/// definition order (fast first for pair yogas); [linker] the
/// intervening/affecting third planet where the yoga has one;
/// [orb] the operative degree gap; [tags] stable data tokens the
/// widget localizes (dispositions, disqualifications).
class TajikaYoga {
  const TajikaYoga({
    required this.type,
    required this.planets,
    this.linker,
    this.orb,
    this.tags = const [],
  });

  final TajikaYogaType type;
  final List<Planet> planets;
  final Planet? linker;
  final double? orb;
  final List<String> tags;
}

bool _fasterThan(Planet a, Planet b) =>
    kTajikaSpeedOrder.indexOf(a) < kTajikaSpeedOrder.indexOf(b);

double _inSign(AstroSnapshot s, Planet p) => s.positions[p]!.longitude % 30;

bool _retro(AstroSnapshot s, Planet p) => s.positions[p]!.speed < 0;

bool _aspect(AstroSnapshot s, Planet a, Planet b) =>
    tajikaRelationBetween(s, a, b).aspects;

/// Aspect with [a] considered as occupying the NEXT sign (Rashyanta).
bool _aspectFromNextSign(AstroSnapshot s, Planet a, Planet b) =>
    tajikaRelationForDistance(tajikaSignDistance(
            ZodiacSign.values[(s.positions[a]!.sign.index + 1) % 12],
            s.positions[b]!.sign))
        .aspects;

int _houseOf(AstroSnapshot s, Planet p) =>
    ((s.positions[p]!.sign.index - s.lagnaSign.index + 12) % 12) + 1;

/// Excellent / good / mediocre / inferior disposition (Kamboola
/// grading, book p. 137) as a stable token.
String dispositionOf(AstroSnapshot s, Planet p) {
  final pos = s.positions[p]!;
  final d = dignityOf(pos);
  if (d == PlanetDignity.exalted || d == PlanetDignity.ownSign) {
    return 'excellent';
  }
  final lon = pos.longitude;
  final ownHudda =
      p != Planet.sun && p != Planet.moon ? huddaLordOf(lon) == p : false;
  if (ownHudda ||
      panchavargiyaDrekkanaLordOf(lon) == p ||
      navamsaSign(lon).lord == p) {
    return 'good';
  }
  if (d == PlanetDignity.debilitated ||
      naturalRelOf(p, pos.sign.lord) == PlanetaryRel.enemy) {
    return 'inferior';
  }
  return 'mediocre';
}

/// "Unqualified": neither exalted nor debilitated, not in own hudda /
/// drekkana / navamsha, and not Tajika-aspected by any planet
/// (book p. 140).
bool _unqualified(AstroSnapshot s, Planet p) {
  final pos = s.positions[p]!;
  if (dignityOf(pos) != PlanetDignity.none) return false;
  final lon = pos.longitude;
  if (p != Planet.sun && p != Planet.moon && huddaLordOf(lon) == p) {
    return false;
  }
  if (panchavargiyaDrekkanaLordOf(lon) == p) return false;
  if (navamsaSign(lon).lord == p) return false;
  for (final other in kTajikaPlanets) {
    if (other != p && _aspect(s, p, other)) return false;
  }
  return true;
}

/// The Ithasala-family relation between two planets, or null.
TajikaYoga? ithasalaBetween(AstroSnapshot s, Planet a, Planet b) {
  final fast = _fasterThan(a, b) ? a : b;
  final slow = fast == a ? b : a;
  final df = _inSign(s, fast);
  final ds = _inSign(s, slow);
  final mean = (kDeeptamsha[fast]! + kDeeptamsha[slow]!) / 2;
  final aspect = _aspect(s, fast, slow);

  // Rashyanta: the fast-mover at 29°+ operates from the next sign —
  // behind everything there; orb = distance across the sign boundary.
  if (df >= 29 && !_retro(s, fast)) {
    final gap = ds + 30 - df;
    if (_aspectFromNextSign(s, fast, slow) && gap <= mean) {
      return TajikaYoga(
          type: TajikaYogaType.rashyantaIthasala,
          planets: [fast, slow],
          orb: gap);
    }
  }

  if (!aspect) return null;

  // Poorna: within one degree either way (book p. 120).
  if ((df - ds).abs() <= 1 && !_retro(s, fast)) {
    return TajikaYoga(
        type: TajikaYogaType.poornaIthasala,
        planets: [fast, slow],
        orb: (df - ds).abs());
  }

  if (df < ds) {
    // Fast behind slow — Ithasala territory. A retrograde fast-mover
    // forms none; a retrograde slow-mover intensifies (tagged).
    if (_retro(s, fast)) return null;
    final gap = ds - df;
    if (gap <= mean) {
      return TajikaYoga(
        type: TajikaYogaType.vartamanaIthasala,
        planets: [fast, slow],
        orb: gap,
        tags: [if (_retro(s, slow)) 'slow-retrograde'],
      );
    }
    // Distance Bhavishyat (book p. 125): beyond the mean range but
    // more than the fast-mover's individual deeptamsha and within the
    // sum of the two.
    if (gap > kDeeptamsha[fast]! &&
        gap <= kDeeptamsha[fast]! + kDeeptamsha[slow]!) {
      return TajikaYoga(
          type: TajikaYogaType.bhavishyatIthasala,
          planets: [fast, slow],
          orb: gap);
    }
    return null;
  }

  // Fast ahead of slow — Ishrafa when separated by 1° to the mean
  // deeptamsha (book p. 127).
  final sep = df - ds;
  if (sep >= 1 && sep <= mean) {
    return TajikaYoga(
        type: TajikaYogaType.ishrafa, planets: [fast, slow], orb: sep);
  }
  return null;
}

/// Contiguous-sign Bhavishyat (book p. 123): fast-mover at 29°+ with
/// the slow-mover early in the NEXT sign, within the mean range.
TajikaYoga? contiguousBhavishyat(AstroSnapshot s, Planet a, Planet b) {
  final fast = _fasterThan(a, b) ? a : b;
  final slow = fast == a ? b : a;
  final df = _inSign(s, fast);
  if (df < 29 || _retro(s, fast)) return null;
  final nextSign = ZodiacSign.values[(s.positions[fast]!.sign.index + 1) % 12];
  if (s.positions[slow]!.sign != nextSign) return null;
  final gap = _inSign(s, slow) + 30 - df;
  final mean = (kDeeptamsha[fast]! + kDeeptamsha[slow]!) / 2;
  if (gap <= mean) {
    return TajikaYoga(
        type: TajikaYogaType.bhavishyatIthasala,
        planets: [fast, slow],
        orb: gap,
        tags: const ['contiguous']);
  }
  return null;
}

bool _isIthasala(TajikaYoga? y) =>
    y != null &&
    (y.type == TajikaYogaType.vartamanaIthasala ||
        y.type == TajikaYogaType.poornaIthasala ||
        y.type == TajikaYogaType.rashyantaIthasala);

/// Full scan of a varsha chart. [karyeshaHouse] frames the
/// lagnesha-karyesha yogas (Kuttha, Durpaha, Dutthottha, Tambira).
class TajikaYogaScan {
  const TajikaYogaScan({
    required this.chartYogas,
    required this.pairYogas,
    required this.lagnesha,
    required this.karyesha,
  });

  final List<TajikaYoga> chartYogas;
  final List<TajikaYoga> pairYogas;
  final Planet lagnesha;
  final Planet karyesha;
}

TajikaYogaScan scanTajikaYogas(AstroSnapshot s, {required int karyeshaHouse}) {
  final chart = <TajikaYoga>[];
  final pairs = <TajikaYoga>[];

  // --- Ikabala / Induvara (whole-chart placement yogas) ------------------
  final kendraPanaphara = {1, 2, 4, 5, 7, 8, 10, 11};
  final inKp = kTajikaPlanets
      .where((p) => kendraPanaphara.contains(_houseOf(s, p)))
      .length;
  if (inKp == 7) {
    chart.add(const TajikaYoga(
        type: TajikaYogaType.ikabala, planets: kTajikaPlanets));
  } else if (inKp >= 5) {
    chart.add(TajikaYoga(
        type: TajikaYogaType.ikabalaPartial,
        planets: kTajikaPlanets
            .where((p) => kendraPanaphara.contains(_houseOf(s, p)))
            .toList()));
  }
  final inApo = 7 - inKp;
  if (inApo == 7) {
    chart.add(const TajikaYoga(
        type: TajikaYogaType.induvara, planets: kTajikaPlanets));
  } else if (inApo >= 5) {
    chart.add(TajikaYoga(
        type: TajikaYogaType.induvaraPartial,
        planets: kTajikaPlanets
            .where((p) => !kendraPanaphara.contains(_houseOf(s, p)))
            .toList()));
  }

  // --- Pair scan ---------------------------------------------------------
  for (var i = 0; i < kTajikaPlanets.length; i++) {
    for (var j = i + 1; j < kTajikaPlanets.length; j++) {
      final a = kTajikaPlanets[i];
      final b = kTajikaPlanets[j];
      final base = ithasalaBetween(s, a, b) ?? contiguousBhavishyat(s, a, b);
      if (base != null) pairs.add(base);

      if (_isIthasala(base)) {
        final fast = base!.planets.first;
        final participants = base.planets.toSet();

        // Manau: Mars/Saturn (outsider) conjunct or inimically
        // aspecting the faster participant within the malefic's own
        // deeptamsha (book p. 135).
        for (final malefic in const [Planet.mars, Planet.saturn]) {
          if (participants.contains(malefic)) continue;
          final sameSign =
              s.positions[malefic]!.sign == s.positions[fast]!.sign;
          final rel = tajikaRelationBetween(s, malefic, fast);
          final gap = (_inSign(s, malefic) - _inSign(s, fast)).abs();
          if ((sameSign || rel.isEnemy) && gap <= kDeeptamsha[malefic]!) {
            pairs.add(TajikaYoga(
                type: TajikaYogaType.manau,
                planets: base.planets,
                linker: malefic,
                orb: gap));
          }
        }

        // Moon-family qualifiers (only for pairs not involving the
        // Moon itself).
        if (!participants.contains(Planet.moon)) {
          final moonA = ithasalaBetween(s, Planet.moon, a);
          final moonB = ithasalaBetween(s, Planet.moon, b);
          if (_isIthasala(moonA) || _isIthasala(moonB)) {
            final joined = _isIthasala(moonA) ? a : b;
            pairs.add(TajikaYoga(
              type: TajikaYogaType.kamboola,
              planets: base.planets,
              linker: Planet.moon,
              tags: [
                'moon:${dispositionOf(s, Planet.moon)}',
                'pair:${dispositionOf(s, joined)}',
              ],
            ));
          } else if (_unqualified(s, Planet.moon)) {
            if (_inSign(s, Planet.moon) >= 29) {
              // Gairi-Kamboola: the unqualified Rashyanta Moon links up
              // from the next sign with a participant and a strong
              // planet (book p. 139).
              final linksParticipant = _aspectFromNextSign(s, Planet.moon, a) ||
                  _aspectFromNextSign(s, Planet.moon, b);
              final strongLink = kTajikaPlanets.any((p) =>
                  p != Planet.moon &&
                  dispositionOf(s, p) == 'excellent' &&
                  _aspectFromNextSign(s, Planet.moon, p));
              if (linksParticipant && strongLink) {
                pairs.add(TajikaYoga(
                    type: TajikaYogaType.gairiKamboola,
                    planets: base.planets,
                    linker: Planet.moon));
              }
            } else {
              pairs.add(TajikaYoga(
                  type: TajikaYogaType.khallasara,
                  planets: base.planets,
                  linker: Planet.moon));
            }
          }
        }

        // Rudda: a participant combust / debilitated / in 6-8-12 / in
        // an enemy's sign / with a malefic — the slow-retrograde case
        // intensifies instead and is excluded (book p. 141).
        final disq = <String>[];
        for (final p in base.planets) {
          final pos = s.positions[p]!;
          if (p != Planet.sun && isCombust(pos, s.positions[Planet.sun]!)) {
            disq.add('${p.name}:combust');
          }
          if (dignityOf(pos) == PlanetDignity.debilitated) {
            disq.add('${p.name}:debilitated');
          }
          if (const {6, 8, 12}.contains(_houseOf(s, p))) {
            disq.add('${p.name}:trik');
          }
          if (naturalRelOf(p, pos.sign.lord) == PlanetaryRel.enemy) {
            disq.add('${p.name}:enemy-sign');
          }
        }
        if (disq.isNotEmpty) {
          pairs.add(TajikaYoga(
              type: TajikaYogaType.rudda, planets: base.planets, tags: disq));
        }

        // Duhphali-Kuttha: strong slow-mover, weak fast-mover
        // (book p. 142) — dispositions as the mechanical proxy.
        final slow = base.planets.last;
        final slowDisp = dispositionOf(s, slow);
        final fastDisp = dispositionOf(s, fast);
        if (slowDisp == 'excellent' &&
            fastDisp != 'excellent' &&
            !_retro(s, fast)) {
          pairs.add(TajikaYoga(
              type: TajikaYogaType.duhphaliKuttha,
              planets: base.planets,
              tags: ['slow:$slowDisp', 'fast:$fastDisp']));
        }
      }

      // Nakta / Yamaya for non-aspecting pairs: an intervener aspects
      // both with both inside ITS individual deeptamsha — faster than
      // both for Nakta, slower for Yamaya (book pp. 129, 133).
      if (!_aspect(s, a, b)) {
        for (final t in kTajikaPlanets) {
          if (t == a || t == b) continue;
          if (!_aspect(s, t, a) || !_aspect(s, t, b)) continue;
          final dt = kDeeptamsha[t]!;
          final ga = (_inSign(s, t) - _inSign(s, a)).abs();
          final gb = (_inSign(s, t) - _inSign(s, b)).abs();
          if (ga > dt || gb > dt) continue;
          if (_fasterThan(t, a) && _fasterThan(t, b)) {
            pairs.add(TajikaYoga(
                type: TajikaYogaType.nakta, planets: [a, b], linker: t));
          } else if (_fasterThan(a, t) && _fasterThan(b, t)) {
            pairs.add(TajikaYoga(
                type: TajikaYogaType.yamaya, planets: [a, b], linker: t));
          }
        }
      }
    }
  }

  // --- Lagnesha/karyesha framing ----------------------------------------
  final lagnesha = s.lagnaSign.lord;
  final karyesha =
      ZodiacSign.values[(s.lagnaSign.index + karyeshaHouse - 1) % 12].lord;

  if (lagnesha != karyesha) {
    final both = [lagnesha, karyesha];
    bool strong(Planet p) => dispositionOf(s, p) == 'excellent';
    bool weak(Planet p) {
      final d = dispositionOf(s, p);
      return d == 'inferior' ||
          (d == 'mediocre' && const {6, 8, 12}.contains(_houseOf(s, p)));
    }

    // Kuttha: both strong in kendras/panapharas, no malefic aspect
    // (book p. 143).
    final bothPlaced =
        both.every((p) => kendraPanaphara.contains(_houseOf(s, p)));
    final maleficHit = both.any((p) => const [Planet.mars, Planet.saturn].any(
        (m) => !both.contains(m) && tajikaRelationBetween(s, m, p).isEnemy));
    if (bothPlaced && both.every(strong) && !maleficHit) {
      pairs.add(TajikaYoga(type: TajikaYogaType.kuttha, planets: both));
    }

    // Durpaha: both weak in trik houses, afflicted (book p. 143).
    if (both.every((p) =>
        const {6, 8, 12}.contains(_houseOf(s, p)) &&
        (weak(p) ||
            _retro(s, p) ||
            (p != Planet.sun &&
                isCombust(s.positions[p]!, s.positions[Planet.sun]!))))) {
      pairs.add(TajikaYoga(type: TajikaYogaType.durpaha, planets: both));
    }

    // Dutthottha-Davira: both weak, but one linked by Ithasala to a
    // strong third planet (book p. 142).
    if (both.every((p) => !strong(p))) {
      for (final p in both) {
        for (final t in kTajikaPlanets) {
          if (both.contains(t) || !strong(t)) continue;
          if (_isIthasala(ithasalaBetween(s, p, t))) {
            pairs.add(TajikaYoga(
                type: TajikaYogaType.dutthotthaDavira,
                planets: both,
                linker: t));
            break;
          }
        }
      }
    }

    // Tambira: no mutual link, karyesha in Rashyanta, forming Ithasala
    // from the next sign with the lagnesha AND a strong planet
    // (book p. 143).
    if (!_aspect(s, lagnesha, karyesha) &&
        _inSign(s, karyesha) >= 29 &&
        _aspectFromNextSign(s, karyesha, lagnesha)) {
      final strongThird = kTajikaPlanets.any((p) =>
          !both.contains(p) &&
          dispositionOf(s, p) == 'excellent' &&
          _aspectFromNextSign(s, karyesha, p));
      if (strongThird) {
        pairs.add(TajikaYoga(type: TajikaYogaType.tambira, planets: both));
      }
    }
  }

  return TajikaYogaScan(
    chartYogas: chart,
    pairYogas: pairs,
    lagnesha: lagnesha,
    karyesha: karyesha,
  );
}

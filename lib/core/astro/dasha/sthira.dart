/// Jaimini Sthira dasha — SIGN-based with FIXED durations, started from
/// Brahma's rashi.
///
/// Implementation follows Akhila Kumar, "Predicting through Jaimini's
/// Sthira Dasha" (Vani Publications; the K.N. Rao / Bharatiya Vidya
/// Bhawan method), Introduction pp. 10–27 — the same school our Chara
/// dasha follows. The book resolves each classical controversy and its
/// choices are what ship here:
///
/// - GRAHA BALA (seven grahas, never the nodes) = Mulatrikonadi bala
///   (exalted 70 / moolatrikona 60 / own 50 / friend 40 / neutral 30 /
///   enemy 20 / debilitated 10) + Amsa bala by chara-karaka rank
///   (AK 70 … DK 10) + Kendradi bala from the Atmakaraka's rashi
///   (kendra 60 / panaphara 40 / apoklima 20).
/// - RASHI BALA = the LORD's graha bala posted to the sign(s) it owns
///   (the book's "posted in their respective rashis" — verified against
///   its Nehru table, which only reproduces under lordship-posting) +
///   chara bala by modality (movable 20 / fixed 40 / dual 60) + sthira
///   bala (10 per occupying graha) + drishti bala: 60 each for the
///   sign's lord, for Jupiter, and for Mercury either SITTING IN the
///   sign or casting Rashi Drishti onto it. The three channels are
///   independent — Jupiter lording Sagittarius from Sagittarius scores
///   both the lord 60 and the Jupiter 60 (book's Dhanu row: 120).
/// - BRAHMA: from the stronger of lagna/7th by rashi bala, the strongest
///   by graha bala among that sign's 6th, 8th and 12th lords; Saturn is
///   simply rejected (the book states the "count the 6th from there"
///   exception only to discard it as circular). Rahu/Ketu never
///   compete — they hold no graha bala and lord nothing here.
/// - RUDRA: the stronger by graha bala of the 2nd and 8th lords from
///   lagna (P.S. Shastri's single Rudra). MAHESHWARA: the 8th lord from
///   the Atmakaraka's rashi. Saturn may be either; only Brahma bars it.
/// - THE DASHA: mahadashas run from Brahma's rashi, always DIRECT, all
///   twelve signs; durations are fixed by modality — movable 7, fixed 8,
///   dual 9 years — with no balance at birth. Antardashas start from the
///   mahadasha's OWN sign, direct, in twelve equal parts (the book's
///   uniform 7/8/9 months, set by the maha sign's modality — its three
///   worked antardasha tables all confirm uniform-per-maha, against a
///   misreadable sentence in the intro). Pratyantars repeat the same
///   shape from the antardasha's sign (the book's 17d12h/20d/22d12h are
///   exactly parent/12); deeper levels generalize identically.
///
/// One inference is ours, marked in [_mulatrikonadiBala]: the book shows
/// debilitation degrading past the deep-fall degree (its Example 3 Sun in
/// Libra 14°41' scores 20, "Exceeds Deepest debilitation point") and
/// exaltation holding up to the deep point; the symmetric case — an
/// exaltation sign PAST the deep degree — has no worked example and
/// falls through to the relationship tiers here.
library;

import '../jaimini_aspect.dart';
import '../jaimini_karaka.dart';
import '../models.dart';
import '../shadbala.dart'
    show
        PlanetaryRel,
        deepExaltationDegreeOf,
        moolatrikonaRangeOf,
        moolatrikonaSignOf,
        naturalRelOf;
import '../dignity.dart' show exaltationSignOf;
import 'dasha.dart';

/// The seven grahas that carry graha bala (no nodes — book p. 8: "never
/// consider Rahu and Ketu because they have no place in the scheme").
const List<Planet> kSthiraGrahas = [
  Planet.sun,
  Planet.moon,
  Planet.mars,
  Planet.mercury,
  Planet.jupiter,
  Planet.venus,
  Planet.saturn,
];

/// Fixed years per sign — movable 7, fixed 8, dual 9 (modality is
/// index % 3, so the sum works out as 7 + index % 3).
int sthiraYears(ZodiacSign sign) => 7 + sign.index % 3;

/// The full strength working: both bala tables with their component
/// breakdowns (the detail view and PDF print them the way the book
/// does), the three deities, and the karaka map that fed Amsa bala.
class SthiraBala {
  const SthiraBala({
    required this.mulatrikonadiBala,
    required this.amsaBala,
    required this.kendradiBala,
    required this.grahaBala,
    required this.lordBala,
    required this.charaBala,
    required this.sthiraBala,
    required this.drishtiBala,
    required this.rashiBala,
    required this.brahma,
    required this.rudra,
    required this.maheshwara,
    required this.karakas,
  });

  final Map<Planet, int> mulatrikonadiBala;
  final Map<Planet, int> amsaBala;
  final Map<Planet, int> kendradiBala;
  final Map<Planet, int> grahaBala; // sum of the three, per graha

  final Map<ZodiacSign, int> lordBala; // lord's graha bala, posted
  final Map<ZodiacSign, int> charaBala; // 20/40/60 by modality
  final Map<ZodiacSign, int> sthiraBala; // 10 per occupying graha
  final Map<ZodiacSign, int> drishtiBala; // lord/Jupiter/Mercury, 60 each
  final Map<ZodiacSign, int> rashiBala; // sum of the four, per sign

  final Planet brahma;
  final Planet rudra;
  final Planet maheshwara;
  final Map<Planet, Karaka> karakas;
}

/// Mulatrikonadi bala per the book's "improvised" table (p. 15) and its
/// demonstrated edge cases: Jupiter in Sagittarius OUTSIDE the
/// moolatrikona degrees is own-sign 50 (Nehru), the Sun in Libra PAST
/// the deep-fall degree is enemy-sign 20 rather than 10 (Example 3).
int _mulatrikonadiBala(PlanetPosition pos) {
  final p = pos.planet;
  final sign = pos.sign;
  final deg = pos.degreesInSign;

  final exSign = exaltationSignOf(p);
  final deep = deepExaltationDegreeOf(p)!;
  if (sign == exSign && deg <= deep) return 70;

  final mtSign = moolatrikonaSignOf(p);
  if (sign == mtSign) {
    final (lo, hi) = moolatrikonaRangeOf(p)!;
    if (deg >= lo && deg <= hi) return 60;
  }
  if (sign.lord == p) return 50;

  // Debilitation sign is always opposite exaltation, deep degree at the
  // same degree number. Past the deep point the fall is spent (book's
  // Example 3) and the ordinary relationship tiers apply below.
  final debSign = ZodiacSign.values[(exSign!.index + 6) % 12];
  if (sign == debSign && deg <= deep) return 10;

  return switch (naturalRelOf(p, sign.lord)) {
    PlanetaryRel.friend => 40,
    PlanetaryRel.neutral => 30,
    PlanetaryRel.enemy => 20,
  };
}

/// Whether [source]'s placement reaches [target]: sitting in it, or
/// casting Rashi Drishti onto it. The book scores presence and aspect
/// identically (Nehru: "Tula has Venus in it and gets 60 units" beside
/// "Vrishabha is aspected by its lord Venus … 60 units").
bool _reaches(ZodiacSign sourceSign, ZodiacSign target) =>
    sourceSign == target || jaiminiRashiDrishti(sourceSign).contains(target);

SthiraBala computeSthiraBala(AstroSnapshot snapshot) {
  final positions = snapshot.positions;
  final karakas = saptaKarakas(positions);

  // --- Graha bala -------------------------------------------------------
  final mula = <Planet, int>{};
  final amsa = <Planet, int>{};
  final kendradi = <Planet, int>{};
  final graha = <Planet, int>{};

  final akSign = positions[
          karakas.entries.firstWhere((e) => e.value == Karaka.atmakaraka).key]!
      .sign;

  for (final p in kSthiraGrahas) {
    final pos = positions[p]!;
    mula[p] = _mulatrikonadiBala(pos);
    // AK 70 … DK 10, straight down the karaka ranks.
    amsa[p] = 70 - 10 * karakas[p]!.index;
    // House counted from the AK's rashi: kendra/panaphara/apoklima.
    final house = ((pos.sign.index - akSign.index + 12) % 12) + 1;
    kendradi[p] = switch ((house - 1) % 3) { 0 => 60, 1 => 40, _ => 20 };
    graha[p] = mula[p]! + amsa[p]! + kendradi[p]!;
  }

  // --- Rashi bala -------------------------------------------------------
  final lordB = <ZodiacSign, int>{};
  final charaB = <ZodiacSign, int>{};
  final sthiraB = <ZodiacSign, int>{};
  final drishtiB = <ZodiacSign, int>{};
  final rashi = <ZodiacSign, int>{};

  final jupiterSign = positions[Planet.jupiter]!.sign;
  final mercurySign = positions[Planet.mercury]!.sign;

  for (final sign in ZodiacSign.values) {
    lordB[sign] = graha[sign.lord]!;
    charaB[sign] = 20 + 20 * (sign.index % 3);
    sthiraB[sign] =
        10 * kSthiraGrahas.where((p) => positions[p]!.sign == sign).length;
    // Three independent 60-unit channels — the lord channel still counts
    // when the lord happens to BE Jupiter or Mercury (book's Dhanu: 120).
    var d = 0;
    if (_reaches(positions[sign.lord]!.sign, sign)) d += 60;
    if (_reaches(jupiterSign, sign)) d += 60;
    if (_reaches(mercurySign, sign)) d += 60;
    drishtiB[sign] = d;
    rashi[sign] = lordB[sign]! + charaB[sign]! + sthiraB[sign]! + d;
  }

  // --- Brahma -----------------------------------------------------------
  final lagna = snapshot.lagnaSign;
  final seventh = ZodiacSign.values[(lagna.index + 6) % 12];
  // Tie → lagna: the book never shows one and gives no rule; the chart's
  // own first house is the least surprising default.
  final anchor = rashi[seventh]! > rashi[lagna]! ? seventh : lagna;

  ZodiacSign fromAnchor(int houses) =>
      ZodiacSign.values[(anchor.index + houses - 1) % 12];
  // 6th, 8th, 12th lords from the stronger house; Saturn rejected
  // outright. Saturn can lord at most one of the three, so at least two
  // candidates always survive. Tie → the earlier of the 6th/8th/12th
  // order (no book rule; its examples never tie).
  final candidates = [
    fromAnchor(6).lord,
    fromAnchor(8).lord,
    fromAnchor(12).lord
  ].where((p) => p != Planet.saturn).toList();
  var brahma = candidates.first;
  for (final c in candidates.skip(1)) {
    if (graha[c]! > graha[brahma]!) brahma = c;
  }

  // --- Rudra & Maheshwara ----------------------------------------------
  final second = ZodiacSign.values[(lagna.index + 1) % 12].lord;
  final eighth = ZodiacSign.values[(lagna.index + 7) % 12].lord;
  // Tie → the 2nd lord: P.S. Shastri's single-Rudra reading, and the
  // book compares strengths without a tie rule.
  final rudra = graha[eighth]! > graha[second]! ? eighth : second;

  final maheshwara = ZodiacSign.values[(akSign.index + 7) % 12].lord;

  return SthiraBala(
    mulatrikonadiBala: mula,
    amsaBala: amsa,
    kendradiBala: kendradi,
    grahaBala: graha,
    lordBala: lordB,
    charaBala: charaB,
    sthiraBala: sthiraB,
    drishtiBala: drishtiB,
    rashiBala: rashi,
    brahma: brahma,
    rudra: rudra,
    maheshwara: maheshwara,
    karakas: karakas,
  );
}

class SthiraDashaCalculator implements DashaCalculator {
  @override
  DashaSystem get system => DashaSystem.sthira;

  @override
  DashaResult calculate(AstroSnapshot snapshot) {
    final birth = snapshot.birth.dateTimeUtc;
    final bala = computeSthiraBala(snapshot);
    final startSign = snapshot.positions[bala.brahma]!.sign;

    // CALENDAR arithmetic, not solar-year arithmetic: the book's own
    // tables run birthday to birthday ("Tula started from 14th November
    // 1889 and ended in 14th November 1896") and month-day to month-day
    // for antardashas (Nov → Jun) — so boundaries here are computed as
    // whole calendar months from birth. Cycles repeat only up to the
    // app-wide horizon: the last mahadasha STARTS before age 120.
    var monthsFromBirth = 0;
    var i = 0;
    final periods = <DashaPeriod>[];
    while (monthsFromBirth < kDashaHorizonYears * 12) {
      final sign = ZodiacSign.values[(startSign.index + i) % 12];
      final years = sthiraYears(sign);
      final start = _addCalendarMonths(birth, monthsFromBirth);
      final end = _addCalendarMonths(birth, monthsFromBirth + years * 12);
      periods.add(_buildPeriod(sign, years, start, end, 1));
      monthsFromBirth += years * 12;
      i++;
    }
    return DashaResult(system: system, periods: periods);
  }

  /// Sub-periods, DIRECT, starting from the parent's OWN sign (the
  /// book's antardashas and pratyantars both do this; deeper levels
  /// generalize the same way). Antardashas are whole calendar months —
  /// a 7-year maha's twelve antars of 7 months each, month-day to
  /// month-day like the book's tables. Deeper levels have no calendar
  /// unit left, so they are twelve equal parts of the real parent (the
  /// book's "17 days and 12 hours" assumes idealized 30-day months and
  /// would leave gaps against its own calendar-month antardashas).
  DashaPeriod _buildPeriod(
    ZodiacSign sign,
    int years,
    DateTime start,
    DateTime end,
    int level,
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
              final children = <DashaPeriod>[];
              if (level == 1) {
                for (var i = 0; i < 12; i++) {
                  final sub = ZodiacSign.values[(sign.index + i) % 12];
                  final subStart = _addCalendarMonths(parent.start, i * years);
                  final subEnd = i == 11
                      ? parent.end
                      : _addCalendarMonths(parent.start, (i + 1) * years);
                  children.add(
                      _buildPeriod(sub, years, subStart, subEnd, level + 1));
                }
              } else {
                final twelfth = parent.length ~/ 12;
                var cursor = parent.start;
                for (var i = 0; i < 12; i++) {
                  final sub = ZodiacSign.values[(sign.index + i) % 12];
                  final subEnd = i == 11 ? parent.end : cursor.add(twelfth);
                  children
                      .add(_buildPeriod(sub, years, cursor, subEnd, level + 1));
                  cursor = subEnd;
                }
              }
              return children;
            },
    );
  }
}

/// [months] whole calendar months after [t], the day-of-month clamped to
/// the target month's length (a 31st birthday clamps in a 30-day month,
/// as calendars do).
DateTime _addCalendarMonths(DateTime t, int months) {
  final zeroBased = t.month - 1 + months;
  final year = t.year + zeroBased ~/ 12;
  final month = zeroBased % 12 + 1;
  final lastDay = DateTime.utc(year, month + 1, 0).day;
  return DateTime.utc(year, month, t.day > lastDay ? lastDay : t.day, t.hour,
      t.minute, t.second);
}

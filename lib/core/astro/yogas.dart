/// Yoga/dosha detection for display and for the Mahakosh searchable
/// index (brief §2.6). Codes are stable machine identifiers stored in
/// the index — never change them once charts are contributed; the
/// engine only ever ADDS codes.
///
/// Phase-1 rule engine: structural facts come from [ChartFacts]
/// (houses, lords, drishti, exchange), rules read them declaratively.
/// Runs fully offline — Mahakosh only stores the codes when a chart
/// is contributed.
library;

import 'chart_facts.dart';
import 'dignity.dart';
import 'models.dart';

List<DetectedYoga> detectYogas({
  required Map<Planet, PlanetPosition> positions,
  required double ascendant,
}) {
  final yogas = <DetectedYoga>[];
  final f = ChartFacts(positions: positions, ascendant: ascendant);
  final lagnaSignIdx = f.lagnaIdx;

  int houseFromLagna(double lon) => f.houseOfSignIdx((lon ~/ 30) % 12);
  int houseFromMoon(double lon) {
    final moonIdx = (positions[Planet.moon]!.longitude ~/ 30) % 12;
    return ((((lon ~/ 30) % 12) - moonIdx + 12) % 12) + 1;
  }

  // --- Chandra yogas ---------------------------------------------------

  // Gaja-Kesari: Jupiter in a kendra (1,4,7,10) from the Moon, with a
  // strength note from Jupiter's dignity.
  final juFromMoon = houseFromMoon(positions[Planet.jupiter]!.longitude);
  if (const {1, 4, 7, 10}.contains(juFromMoon)) {
    final juDignity = dignityOf(positions[Planet.jupiter]!);
    final strength = switch (juDignity) {
      PlanetDignity.exalted => ' — strong (Jupiter exalted)',
      PlanetDignity.ownSign => ' — strong (Jupiter in own sign)',
      PlanetDignity.debilitated => ' — weak (Jupiter debilitated)',
      PlanetDignity.none => '',
    };
    yogas.add(DetectedYoga(
      code: 'gaja_kesari',
      name: 'Gaja-Kesari Yoga',
      detail: 'Jupiter in kendra $juFromMoon from Moon$strength',
      category: 'Chandra',
      participants: const [Planet.jupiter, Planet.moon],
    ));
  }

  // Sunapha / Anapha / Durudhara / Kemadruma: occupation of the 2nd
  // and 12th from the Moon by the five tara-grahas (Sun and the nodes
  // are excluded classically).
  const taraGrahas = [
    Planet.mars, Planet.mercury, Planet.jupiter, Planet.venus, Planet.saturn,
  ];
  final moonIdx = positions[Planet.moon]!.sign.index;
  final in2ndFromMoon =
      taraGrahas.where((p) => f.houseFrom(moonIdx, p) == 2).toList();
  final in12thFromMoon =
      taraGrahas.where((p) => f.houseFrom(moonIdx, p) == 12).toList();
  String names(List<Planet> ps) => ps.map((p) => p.displayName).join(', ');
  if (in2ndFromMoon.isNotEmpty && in12thFromMoon.isNotEmpty) {
    yogas.add(DetectedYoga(
      code: 'durudhara',
      name: 'Durudhara Yoga',
      detail: '2nd from Moon: ${names(in2ndFromMoon)};'
          ' 12th: ${names(in12thFromMoon)}',
      category: 'Chandra',
      participants: [Planet.moon, ...in2ndFromMoon, ...in12thFromMoon],
    ));
  } else if (in2ndFromMoon.isNotEmpty) {
    yogas.add(DetectedYoga(
      code: 'sunapha',
      name: 'Sunapha Yoga',
      detail: '${names(in2ndFromMoon)} in 2nd from Moon',
      category: 'Chandra',
      participants: [Planet.moon, ...in2ndFromMoon],
    ));
  } else if (in12thFromMoon.isNotEmpty) {
    yogas.add(DetectedYoga(
      code: 'anapha',
      name: 'Anapha Yoga',
      detail: '${names(in12thFromMoon)} in 12th from Moon',
      category: 'Chandra',
      participants: [Planet.moon, ...in12thFromMoon],
    ));
  } else {
    // Kemadruma — lonely Moon; cancelled by a graha in kendra from
    // the Moon or the Moon itself in a kendra from the lagna.
    final kendraFromMoon = taraGrahas
        .where((p) => ChartFacts.kendras.contains(f.houseFrom(moonIdx, p)))
        .toList();
    final moonInLagnaKendra =
        ChartFacts.kendras.contains(f.houseOf(Planet.moon));
    if (kendraFromMoon.isEmpty && !moonInLagnaKendra) {
      yogas.add(const DetectedYoga(
        code: 'kemadruma',
        name: 'Kemadruma Yoga',
        detail: 'No grahas in 2nd/12th or kendra from Moon',
        category: 'Dosha',
        participants: [Planet.moon],
      ));
    }
  }

  // Vesi / Vasi / Ubhayachari: the same pattern around the Sun
  // (Moon and the nodes excluded).
  final sunIdx = positions[Planet.sun]!.sign.index;
  final in2ndFromSun =
      taraGrahas.where((p) => f.houseFrom(sunIdx, p) == 2).toList();
  final in12thFromSun =
      taraGrahas.where((p) => f.houseFrom(sunIdx, p) == 12).toList();
  if (in2ndFromSun.isNotEmpty && in12thFromSun.isNotEmpty) {
    yogas.add(DetectedYoga(
      code: 'ubhayachari',
      name: 'Ubhayachari Yoga',
      detail: '2nd from Sun: ${names(in2ndFromSun)};'
          ' 12th: ${names(in12thFromSun)}',
      category: 'Other',
      participants: [Planet.sun, ...in2ndFromSun, ...in12thFromSun],
    ));
  } else if (in2ndFromSun.isNotEmpty) {
    yogas.add(DetectedYoga(
      code: 'vesi',
      name: 'Vesi Yoga',
      detail: '${names(in2ndFromSun)} in 2nd from Sun',
      category: 'Other',
      participants: [Planet.sun, ...in2ndFromSun],
    ));
  } else if (in12thFromSun.isNotEmpty) {
    yogas.add(DetectedYoga(
      code: 'vasi',
      name: 'Vasi Yoga',
      detail: '${names(in12thFromSun)} in 12th from Sun',
      category: 'Other',
      participants: [Planet.sun, ...in12thFromSun],
    ));
  }

  // Adhi yoga: at least two conditional benefics among the 6th, 7th
  // and 8th from the Moon.
  final adhiBenefics = f.yogaBenefics
      .where((p) =>
          p != Planet.moon &&
          const {6, 7, 8}.contains(f.houseFrom(moonIdx, p)))
      .toList();
  if (adhiBenefics.length >= 2) {
    yogas.add(DetectedYoga(
      code: 'adhi_yoga',
      name: 'Adhi Yoga',
      detail: '${names(adhiBenefics)} in 6th/7th/8th from Moon',
      category: 'Chandra',
      participants: [Planet.moon, ...adhiBenefics],
    ));
  }

  // Amala: a benefic alone in the 10th from the lagna or the Moon,
  // no malefic sharing it.
  for (final (anchorName, anchorIdx) in [
    ('lagna', lagnaSignIdx),
    ('Moon', moonIdx),
  ]) {
    final tenth =
        positions.values.where((p) => f.houseFrom(anchorIdx, p.planet) == 10);
    final benefics = [
      for (final p in tenth)
        if (f.yogaBenefics.contains(p.planet)) p.planet,
    ];
    final hasMalefic = tenth.any((p) => f.isYogaMalefic(p.planet));
    if (benefics.isNotEmpty && !hasMalefic) {
      yogas.add(DetectedYoga(
        code: 'amala',
        name: 'Amala Yoga',
        detail: '${names(benefics)} alone in 10th from $anchorName',
        category: 'Other',
        participants: benefics,
      ));
      break; // one entry is enough
    }
  }

  // Shakata: Moon in 6/8/12 from Jupiter, unless the Moon holds a
  // kendra from the lagna.
  final moonFromJu = f.houseFrom(positions[Planet.jupiter]!.sign.index,
      Planet.moon);
  if (ChartFacts.dusthanas.contains(moonFromJu) &&
      !ChartFacts.kendras.contains(f.houseOf(Planet.moon))) {
    yogas.add(DetectedYoga(
      code: 'shakata',
      name: 'Shakata Yoga',
      detail: 'Moon $moonFromJu from Jupiter',
      category: 'Dosha',
      participants: const [Planet.moon, Planet.jupiter],
    ));
  }

  // Budha-Aditya: Sun + Mercury conjunct in the same sign.
  if (positions[Planet.sun]!.sign == positions[Planet.mercury]!.sign) {
    yogas.add(const DetectedYoga(
      code: 'budha_aditya',
      name: 'Budha-Aditya Yoga',
      detail: 'Sun and Mercury conjunct',
      category: 'Other',
      participants: [Planet.sun, Planet.mercury],
    ));
  }

  // Chandra-Mangala: Moon + Mars conjunct (a wealth combination).
  if (positions[Planet.moon]!.sign == positions[Planet.mars]!.sign) {
    yogas.add(const DetectedYoga(
      code: 'chandra_mangala',
      name: 'Chandra-Mangala Yoga',
      detail: 'Moon and Mars conjunct',
      category: 'Dhana',
      participants: [Planet.moon, Planet.mars],
    ));
  }

  // --- Raj yogas: every kendra-lord × trikona-lord link ----------------
  final kendraLords = {for (final h in ChartFacts.kendras) f.lordOf(h)};
  final trikonaLords = {for (final h in ChartFacts.trikonas) f.lordOf(h)};
  final seenRajPairs = <String>{};
  for (final k in kendraLords) {
    for (final t in trikonaLords) {
      if (k == t) continue;
      final key = ([k.index, t.index]..sort()).join('-');
      if (!seenRajPairs.add(key)) continue;
      final link = f.connection(k, t);
      if (link != null) {
        yogas.add(DetectedYoga(
          code: 'raj_yoga',
          name: 'Raj Yoga',
          detail: '${k.displayName} (kendra lord) and ${t.displayName}'
              ' (trikona lord) by $link',
          category: 'Raj',
          participants: [k, t],
        ));
      }
    }
  }

  // Yogakaraka: one graha lording both a kendra (4/7/10) and a
  // trikona (5/9) — Mars for Cancer/Leo, Venus for Capricorn/
  // Aquarius, Saturn for Taurus/Libra lagnas.
  final lorded = <Planet, Set<int>>{};
  for (var h = 1; h <= 12; h++) {
    (lorded[f.lordOf(h)] ??= {}).add(h);
  }
  lorded.forEach((p, houses) {
    final kendra = houses.where((h) => const {4, 7, 10}.contains(h));
    final trikona = houses.where((h) => const {5, 9}.contains(h));
    if (kendra.isNotEmpty && trikona.isNotEmpty) {
      yogas.add(DetectedYoga(
        code: 'yogakaraka',
        name: 'Yogakaraka',
        detail: '${p.displayName} lords houses ${kendra.first} and'
            ' ${trikona.first}',
        category: 'Raj',
        participants: [p],
      ));
    }
  });

  // --- Parivartana (exchange) yogas -------------------------------------
  // Iterate planet pairs and classify by the houses each OCCUPIES
  // (with dual lordship, iterating house pairs would misattribute the
  // exchange to a sign neither planet is in).
  const classicalSeven = [
    Planet.sun, Planet.moon, Planet.mars, Planet.mercury,
    Planet.jupiter, Planet.venus, Planet.saturn,
  ];
  for (var a = 0; a < classicalSeven.length; a++) {
    for (var b = a + 1; b < classicalSeven.length; b++) {
      final pa = classicalSeven[a], pb = classicalSeven[b];
      if (!f.exchange(pa, pb)) continue;
      final i = f.houseOf(pa), j = f.houseOf(pb);
      final dusthana = ChartFacts.dusthanas.contains(i) ||
          ChartFacts.dusthanas.contains(j);
      final khala = i == 3 || j == 3;
      final (code, name) = dusthana
          ? ('parivartana_dainya', 'Dainya Parivartana')
          : khala
              ? ('parivartana_khala', 'Khala Parivartana')
              : ('parivartana_maha', 'Maha Parivartana');
      yogas.add(DetectedYoga(
        code: code,
        name: name,
        detail: '${pa.displayName} ↔ ${pb.displayName} exchange between'
            ' houses $i and $j',
        category: 'Parivartana',
        participants: [pa, pb],
      ));
    }
  }

  // --- Dhana yogas: wealth-house lord links ------------------------------
  const dhanaPairs = [(2, 5), (2, 9), (2, 11), (5, 11), (9, 11)];
  final seenDhana = <String>{};
  for (final (a, b) in dhanaPairs) {
    final la = f.lordOf(a), lb = f.lordOf(b);
    if (la == lb) continue;
    final key = ([la.index, lb.index]..sort()).join('-');
    if (!seenDhana.add(key)) continue;
    final link = f.connection(la, lb);
    if (link != null) {
      yogas.add(DetectedYoga(
        code: 'dhana_yoga',
        name: 'Dhana Yoga',
        detail: 'Lords of houses $a and $b (${la.displayName},'
            ' ${lb.displayName}) by $link',
        category: 'Dhana',
        participants: [la, lb],
      ));
    }
  }

  // --- Vipreet Raj yogas: dusthana lords in dusthanas --------------------
  const vipreet = {
    6: ('harsha', 'Harsha Yoga'),
    8: ('sarala', 'Sarala Yoga'),
    12: ('vimala', 'Vimala Yoga'),
  };
  vipreet.forEach((house, id) {
    final lord = f.lordOf(house);
    final placed = f.houseOf(lord);
    if (ChartFacts.dusthanas.contains(placed)) {
      final (code, name) = id;
      yogas.add(DetectedYoga(
        code: code,
        name: name,
        detail: 'Lord of $house (${lord.displayName}) in house $placed',
        category: 'Vipreet Raj',
        participants: [lord],
      ));
    }
  });

  // --- Neecha Bhanga: debilitation cancelled ------------------------------
  final moonSignIdx = positions[Planet.moon]!.sign.index;
  for (final pos in positions.values) {
    if (dignityOf(pos) != PlanetDignity.debilitated) continue;
    final dispositor = pos.sign.lord;
    Planet? exaltedHere;
    for (final q in positions.values) {
      if (q.planet != pos.planet && exaltationSignOf(q.planet) == pos.sign) {
        exaltedHere = q.planet;
        break;
      }
    }
    final byDispositor = f.inKendraFrom(lagnaSignIdx, dispositor) ||
        f.inKendraFrom(moonSignIdx, dispositor);
    final byExalted = exaltedHere != null &&
        (f.inKendraFrom(lagnaSignIdx, exaltedHere) ||
            f.inKendraFrom(moonSignIdx, exaltedHere));
    if (byDispositor || byExalted) {
      yogas.add(DetectedYoga(
        code: 'neecha_bhanga',
        name: 'Neecha Bhanga',
        detail: '${pos.planet.displayName} debilitated, cancelled by '
            '${byDispositor ? 'dispositor ${dispositor.displayName}' : 'exalted-here ${exaltedHere!.displayName}'}'
            ' in kendra',
        category: 'Raj',
        participants: [
          pos.planet,
          if (byDispositor) dispositor else exaltedHere!,
        ],
      ));
    }
  }

  // --- Phase 3: named combinations and Nabhasa ---------------------------

  // Lakshmi: the 9th lord in a kendra/trikona AND in own or exalted
  // sign.
  final ninthLord = f.lordOf(9);
  final ninthLordHouse = f.houseOf(ninthLord);
  final ninthLordDignity = dignityOf(positions[ninthLord]!);
  if ((ChartFacts.kendras.contains(ninthLordHouse) ||
          ChartFacts.trikonas.contains(ninthLordHouse)) &&
      (ninthLordDignity == PlanetDignity.ownSign ||
          ninthLordDignity == PlanetDignity.exalted)) {
    yogas.add(DetectedYoga(
      code: 'lakshmi_yoga',
      name: 'Lakshmi Yoga',
      detail: '9th lord ${ninthLord.displayName}'
          ' ${ninthLordDignity == PlanetDignity.exalted ? 'exalted' : 'in own sign'}'
          ' in house $ninthLordHouse',
      category: 'Dhana',
      participants: [ninthLord],
    ));
  }

  // Saraswati: Jupiter, Venus and Mercury all in kendras, trikonas or
  // the 2nd, with Jupiter not debilitated.
  const saraswatiHouses = {1, 2, 4, 5, 7, 9, 10};
  final saraswatiTrio = [Planet.jupiter, Planet.venus, Planet.mercury];
  if (saraswatiTrio.every((p) => saraswatiHouses.contains(f.houseOf(p))) &&
      dignityOf(positions[Planet.jupiter]!) != PlanetDignity.debilitated) {
    yogas.add(DetectedYoga(
      code: 'saraswati_yoga',
      name: 'Saraswati Yoga',
      detail: 'Jupiter, Venus and Mercury all in kendra/trikona/2nd',
      category: 'Other',
      participants: saraswatiTrio,
    ));
  }

  // Parvata: benefics in kendras with no malefic there, and the 6th
  // and 8th empty or benefic-occupied.
  final inKendras = positions.values
      .where((p) => ChartFacts.kendras.contains(f.houseOf(p.planet)))
      .map((p) => p.planet)
      .toList();
  final kendraBenefics =
      inKendras.where((p) => f.yogaBenefics.contains(p)).toList();
  final kendraHasMalefic = inKendras.any(f.isYogaMalefic);
  final sixEight = positions.values
      .where((p) => const {6, 8}.contains(f.houseOf(p.planet)))
      .map((p) => p.planet);
  final sixEightClean = sixEight.every((p) => f.yogaBenefics.contains(p));
  if (kendraBenefics.isNotEmpty && !kendraHasMalefic && sixEightClean) {
    yogas.add(DetectedYoga(
      code: 'parvata_yoga',
      name: 'Parvata Yoga',
      detail: '${names(kendraBenefics)} in kendra; 6th/8th unafflicted',
      category: 'Other',
      participants: kendraBenefics,
    ));
  }

  // Kahala: the 4th and 9th lords in mutual kendras, lagna lord
  // neither debilitated nor in a dusthana.
  final fourthLord = f.lordOf(4);
  final lagnaLord = f.lordOf(1);
  if (fourthLord != ninthLord) {
    final between = f.houseFrom(
        positions[fourthLord]!.sign.index, ninthLord);
    final lagnaLordOk =
        dignityOf(positions[lagnaLord]!) != PlanetDignity.debilitated &&
            !ChartFacts.dusthanas.contains(f.houseOf(lagnaLord));
    if (ChartFacts.kendras.contains(between) && lagnaLordOk) {
      yogas.add(DetectedYoga(
        code: 'kahala_yoga',
        name: 'Kahala Yoga',
        detail: '4th lord ${fourthLord.displayName} and 9th lord'
            ' ${ninthLord.displayName} in mutual kendras',
        category: 'Raj',
        participants: [fourthLord, ninthLord],
      ));
    }
  }

  // Nabhasa ashraya: all seven classical grahas in movable / fixed /
  // dual signs.
  const seven = [
    Planet.sun, Planet.moon, Planet.mars, Planet.mercury,
    Planet.jupiter, Planet.venus, Planet.saturn,
  ];
  final allMovable = seven.every((p) => positions[p]!.sign.isMovable);
  final allFixed = seven.every((p) => positions[p]!.sign.isFixed);
  final allDual = seven.every((p) => positions[p]!.sign.isDual);
  if (allMovable || allFixed || allDual) {
    final (code, name, kind) = allMovable
        ? ('rajju_yoga', 'Rajju Yoga', 'movable')
        : allFixed
            ? ('musala_yoga', 'Musala Yoga', 'fixed')
            : ('nala_yoga', 'Nala Yoga', 'dual');
    yogas.add(DetectedYoga(
      code: code,
      name: name,
      detail: 'All seven grahas in $kind signs',
      category: 'Other',
      participants: seven,
    ));
  }

  // --- Doshas -------------------------------------------------------------

  // Mangal dosha: Mars in 1, 2, 4, 7, 8 or 12 from lagna — with a
  // mitigation note when Mars is in own or exalted sign.
  final marsHouse = houseFromLagna(positions[Planet.mars]!.longitude);
  if (const {1, 2, 4, 7, 8, 12}.contains(marsHouse)) {
    final marsDignity = dignityOf(positions[Planet.mars]!);
    final mitigated = marsDignity == PlanetDignity.ownSign ||
        marsDignity == PlanetDignity.exalted;
    yogas.add(DetectedYoga(
      code: 'mangal_dosha',
      name: 'Mangal Dosha',
      detail: 'Mars in house $marsHouse from lagna'
          '${mitigated ? ' — mitigated (Mars in own/exalted sign)' : ''}',
      category: 'Dosha',
      participants: const [Planet.mars],
    ));
  }

  // Conjunction doshas.
  if (positions[Planet.jupiter]!.sign == positions[Planet.rahu]!.sign ||
      positions[Planet.jupiter]!.sign == positions[Planet.ketu]!.sign) {
    final node =
        positions[Planet.jupiter]!.sign == positions[Planet.rahu]!.sign
            ? Planet.rahu
            : Planet.ketu;
    yogas.add(DetectedYoga(
      code: 'guru_chandal',
      name: 'Guru-Chandal Dosha',
      detail: 'Jupiter conjunct ${node.displayName}',
      category: 'Dosha',
      participants: [Planet.jupiter, node],
    ));
  }
  if (positions[Planet.saturn]!.sign == positions[Planet.moon]!.sign) {
    yogas.add(const DetectedYoga(
      code: 'vish_yoga',
      name: 'Vish Yoga',
      detail: 'Saturn and Moon conjunct',
      category: 'Dosha',
      participants: [Planet.saturn, Planet.moon],
    ));
  }
  if (positions[Planet.mars]!.sign == positions[Planet.rahu]!.sign) {
    yogas.add(const DetectedYoga(
      code: 'angarak_dosha',
      name: 'Angarak Dosha',
      detail: 'Mars and Rahu conjunct',
      category: 'Dosha',
      participants: [Planet.mars, Planet.rahu],
    ));
  }
  for (final lum in const [Planet.sun, Planet.moon]) {
    for (final node in const [Planet.rahu, Planet.ketu]) {
      if (positions[lum]!.sign == positions[node]!.sign) {
        yogas.add(DetectedYoga(
          code: 'grahan_dosha',
          name: 'Grahan Dosha',
          detail: '${lum.displayName} conjunct ${node.displayName}',
          category: 'Dosha',
          participants: [lum, node],
        ));
      }
    }
  }

  // Kaal Sarp dosha: all seven classical planets on one side of the
  // Rahu–Ketu axis.
  final rahuLon = positions[Planet.rahu]!.longitude;
  final ketuLon = positions[Planet.ketu]!.longitude;
  bool between(double x, double a, double b) {
    final span = (b - a + 360) % 360;
    final off = (x - a + 360) % 360;
    return off > 0 && off < span;
  }

  final outsideA = seven
      .where((p) => !between(positions[p]!.longitude, rahuLon, ketuLon))
      .toList();
  final outsideB = seven
      .where((p) => !between(positions[p]!.longitude, ketuLon, rahuLon))
      .toList();
  if (outsideA.isEmpty || outsideB.isEmpty) {
    yogas.add(const DetectedYoga(
      code: 'kaal_sarp',
      name: 'Kaal Sarp Dosha',
      detail: 'All planets within the Rahu–Ketu axis',
      category: 'Dosha',
      participants: [Planet.rahu, Planet.ketu],
    ));
  } else if (outsideA.length == 1 || outsideB.length == 1) {
    final escaper =
        (outsideA.length == 1 ? outsideA : outsideB).first;
    yogas.add(DetectedYoga(
      code: 'kaal_sarp_partial',
      name: 'Partial Kaal Sarp',
      detail: 'Only ${escaper.displayName} outside the Rahu–Ketu axis',
      category: 'Dosha',
      participants: [Planet.rahu, Planet.ketu, escaper],
    ));
  }

  // --- Panch Mahapurusha ---------------------------------------------------
  const exaltation = {
    Planet.mars: ZodiacSign.capricorn,
    Planet.mercury: ZodiacSign.virgo,
    Planet.jupiter: ZodiacSign.cancer,
    Planet.venus: ZodiacSign.pisces,
    Planet.saturn: ZodiacSign.libra,
  };
  const mahapurushaNames = {
    Planet.mars: ('ruchaka', 'Ruchaka Yoga'),
    Planet.mercury: ('bhadra', 'Bhadra Yoga'),
    Planet.jupiter: ('hamsa', 'Hamsa Yoga'),
    Planet.venus: ('malavya', 'Malavya Yoga'),
    Planet.saturn: ('shasha', 'Shasha Yoga'),
  };
  for (final p in mahapurushaNames.keys) {
    final pos = positions[p]!;
    final own = pos.sign.lord == p;
    final exalted = exaltation[p] == pos.sign;
    final inKendra =
        const {1, 4, 7, 10}.contains(houseFromLagna(pos.longitude));
    if ((own || exalted) && inKendra) {
      final (code, name) = mahapurushaNames[p]!;
      yogas.add(DetectedYoga(
        code: code,
        name: name,
        detail:
            '${p.displayName} ${exalted ? 'exalted' : 'in own sign'} in kendra',
        category: 'Mahapurusha',
        participants: [p],
      ));
    }
  }

  return yogas;
}

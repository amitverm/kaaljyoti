// Pure-Dart engine sanity tests (no plugins / FFI needed).
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/dasha/yogini.dart';
import 'package:kaaljyoti/core/astro/divisional.dart';
import 'package:kaaljyoti/core/astro/jaimini_pada.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/core/astro/kota_chakra.dart';
import 'package:kaaljyoti/core/astro/nakshatra28.dart';
import 'package:kaaljyoti/core/astro/panchang.dart';
import 'package:kaaljyoti/core/astro/sarvatobhadra.dart';
import 'package:kaaljyoti/core/astro/special_lagna.dart';
import 'package:kaaljyoti/core/astro/yogas.dart';

void main() {
  test('zodiac sign from sidereal longitude', () {
    expect(ZodiacSign.fromLongitude(0), ZodiacSign.aries);
    expect(ZodiacSign.fromLongitude(29.999), ZodiacSign.aries);
    expect(ZodiacSign.fromLongitude(30), ZodiacSign.taurus);
    expect(ZodiacSign.fromLongitude(359.9), ZodiacSign.pisces);
  });

  test('nakshatra and pada from longitude', () {
    expect(Nakshatra.fromLongitude(0), Nakshatra.ashwini);
    expect(Nakshatra.padaFromLongitude(0), 1);
    // 13°20' = start of Bharani.
    expect(Nakshatra.fromLongitude(13.34), Nakshatra.bharani);
    // Chitra spans 173°20'–186°40'.
    expect(Nakshatra.fromLongitude(180), Nakshatra.chitra);
  });

  test('navamsa mapping (movable/fixed/dual counting)', () {
    // Aries 0°–3°20' (pada 1 of movable sign) → Aries navamsa.
    expect(navamsaSign(1.0), ZodiacSign.aries);
    // Taurus (fixed) first navamsa starts from Capricorn (9th from it).
    expect(navamsaSign(31.0), ZodiacSign.capricorn);
    // Gemini (dual) first navamsa starts from Libra (5th from it).
    expect(navamsaSign(61.0), ZodiacSign.libra);
  });

  test('panchang: tithi/paksha/karana boundaries', () {
    final p = computePanchang(
      sunLongitude: 0,
      moonLongitude: 12, // elongation 12° → 2nd tithi (index 1)
      localDateTime: DateTime(2024, 1, 1), // Monday
    );
    expect(p.tithiIndex, 1);
    expect(p.paksha, 'Shukla');
    expect(p.vara, 'Somavara');

    final amavasya = computePanchang(
      sunLongitude: 100,
      moonLongitude: 99, // elongation 359° → last tithi
      localDateTime: DateTime(2024, 1, 2),
    );
    expect(amavasya.tithiIndex, 29);
    expect(amavasya.tithiName, 'Amavasya');
    expect(amavasya.paksha, 'Krishna');
  });

  test('yogini starting lord: remainder 1 = Mangala rule', () {
    // Classical mapping of (nakshatra number + 3) mod 8:
    // Ashwini (1) → remainder 4 → 4th Yogini = Bhramari (Mars).
    // Pushya (8) → remainder 3 → 3rd Yogini = Dhanya (Jupiter).
    // Rohini (4) → remainder 7 → 7th Yogini = Siddha (Venus).
    (String, Planet) startFor(int nakNumber) {
      final idx = ((nakNumber + 3) % 8 + 7) % 8;
      final (name, planet, _) = YoginiCalculator.sequence[idx];
      return (name, planet);
    }

    expect(startFor(1), ('Bhramari', Planet.mars));
    expect(startFor(8), ('Dhanya', Planet.jupiter));
    expect(startFor(4), ('Siddha', Planet.venus));
    expect(startFor(5), ('Sankata', Planet.rahu)); // remainder 0
  });

  test('arudha padas: K.N. Rao rule, no 1st/7th exceptions', () {
    // Capricorn lagna; Sa & Ju in Virgo, Me/Ma/Su/Ve in Pisces, Mo in
    // Taurus (the reference chart from Parashar Light used to validate
    // this module — pada = as far from the lord as the lord is from
    // the house, kept even when it lands in the 1st or 7th).
    final lordSigns = <Planet, ZodiacSign>{
      Planet.saturn: ZodiacSign.virgo,
      Planet.jupiter: ZodiacSign.virgo,
      Planet.mercury: ZodiacSign.pisces,
      Planet.mars: ZodiacSign.pisces,
      Planet.sun: ZodiacSign.pisces,
      Planet.venus: ZodiacSign.pisces,
      Planet.moon: ZodiacSign.taurus,
    };
    final padas = arudhaPadasFromLagna(
        ZodiacSign.capricorn, (lord) => lordSigns[lord]!);
    final expected = [
      ZodiacSign.taurus, // 1P
      ZodiacSign.aries, // 2P
      ZodiacSign.pisces, // 3P — lands in its own house, kept (no exception)
      ZodiacSign.aquarius, // 4P
      ZodiacSign.capricorn, // 5P
      ZodiacSign.sagittarius, // 6P — lands in the 7th, kept (no exception)
      ZodiacSign.pisces, // 7P
      ZodiacSign.libra, // 8P
      ZodiacSign.virgo, // 9P — its own house, kept
      ZodiacSign.leo, // 10P
      ZodiacSign.cancer, // 11P
      ZodiacSign.gemini, // 12P — the 7th, kept
    ];
    for (var h = 1; h <= 12; h++) {
      expect(padas[h - 1].house, h);
      expect(padas[h - 1].sign, expected[h - 1], reason: '${h}P');
    }
    expect(padas.first.label, 'Arudha Lagna (1P)');
    expect(padas.last.code, '12P');

    // Lord in its own sign → the house itself is the pada.
    final own = arudhaPadasFromLagna(
        ZodiacSign.aries, (lord) => ZodiacSign.aries.lord == lord
            ? ZodiacSign.aries
            : lordSigns[lord] ?? ZodiacSign.aries);
    expect(own.first.sign, ZodiacSign.aries);
  });

  test('yoga engine phase 1: reference chart', () {
    // Capricorn lagna; Sa+Ju Virgo, Su/Me/Ma/Ve Pisces, Mo Taurus,
    // Ra Cancer, Ke Capricorn (the PL validation chart). Cross-checked
    // by hand: 6 Raj pairs, Yogakaraka Venus, Khala Parivartana
    // (Me↔Ju, houses 3/9), 5 Dhana links, Budha-Aditya — and none of
    // vipreet / neecha bhanga / mahapurusha / doshas.
    PlanetPosition at(Planet p, double lon) =>
        PlanetPosition(planet: p, longitude: lon, latitude: 0, speed: 1);
    final positions = {
      Planet.sun: at(Planet.sun, 340),
      Planet.moon: at(Planet.moon, 40),
      Planet.mars: at(Planet.mars, 341),
      Planet.mercury: at(Planet.mercury, 342),
      Planet.jupiter: at(Planet.jupiter, 155),
      Planet.venus: at(Planet.venus, 343),
      Planet.saturn: at(Planet.saturn, 156),
      Planet.rahu: at(Planet.rahu, 100),
      Planet.ketu: at(Planet.ketu, 280),
    };
    final yogas = detectYogas(positions: positions, ascendant: 275);
    List<DetectedYoga> byCode(String c) =>
        yogas.where((y) => y.code == c).toList();

    expect(byCode('raj_yoga').length, 6);
    expect(byCode('yogakaraka').single.participants, [Planet.venus]);
    final khala = byCode('parivartana_khala').single;
    expect(khala.participants.toSet(), {Planet.mercury, Planet.jupiter});
    expect(byCode('dhana_yoga').length, 5);
    expect(byCode('budha_aditya').length, 1);
    // Phase 2/3: lonely Moon (nothing in 2nd/12th/kendra from Taurus
    // Moon, Moon not in a lagna kendra) and Kahala (4th lord Mars
    // conjunct 9th lord Mercury, lagna lord Saturn unafflicted).
    expect(byCode('kemadruma').length, 1);
    final kahala = byCode('kahala_yoga').single;
    expect(kahala.participants.toSet(), {Planet.mars, Planet.mercury});
    for (final absent in [
      'harsha', 'sarala', 'vimala', 'neecha_bhanga', 'gaja_kesari',
      'chandra_mangala', 'mangal_dosha', 'kaal_sarp', 'kaal_sarp_partial',
      'ruchaka', 'bhadra', 'hamsa', 'malavya', 'shasha',
      'parivartana_maha', 'parivartana_dainya', 'sunapha', 'anapha',
      'durudhara', 'vesi', 'vasi', 'ubhayachari', 'adhi_yoga', 'amala',
      'shakata', 'lakshmi_yoga', 'saraswati_yoga', 'parvata_yoga',
      'rajju_yoga', 'musala_yoga', 'nala_yoga', 'guru_chandal',
      'vish_yoga', 'grahan_dosha', 'angarak_dosha',
    ]) {
      expect(byCode(absent), isEmpty, reason: absent);
    }
    expect(yogas.length, 16);
    // Every yoga carries participants for the dasha-active filter.
    expect(yogas.every((y) => y.participants.isNotEmpty), true);
  });

  test('28-nakshatra scheme: Abhijit boundaries', () {
    expect(Nakshatra28.fromLongitude(0), 0); // Ashwini
    expect(Nakshatra28.fromLongitude(276), 20); // Uttara Ashadha
    expect(Nakshatra28.fromLongitude(279), 21); // Abhijit
    expect(Nakshatra28.fromLongitude(280.9), 22); // Shravana
    expect(Nakshatra28.fromLongitude(293.4), 23); // Dhanishta
    expect(Nakshatra28.fromLongitude(359), 27); // Revati
    expect(Nakshatra28.countFrom(21, 21), 1);
    expect(Nakshatra28.countFrom(27, 0), 2);
  });

  test('kota chakra: classical ring membership', () {
    const stambha = {4, 11, 18, 25};
    const madhya = {3, 5, 10, 12, 17, 19, 24, 26};
    const prakara = {2, 6, 9, 13, 16, 20, 23, 27};
    const bahya = {1, 7, 8, 14, 15, 21, 22, 28};
    for (var off = 1; off <= 28; off++) {
      final expected = stambha.contains(off)
          ? KotaRing.stambha
          : madhya.contains(off)
              ? KotaRing.madhya
              : prakara.contains(off)
                  ? KotaRing.prakara
                  : KotaRing.bahya;
      expect(kotaRing(off), expected, reason: 'offset $off');
    }
    // Entry path = first four of each direction group.
    expect(kotaIsEntry(1), true);
    expect(kotaIsEntry(4), true);
    expect(kotaIsEntry(5), false);
    expect(kotaIsEntry(7), false);
  });

  test('sarvatobhadra: grid integrity and Punarvasu vedha', () {
    // All 28 nakshatras and 12 rashis present exactly once.
    expect(sbcNakCell.length, 28);
    expect(sbcRashiCell.length, 12);

    // The published example (P.V.R. Narasimha Rao): Saturn in
    // Punarvasu (right border) → across row hits ha, Cancer, au,
    // Mon/Wed·Bhadra, am, Scorpio, ya, Mula; the rear diagonal hits
    // ka, Taurus, Aries, da, P.Bhadrapada; the forward diagonal hits
    // Da, ma, U.Phalguni.
    final punarvasu = sbcNakCell[6]!; // (5,8)
    expect(punarvasu, (5, 8));
    final cells = sbcVedhaCells(punarvasu);
    String at((int, int) rc) => sbcGrid[rc.$1][rc.$2].display();
    final labels = cells.map(at).toList();
    for (final want in [
      'ha', 'au', 'ya', 'Mul', // across row
      'ka', 'Tau', 'Ari', 'da', 'PBh', // rear diagonal
      'Da', 'ma', 'UPh', // forward diagonal
    ]) {
      expect(labels, contains(want));
    }
    // Vedha never includes the origin cell.
    expect(cells, isNot(contains(punarvasu)));
  });

  test('special lagnas: Indu, Sree and time-based rates', () {
    // Capricorn lagna (275°), Moon in Taurus at 41°.
    final snapshot = AstroSnapshot(
      birth: BirthData(
        dateTimeUtc: DateTime.utc(2000),
        latitude: 0,
        longitude: 0,
        timezoneName: 'UTC',
        utcOffsetMinutes: 0,
      ),
      ayanamsaId: 1,
      ayanamsaValue: 24,
      positions: const {
        Planet.moon: PlanetPosition(
            planet: Planet.moon, longitude: 41, latitude: 0, speed: 13),
      },
      ascendant: 275,
      houseCusps: const [],
      panchang: computePanchang(
          sunLongitude: 0, moonLongitude: 41, localDateTime: DateTime(2000)),
      yogas: const [],
    );

    // Indu: 9th from Cap = Virgo → Mercury (8 kalas); 9th from Taurus
    // = Capricorn → Saturn (1). 8+1=9 → 9th from Moon sign = Capricorn.
    expect(induLagnaSign(snapshot), ZodiacSign.capricorn);

    // Sree: Moon 41° → 1° into its nakshatra (span 13°20'), fraction
    // 0.075 → 275 + 27 = 302° (Aquarius).
    expect(sreeLagnaLongitude(snapshot), closeTo(302.0, 0.01));

    // Rates: 6 hours (0.25 day) after a sunrise with Sun at 100°.
    expect(bhavaLagnaLongitude(sunAtSunrise: 100, daysSinceSunrise: 0.25),
        closeTo(190, 1e-9)); // 360°/day
    expect(horaLagnaLongitude(sunAtSunrise: 100, daysSinceSunrise: 0.25),
        closeTo(280, 1e-9)); // 720°/day
    expect(ghatiLagnaLongitude(sunAtSunrise: 100, daysSinceSunrise: 0.25),
        closeTo(190, 1e-9)); // 1800°/day → 450° ≡ 190°
  });

  test('whole-sign house counting from lagna', () {
    // Lagna in Leo (120–150). A planet at 200° (Libra) = 3rd house.
    final snapshot = AstroSnapshot(
      birth: BirthData(
        dateTimeUtc: DateTime.utc(2000),
        latitude: 0,
        longitude: 0,
        timezoneName: 'UTC',
        utcOffsetMinutes: 0,
      ),
      ayanamsaId: 1,
      ayanamsaValue: 24,
      positions: const {},
      ascendant: 125,
      houseCusps: const [],
      panchang: computePanchang(
          sunLongitude: 0, moonLongitude: 0, localDateTime: DateTime(2000)),
      yogas: const [],
    );
    expect(snapshot.houseOf(200), 3);
    expect(snapshot.houseOf(125), 1);
    expect(snapshot.houseOf(95), 12);
  });
}

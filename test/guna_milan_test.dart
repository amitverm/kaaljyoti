// Ashtakoota Guna Milan pure-function tests. Reference values are the
// classical named-table rules as printed in two Hindi references
// checked page-by-page against scans: "Saral Jyotish" (Book S,
// pp.143–152) and "Saral Asht-Koot Milan" / Future Point (Book F,
// chapters 3–10). All tables use rows = bride, columns = groom. The
// golden end-to-end pair is cross-checked against a Parashara's Light
// screenshot. See guna_milan.dart's header for sourcing.
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/guna_milan.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/core/astro/panchang.dart';

void main() {
  group('varnaKoota', () {
    test('varna labels by element (Book S p.147, Book F p.7)', () {
      // Water = Brahmin, Fire = Kshatriya, Earth = Vaishya, Air = Shudra.
      expect(varnaNameOf(ZodiacSign.cancer), 'Brahmin');
      expect(varnaNameOf(ZodiacSign.aries), 'Kshatriya');
      expect(varnaNameOf(ZodiacSign.taurus), 'Vaishya'); // earth
      expect(varnaNameOf(ZodiacSign.aquarius), 'Shudra'); // air
    });
    test('groom Varna >= bride Varna scores 1', () {
      // Taurus (Vaishya) bride, Cancer (Brahmin) groom.
      expect(varnaKoota(ZodiacSign.taurus, ZodiacSign.cancer), 1);
      // Equal Varna also scores 1 (both Kshatriya).
      expect(varnaKoota(ZodiacSign.aries, ZodiacSign.leo), 1);
    });
    test('groom Varna < bride Varna scores 0', () {
      // Cancer (Brahmin) bride, Taurus (Vaishya) groom.
      expect(varnaKoota(ZodiacSign.cancer, ZodiacSign.taurus), 0);
      // Virgo (Vaishya) bride, Aquarius (Shudra) groom.
      expect(varnaKoota(ZodiacSign.virgo, ZodiacSign.aquarius), 0);
    });
  });

  group('vashyaKoota', () {
    test('same group scores the diagonal (self) value', () {
      expect(
        vashyaKoota(ZodiacSign.gemini, 10, ZodiacSign.virgo, 10),
        2, // both Manav
      );
    });
    test('Leo x Leo (Vanchar/self) scores full 2', () {
      expect(vashyaKoota(ZodiacSign.leo, 5, ZodiacSign.leo, 20), 2);
    });
    test('Book F p.10 chakra half-points', () {
      // Chatushpad bride (Aries) x Vanchar groom (Leo) = 0.5.
      expect(vashyaKoota(ZodiacSign.aries, 5, ZodiacSign.leo, 5), 0.5);
      // Manav bride (Gemini) x Jalchar groom (Cancer) = 0.5.
      expect(vashyaKoota(ZodiacSign.gemini, 5, ZodiacSign.cancer, 5), 0.5);
      // Manav bride (Gemini) x Vanchar groom (Leo) = 0 (Manav row, Vanchar col).
      expect(vashyaKoota(ZodiacSign.gemini, 5, ZodiacSign.leo, 5), 0);
    });
    test('Capricorn degree split: <15 quadruped, >=15 jalachara', () {
      expect(vashyaGroupOf(ZodiacSign.capricorn, 10), VashyaGroup.quadruped);
      expect(vashyaGroupOf(ZodiacSign.capricorn, 20), VashyaGroup.jalachara);
    });
    test('Sagittarius degree split (Book F): <15 human, >=15 quadruped', () {
      expect(vashyaGroupOf(ZodiacSign.sagittarius, 10), VashyaGroup.human);
      expect(vashyaGroupOf(ZodiacSign.sagittarius, 20), VashyaGroup.quadruped);
    });
  });

  group('taraKoota', () {
    test(
        'bride Ashwini -> groom Rohini: bride-to-groom count = 4 (Kshema, auspicious)',
        () {
      // Ashwini(0) -> Rohini(3): count = 4, tara = 4 (Kshema) - favorable.
      // (Reverse direction, groom->bride, wraps to tara 7 = Vadha,
      // unfavorable, so overall this pair scores 1.5 not the full 3 —
      // see the doc comment on taraKoota for the counting convention.)
      final score = taraKoota(Nakshatra.ashwini, Nakshatra.rohini);
      expect(score, 1.5);
    });
    test('same nakshatra: count=1 both ways (Janma), always favorable', () {
      expect(taraKoota(Nakshatra.pushya, Nakshatra.pushya), 3);
    });
    test('taraKoota only ever returns 0, 1.5 or 3', () {
      for (final a in Nakshatra.values) {
        for (final b in Nakshatra.values) {
          final s = taraKoota(a, b);
          expect(s == 0 || s == 1.5 || s == 3, true);
        }
      }
    });
  });

  group('yoniKoota', () {
    test('same Yoni (self pair) scores full 4', () {
      expect(yoniKoota(Nakshatra.ashwini, Nakshatra.shatabhisha), 4);
      expect(yoniOf(Nakshatra.ashwini), Yoni.horse);
      expect(yoniOf(Nakshatra.rohini), Yoni.serpent);
      expect(yoniOf(Nakshatra.ardra), Yoni.dog);
      expect(yoniOf(Nakshatra.magha), Yoni.rat);
    });
    test('bride Horse x groom Serpent = 2 (Book S p.150, Parashara match)', () {
      // Ashwini = Horse, Rohini = Serpent.
      expect(yoniKoota(Nakshatra.ashwini, Nakshatra.rohini), 2);
    });
    test('book worked example: bride Elephant x groom Mongoose = 2', () {
      // Bharani = Elephant, uttaraAshadha = Mongoose.
      expect(yoniOf(Nakshatra.bharani), Yoni.elephant);
      expect(yoniOf(Nakshatra.uttaraAshadha), Yoni.mongoose);
      expect(yoniKoota(Nakshatra.bharani, Nakshatra.uttaraAshadha), 2);
    });
    test('asymmetric pair implemented as printed (Deer/Lion)', () {
      // Deer = Jyeshtha, Lion = purvaBhadrapada.
      expect(yoniOf(Nakshatra.jyeshtha), Yoni.deer);
      expect(yoniOf(Nakshatra.purvaBhadrapada), Yoni.lion);
      // Deer-bride x Lion-groom = 3, but Lion-bride x Deer-groom = 1.
      expect(yoniKoota(Nakshatra.jyeshtha, Nakshatra.purvaBhadrapada), 3);
      expect(yoniKoota(Nakshatra.purvaBhadrapada, Nakshatra.jyeshtha), 1);
    });
    test('enemy pair scores 0 (Cat/Rat, both directions)', () {
      // Cat = ashlesha, Rat = magha.
      expect(yoniOf(Nakshatra.ashlesha), Yoni.cat);
      expect(yoniKoota(Nakshatra.ashlesha, Nakshatra.magha), 0);
      expect(yoniKoota(Nakshatra.magha, Nakshatra.ashlesha), 0);
    });
    test('every Yoni scores its max (4) against itself', () {
      for (final y in Yoni.values) {
        final n1 = Nakshatra.values.firstWhere((n) => yoniOf(n) == y);
        expect(yoniKoota(n1, n1), 4);
      }
    });
  });

  group('grahaMaitriKoota', () {
    test('same rasi lord scores full 5', () {
      // Aries & Scorpio: both Mars-ruled.
      expect(grahaMaitriKoota(ZodiacSign.aries, ZodiacSign.scorpio), 5);
    });
    test('mutual friends score 5', () {
      // Leo (Sun) & Cancer (Moon): mutual friends.
      expect(grahaMaitriKoota(ZodiacSign.leo, ZodiacSign.cancer), 5);
    });
    test('one-way friendship (friend + neutral) scores 4', () {
      // Cancer (Moon) & Scorpio (Mars): Mars->Moon friend, Moon->Mars neutral.
      expect(grahaMaitriKoota(ZodiacSign.cancer, ZodiacSign.scorpio), 4);
    });
    test('friend + enemy scores 1', () {
      // Cancer (Moon) & Virgo (Mercury): Moon->Mercury friend,
      // Mercury->Moon enemy.
      expect(grahaMaitriKoota(ZodiacSign.cancer, ZodiacSign.virgo), 1);
    });
    test('neutral + enemy scores 0.5', () {
      // Cancer (Moon) & Capricorn (Saturn): Moon->Saturn neutral,
      // Saturn->Moon enemy. (NB: the orchestrator's Leo x Capricorn
      // example is mutual-enemy = 0 in this codebase's classical table,
      // so Cancer x Capricorn is used for the neutral+enemy case.)
      expect(grahaMaitriKoota(ZodiacSign.cancer, ZodiacSign.capricorn), 0.5);
    });
    test('mutual enemies score 0', () {
      // Leo (Sun) & Libra (Venus): Sun-Venus mutual enemies.
      expect(grahaMaitriKoota(ZodiacSign.leo, ZodiacSign.libra), 0);
    });
  });

  group('ganaKoota', () {
    test('same Gana scores 6', () {
      expect(
          ganaKoota(Nakshatra.ashwini, Nakshatra.mrigashira), 6); // both Deva
      expect(ganaOf(Nakshatra.ashwini), Gana.deva);
      expect(ganaOf(Nakshatra.rohini), Gana.manushya);
      expect(ganaOf(Nakshatra.krittika), Gana.rakshasa);
    });
    test('Deva bride + Manushya groom scores 5, reverse scores 6', () {
      expect(ganaKoota(Nakshatra.ashwini, Nakshatra.rohini), 5);
      expect(ganaKoota(Nakshatra.rohini, Nakshatra.ashwini), 6);
    });
    test('Deva/Rakshasa scores 1 either direction', () {
      expect(ganaKoota(Nakshatra.ashwini, Nakshatra.krittika), 1);
      expect(ganaKoota(Nakshatra.krittika, Nakshatra.ashwini), 1);
    });
    test('Manushya/Rakshasa scores 0 either direction', () {
      expect(ganaKoota(Nakshatra.rohini, Nakshatra.krittika), 0);
      expect(ganaKoota(Nakshatra.krittika, Nakshatra.rohini), 0);
    });
  });

  group('bhakootKoota', () {
    test('benefic distances (1,3,4,7,10,11) score full 7', () {
      expect(bhakootKoota(ZodiacSign.aries, ZodiacSign.aries), 7); // dist 1
      expect(bhakootKoota(ZodiacSign.aries, ZodiacSign.gemini), 7); // dist 3
      expect(bhakootKoota(ZodiacSign.aries, ZodiacSign.libra), 7); // dist 7
    });
    test('dosha distances (2,5,6,8,9,12) score 0', () {
      expect(bhakootKoota(ZodiacSign.aries, ZodiacSign.taurus), 0); // dist 2
      expect(bhakootKoota(ZodiacSign.aries, ZodiacSign.leo), 0); // dist 5
      expect(bhakootKoota(ZodiacSign.aries, ZodiacSign.virgo), 0); // dist 6
    });
  });

  group('nadiKoota', () {
    test('same Nadi (dosha) scores 0', () {
      expect(nadiOf(Nakshatra.ashwini), Nadi.adi);
      expect(nadiOf(Nakshatra.ardra), Nadi.adi);
      expect(nadiKoota(Nakshatra.ashwini, Nakshatra.ardra), 0);
    });
    test('different Nadi scores full 8', () {
      expect(nadiOf(Nakshatra.bharani), Nadi.madhya);
      expect(nadiKoota(Nakshatra.ashwini, Nakshatra.bharani), 8);
    });
  });

  group('computeGunaMilan golden end-to-end', () {
    // Girl Moon Ashwini (Aries), boy Moon Rohini (Taurus) — the pair on
    // the user's Parashara's Light "9" screenshot. Expected per-koota:
    // varna 0, vashya 2, tara 1.5, yoni 2, maitri 3, gana 5, bhakoot 0,
    // nadi 8, TOTAL 21.5.
    AstroSnapshot snap(double moonLong) => AstroSnapshot(
          birth: BirthData(
            dateTimeUtc: DateTime.utc(1990, 1, 1, 6),
            latitude: 28.6,
            longitude: 77.2,
            timezoneName: 'Asia/Kolkata',
            utcOffsetMinutes: 330,
          ),
          ayanamsaId: 1,
          ayanamsaValue: 24.1,
          positions: {
            // Moon drives every koota; Mars is only read by the Mangal
            // Dosha check (not asserted here) — kept out of the doshic
            // houses from the Moon so it doesn't matter.
            Planet.moon: PlanetPosition(
                planet: Planet.moon,
                longitude: moonLong,
                latitude: 0,
                speed: 1),
            Planet.mars: const PlanetPosition(
                planet: Planet.mars, longitude: 200, latitude: 0, speed: 1),
          },
          ascendant: 0,
          houseCusps: List.filled(12, 0.0),
          panchang: computePanchang(
              sunLongitude: 10,
              moonLongitude: moonLong,
              localDateTime: DateTime(1990)),
          yogas: const [],
        );

    test('per-koota and total match the Parashara reference', () {
      // Ashwini is 0–13.333° (Aries); Rohini is 40–53.333° (Taurus).
      final bride = snap(5); // Moon 5° = Aries, Ashwini
      final groom = snap(45); // Moon 45° = Taurus, Rohini
      final result = computeGunaMilan(bride, groom);

      double pts(Koota k) =>
          result.kootas.firstWhere((s) => s.koota == k).points;

      expect(pts(Koota.varna), 0);
      expect(pts(Koota.vashya), 2);
      expect(pts(Koota.tara), 1.5);
      expect(pts(Koota.yoni), 2);
      expect(pts(Koota.grahaMaitri), 3);
      expect(pts(Koota.gana), 5);
      expect(pts(Koota.bhakoot), 0);
      expect(pts(Koota.nadi), 8);
      expect(result.total, 21.5);
    });
  });

  group('GunaMilanResult.verdict', () {
    const kootas = [
      KootaScore(koota: Koota.varna, points: 0, maxPoints: 1),
    ];
    GunaMilanResult withTotal(double total) {
      // Build a synthetic result whose kootas sum to `total`.
      return GunaMilanResult(
        kootas: [
          KootaScore(koota: Koota.varna, points: total, maxPoints: 36),
        ],
        brideMangalDosha: false,
        groomMangalDosha: false,
      );
    }

    test('bands match the handoff spec', () {
      expect(withTotal(17).verdict, GunaVerdict.notRecommended);
      expect(withTotal(18).verdict, GunaVerdict.average);
      expect(withTotal(24).verdict, GunaVerdict.average);
      expect(withTotal(25).verdict, GunaVerdict.good);
      expect(withTotal(32).verdict, GunaVerdict.good);
      expect(withTotal(33).verdict, GunaVerdict.excellent);
      expect(withTotal(36).verdict, GunaVerdict.excellent);
    });
    test('maxTotal is 36', () {
      expect(GunaMilanResult.maxTotal, 36);
      expect(kootas.length, 1); // sanity: fixture compiles/unused-safe
    });
  });
}

/// The janma-nakshatra attribute lookups: the Vimshottari star lord,
/// the presiding deity and symbol, and the Ashtakoota tables (Gana /
/// Yoni / Nadi / Varna) read as chart attributes rather than as match
/// scores.
///
/// The deity/symbol enums pair with [Nakshatra] POSITIONALLY, so the
/// spot checks below deliberately sample the ends and the middle — an
/// off-by-one anywhere in a 27-entry list moves every later entry.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/guna_milan.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/core/astro/nakshatra_attrs.dart';

void main() {
  group('the Vimshottari star lord cycle', () {
    test('repeats Ketu → … → Mercury from Ashwini', () {
      expect(Nakshatra.ashwini.lord, Planet.ketu);
      expect(Nakshatra.bharani.lord, Planet.venus);
      expect(Nakshatra.krittika.lord, Planet.sun);
      expect(Nakshatra.rohini.lord, Planet.moon);
      expect(Nakshatra.revati.lord, Planet.mercury);
    });

    test('the cycle restarts at Magha and again at Mula', () {
      // Indices 9 and 18 — both 0 mod 9, so both return to Ketu.
      expect(Nakshatra.magha.lord, Planet.ketu);
      expect(Nakshatra.mula.lord, Planet.ketu);
    });

    test('every nakshatra has a lord, nine of each', () {
      final counts = <Planet, int>{};
      for (final n in Nakshatra.values) {
        counts[n.lord] = (counts[n.lord] ?? 0) + 1;
      }
      expect(counts.length, 9);
      expect(counts.values.every((c) => c == 3), isTrue);
    });
  });

  group('deities and symbols', () {
    test('both enums are exactly as long as the nakshatra list', () {
      // The lookups index by [Nakshatra.index]; a short list would be a
      // range error on the last nakshatra and nothing before it.
      expect(NakshatraDeity.values.length, Nakshatra.values.length);
      expect(NakshatraSymbol.values.length, Nakshatra.values.length);
    });

    test('the classical pairings hold at both ends and the middle', () {
      expect(deityOf(Nakshatra.ashwini), NakshatraDeity.ashwiniKumaras);
      expect(deityOf(Nakshatra.bharani), NakshatraDeity.yama);
      expect(deityOf(Nakshatra.magha), NakshatraDeity.pitris);
      expect(deityOf(Nakshatra.jyeshtha), NakshatraDeity.indra);
      expect(deityOf(Nakshatra.shravana), NakshatraDeity.vishnu);
      expect(deityOf(Nakshatra.revati), NakshatraDeity.pushan);

      expect(symbolOf(Nakshatra.ashwini), NakshatraSymbol.horseHead);
      expect(symbolOf(Nakshatra.rohini), NakshatraSymbol.cart);
      expect(symbolOf(Nakshatra.hasta), NakshatraSymbol.hand);
      expect(symbolOf(Nakshatra.shatabhisha), NakshatraSymbol.emptyCircle);
      expect(symbolOf(Nakshatra.revati), NakshatraSymbol.fish);
    });

    test('every nakshatra resolves both', () {
      for (final n in Nakshatra.values) {
        expect(deityOf(n), isNotNull);
        expect(symbolOf(n), isNotNull);
      }
    });
  });

  group('the Ashtakoota attribute tables', () {
    test('every nakshatra has a Gana, a Yoni and a Nadi', () {
      // The three tables are maps with a `!` lookup — a missing entry is
      // a null-check crash on exactly one chart, which is the kind of
      // gap only a full sweep finds.
      for (final n in Nakshatra.values) {
        expect(() => ganaOf(n), returnsNormally, reason: n.displayName);
        expect(() => yoniOf(n), returnsNormally, reason: n.displayName);
        expect(() => nadiOf(n), returnsNormally, reason: n.displayName);
      }
    });

    test('the nakshatra attribute spot checks match the printed tables', () {
      expect(ganaOf(Nakshatra.ashwini), Gana.deva);
      expect(ganaOf(Nakshatra.bharani), Gana.manushya);
      expect(ganaOf(Nakshatra.krittika), Gana.rakshasa);

      expect(yoniOf(Nakshatra.ashwini), Yoni.horse);
      expect(yoniOf(Nakshatra.uttaraAshadha), Yoni.mongoose);

      expect(nadiOf(Nakshatra.ashwini), Nadi.adi);
      expect(nadiOf(Nakshatra.bharani), Nadi.madhya);
      expect(nadiOf(Nakshatra.krittika), Nadi.antya);
    });

    test('Varna is read from the Moon SIGN, by element', () {
      // Water = Brahmin (4) … air = Shudra (1); the rank is what the
      // display helper indexes, so it has to stay 1-based.
      expect(varnaRankOf(ZodiacSign.cancer), 4);
      expect(varnaRankOf(ZodiacSign.aries), 3);
      expect(varnaRankOf(ZodiacSign.taurus), 2);
      expect(varnaRankOf(ZodiacSign.gemini), 1);
      for (final s in ZodiacSign.values) {
        expect(varnaRankOf(s), inInclusiveRange(1, 4));
      }
    });
  });
}

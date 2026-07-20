/// Tri-Pataki golden tests — both of Charak's worked charts (ch. VIII):
/// the Example Chart's 41st year (Fig. VIII-2, Scorpio varsha lagna)
/// and 47th year (Fig. VIII-3, Gemini varsha lagna). Natal signs per
/// the book: Moon Leo, Sun/Mercury/Jupiter/Venus Leo, Saturn Gemini,
/// Mars Virgo, Rahu Cancer, Ketu Capricorn.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/core/astro/tripataki.dart';

const natal = <Planet, ZodiacSign>{
  Planet.sun: ZodiacSign.leo,
  Planet.moon: ZodiacSign.leo,
  Planet.mars: ZodiacSign.virgo,
  Planet.mercury: ZodiacSign.leo,
  Planet.jupiter: ZodiacSign.leo,
  Planet.venus: ZodiacSign.leo,
  Planet.saturn: ZodiacSign.gemini,
  Planet.rahu: ZodiacSign.cancer,
  Planet.ketu: ZodiacSign.capricorn,
};

void main() {
  test('41st year (Fig. VIII-2): placements and the narrated vedhas', () {
    final d = tripataki(
        varshaLagna: ZodiacSign.scorpio, natalSigns: natal, currentYear: 41);
    // Placements per the figure: Moon Sag, Su/Me/Ju/Ve Leo, Sat Gemini,
    // Mars Capricorn, Rahu Pisces, Ketu Virgo.
    expect(tripatakiProgressedSign(Planet.moon, ZodiacSign.leo, 41),
        ZodiacSign.sagittarius);
    expect(tripatakiProgressedSign(Planet.sun, ZodiacSign.leo, 41),
        ZodiacSign.leo);
    expect(tripatakiProgressedSign(Planet.mars, ZodiacSign.virgo, 41),
        ZodiacSign.capricorn);
    expect(tripatakiProgressedSign(Planet.rahu, ZodiacSign.cancer, 41),
        ZodiacSign.pisces);
    expect(tripatakiProgressedSign(Planet.ketu, ZodiacSign.capricorn, 41),
        ZodiacSign.virgo);

    // Book: "the Moon has the vedha caused by an exalted Mars".
    expect(d.vedhaToMoon, contains(Planet.mars));
    // Book: "The lagna has the vedha caused by the Sun … along with the
    // three benefics Mercury, Jupiter and Venus."
    final lagnaVedha = d.vedhaToLagna.toSet();
    expect(
        lagnaVedha.containsAll(
            {Planet.sun, Planet.mercury, Planet.jupiter, Planet.venus}),
        true,
        reason: '$lagnaVedha');
  });

  test('47th year (Fig. VIII-3): lagna and Moon both hit by the nodes', () {
    final d = tripataki(
        varshaLagna: ZodiacSign.gemini, natalSigns: natal, currentYear: 47);
    // Placements per the figure: Moon Virgo (with Ketu), Sat Leo,
    // Su/Me/Ju/Ve Libra, Mars Capricorn, Rahu Pisces.
    expect(tripatakiProgressedSign(Planet.moon, ZodiacSign.leo, 47),
        ZodiacSign.virgo);
    expect(tripatakiProgressedSign(Planet.saturn, ZodiacSign.gemini, 47),
        ZodiacSign.leo);
    expect(tripatakiProgressedSign(Planet.sun, ZodiacSign.leo, 47),
        ZodiacSign.libra);
    expect(tripatakiProgressedSign(Planet.ketu, ZodiacSign.capricorn, 47),
        ZodiacSign.virgo);
    expect(tripatakiProgressedSign(Planet.rahu, ZodiacSign.cancer, 47),
        ZodiacSign.pisces);

    // Book: "The ascendant and the Moon are both under the vedha caused
    // by Rahu and Ketu, without any relief from benefics."
    final lagnaVedha = d.vedhaToLagna.toSet();
    expect(lagnaVedha.containsAll({Planet.rahu, Planet.ketu}), true,
        reason: '$lagnaVedha');
    expect(
        lagnaVedha.intersection(
            {Planet.jupiter, Planet.venus, Planet.mercury}).isEmpty,
        true,
        reason: '$lagnaVedha');
    final moonVedha = d.vedhaToMoon.toSet();
    expect(moonVedha.containsAll({Planet.rahu, Planet.ketu}), true,
        reason: '$moonVedha');
  });

  test('vedha partner map is symmetric', () {
    for (var p = 0; p < 12; p++) {
      for (final q in tripatakiPartners[p]) {
        expect(tripatakiPartners[q], contains(p), reason: '$p↔$q');
      }
    }
  });
}

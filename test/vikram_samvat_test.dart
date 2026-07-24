// Purnimanta must not rename adhik months. computeVikramMasa is fully
// ephemeris-driven (no headless FFI), so these pin the pure naming rule
// it delegates to — resolveMonthIndex — with the DrikPanchang-verified
// Adhika Shravana 2023 case (Shravana = month index 4). A regular
// Krishna-paksha month must still bump under purnimanta.
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/vikram_samvat.dart';

void main() {
  const shravana = 4; // Chaitra = 0 … Shravana = 4 … Phalguna = 11.

  group('resolveMonthIndex — adhik months keep their name', () {
    test('Adhika Shravana Krishna paksha stays Shravana under purnimanta', () {
      expect(
        resolveMonthIndex(shravana,
            krishnaPaksha: true, isAdhik: true, system: MasaSystem.purnimanta),
        shravana,
      );
    });

    test('Adhika Shravana Krishna paksha stays Shravana under amanta', () {
      expect(
        resolveMonthIndex(shravana,
            krishnaPaksha: true, isAdhik: true, system: MasaSystem.amanta),
        shravana,
      );
    });
  });

  group('resolveMonthIndex — non-adhik purnimanta still bumps', () {
    test('regular Shravana Krishna paksha bumps to Bhadrapada (5)', () {
      expect(
        resolveMonthIndex(shravana,
            krishnaPaksha: true, isAdhik: false, system: MasaSystem.purnimanta),
        5,
      );
    });

    test('purnimanta Shukla paksha is never bumped', () {
      expect(
        resolveMonthIndex(shravana,
            krishnaPaksha: false, isAdhik: false, system: MasaSystem.purnimanta),
        shravana,
      );
    });

    test('amanta never bumps regardless of paksha', () {
      expect(
        resolveMonthIndex(shravana,
            krishnaPaksha: true, isAdhik: false, system: MasaSystem.amanta),
        shravana,
      );
    });

    test('wraps Phalguna (11) Krishna paksha to Chaitra (0)', () {
      expect(
        resolveMonthIndex(11,
            krishnaPaksha: true, isAdhik: false, system: MasaSystem.purnimanta),
        0,
      );
    });
  });
}

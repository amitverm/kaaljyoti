/// Chalit house math — the pure midpoint/assignment rules (the madhyas
/// themselves come from the ephemeris and are exercised on device).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/chalit.dart';

void main() {
  test('circular midpoint, including the 360° wrap', () {
    expect(circularMidpoint(10, 30), 20);
    expect(circularMidpoint(350, 10), 0); // wraps through 0°
    expect(circularMidpoint(300, 20), 340);
  });

  test('equal-house madhyas reduce to the "madhya + 15° = next sandhi" rule',
      () {
    // Lagna at 17.3° Taurus → madhyas at 47.3, 77.3, … (Equal system).
    final madhya = [for (var i = 0; i < 12; i++) (47.3 + 30.0 * i) % 360];
    final sandhi = sandhisFromMadhyas(madhya);
    for (var i = 0; i < 12; i++) {
      // Start of the NEXT house = this house's madhya + 15°. Compare as
      // a circular distance — a raw % of a float epsilon flips to ~360.
      final next = sandhi[(i + 1) % 12];
      final dd = ((next - (madhya[i] + 15)) % 360 + 360) % 360;
      final circular = dd > 180 ? 360 - dd : dd;
      expect(circular < 1e-9, true, reason: 'house ${i + 1} (off by $dd°)');
    }
  });

  test('sandhis are midpoints of neighbouring madhyas', () {
    // Equal 30°-spaced madhyas starting at 15° → sandhis at sign
    // boundaries: house 1 runs 0°–30° centred on its 15° madhya.
    final madhya = [for (var i = 0; i < 12; i++) (15.0 + 30 * i) % 360];
    final sandhi = sandhisFromMadhyas(madhya);
    expect(sandhi[0], 0); // start of house 1 = mid(345, 15) = 0
    expect(sandhi[1], 30);
    expect(sandhi[11], 330);
  });

  test('unequal houses assign planets by sandhi span, with wrap', () {
    // Compressed daytime houses: madhyas bunch up around 100°.
    final madhya = <double>[
      80,
      95,
      105,
      115,
      130,
      160,
      200,
      240,
      275,
      300,
      330,
      30,
    ];
    final sandhi = sandhisFromMadhyas(madhya);
    // House 1 starts at mid(30°→80°)=55 and ends at mid(80°→95°)=87.5.
    expect(sandhi[0], 55);
    expect(houseOfIn(sandhi, 55), 1); // inclusive of its own start
    expect(houseOfIn(sandhi, 87.0), 1);
    expect(houseOfIn(sandhi, 87.5), 2); // exact boundary → next house
    expect(houseOfIn(sandhi, 100.0), 3);
    // House 12 (madhya 30°) starts at mid(330→30) = 0°; the 0°-wrap
    // itself falls inside house 11 (315°→0°).
    expect(houseOfIn(sandhi, 0), 12);
    expect(houseOfIn(sandhi, 54.9), 12);
    expect(houseOfIn(sandhi, 359.9), 11);
    expect(houseOfIn(sandhi, 316.0), 11);
    // Every longitude lands in exactly one house.
    for (var lon = 0.0; lon < 360; lon += 0.5) {
      final h = houseOfIn(sandhi, lon);
      expect(h >= 1 && h <= 12, true, reason: 'lon $lon → $h');
    }
  });

  test('the whole ring is covered exactly once per house', () {
    final madhya = <double>[
      80,
      95,
      105,
      115,
      130,
      160,
      200,
      240,
      275,
      300,
      330,
      30,
    ];
    final sandhi = sandhisFromMadhyas(madhya);
    // Spans of all 12 houses sum to 360°.
    var total = 0.0;
    for (var i = 0; i < 12; i++) {
      total += ((sandhi[(i + 1) % 12] - sandhi[i]) % 360 + 360) % 360;
    }
    expect((total - 360).abs() < 1e-9, true);
  });
}

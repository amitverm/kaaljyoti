// Transit scan engine tests — synthetic motion, no ephemeris/FFI.
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/core/astro/transit_scan.dart';

void main() {
  final epoch = DateTime.utc(2026, 1, 1);
  double days(DateTime t) =>
      t.difference(epoch).inSeconds / Duration.secondsPerDay;

  // Linear motion: lon = start + rate°/day.
  LongitudeAt linear(double start, double rate) =>
      (t) => (start + rate * days(t)) % 360;

  // Forward 30d, retrograde 20d, forward again — crosses 25° thrice.
  double zigzag(DateTime t) {
    final d = days(t);
    if (d <= 30) return d * 1.0; // 0 → 30
    if (d <= 50) return 30 - (d - 30) * 0.5; // 30 → 20
    return 20 + (d - 50) * 1.0; // 20 → …
  }

  test('finds direct crossings at moon speed', () {
    final f = linear(350, 13.2);
    final hits = findLongitudeCrossings(
        f, 0, epoch, epoch.add(const Duration(days: 60)));
    expect(hits.length, 3); // ~0.76d, ~28.0d, ~55.3d
    for (final h in hits) {
      // Within a minute of exact → within rate/day/1440 degrees.
      final lon = f(h);
      final err = (lon > 180 ? 360 - lon : lon).abs();
      expect(err, lessThan(0.02), reason: '$h');
    }
  });

  test('retrograde triple crossing detected in order', () {
    final hits = findLongitudeCrossings(
        zigzag, 25, epoch, epoch.add(const Duration(days: 80)));
    expect(hits.length, 3);
    expect(hits[0].isBefore(hits[1]) && hits[1].isBefore(hits[2]), true);
    for (final h in hits) {
      expect((zigzag(h) - 25).abs(), lessThan(0.02));
    }
  });

  test('no false crossing at the ±180 wrap', () {
    // Body at 100° moving 1°/day; target 280° is opposite — only a
    // genuine crossing (day ~180) may appear, no wrap artifacts.
    final f = linear(100, 1);
    final hits = findLongitudeCrossings(
        f, 280, epoch, epoch.add(const Duration(days: 200)));
    expect(hits.length, 1);
    expect(days(hits.first), closeTo(180, 0.1));
  });

  test('signOccupancy: contiguous, correct signs, retro re-entry', () {
    final occ = signOccupancy(
        zigzag, epoch, epoch.add(const Duration(days: 80)),
        step: const Duration(hours: 12));
    // 0→30 (Aries), 30→30- (Taurus briefly), retro back into Aries at
    // 30°… path: Aries [0,30d], Taurus [30d, 50d? lon 30→20 crosses 30
    // immediately]… zigzag hits exactly 30 at d=30 then descends → the
    // Taurus interval is empty; occupancy: Aries, Aries…, ends Taurus
    // after d=60 (lon 30 again) → assert invariants instead of exact
    // segmentation: contiguity + sign matches a mid-sample.
    for (var i = 0; i < occ.length; i++) {
      if (i > 0) expect(occ[i].start, occ[i - 1].end);
      final mid = occ[i].start.add(occ[i].end.difference(occ[i].start) ~/ 2);
      expect(occ[i].sign, ZodiacSign.fromLongitude(zigzag(mid)));
    }
    expect(occ.first.start, epoch);
    expect(occ.last.end, epoch.add(const Duration(days: 80)));
    // The 25° level is in Aries; the body must end in Taurus (lon 50).
    expect(occ.last.sign, ZodiacSign.taurus);
  });

  test('scanGochar: conjunction found, drishti targets honored', () {
    final events = scanGochar(
      natalPoints: const {'Moon': 101.0},
      from: epoch,
      to: epoch.add(const Duration(days: 365)),
      ayanamsaId: 1,
      planets: const [Planet.saturn],
      samplerFor: (_) => linear(100, 0.0333),
    );
    // Saturn 100→112°: stays in Cancer (90–120): no ingress. Drishti
    // targets for natal 101: conj 101 ✓, 3rd 41 ✗, 7th 281 ✗, 10th 191 ✗.
    expect(events.length, 1);
    final e = events.single;
    expect(e.kind, TransitEventKind.aspect);
    expect(e.drishti, 1);
    expect(e.natalPoint, 'Moon');
    expect(days(e.time), closeTo(30, 0.5)); // 1° at 0.0333°/day
    expect(e.label, contains('conjunct natal Moon'));
  });

  test('scanGochar ingress reports the sign actually entered', () {
    final events = scanGochar(
      natalPoints: const {},
      from: epoch,
      to: epoch.add(const Duration(days: 80)),
      ayanamsaId: 1,
      planets: const [Planet.jupiter],
      samplerFor: (_) => zigzag,
    );
    final ingresses =
        events.where((e) => e.kind == TransitEventKind.ingress).toList();
    // Crossings of 30°: d=30 (touch, enters Taurus/back), d=60 (enters
    // Taurus for good). At least the final one must say Taurus.
    expect(ingresses, isNotEmpty);
    expect(ingresses.last.sign, ZodiacSign.taurus);
  });

  test('sadeSatiPhases: Rising → Peak → Setting for Taurus Moon', () {
    // Fast fake Saturn: 1°/3 days from 355° (late Pisces).
    final phases = sadeSatiPhases(
      moonSign: ZodiacSign.taurus,
      from: epoch,
      to: epoch.add(const Duration(days: 420)),
      ayanamsaId: 1,
      saturn: linear(355, 1 / 3),
    );
    expect(phases.map((p) => p.kind).take(3).toList(), [
      SadeSatiPhaseKind.rising,
      SadeSatiPhaseKind.peak,
      SadeSatiPhaseKind.setting,
    ]);
    expect(phases[0].sign, ZodiacSign.aries);
    expect(phases[1].sign, ZodiacSign.taurus);
    expect(phases[2].sign, ZodiacSign.gemini);
    // Contiguous through the sade sati proper.
    expect(phases[1].start, phases[0].end);
    expect(phases[2].start, phases[1].end);
    // Each ~90 days at 1°/3d.
    expect(phases[1].length.inDays, closeTo(90, 3));
  });
}

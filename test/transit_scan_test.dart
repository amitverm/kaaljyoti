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

  // --- Sade Sati, degree method (±45° of the natal Moon) -------------------
  //
  // Synthetic motion only: the point of these is the geometry of the
  // 90° arc, so no ephemeris is involved anywhere below.

  group('sadeSatiDegreeWindows', () {
    List<SadeSatiDegreeWindow> scan(
      LongitudeAt f,
      double moon,
      int spanDays, {
      Duration step = const Duration(days: 5),
    }) =>
        sadeSatiDegreeWindows(
          natalMoonLon: moon,
          from: epoch,
          to: epoch.add(Duration(days: spanDays)),
          ayanamsaId: 1,
          saturn: f,
          step: step,
        );

    test('linear motion: the boundaries land at ±45° exactly', () {
      // Moon at 100°, Saturn from 0° at 1°/day: in at 55°, out at 145°.
      final f = linear(0, 1);
      final windows = scan(f, 100, 200);
      expect(windows.length, 1);
      final w = windows.single;
      expect(days(w.start), closeTo(55, 0.01));
      expect(days(w.end), closeTo(145, 0.01));
      // Not clipped — both ends are real crossings.
      expect(w.clippedStart, false);
      expect(w.clippedEnd, false);
      // The defining property, checked on the instants themselves.
      expect(sadeSatiSeparation(f(w.start), 100), closeTo(-45, 0.02));
      expect(sadeSatiSeparation(f(w.end), 100), closeTo(45, 0.02));
      // One exact conjunction, at 100° on day 100.
      expect(w.conjunctions.length, 1);
      expect(days(w.conjunctions.single), closeTo(100, 0.01));
    });

    test('a retrograde wiggle across +45° splits the window in two', () {
      // Moon at 0°. Saturn 30→50 (leaves at 45 on d15), retrogrades
      // 50→40 (re-enters at 45 on d30), then forward again (leaves for
      // good at 45 on d45).
      double wiggle(DateTime t) {
        final d = days(t);
        if (d <= 20) return 30 + d;
        if (d <= 40) return 50 - (d - 20) * 0.5;
        return 40 + (d - 40);
      }

      final windows = scan(wiggle, 0, 80);
      expect(windows.length, 2, reason: 'the retro dip re-enters the arc');
      expect(days(windows[0].start), 0); // scan range, not a crossing
      expect(windows[0].clippedStart, true);
      expect(days(windows[0].end), closeTo(15, 0.01));
      expect(days(windows[1].start), closeTo(30, 0.01));
      expect(days(windows[1].end), closeTo(45, 0.01));
      expect(windows[1].clippedEnd, false);
      // Saturn never reaches the Moon here.
      expect(windows.expand((w) => w.conjunctions), isEmpty);
    });

    test('the arc spans 0° Aries when the Moon sits just inside it', () {
      // Moon at 10° → the arc runs 325°…55°, across the wrap.
      final f = linear(300, 1);
      final windows = scan(f, 10, 120);
      expect(windows.length, 1);
      final w = windows.single;
      expect(days(w.start), closeTo(25, 0.01)); // 325°
      expect(days(w.end), closeTo(115, 0.01)); // 55°
      expect(w.conjunctions.length, 1);
      expect(days(w.conjunctions.single), closeTo(70, 0.01)); // 370° = 10°
      for (final c in w.conjunctions) {
        expect(sadeSatiSeparation(f(c), 10).abs(), lessThan(0.02));
      }
    });

    test('a retrograde triple conjunction is reported inside one window', () {
      // The shared zigzag never leaves ±45° of 25°, so the whole scan
      // is a single (clipped) window carrying all three crossings.
      final windows = scan(zigzag, 25, 80, step: const Duration(hours: 12));
      expect(windows.length, 1);
      final w = windows.single;
      expect(w.clippedStart, true);
      expect(w.clippedEnd, true);
      expect(w.conjunctions.length, 3);
      expect(days(w.conjunctions[0]), closeTo(25, 0.01));
      expect(days(w.conjunctions[1]), closeTo(40, 0.01));
      expect(days(w.conjunctions[2]), closeTo(55, 0.01));
      for (final c in w.conjunctions) {
        expect((zigzag(c) - 25).abs(), lessThan(0.02));
      }
    });

    test('the side of the Moon at entry is recorded, not inferred', () {
      // Entered at -45 degrees -> approaching.
      expect(scan(linear(0, 1), 100, 200).single.approachingAtStart, true);
      // Wrapped arc, same story: entry at 325 against a Moon at 10.
      expect(scan(linear(300, 1), 10, 120).single.approachingAtStart, true);
    });

    test('a window retrograded into from the far side is NOT approaching', () {
      // Moon at 0, Saturn wandering between 30 and 50 - every instant
      // is PAST the Moon, including the re-entry at +45. Inferring
      // "approaching before the first conjunction" would get both of
      // these backwards; the recorded flag does not.
      double wiggle(DateTime t) {
        final d = days(t);
        if (d <= 20) return 30 + d;
        if (d <= 40) return 50 - (d - 20) * 0.5;
        return 40 + (d - 40);
      }

      final windows = scan(wiggle, 0, 80);
      expect(windows.length, 2);
      expect(windows.every((w) => !w.approachingAtStart), true);
    });

    test('separation is signed and wrap-safe', () {
      expect(sadeSatiSeparation(10, 350), closeTo(20, 1e-9));
      expect(sadeSatiSeparation(350, 10), closeTo(-20, 1e-9));
      expect(sadeSatiSeparation(100, 100), closeTo(0, 1e-9));
    });
  });

  // Which side of the Moon each stretch of a passage is on. Pure over
  // the window data — no sampler — so these are constructed directly.
  group('degreeArcSpans', () {
    final base = DateTime.utc(2026, 1, 1);
    DateTime at(int d) => base.add(Duration(days: d));

    SadeSatiDegreeWindow win(
      int start,
      int end, {
      List<int> conjunctions = const [],
      bool approachingAtStart = true,
    }) =>
        SadeSatiDegreeWindow(
          start: at(start),
          end: at(end),
          conjunctions: [for (final c in conjunctions) at(c)],
          approachingAtStart: approachingAtStart,
        );

    test('one conjunction cuts a window into approaching then separating', () {
      final spans = degreeArcSpans([
        win(0, 100, conjunctions: [50])
      ]);
      expect(spans.map((s) => s.kind),
          [DegreeSpanKind.approaching, DegreeSpanKind.separating]);
      expect(spans[0].start, at(0));
      expect(spans[0].end, at(50));
      expect(spans[1].end, at(100));
    });

    test('three conjunctions alternate across the cuts', () {
      final spans = degreeArcSpans([
        win(0, 100, conjunctions: [40, 50, 60])
      ]);
      expect(spans.map((s) => s.kind), [
        DegreeSpanKind.approaching,
        DegreeSpanKind.separating,
        DegreeSpanKind.approaching,
        DegreeSpanKind.separating,
      ]);
    });

    test('a re-entry window trailing the last conjunction is separating', () {
      final spans = degreeArcSpans([
        win(0, 100, conjunctions: [40, 50, 60]),
        win(140, 200, approachingAtStart: false),
      ]);
      expect(spans.map((s) => s.kind), [
        DegreeSpanKind.approaching,
        DegreeSpanKind.separating,
        DegreeSpanKind.approaching,
        DegreeSpanKind.separating,
        DegreeSpanKind.outOfArc,
        DegreeSpanKind.separating,
      ]);
      expect(spans[4].start, at(100));
      expect(spans[4].end, at(140));
    });

    test('a conjunction-free window is one span, on the side it began', () {
      // A grazing pass that turns back before reaching the Moon...
      expect(degreeArcSpans([win(0, 30)]).map((s) => s.kind),
          [DegreeSpanKind.approaching]);
      // ...and one entered from the far side.
      expect(
          degreeArcSpans([win(0, 30, approachingAtStart: false)])
              .map((s) => s.kind),
          [DegreeSpanKind.separating]);
    });

    test('spans tile the passage end to end', () {
      final passage = [
        win(0, 100, conjunctions: [40, 60]),
        win(140, 200, approachingAtStart: false),
      ];
      final spans = degreeArcSpans(passage);
      expect(spans.first.start, passage.first.start);
      expect(spans.last.end, passage.last.end);
      for (var i = 1; i < spans.length; i++) {
        expect(spans[i].start, spans[i - 1].end);
      }
    });
  });
}

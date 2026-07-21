// Tithi span-walk tests — pure logic over synthetic buckets, no
// ephemeris/FFI. Time axis: JD 0 = this sunrise; nextRise = 1.0.
//
// tithiSpansForWindow only sees the injected bucket function, so lunar
// motion is modeled as uniform: index(t) = atRise + 1 + floor((t - firstEnd)
// / length). Real tithis run ~0.9–1.12 days; the kshaya scenario shortens
// them so a whole tithi fits inside one Vedic day, which is exactly the
// kshaya geometry (born after sunrise, gone before the next).
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/daily_panchang.dart';

void main() {
  // Anchor so JD offsets convert to readable DateTimes.
  final epoch = DateTime.utc(2026, 7, 21, 6);
  DateTime? toLocal(double? jd) => jd == null
      ? null
      : epoch.add(Duration(milliseconds: (jd * 86400000).round()));
  double jdOf(DateTime t) =>
      t.difference(epoch).inMilliseconds / 86400000;

  double Function(double) bucket({
    required int atRise,
    required double firstEnd,
    required double length,
  }) =>
      (t) => (atRise + 1 + ((t - firstEnd) / length).floor()).toDouble();

  List<TithiSpan> walk({
    required double Function(double) tithiBucket,
    int? prevSunriseTithi,
  }) =>
      tithiSpansForWindow(
        riseJd: 0,
        nextRiseJd: 1.0,
        prevSunriseTithi: prevSunriseTithi,
        tithiBucket: tithiBucket,
        toLocal: toLocal,
      );

  // Boundary search bisects to half-minute precision.
  void expectNear(DateTime? actual, double jd) {
    expect(actual, isNotNull);
    expect((jdOf(actual!) - jd).abs(), lessThan(1.5 / 1440));
  }

  group('tithiSpansForWindow', () {
    test('normal transition day: two spans, no flags', () {
      final spans = walk(
        tithiBucket: bucket(atRise: 7, firstEnd: 0.3, length: 0.95),
        prevSunriseTithi: 6,
      );
      expect(spans.length, 2);
      expect(spans[0].index, 7); // Shukla Ashtami at sunrise
      expect(spans[0].name, 'Ashtami');
      expect(spans[0].starts, isNull); // began before the window
      expectNear(spans[0].ends, 0.3);
      expect(spans[0].kshaya, isFalse);
      expect(spans[0].vriddhi, isFalse);
      expect(spans[1].index, 8);
      expectNear(spans[1].starts, 0.3);
      expectNear(spans[1].ends, 1.25); // hands over tomorrow, after rise
      expect(spans[1].kshaya, isFalse);
      expect(spans[1].vriddhi, isFalse);
    });

    test('kshaya day: three spans, only the middle one flagged', () {
      final spans = walk(
        tithiBucket: bucket(atRise: 9, firstEnd: 0.2, length: 0.6),
        prevSunriseTithi: 8,
      );
      expect(spans.length, 3);
      expect(spans.map((s) => s.index), [9, 10, 11]);
      // The middle tithi touches neither sunrise → kshaya.
      expect(spans.map((s) => s.kshaya), [false, true, false]);
      expect(spans.map((s) => s.vriddhi), [false, false, false]);
      expectNear(spans[1].starts, 0.2);
      expectNear(spans[1].ends, 0.8);
    });

    test('vriddhi day 1: one span covering the whole window', () {
      final spans = walk(
        tithiBucket: bucket(atRise: 15, firstEnd: 1.1, length: 1.12),
        prevSunriseTithi: 14,
      );
      expect(spans.length, 1);
      expect(spans[0].index, 15); // Krishna Pratipada
      expect(spans[0].paksha, 'Krishna');
      expect(spans[0].vriddhi, isTrue);
      expect(spans[0].kshaya, isFalse);
      expectNear(spans[0].ends, 1.1);
    });

    test('vriddhi day 2: sunrise tithi repeats the previous sunrise', () {
      final spans = walk(
        tithiBucket: bucket(atRise: 15, firstEnd: 0.4, length: 1.12),
        prevSunriseTithi: 15,
      );
      expect(spans.length, 2);
      expect(spans[0].index, 15);
      expect(spans[0].vriddhi, isTrue); // second day of the pair
      expect(spans[0].kshaya, isFalse);
      expect(spans[1].index, 16);
      expect(spans[1].vriddhi, isFalse);
    });

    test('unknown previous sunrise: day-2 vriddhi simply not flagged', () {
      final spans = walk(
        tithiBucket: bucket(atRise: 15, firstEnd: 0.4, length: 1.12),
        prevSunriseTithi: null,
      );
      expect(spans[0].vriddhi, isFalse);
    });

    test('Amavasya wraps to Shukla Pratipada mid-window', () {
      // Production bucket: floor(norm(moon-sun)/12) — model the
      // elongation itself so the 360°→0° wrap is exercised.
      const rate = 12 / 0.95; // deg/day
      const elong0 = 350.0; // tithi 29 (Amavasya) at sunrise
      double b(double t) => (((elong0 + rate * t) % 360) / 12).floorToDouble();
      final spans = walk(tithiBucket: b, prevSunriseTithi: 28);
      expect(spans.length, 2);
      expect(spans[0].index, 29);
      expect(spans[0].name, 'Amavasya');
      expect(spans[0].paksha, 'Krishna');
      expect(spans[1].index, 0);
      expect(spans[1].name, 'Pratipada');
      expect(spans[1].paksha, 'Shukla');
      expectNear(spans[0].ends, (360 - elong0) / rate);
    });
  });
}

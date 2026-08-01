/// The Vedic-day window the snapshot builder hangs the panchang's
/// sunrise/sunset readings on.
///
/// The native Swiss Ephemeris cannot load under headless `flutter test`,
/// so [vedicDayWindow] takes its three rise/set lookups as closures.
/// That is the seam these tests drive: fixed Julian days in, and the
/// ordering rule (sunrise ≤ instant < next sunrise, sunrise < sunset <
/// next sunrise) checked on the way out.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/ephemeris_service.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/core/astro/snapshot_builder.dart';

/// IST.
const _offset = 330;

double _jd(DateTime utc) =>
    utc.millisecondsSinceEpoch / 86400000 + 2440587.5;

/// A place whose sun rises at 07:11 and sets at 18:10 local, every day —
/// enough to pin the window's SHAPE without an ephemeris.
({
  double? Function(double) before,
  double? Function(double, {required bool rise}) after,
}) _fixedSun({
  DateTime? riseAt,
  DateTime? setAt,
  DateTime? nextRiseAt,
}) {
  return (
    before: (_) => riseAt == null ? null : _jd(riseAt),
    after: (jd, {required bool rise}) {
      final t = rise ? nextRiseAt : setAt;
      return t == null ? null : _jd(t);
    },
  );
}

void main() {
  // 00:30 IST on Tue 2 Jan 1990 — after midnight, before sunrise.
  final birthUtc = DateTime.utc(1990, 1, 1, 19, 0);
  // The same instants in UTC, i.e. 07:11 / 18:10 / 07:11 IST.
  final riseUtc = DateTime.utc(1990, 1, 1, 1, 41);
  final setUtc = DateTime.utc(1990, 1, 1, 12, 40);
  final nextRiseUtc = DateTime.utc(1990, 1, 2, 1, 41);

  ({DateTime sunrise, DateTime? sunset, DateTime? nextSunrise})? window({
    DateTime? riseAt,
    DateTime? setAt,
    DateTime? nextRiseAt,
  }) {
    final sun =
        _fixedSun(riseAt: riseAt, setAt: setAt, nextRiseAt: nextRiseAt);
    return vedicDayWindow(
      jdUt: _jd(birthUtc),
      utcOffsetMinutes: _offset,
      sunriseBefore: sun.before,
      sunEventAfter: sun.after,
    );
  }

  test('brackets the instant: sunrise ≤ birth < next sunrise', () {
    final w = window(
        riseAt: riseUtc, setAt: setUtc, nextRiseAt: nextRiseUtc)!;
    final birthLocal = BirthData(
      dateTimeUtc: birthUtc,
      latitude: 18.52,
      longitude: 73.86,
      timezoneName: 'Asia/Kolkata',
      utcOffsetMinutes: _offset,
    ).localDateTime;

    expect(w.sunrise.isAfter(birthLocal), isFalse);
    expect(w.nextSunrise!.isAfter(birthLocal), isTrue);
    expect(w.sunrise.isBefore(w.sunset!), isTrue);
    expect(w.sunset!.isBefore(w.nextSunrise!), isTrue);
  });

  test('returns place-local wall clocks, not UTC', () {
    final w = window(
        riseAt: riseUtc, setAt: setUtc, nextRiseAt: nextRiseUtc)!;
    // 01:41 UTC + 5:30 = 07:11 at the birth place — the same
    // offset-shifted form BirthData.localDateTime uses, so the two are
    // directly comparable.
    expect(w.sunrise.hour, 7);
    expect(w.sunrise.minute, 11);
    expect(w.sunset!.hour, 18);
    expect(w.sunset!.minute, 10);
  });

  test('a pre-sunrise birth belongs to the PREVIOUS weekday', () {
    final w = window(
        riseAt: riseUtc, setAt: setUtc, nextRiseAt: nextRiseUtc)!;
    // The clock says Tuesday 2 Jan; the Vedic day opened at Monday's
    // sunrise, and the vara follows the sunrise.
    expect(w.sunrise.day, 1);
    expect(w.sunrise.weekday, DateTime.monday);
  });

  test('the next sunrise is searched from the SUNSET, not the sunrise', () {
    // Seeding the "next rise" search at the sunrise itself can hand back
    // that same sunrise on a rounding tie, which would collapse the
    // window to zero length. Sunset is the safe seed — so a run with no
    // sunset must not produce a next sunrise either.
    final seeds = <double>[];
    final w = vedicDayWindow(
      jdUt: _jd(birthUtc),
      utcOffsetMinutes: _offset,
      sunriseBefore: (_) => _jd(riseUtc),
      sunEventAfter: (jd, {required bool rise}) {
        seeds.add(jd);
        return rise ? _jd(nextRiseUtc) : _jd(setUtc);
      },
    )!;
    expect(w.nextSunrise, isNotNull);
    expect(seeds.length, 2);
    expect(seeds.first, closeTo(_jd(riseUtc), 1e-9)); // the sunset search
    expect(seeds.last, closeTo(_jd(setUtc), 1e-9)); // the next-rise search
  });

  group('degenerate skies', () {
    test('no sunrise at all yields no window', () {
      expect(window(setAt: setUtc, nextRiseAt: nextRiseUtc), isNull);
    });

    test('a sun that rises but never sets keeps the sunrise only', () {
      final w = window(riseAt: riseUtc)!;
      expect(w.sunrise, isNotNull);
      expect(w.sunset, isNull);
      // Without a sunset there is no seed for the next-rise search.
      expect(w.nextSunrise, isNull);
    });
  });

  group('PanchangData.withVedicDay', () {
    const base = PanchangData(
      tithiIndex: 0,
      tithiName: 'Pratipada',
      paksha: 'Shukla',
      nakshatra: Nakshatra.ashwini,
      pada: 1,
      yogaIndex: 0,
      yogaName: 'Vishkambha',
      karanaIndex: 1,
      karanaName: 'Bava',
      varaIndex: 0,
      vara: 'Somavara',
    );

    test('threads every Vedic-day and maasa field through', () {
      final p = base.withVedicDay(
        sunrise: DateTime.utc(1990, 1, 1, 7, 11),
        sunset: DateTime.utc(1990, 1, 1, 18, 10),
        nextSunrise: DateTime.utc(1990, 1, 2, 7, 11),
        amantaMonthIndex: 9,
        isAdhikMaasa: true,
        samvatYear: 2046,
      );
      expect(p.sunrise, DateTime.utc(1990, 1, 1, 7, 11));
      expect(p.sunset, DateTime.utc(1990, 1, 1, 18, 10));
      expect(p.nextSunrise, DateTime.utc(1990, 1, 2, 7, 11));
      expect(p.amantaMonthIndex, 9);
      expect(p.isAdhikMaasa, isTrue);
      expect(p.samvatYear, 2046);
      // The five limbs are untouched.
      expect(p.tithiIndex, base.tithiIndex);
      expect(p.nakshatra, base.nakshatra);
      expect(p.vara, base.vara);
    });

    test('the fields default to absent, so existing call sites are '
        'unchanged', () {
      expect(base.sunrise, isNull);
      expect(base.sunset, isNull);
      expect(base.nextSunrise, isNull);
      expect(base.amantaMonthIndex, isNull);
      expect(base.isAdhikMaasa, isNull);
      expect(base.samvatYear, isNull);
    });
  });

  test('the JD round trip these tests rely on is the real one', () {
    // _jd above is the inverse the production code uses; if that drifts
    // every assertion here quietly measures the wrong instant.
    expect(EphemerisService.dateTimeFromJdUt(_jd(riseUtc)), riseUtc);
  });
}

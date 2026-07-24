// Vara must be sunrise-bounded (Vedic day runs sunrise → sunrise), not
// civil-midnight. The full snapshot path resolves sunrise via the Swiss
// Ephemeris (which can't load under headless `flutter test`), so these
// pin the two pure seams that path relies on: the vedicWeekday() helper
// and computePanchang honouring an explicit Vedic weekday.
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/panchang.dart';

void main() {
  group('vedicWeekday helper', () {
    // 2026-07-07 is a Tuesday; take sunrise at 06:00 local.
    final sunrise = DateTime(2026, 7, 7, 6, 0);

    test('before sunrise belongs to the previous weekday', () {
      // Delhi 03:00 on a civil Tuesday is still the Monday Vedic day.
      expect(vedicWeekday(DateTime(2026, 7, 7, 3, 0), sunrise),
          DateTime.monday);
    });

    test('exactly at sunrise is the current weekday', () {
      expect(vedicWeekday(sunrise, sunrise), DateTime.tuesday);
    });

    test('after sunrise is unchanged', () {
      expect(vedicWeekday(DateTime(2026, 7, 7, 8, 0), sunrise),
          DateTime.tuesday);
    });

    test('pre-sunrise Monday wraps to Sunday (weekday 1 → 7)', () {
      // 2026-07-06 is a Monday.
      final monSunrise = DateTime(2026, 7, 6, 6, 0);
      expect(vedicWeekday(DateTime(2026, 7, 6, 3, 0), monSunrise),
          DateTime.sunday);
    });
  });

  group('computePanchang vara is Vedic when the weekday is supplied', () {
    // A civil-Tuesday 03:00 birth: without the sunrise-bounded weekday
    // it reads Mangalavara (Tuesday), with it reads Somavara (Monday).
    final civilTue3am = DateTime(2026, 7, 7, 3, 0);

    test('sunrise-bounded Monday → Somavara', () {
      final p = computePanchang(
        sunLongitude: 10,
        moonLongitude: 100,
        localDateTime: civilTue3am,
        vedicWeekday: DateTime.monday,
      );
      expect(p.vara, 'Somavara');
      expect(p.varaIndex, 0);
    });

    test('no override falls back to the civil weekday (Mangalavara)', () {
      final p = computePanchang(
        sunLongitude: 10,
        moonLongitude: 100,
        localDateTime: civilTue3am,
      );
      expect(p.vara, 'Mangalavara');
      expect(p.varaIndex, 1);
    });
  });
}

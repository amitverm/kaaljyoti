// Regression for the sunRiseSet wrong-day anchor: it used UTC noon,
// which for western longitudes lands BEFORE local sunrise and returns
// the PREVIOUS day's sunrise (e.g. New York winter: UTC noon = 07:00
// EST). The fix anchors the rise/set search at approximate LOCAL solar
// noon (12:00 UT − longitude/15h). The full sunrise assertion needs the
// native Swiss Ephemeris (unavailable in host `flutter test`), so this
// pins the load-bearing part — the anchor instant — via the pure
// EphemerisService.localSolarNoonUt helper.
import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/ephemeris_service.dart';

void main() {
  group('localSolarNoonUt anchor', () {
    test('New York (−74°E) anchors ~16:56 UT, well after 07:19 EST sunrise',
        () {
      final a = EphemerisService.localSolarNoonUt(
          DateTime.utc(2026, 1, 15), -74.006);
      // 12:00 UT − (−74.006/15)h = 12:00 + 4h56m ≈ 16:56 UT.
      expect(a.year, 2026);
      expect(a.month, 1);
      expect(a.day, 15);
      expect(a.hour, 16);
      expect(a.minute, inInclusiveRange(55, 57));
      // Must be after the day's ~07:19 EST (12:19 UT) sunrise so the
      // "last sunrise at or before the anchor" is Jan 15's, not Jan 14's.
      expect(a.isAfter(DateTime.utc(2026, 1, 15, 12, 19)), true);
    });

    test('Delhi (+77°E) anchors ~06:52 UT, still on the intended day', () {
      final a = EphemerisService.localSolarNoonUt(
          DateTime.utc(2026, 1, 15), 77.2090);
      // 12:00 UT − (77.209/15)h = 12:00 − 5h09m ≈ 06:51 UT.
      expect(a.day, 15);
      expect(a.hour, 6);
      expect(a.minute, inInclusiveRange(50, 53));
      // Delhi sunrise (~07:12 IST = 01:42 UT) precedes this anchor, so
      // the resolved sunrise is unchanged/correct — the eastern case the
      // old UTC-noon anchor already got right stays right.
      expect(a.isAfter(DateTime.utc(2026, 1, 15, 1, 42)), true);
    });

    test('Greenwich (0°E) anchor is exactly UTC noon', () {
      final a =
          EphemerisService.localSolarNoonUt(DateTime.utc(2026, 1, 15), 0);
      expect(a, DateTime.utc(2026, 1, 15, 12));
    });
  });
}

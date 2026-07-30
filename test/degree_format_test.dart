/// Arc-minute / arc-second CARRY in the degree formatters.
///
/// These two functions render every degree the app shows — the
/// planetary positions table on screen, the same table in the PDF, the
/// chart annotations, the Ascendant marker, the OS widget — so a
/// rounding slip here is visible everywhere at once and nowhere in
/// particular. One shipped: Mercury printed as `8°56'60"`, because
/// minutes and seconds were each rounded in isolation and the seconds
/// carried nowhere.
///
/// The sign-boundary clamp is the deliberate half of the fix and is
/// pinned here so nobody "fixes" it back into a carry: see
/// [formatDegree]'s helper for why 29°59'59.9" must not become 30° (a
/// degree no sign has) or 0° (which reads as the next sign, while the
/// sign label printed beside it still says this one).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/astro/models.dart';

void main() {
  group('formatDegree', () {
    test('carries seconds into minutes instead of printing 60', () {
      // The reported reading: Mercury at 8.94999…° in Aries.
      expect(formatDegree(8.949999), '8°57\'00"');
      // 59.98 seconds — rounds to a full minute, which must carry.
      expect(formatDegree(1 + 59 / 60 + 59.98 / 3600), '2°00\'00"');
    });

    test('carries minutes into degrees', () {
      expect(formatDegree(4 + 59.999 / 60), '5°00\'00"');
    });

    test('leaves an exact value alone', () {
      expect(formatDegree(0), '0°00\'00"');
      expect(formatDegree(8 + 56 / 60 + 12 / 3600), '8°56\'12"');
      expect(formatDegree(29 + 59 / 60 + 59 / 3600), '29°59\'59"');
    });

    test('reduces a full sidereal longitude into its own sign', () {
      // 188.30° is 8.30° of Libra, not 188 degrees of anything.
      expect(formatDegree(188.30), '8°18\'00"');
    });

    test('clamps at the end of a sign rather than rolling over', () {
      // Carrying would print 30°00'00" — a degree no sign has — or
      // 0°00'00", which reads as the NEXT sign while the sign label
      // beside it still says this one. One arc-second is the cheaper
      // error.
      expect(formatDegree(29.9999999), '29°59\'59"');
      expect(formatDegree(179.9999999), '29°59\'59"'); // end of Virgo
    });
  });

  group('formatDegreeInSign', () {
    test('carries minutes into degrees instead of printing 60', () {
      expect(formatDegreeInSign(8.9999), '9°00\'');
      expect(formatDegreeInSign(12.99999), '13°00\'');
    });

    test('rounds to the nearest minute', () {
      expect(formatDegreeInSign(3.62), '3°37\'');
      expect(formatDegreeInSign(0), '0°00\'');
    });

    test('accepts a degree-in-sign or a whole longitude', () {
      expect(formatDegreeInSign(188.30), formatDegreeInSign(8.30));
    });

    test('clamps at the end of a sign rather than rolling over', () {
      expect(formatDegreeInSign(29.9999), '29°59\'');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/core/coordinate_parse.dart';

void main() {
  double? lat(String s) => parseCoordinate(s, isLatitude: true);
  double? lon(String s) => parseCoordinate(s, isLatitude: false);

  group('decimal input', () {
    test('plain decimal passes through', () {
      expect(lat('31.3260'), closeTo(31.3260, 1e-9));
      expect(lon('75.5762'), closeTo(75.5762, 1e-9));
    });

    test('signed decimal', () {
      expect(lat('-18.9667'), closeTo(-18.9667, 1e-9));
      expect(lon('+72.5'), closeTo(72.5, 1e-9));
    });

    test('whitespace tolerated', () {
      expect(lat('  18.5  '), closeTo(18.5, 1e-9));
    });
  });

  group('DMS with hemisphere letter', () {
    test("18N50'00 — the book format from the bug report", () {
      expect(lat("18N50'00"), closeTo(18 + 50 / 60, 1e-9));
    });

    test("72E50'00", () {
      expect(lon("72E50'00"), closeTo(72 + 50 / 60, 1e-9));
    });

    test('18º58\'N — trailing hemisphere, masculine-ordinal symbol', () {
      expect(lat("18º58'N"), closeTo(18 + 58 / 60, 1e-9));
    });

    test('full DMS with degree/minute/second symbols', () {
      expect(lat('18°58\'30"N'), closeTo(18 + 58 / 60 + 30 / 3600, 1e-9));
      expect(lon('72°49\'33"E'), closeTo(72 + 49 / 60 + 33 / 3600, 1e-9));
    });

    test('south and west are negative', () {
      expect(lat("33S52'00"), closeTo(-(33 + 52 / 60), 1e-9));
      expect(lon('151W12\'30"'), closeTo(-(151 + 12 / 60 + 30 / 3600), 1e-9));
    });

    test('leading hemisphere letter', () {
      expect(lat('N18 58 30'), closeTo(18 + 58 / 60 + 30 / 3600, 1e-9));
      expect(lon('W 72 30'), closeTo(-72.5, 1e-9));
    });

    test('lower case accepted', () {
      expect(lat("18n50'00"), closeTo(18 + 50 / 60, 1e-9));
      expect(lon("72e50'"), closeTo(72 + 50 / 60, 1e-9));
    });

    test('decimal degrees with hemisphere', () {
      expect(lat('18.9667N'), closeTo(18.9667, 1e-9));
      expect(lat('18.9667S'), closeTo(-18.9667, 1e-9));
    });

    test('decimal minutes', () {
      expect(lat('18N58.5'), closeTo(18 + 58.5 / 60, 1e-9));
    });
  });

  group('bare DMS separators', () {
    test('spaces', () {
      expect(lat('18 58 30'), closeTo(18 + 58 / 60 + 30 / 3600, 1e-9));
    });

    test('colons', () {
      expect(lon('72:49:33'), closeTo(72 + 49 / 60 + 33 / 3600, 1e-9));
    });

    test('leading minus applies to the whole value', () {
      expect(lat('-18 30'), closeTo(-18.5, 1e-9));
    });

    test('unicode prime and double-prime', () {
      expect(lat('18°58′30″N'), closeTo(18 + 58 / 60 + 30 / 3600, 1e-9));
    });
  });

  group('rejections', () {
    test('empty and junk', () {
      expect(lat(''), isNull);
      expect(lat('abc'), isNull);
      expect(lat('18N50XYZ'), isNull);
    });

    test('wrong-axis hemisphere letter', () {
      expect(lat("72E50'00"), isNull, reason: 'E in a latitude field');
      expect(lon("18N50'00"), isNull, reason: 'N in a longitude field');
    });

    test('conflicting or duplicate signs', () {
      expect(lat('-18N30'), isNull);
      expect(lat('18N30S'), isNull);
      expect(lat('18 -30'), isNull);
    });

    test('minutes or seconds out of range', () {
      expect(lat('18 60'), isNull);
      expect(lat('18 30 60'), isNull);
    });

    test('too many components', () {
      expect(lat('18 30 15 10'), isNull);
    });

    test('fraction on a non-final component', () {
      expect(lat('18.5 30'), isNull);
    });
  });
}

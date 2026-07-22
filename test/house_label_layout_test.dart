/// HouseLabelLayout stack direction — houses whose zodiacal progression
/// runs upward on screen (North right flank, South left column) reverse
/// their planet stack, and the bhava-madhya divider mirrors with it, so
/// every planet still sits toward the neighbouring house it is near.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kaaljyoti/charts/planet_token.dart';
import 'package:kaaljyoti/core/astro/models.dart';
import 'package:kaaljyoti/l10n/gen/app_localizations_en.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final l10n = AppLocalizationsEn();

  // The reference chart's 3rd house: Me before madhya, Ma/Su/Ve after.
  List<PlanetToken> tokens() => [
        PlanetToken(planet: Planet.mercury, degreeInSign: 7.19),
        PlanetToken(planet: Planet.mars, degreeInSign: 23.95),
        PlanetToken(planet: Planet.sun, degreeInSign: 25.32),
        PlanetToken(planet: Planet.venus, degreeInSign: 25.68),
      ];

  List<String> rowTexts(HouseLabelLayout layout) =>
      [for (final r in layout.rows) r.text!.toPlainText()];

  HouseLabelLayout build({required bool reverseStack}) => HouseLabelLayout(
        l10n: l10n,
        tokens: tokens(),
        cuspLabel: "M 11°16'",
        cuspAfter: 1,
        reverseStack: reverseStack,
        maxWidth: 500,
        maxHeight: 500,
        baseFontSize: 12,
        showDegrees: true, // one chip per row, so rows mirror stack order
      );

  test('normal stack: ascending with the madhya after the pre-cusp graha',
      () {
    final rows = rowTexts(build(reverseStack: false));
    expect(rows.length, 5);
    expect(rows[0], startsWith('Me'));
    expect(rows[1], "M 11°16'");
    expect(rows[2], startsWith('Ma'));
    expect(rows[3], startsWith('Su'));
    expect(rows[4], startsWith('Ve'));
  });

  test('reversed stack: descending with the madhya slot mirrored', () {
    final rows = rowTexts(build(reverseStack: true));
    expect(rows.length, 5);
    expect(rows[0], startsWith('Ve'));
    expect(rows[1], startsWith('Su'));
    expect(rows[2], startsWith('Ma'));
    expect(rows[3], "M 11°16'");
    expect(rows[4], startsWith('Me'));
  });

  test('signs-passed tag prefixes the degree', () {
    final layout = HouseLabelLayout(
      l10n: l10n,
      tokens: [
        PlanetToken(planet: Planet.mars, degreeInSign: 23.95, signTag: '10ˢ'),
      ],
      maxWidth: 500,
      maxHeight: 500,
      baseFontSize: 12,
      showDegrees: true,
    );
    expect(rowTexts(layout).single, contains("10ˢ23°57'"));
  });

  test('As slots into the degree order by rank, mirroring on reversal', () {
    HouseLabelLayout build({required bool reverse}) => HouseLabelLayout(
          l10n: l10n,
          tokens: tokens(),
          ascLabel: "As 24°30'",
          ascAfter: 3, // after Me, Ma, Su — before Ve
          reverseStack: reverse,
          maxWidth: 500,
          maxHeight: 500,
          baseFontSize: 12,
          showDegrees: true,
        );
    // Chips glue their degree with a non-breaking space — split on both.
    List<String> heads(HouseLabelLayout l) => rowTexts(l)
        .map((t) => t.split(RegExp(r'[\s ]')).first)
        .toList();
    expect(heads(build(reverse: false)), ['Me', 'Ma', 'Su', 'As', 'Ve']);
    expect(heads(build(reverse: true)), ['Ve', 'As', 'Su', 'Ma', 'Me']);
  });

  test('As at the madhya sits directly above the cusp line', () {
    // Sripati house 1: the ascendant IS the madhya, so both share rank 1
    // here — As stays above the M row.
    final layout = HouseLabelLayout(
      l10n: l10n,
      tokens: tokens(),
      ascLabel: "As 11°16'",
      ascAfter: 1,
      cuspLabel: "M 11°16'",
      cuspAfter: 1,
      maxWidth: 500,
      maxHeight: 500,
      baseFontSize: 12,
      showDegrees: true,
    );
    final rows = rowTexts(layout);
    expect(rows[0], startsWith('Me'));
    expect(rows[1], startsWith('As'));
    expect(rows[2], "M 11°16'");
    expect(rows[3], startsWith('Ma'));
  });

  test('cramped house drops minutes but never shrinks below the floor', () {
    // A width no full chip ("Me 11ˢ7°11'") fits at the floor scale —
    // the house compacts its degrees ("Me 11ˢ7°") but the font stays AT
    // the floor: sub-floor sizes make the ˢ collapse into the digits.
    // Residual overflow is accepted (the user trades toggles for space).
    final layout = HouseLabelLayout(
      l10n: l10n,
      tokens: [
        for (final t in tokens())
          PlanetToken(
              planet: t.planet, degreeInSign: t.degreeInSign, signTag: '11ˢ'),
      ],
      maxWidth: 42,
      maxHeight: 500,
      baseFontSize: 12,
      minFontScale: 0.8,
      showDegrees: true,
    );
    // Minutes are gone, degree + signs-passed prefix survive.
    expect(rowTexts(layout).first, contains('11ˢ7°'));
    expect(rowTexts(layout).first, isNot(contains("7°11'")));
    // Floor respected: the compact chip at 0.8 scale is wider than the
    // box, and the layout does NOT shrink further to force a fit.
    final atFloor = HouseLabelLayout(
      l10n: l10n,
      tokens: [
        PlanetToken(
            planet: Planet.mercury, degreeInSign: 7.19, signTag: '11ˢ'),
      ],
      maxWidth: 1000,
      maxHeight: 1000,
      baseFontSize: 12 * 0.8,
      showDegrees: true,
    );
    expect(layout.rows.first.height, greaterThanOrEqualTo(atFloor.rows.first.height));
  });

  test('no rank given still pins the ascendant on top', () {
    final layout = HouseLabelLayout(
      l10n: l10n,
      tokens: tokens(),
      ascLabel: "As 0°11'",
      reverseStack: true,
      maxWidth: 500,
      maxHeight: 500,
      baseFontSize: 12,
      showDegrees: true,
    );
    final rows = rowTexts(layout);
    expect(rows[0], "As 0°11'");
    expect(rows[1], startsWith('Ve'));
    expect(rows.last, startsWith('Me'));
  });
}

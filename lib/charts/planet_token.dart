/// Shared per-planet display data and rich-text layout used by all
/// three chart painters, so North/South/Circular render one consistent
/// visual language for retrograde, dignity, combustion, degrees, and
/// Jaimini karakas instead of each painter inventing its own.
///
/// Layout follows the Parashar Light convention: each planet (with its
/// modifiers and degree) is an ATOMIC chip that is never broken across
/// lines — so a degree can't orphan away from its planet — and when
/// degrees are shown each planet gets its own line, stacked vertically.
/// Planet abbreviations are tinted with the traditional per-planet
/// colours from the active palette ([KJPalette.planets]).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/astro/dignity.dart';
import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import 'chart_tuning.dart';

/// Everything a painter needs to render one planet's label: its
/// natal placement plus optional annotations. Any field left at its
/// default renders nothing extra — an unannotated [PlanetToken] draws
/// exactly like the plain abbreviation the painters always showed.
class PlanetToken {
  const PlanetToken({
    required this.planet,
    this.retrograde = false,
    this.degreeInSign,
    this.karaka,
    this.dignity = PlanetDignity.none,
    this.combust = false,
    this.signTag,
  });

  final Planet planet;
  final bool retrograde;
  final double? degreeInSign;
  final String? karaka;
  final PlanetDignity dignity;
  final bool combust;

  /// "Signs passed" prefix (e.g. '10ˢ') gluing onto the degree —
  /// 10ˢ23°57' reads as 10 completed signs + 23°57' into Aquarius, so
  /// the graha's rashi is explicit even when its bhava straddles a sign
  /// boundary (chalit's Planet signs toggle). Null renders nothing.
  final String? signTag;

  /// The lunar nodes are retrograde by definition — never worth
  /// flagging on-chart — so the marker is suppressed regardless of
  /// [retrograde].
  bool get showRetrograde =>
      retrograde && planet != Planet.rahu && planet != Planet.ketu;
}

/// Renders a signs-passed string ("11ˢ11°16'") as spans, enlarging each
/// superscript-s so the marker stays legible: the ˢ glyph is genuinely
/// superscript (small and raised in the font) but nearly invisible at
/// annotation sizes — scaling just that glyph keeps the raised look
/// without faking a baseline shift. Text without ˢ passes through as a
/// single span.
List<InlineSpan> signsPassedSpans(String text, TextStyle style) {
  if (!text.contains('ˢ')) return [TextSpan(text: text, style: style)];
  final sup = style.copyWith(fontSize: (style.fontSize ?? 12) * 1.5);
  final parts = text.split('ˢ');
  return [
    for (var i = 0; i < parts.length; i++) ...[
      if (parts[i].isNotEmpty) TextSpan(text: parts[i], style: style),
      if (i < parts.length - 1) TextSpan(text: 'ˢ', style: sup),
    ],
  ];
}

/// Builds a single planet's label (used by the Circular painter, which
/// stagger-places one planet at a time rather than grouping a whole
/// house into one block). Shares the same glyph conventions as
/// [HouseLabelLayout] so all three chart styles read consistently.
TextPainter singleTokenPainter(
  PlanetToken token, {
  required AppLocalizations l10n,
  required double fontSize,
  bool showDegrees = false,
  bool showKarakas = false,
  bool isTransit = false,
}) {
  final spans = isTransit
      ? _transitChipSpans(l10n, token.planet, token.showRetrograde, fontSize)
      : _natalChipSpans(l10n, token, fontSize,
          showDegrees: showDegrees, showKarakas: showKarakas);
  return TextPainter(
    text: TextSpan(children: spans),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );
}

/// One planet's complete label as inline spans: colored abbreviation +
/// retrograde/dignity/combustion glyphs + degree + karaka. Rendered as
/// one unbreakable unit.
List<InlineSpan> _natalChipSpans(
  AppLocalizations l10n,
  PlanetToken t,
  double fontSize, {
  required bool showDegrees,
  required bool showKarakas,
  bool compactDegrees = false,
}) {
  final tune = chartTuning.value; // Settings > Chart text
  final modSize = fontSize * tune.annotationScale;
  final ink = planetInk(t.planet);
  final base = KJTheme.mono(size: fontSize, color: ink, weight: tune.weight);
  final mod = KJTheme.mono(size: modSize, color: KJColors.inkSoft);
  final degreeStyle = KJTheme.mono(size: modSize, color: KJColors.inkSoft);
  final karakaStyle = KJTheme.mono(
      size: modSize, color: KJColors.maroon, weight: FontWeight.w600);

  final spans = <InlineSpan>[
    TextSpan(text: t.planet.abbrLabel(l10n), style: base)
  ];
  if (t.showRetrograde) {
    spans.add(TextSpan(text: '®', style: mod.copyWith(color: ink)));
  }
  switch (t.dignity) {
    case PlanetDignity.exalted:
      spans.add(
          TextSpan(text: '↑', style: mod.copyWith(color: KJColors.forest)));
    case PlanetDignity.debilitated:
      spans.add(
          TextSpan(text: '↓', style: mod.copyWith(color: KJColors.maroon)));
    case PlanetDignity.ownSign:
      spans.add(TextSpan(text: '○', style: mod));
    case PlanetDignity.none:
      break;
  }
  if (t.combust) {
    spans.add(TextSpan(text: '•', style: mod.copyWith(color: KJColors.maroon)));
  }
  if (showDegrees && t.degreeInSign != null) {
    // Non-breaking space: the degree may never wrap away from its planet.
    final d = t.degreeInSign!;
    // [compactDegrees]: the fit ladder's minutes-dropping step — wins
    // over the Settings-level minutes preference for this house only.
    final degText = tune.degreeMinutes && !compactDegrees
        ? formatDegreeInSign(d)
        : '${(d % 30).floor()}°';
    spans.addAll(signsPassedSpans(
        ' ${t.signTag ?? ''}$degText', degreeStyle));
  }
  if (showKarakas && t.karaka != null) {
    spans.add(TextSpan(text: ' ${t.karaka}', style: karakaStyle));
  }
  if (t.signTag != null && !(showDegrees && t.degreeInSign != null)) {
    // Degrees hidden: the signs-passed tag still shows the rashi,
    // glued with a non-breaking space so it can't wrap away.
    spans.addAll(signsPassedSpans(' ${t.signTag}', degreeStyle));
  }
  return spans;
}

/// A transit (current-sky) planet chip: lowercase, italic, transit
/// green — visually distinct from natal planets.
///
/// `toLowerCase()` is a no-op in caseless scripts (Devanagari and most
/// Indic scripts), so there the italic + transit-green carry the whole
/// distinction. That still reads clearly; it just isn't reinforced by
/// case the way the Latin tokens are.
List<InlineSpan> _transitChipSpans(
    AppLocalizations l10n, Planet p, bool retrograde, double fontSize) {
  final base = KJTheme.mono(size: fontSize * 0.85, color: KJColors.transit)
      .copyWith(fontStyle: FontStyle.italic);
  final spans = <InlineSpan>[
    TextSpan(text: p.abbrLabel(l10n).toLowerCase(), style: base),
  ];
  final isNode = p == Planet.rahu || p == Planet.ketu;
  if (!isNode && retrograde) {
    spans.add(TextSpan(
        text: '®',
        style: KJTheme.mono(size: fontSize * 0.61, color: KJColors.transit)));
  }
  return spans;
}

/// Lays out one house/cell's labels Parashar Light style:
///
/// * every planet chip (abbr + glyphs + degree + karaka) is atomic —
///   it never breaks across lines;
/// * with degrees shown, each planet sits on its own line, stacked;
///   without degrees, chips flow into as few lines as fit the width;
/// * an optional ascendant label ("As 0°11'") stacks as the first line;
/// * arudha pada codes ("7P 12P") flow onto a light-grey trailing line,
///   Parashar Light style;
/// * transit planets flow onto their own trailing lines;
/// * the whole block auto-shrinks until it fits [maxWidth]×[maxHeight],
///   falling back to multi-chip rows at minimum scale if it must.
///
/// Paint the result with [paint], centered on the house's content
/// anchor. [width]/[height] expose the block's final size.
class HouseLabelLayout {
  HouseLabelLayout({
    required AppLocalizations l10n,
    required List<PlanetToken> tokens,
    List<Planet> transitPlanets = const [],
    Map<Planet, bool> transitRetrograde = const {},
    List<String> padaLabels = const [],
    String? cuspLabel,
    int cuspAfter = 0,
    String? ascLabel,
    int? ascAfter,
    bool reverseStack = false,
    required double maxWidth,
    required double maxHeight,
    double? clipWidth,
    required double baseFontSize,
    bool showDegrees = false,
    bool showKarakas = false,
    double? minFontScale,
  }) {
    // Shrink floor: explicit arg wins, else Settings > Chart text.
    final floor = minFontScale ?? chartTuning.value.minFontScale;
    List<TextPainter> pack(double fontSize,
            {required bool onePerRow, bool compactDegrees = false}) =>
        _pack(
          l10n: l10n,
          tokens: tokens,
          transitPlanets: transitPlanets,
          transitRetrograde: transitRetrograde,
          padaLabels: padaLabels,
          cuspLabel: cuspLabel,
          cuspAfter: cuspAfter,
          ascLabel: ascLabel,
          ascAfter: ascAfter,
          reverseStack: reverseStack,
          fontSize: fontSize,
          maxWidth: maxWidth,
          showDegrees: showDegrees,
          showKarakas: showKarakas,
          onePerRow: onePerRow,
          compactDegrees: compactDegrees,
        );

    var scale = 1.0;
    var result = pack(baseFontSize, onePerRow: showDegrees);
    while ((_height(result) > maxHeight || _width(result) > maxWidth) &&
        scale > floor) {
      scale = math.max(floor, scale - 0.1);
      result = pack(baseFontSize * scale, onePerRow: showDegrees);
    }
    // Houses that still overflow WIDTH at the user's floor drop their
    // degree MINUTES ("Me 11ˢ7°12'" → "Me 11ˢ7°") — this house only;
    // full precision stays in the detail table. Only on REAL overflow,
    // measured against [clipWidth] — the centred block's room before
    // the CHART FRAME, where text is actually cut off — not against
    // [maxWidth]: the shape-aware content rects are conservative, and
    // brushing an internal diagonal has always rendered fine (the
    // half-diamond houses would otherwise lose their minutes with just
    // two planets). Without [clipWidth], a 10% grace over [maxWidth]
    // stands in. The font never shrinks below the floor: at sub-floor
    // sizes the superscript ˢ collapses into the digits and the
    // notation stops reading as signs+degree. If even the compact form
    // overflows, it overflows — the user trades toggles for space at a
    // size they can still read.
    final hardWidth = clipWidth ?? maxWidth * 1.1;
    var compact = false;
    if (showDegrees && _width(result) > hardWidth) {
      compact = true;
      result = pack(baseFontSize * scale,
          onePerRow: showDegrees, compactDegrees: true);
    }
    // Last resort for extremely crowded houses (HEIGHT overflow):
    // abandon one-per-row and flow several chips per line.
    if (showDegrees && _height(result) > maxHeight) {
      result = pack(baseFontSize * scale,
          onePerRow: false, compactDegrees: compact);
    }
    rows = result;
    width = _width(rows);
    height = _height(rows);
  }

  late final List<TextPainter> rows;
  late final double width;
  late final double height;

  static double _height(List<TextPainter> rows) =>
      rows.fold(0.0, (h, r) => h + r.height);

  static double _width(List<TextPainter> rows) =>
      rows.fold(0.0, (w, r) => math.max(w, r.width));

  /// Paints the block with its center at [center], rows centered
  /// horizontally on each other.
  void paint(Canvas canvas, Offset center) {
    var y = center.dy - height / 2;
    for (final r in rows) {
      r.paint(canvas, Offset(center.dx - r.width / 2, y));
      y += r.height;
    }
  }

  static List<TextPainter> _pack({
    required AppLocalizations l10n,
    required List<PlanetToken> tokens,
    required List<Planet> transitPlanets,
    required Map<Planet, bool> transitRetrograde,
    required List<String> padaLabels,
    String? cuspLabel,
    int cuspAfter = 0,
    required String? ascLabel,
    int? ascAfter,
    bool reverseStack = false,
    required double fontSize,
    required double maxWidth,
    required bool showDegrees,
    required bool showKarakas,
    required bool onePerRow,
    bool compactDegrees = false,
  }) {
    final gapStyle = KJTheme.mono(size: fontSize);

    // Build every chip with its measured width.
    //
    // [reverseStack]: houses whose zodiacal progression runs UPWARD on
    // screen (the North diamond's right side, the South grid's left
    // column) list later-degree planets first, so each planet still sits
    // toward the neighbouring house it is actually near. The As marker
    // and the madhya slot mirror with the planets.
    //
    // [ascAfter]: how many planets precede the ascendant in zodiacal
    // order — the As chip slots there, reading like any other body in
    // the progression. Null falls back to pinning As on top (callers
    // without longitude data).
    final n = tokens.length;
    final ordered = reverseStack ? tokens.reversed : tokens;
    final chips = <(List<InlineSpan>, double)>[
      for (final t in ordered)
        _measure(_natalChipSpans(l10n, t, fontSize,
            showDegrees: showDegrees,
            showKarakas: showKarakas,
            compactDegrees: compactDegrees)),
    ];
    int? ascPos;
    if (ascLabel != null) {
      final a = (ascAfter ?? 0).clamp(0, n);
      ascPos = ascAfter == null ? 0 : (reverseStack ? n - a : a);
      chips.insert(
          ascPos,
          _measure([
            TextSpan(
              text: ascLabel,
              style: KJTheme.mono(
                  size: fontSize * 0.9,
                  color: KJColors.maroon,
                  weight: FontWeight.w600),
            ),
          ]));
    }
    final clampedCuspAfter = cuspAfter.clamp(0, n);
    final effCuspAfter = reverseStack ? n - clampedCuspAfter : clampedCuspAfter;
    final transitChips = <(List<InlineSpan>, double)>[
      for (final p in transitPlanets)
        _measure(_transitChipSpans(
            l10n, p, transitRetrograde[p] ?? false, fontSize)),
    ];
    // Pada codes: light grey, Parashar Light style — visually recessive
    // next to the planets.
    final padaStyle = KJTheme.mono(
      size: fontSize * 0.85,
      color: KJColors.inkSoft.withValues(alpha: 0.65),
    );
    final padaChips = <(List<InlineSpan>, double)>[
      for (final l in padaLabels)
        _measure([TextSpan(text: l, style: padaStyle)]),
    ];
    // Bhava madhya line — same recessive grey as padas, but it sits
    // WITHIN the planet block (as its own row) rather than after it.
    final cuspChip = cuspLabel == null
        ? null
        : _measure(signsPassedSpans(cuspLabel, padaStyle));
    final gapW = _measure([TextSpan(text: '  ', style: gapStyle)]).$2;

    // Flow chips into rows; a chip is never split.
    List<List<List<InlineSpan>>> flow(
        List<(List<InlineSpan>, double)> chips, bool single) {
      final rows = <List<List<InlineSpan>>>[];
      var row = <List<InlineSpan>>[];
      var rowW = 0.0;
      for (final (spans, w) in chips) {
        final needed = row.isEmpty ? w : rowW + gapW + w;
        if (row.isNotEmpty && (single || needed > maxWidth)) {
          rows.add(row);
          row = [spans];
          rowW = w;
        } else {
          row.add(spans);
          rowW = needed;
        }
      }
      if (row.isNotEmpty) rows.add(row);
      return rows;
    }

    // Split the asc+planet chips at the madhya's slot so the cusp line
    // lands on its own row between the before- and after-madhya grahas.
    // An As chip at or before the slot (asc coincides with the madhya in
    // Sripati house 1) stays ABOVE the cusp line.
    final splitAt = cuspChip == null
        ? chips.length
        : math.min(chips.length,
            effCuspAfter + (ascPos != null && ascPos <= effCuspAfter ? 1 : 0));
    final rowSpans = [
      ...flow(chips.sublist(0, splitAt), onePerRow),
      if (cuspChip != null) [cuspChip.$1],
      ...flow(chips.sublist(splitAt), onePerRow),
      ...flow(padaChips, false), // pada codes always flow compactly
      ...flow(transitChips, false), // transit chips always flow compactly
    ];

    return [
      for (final row in rowSpans)
        TextPainter(
          text: TextSpan(children: [
            for (var i = 0; i < row.length; i++) ...[
              if (i > 0) TextSpan(text: '  ', style: gapStyle),
              ...row[i],
            ],
          ]),
          textDirection: TextDirection.ltr,
        )..layout(),
    ];
  }

  static (List<InlineSpan>, double) _measure(List<InlineSpan> spans) {
    final tp = TextPainter(
      text: TextSpan(children: spans),
      textDirection: TextDirection.ltr,
    )..layout();
    return (spans, tp.width);
  }
}

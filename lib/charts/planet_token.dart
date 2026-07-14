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
/// colours from the active palette ([TEPalette.planets]).
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/astro/dignity.dart';
import '../core/astro/models.dart';
import '../core/theme/theme.dart';
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
  });

  final Planet planet;
  final bool retrograde;
  final double? degreeInSign;
  final String? karaka;
  final PlanetDignity dignity;
  final bool combust;

  /// The lunar nodes are retrograde by definition — never worth
  /// flagging on-chart — so the marker is suppressed regardless of
  /// [retrograde].
  bool get showRetrograde =>
      retrograde && planet != Planet.rahu && planet != Planet.ketu;
}

/// Builds a single planet's label (used by the Circular painter, which
/// stagger-places one planet at a time rather than grouping a whole
/// house into one block). Shares the same glyph conventions as
/// [HouseLabelLayout] so all three chart styles read consistently.
TextPainter singleTokenPainter(
  PlanetToken token, {
  required double fontSize,
  bool showDegrees = false,
  bool showKarakas = false,
  bool isTransit = false,
}) {
  final spans = isTransit
      ? _transitChipSpans(
          token.planet, token.showRetrograde, fontSize)
      : _natalChipSpans(token, fontSize,
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
  PlanetToken t,
  double fontSize, {
  required bool showDegrees,
  required bool showKarakas,
}) {
  final tune = chartTuning.value; // Settings > Chart text
  final modSize = fontSize * tune.annotationScale;
  final ink = planetInk(t.planet);
  final base = TETheme.mono(size: fontSize, color: ink, weight: tune.weight);
  final mod = TETheme.mono(size: modSize, color: TEColors.inkSoft);
  final degreeStyle = TETheme.mono(size: modSize, color: TEColors.inkSoft);
  final karakaStyle = TETheme.mono(
      size: modSize, color: TEColors.maroon, weight: FontWeight.w600);

  final spans = <InlineSpan>[TextSpan(text: t.planet.abbr, style: base)];
  if (t.showRetrograde) {
    spans.add(TextSpan(text: '®', style: mod.copyWith(color: ink)));
  }
  switch (t.dignity) {
    case PlanetDignity.exalted:
      spans.add(TextSpan(text: '↑', style: mod.copyWith(color: TEColors.forest)));
    case PlanetDignity.debilitated:
      spans.add(TextSpan(text: '↓', style: mod.copyWith(color: TEColors.maroon)));
    case PlanetDignity.ownSign:
      spans.add(TextSpan(text: '○', style: mod));
    case PlanetDignity.none:
      break;
  }
  if (t.combust) {
    spans.add(TextSpan(text: '•', style: mod.copyWith(color: TEColors.maroon)));
  }
  if (showDegrees && t.degreeInSign != null) {
    // Non-breaking space: the degree may never wrap away from its planet.
    final d = t.degreeInSign!;
    final degText =
        tune.degreeMinutes ? formatDegreeInSign(d) : '${(d % 30).floor()}°';
    spans.add(TextSpan(text: ' $degText', style: degreeStyle));
  }
  if (showKarakas && t.karaka != null) {
    spans.add(TextSpan(text: ' ${t.karaka}', style: karakaStyle));
  }
  return spans;
}

/// A transit (current-sky) planet chip: lowercase, italic, transit
/// green — visually distinct from natal planets.
List<InlineSpan> _transitChipSpans(
    Planet p, bool retrograde, double fontSize) {
  final base = TETheme.mono(size: fontSize * 0.85, color: TEColors.transit)
      .copyWith(fontStyle: FontStyle.italic);
  final spans = <InlineSpan>[
    TextSpan(text: p.abbr.toLowerCase(), style: base),
  ];
  final isNode = p == Planet.rahu || p == Planet.ketu;
  if (!isNode && retrograde) {
    spans.add(TextSpan(
        text: '®',
        style: TETheme.mono(size: fontSize * 0.61, color: TEColors.transit)));
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
    required List<PlanetToken> tokens,
    List<Planet> transitPlanets = const [],
    Map<Planet, bool> transitRetrograde = const {},
    List<String> padaLabels = const [],
    String? ascLabel,
    required double maxWidth,
    required double maxHeight,
    required double baseFontSize,
    bool showDegrees = false,
    bool showKarakas = false,
    double? minFontScale,
  }) {
    // Shrink floor: explicit arg wins, else Settings > Chart text.
    final floor = minFontScale ?? chartTuning.value.minFontScale;
    List<TextPainter> pack(double fontSize, {required bool onePerRow}) =>
        _pack(
          tokens: tokens,
          transitPlanets: transitPlanets,
          transitRetrograde: transitRetrograde,
          padaLabels: padaLabels,
          ascLabel: ascLabel,
          fontSize: fontSize,
          maxWidth: maxWidth,
          showDegrees: showDegrees,
          showKarakas: showKarakas,
          onePerRow: onePerRow,
        );

    var scale = 1.0;
    var result = pack(baseFontSize, onePerRow: showDegrees);
    while ((_height(result) > maxHeight || _width(result) > maxWidth) &&
        scale > floor) {
      scale = math.max(floor, scale - 0.1);
      result = pack(baseFontSize * scale, onePerRow: showDegrees);
    }
    // Last resort for extremely crowded houses: abandon one-per-row and
    // flow several chips per line at minimum scale.
    if (showDegrees && _height(result) > maxHeight) {
      result = pack(baseFontSize * floor, onePerRow: false);
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
    required List<PlanetToken> tokens,
    required List<Planet> transitPlanets,
    required Map<Planet, bool> transitRetrograde,
    required List<String> padaLabels,
    required String? ascLabel,
    required double fontSize,
    required double maxWidth,
    required bool showDegrees,
    required bool showKarakas,
    required bool onePerRow,
  }) {
    final gapStyle = TETheme.mono(size: fontSize);

    // Build every chip with its measured width.
    final chips = <(List<InlineSpan>, double)>[];
    if (ascLabel != null) {
      chips.add(_measure([
        TextSpan(
          text: ascLabel,
          style: TETheme.mono(
              size: fontSize * 0.9,
              color: TEColors.maroon,
              weight: FontWeight.w600),
        ),
      ]));
    }
    for (final t in tokens) {
      chips.add(_measure(_natalChipSpans(t, fontSize,
          showDegrees: showDegrees, showKarakas: showKarakas)));
    }
    final transitChips = <(List<InlineSpan>, double)>[
      for (final p in transitPlanets)
        _measure(
            _transitChipSpans(p, transitRetrograde[p] ?? false, fontSize)),
    ];
    // Pada codes: light grey, Parashar Light style — visually recessive
    // next to the planets.
    final padaStyle = TETheme.mono(
      size: fontSize * 0.85,
      color: TEColors.inkSoft.withValues(alpha: 0.65),
    );
    final padaChips = <(List<InlineSpan>, double)>[
      for (final l in padaLabels)
        _measure([TextSpan(text: l, style: padaStyle)]),
    ];
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

    final rowSpans = [
      ...flow(chips, onePerRow),
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

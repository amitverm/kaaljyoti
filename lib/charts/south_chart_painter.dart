import 'package:flutter/material.dart';

import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import 'chart_tuning.dart';
import 'planet_token.dart';

/// Sign under [pos] in a South chart of [size], or null for the empty
/// center 2×2.
ZodiacSign? southSignHit(Size size, Offset pos) {
  final col = (pos.dx / size.width * 4).floor().clamp(0, 3);
  final row = (pos.dy / size.height * 4).floor().clamp(0, 3);
  for (final e in SouthChartPainter.cells.entries) {
    if (e.value == (row, col)) return e.key;
  }
  return null;
}

/// South Indian (fixed grid) chart.
///
/// A 4×4 grid whose center 2×2 is empty. Signs never move: Pisces sits in
/// the top-left cell and the zodiac proceeds clockwise around the ring.
/// The [lagna] cell (house 1 under the current "view from" anchor) is
/// tinted and struck with a short maroon diagonal. The true ascendant
/// sign is always marked separately with an "Asc" label (+ degree, if
/// known), independent of [lagna].
class SouthChartPainter extends CustomPainter {
  SouthChartPainter({
    required this.l10n,
    required this.placements,
    required this.lagna,
    this.retrograde = const {},
    this.trueAscendantSign,
    this.ascendantDegree,
    this.tokens = const {},
    this.showDegrees = false,
    this.showKarakas = false,
    this.transitPlacements,
    this.transitRetrograde = const {},
    this.padaLabels = const {},
    // Repaint live when the chart text settings change.
  }) : super(repaint: chartTuning);

  /// Localized strings for the graha/rashi tokens. A painter has no
  /// BuildContext at paint time, so the host widget injects it.
  final AppLocalizations l10n;

  final Map<ZodiacSign, List<Planet>> placements;
  final ZodiacSign lagna;
  final Map<Planet, bool> retrograde;
  final ZodiacSign? trueAscendantSign;
  final double? ascendantDegree;
  final Map<Planet, PlanetToken> tokens;
  final bool showDegrees;
  final bool showKarakas;
  final Map<ZodiacSign, List<Planet>>? transitPlacements;
  final Map<Planet, bool> transitRetrograde;

  /// Arudha pada codes ('1P' … '12P') per sign, rendered as a light-
  /// grey trailing line in each cell (Parashar Light style).
  final Map<ZodiacSign, List<String>> padaLabels;

  /// Fixed (row, col) for each sign in the 4×4 ring, clockwise from
  /// Pisces at the top-left corner. Public so hit-testing
  /// ([southSignHit]) shares the exact layout.
  static const Map<ZodiacSign, (int, int)> cells = {
    ZodiacSign.pisces: (0, 0),
    ZodiacSign.aries: (0, 1),
    ZodiacSign.taurus: (0, 2),
    ZodiacSign.gemini: (0, 3),
    ZodiacSign.cancer: (1, 3),
    ZodiacSign.leo: (2, 3),
    ZodiacSign.virgo: (3, 3),
    ZodiacSign.libra: (3, 2),
    ZodiacSign.scorpio: (3, 1),
    ZodiacSign.sagittarius: (3, 0),
    ZodiacSign.capricorn: (2, 0),
    ZodiacSign.aquarius: (1, 0),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final base = size.shortestSide;
    final strokeW = (base * 0.004).clamp(1.0, 1.6).toDouble();
    final rect = (Offset.zero & size).deflate(strokeW / 2);
    final cellW = rect.width / 4;
    final cellH = rect.height / 4;
    final trueAsc = trueAscendantSign ?? lagna;

    Rect cellRect(int row, int col) => Rect.fromLTWH(
          rect.left + col * cellW,
          rect.top + row * cellH,
          cellW,
          cellH,
        );

    // Ground.
    canvas.drawRect(Offset.zero & size, Paint()..color = KJColors.paper);

    // Ascendant cell tint — follows the TRUE ascendant, not the
    // "view from" rotation anchor, so the highlight never lies about
    // where the lagna is.
    final (ascRow, ascCol) = cells[trueAsc]!;
    final ascCell = cellRect(ascRow, ascCol);
    canvas.drawRect(
      ascCell,
      Paint()..color = KJColors.maroon.withValues(alpha: 0.08),
    );

    // Grid: outer frame plus each ring cell (center 2×2 stays open).
    final line = Paint()
      ..color = KJColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeJoin = StrokeJoin.miter;
    canvas.drawRect(rect, line);
    for (final (row, col) in cells.values) {
      canvas.drawRect(cellRect(row, col), line);
    }

    // Ascendant marker: short maroon diagonal across the cell's
    // top-left corner.
    final diagLen = cellW * 0.28;
    canvas.drawLine(
      Offset(ascCell.left + diagLen, ascCell.top),
      Offset(ascCell.left, ascCell.top + diagLen),
      Paint()
        ..color = KJColors.maroon
        ..strokeWidth = strokeW * 1.2
        ..strokeCap = StrokeCap.round,
    );

    final tune = chartTuning.value; // Settings > Chart text
    final planetSize = base * 0.036 * tune.baseScale;
    final signSize = base * 0.024 * tune.signScale;
    final pad = cellW * 0.06;

    for (final sign in ZodiacSign.values) {
      final (row, col) = cells[sign]!;
      final cell = cellRect(row, col);

      // Sign abbreviation, tucked into the top-right corner.
      final signTp = _layout(
        sign.abbrLabel(l10n),
        KJTheme.mono(
          size: signSize,
          color: sign == trueAsc ? KJColors.maroon : KJColors.inkSoft,
          weight: sign == trueAsc ? FontWeight.w600 : FontWeight.w400,
        ),
        cellW,
      );
      signTp.paint(
        canvas,
        Offset(cell.right - pad - signTp.width, cell.top + pad),
      );

      // Ascendant marker, tucked into the bottom-left corner — kept
      // clear of the sign abbreviation (top-right) AND the lagna
      // diagonal stroke (top-left), which otherwise collide with it in
      // the common case where the ascendant's sign is also the current
      // house-1 cell.
      if (sign == trueAsc) {
        final deg = ascendantDegree;
        final ascTp = _layout(
          deg != null
              ? '${l10n.chartAsc} ${formatDegreeInSign(deg)}'
              : l10n.chartAsc,
          KJTheme.mono(
              size: signSize, color: KJColors.maroon, weight: FontWeight.w600),
          cellW,
        );
        ascTp.paint(
          canvas,
          Offset(cell.left + pad, cell.bottom - pad - ascTp.height),
        );
      }

      // Planet labels, centered and wrapped/shrunk to fit within the
      // cell — replaces the old single unbroken joined string.
      final planets = placements[sign] ?? const <Planet>[];
      final transitPlanets = transitPlacements?[sign] ?? const <Planet>[];
      final padas = padaLabels[sign] ?? const <String>[];
      if (planets.isEmpty && transitPlanets.isEmpty && padas.isEmpty) {
        continue;
      }
      final planetTokens = [
        for (final p in planets)
          tokens[p] ??
              PlanetToken(planet: p, retrograde: retrograde[p] ?? false),
      ];
      final layout = HouseLabelLayout(
        l10n: l10n,
        tokens: planetTokens,
        transitPlanets: transitPlanets,
        transitRetrograde: transitRetrograde,
        padaLabels: padas,
        maxWidth: cellW * 0.82 * tune.contentInflate,
        maxHeight: cellH * 0.7 * tune.contentInflate,
        baseFontSize: planetSize,
        showDegrees: showDegrees,
        showKarakas: showKarakas,
      );
      layout.paint(canvas, cell.center);
    }
  }

  TextPainter _layout(String text, TextStyle style, double maxWidth) =>
      TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: maxWidth);

  // Captured at construction: paint output depends on the active
  // palette, so a palette change must trigger a repaint.
  final KJPalette _palette = KJColors.current;

  @override
  bool shouldRepaint(covariant SouthChartPainter oldDelegate) =>
      oldDelegate.lagna != lagna ||
      oldDelegate.placements != placements ||
      oldDelegate.retrograde != retrograde ||
      oldDelegate.trueAscendantSign != trueAscendantSign ||
      oldDelegate.ascendantDegree != ascendantDegree ||
      oldDelegate.tokens != tokens ||
      oldDelegate.showDegrees != showDegrees ||
      oldDelegate.showKarakas != showKarakas ||
      oldDelegate.transitPlacements != transitPlacements ||
      oldDelegate.transitRetrograde != transitRetrograde ||
      oldDelegate.padaLabels != padaLabels ||
      oldDelegate.l10n != l10n ||
      oldDelegate._palette != _palette;
}

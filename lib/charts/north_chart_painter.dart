import 'package:flutter/material.dart';

import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import 'chart_tuning.dart';
import 'planet_token.dart';

/// One North-chart house's geometry: centroid + inner vertex (the sign
/// number sits on the segment between them) and the largest axis-
/// aligned content rect inside the house's triangle/diamond shape.
typedef NorthHouse = ({Offset centroid, Offset vertex, Rect content});

/// Geometry for the 12 North-chart houses within [rect]
/// (index 0 = house 1, counter-clockwise). Shared by the planet chart
/// painter and the ashtakavarga (bindu) painter so the diamond layout
/// exists in exactly one place.
List<NorthHouse> northHouseGeometry(Rect rect) {
  Offset at(double fx, double fy) =>
      Offset(rect.left + rect.width * fx, rect.top + rect.height * fy);
  Rect box(double l, double t, double w, double h) => Rect.fromLTWH(
      rect.left + rect.width * l,
      rect.top + rect.height * t,
      rect.width * w,
      rect.height * h);
  return [
    // 1: top diamond
    (centroid: at(0.50, 0.25), vertex: at(0.50, 0.50), content: box(0.38, 0.14, 0.24, 0.22)),
    // 2: top-left edge triangle — content hugs the wide top edge
    (centroid: at(0.25, 1 / 12), vertex: at(0.25, 0.25), content: box(0.145, 0.025, 0.21, 0.11)),
    // 3: left-top corner triangle — content stacks along the tall left edge
    (centroid: at(1 / 12, 0.25), vertex: at(0.25, 0.25), content: box(0.02, 0.14, 0.115, 0.22)),
    // 4: left diamond
    (centroid: at(0.25, 0.50), vertex: at(0.50, 0.50), content: box(0.13, 0.39, 0.24, 0.22)),
    // 5: left-bottom corner triangle
    (centroid: at(1 / 12, 0.75), vertex: at(0.25, 0.75), content: box(0.02, 0.64, 0.115, 0.22)),
    // 6: bottom-left edge triangle
    (centroid: at(0.25, 11 / 12), vertex: at(0.25, 0.75), content: box(0.145, 0.865, 0.21, 0.11)),
    // 7: bottom diamond
    (centroid: at(0.50, 0.75), vertex: at(0.50, 0.50), content: box(0.38, 0.64, 0.24, 0.22)),
    // 8: bottom-right edge triangle
    (centroid: at(0.75, 11 / 12), vertex: at(0.75, 0.75), content: box(0.645, 0.865, 0.21, 0.11)),
    // 9: right-bottom corner triangle
    (centroid: at(11 / 12, 0.75), vertex: at(0.75, 0.75), content: box(0.865, 0.64, 0.115, 0.22)),
    // 10: right diamond
    (centroid: at(0.75, 0.50), vertex: at(0.50, 0.50), content: box(0.63, 0.39, 0.24, 0.22)),
    // 11: right-top corner triangle
    (centroid: at(11 / 12, 0.25), vertex: at(0.75, 0.25), content: box(0.865, 0.14, 0.115, 0.22)),
    // 12: top-right edge triangle
    (centroid: at(0.75, 1 / 12), vertex: at(0.75, 0.25), content: box(0.645, 0.025, 0.21, 0.11)),
  ];
}

/// House polygons (normalized 0..1 coordinates) for hit-testing the
/// North chart — index 0 = house 1, matching [northHouseGeometry].
const List<List<(double, double)>> _northPolys = [
  [(0.5, 0), (0.75, 0.25), (0.5, 0.5), (0.25, 0.25)], // 1
  [(0, 0), (0.5, 0), (0.25, 0.25)], // 2
  [(0, 0), (0.25, 0.25), (0, 0.5)], // 3
  [(0, 0.5), (0.25, 0.25), (0.5, 0.5), (0.25, 0.75)], // 4
  [(0, 0.5), (0.25, 0.75), (0, 1)], // 5
  [(0, 1), (0.25, 0.75), (0.5, 1)], // 6
  [(0.5, 1), (0.25, 0.75), (0.5, 0.5), (0.75, 0.75)], // 7
  [(0.5, 1), (0.75, 0.75), (1, 1)], // 8
  [(1, 1), (0.75, 0.75), (1, 0.5)], // 9
  [(1, 0.5), (0.75, 0.75), (0.5, 0.5), (0.75, 0.25)], // 10
  [(1, 0.5), (0.75, 0.25), (1, 0)], // 11
  [(1, 0), (0.75, 0.25), (0.5, 0)], // 12
];

bool _inPoly(List<(double, double)> poly, double x, double y) {
  var inside = false;
  for (var i = 0, j = poly.length - 1; i < poly.length; j = i++) {
    final (xi, yi) = poly[i];
    final (xj, yj) = poly[j];
    if ((yi > y) != (yj > y) &&
        x < (xj - xi) * (y - yi) / (yj - yi) + xi) {
      inside = !inside;
    }
  }
  return inside;
}

/// House (1–12) under [pos] in a North chart of [size], or null.
int? northHouseHit(Size size, Offset pos) {
  final x = pos.dx / size.width;
  final y = pos.dy / size.height;
  if (x < 0 || x > 1 || y < 0 || y > 1) return null;
  for (var h = 0; h < 12; h++) {
    if (_inPoly(_northPolys[h], x, y)) return h + 1;
  }
  return null;
}

/// Draws the North chart's ground, the tinted house, frame, diagonals
/// and inner diamond. Shared by the planet and bindu painters.
/// [tintHouse] (1–12) picks which house gets the maroon wash — the
/// planet painter passes the TRUE ascendant's house so the highlight
/// travels with the Ascendant when the chart is rotated via "view
/// from", instead of clinging to the top diamond.
void drawNorthFrame(Canvas canvas, Size size, Rect rect, double strokeW,
    {int tintHouse = 1}) {
  canvas.drawRect(Offset.zero & size, Paint()..color = TEColors.paper);
  final poly = _northPolys[(tintHouse - 1).clamp(0, 11)];
  final tintPath = Path()
    ..moveTo(rect.left + rect.width * poly.first.$1,
        rect.top + rect.height * poly.first.$2);
  for (final (fx, fy) in poly.skip(1)) {
    tintPath.lineTo(rect.left + rect.width * fx, rect.top + rect.height * fy);
  }
  tintPath.close();
  canvas.drawPath(
    tintPath,
    Paint()..color = TEColors.maroon.withValues(alpha: 0.06),
  );
  final line = Paint()
    ..color = TEColors.ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = strokeW
    ..strokeJoin = StrokeJoin.miter;
  canvas.drawRect(rect, line);
  canvas.drawLine(rect.topLeft, rect.bottomRight, line);
  canvas.drawLine(rect.topRight, rect.bottomLeft, line);
  final innerDiamond = Path()
    ..moveTo(rect.topCenter.dx, rect.topCenter.dy)
    ..lineTo(rect.centerRight.dx, rect.centerRight.dy)
    ..lineTo(rect.bottomCenter.dx, rect.bottomCenter.dy)
    ..lineTo(rect.centerLeft.dx, rect.centerLeft.dy)
    ..close();
  canvas.drawPath(innerDiamond, line);
}

/// North Indian (diamond) chart.
///
/// Houses are fixed in position: house 1 (the lagna) is the top-center
/// diamond and houses proceed counter-clockwise. The sign occupying each
/// house rotates with [lagna] and is shown as a small number (1 = Aries
/// … 12 = Pisces) near the house's inner corner.
///
/// [lagna] drives which sign sits in house 1 — normally the true
/// ascendant, but the Birth Chart widget's "view from" selector can
/// pass a different sign to rotate the house numbering while keeping
/// sign-planet placements unchanged. The real ascendant is always
/// marked via an "Asc" label (plus degree, if [ascendantDegree] is
/// given) at [trueAscendantSign]'s house, independent of [lagna].
class NorthChartPainter extends CustomPainter {
  NorthChartPainter({
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
  /// grey trailing line in each house (Parashar Light style).
  final Map<ZodiacSign, List<String>> padaLabels;

  @override
  void paint(Canvas canvas, Size size) {
    final base = size.shortestSide;
    final strokeW = (base * 0.004).clamp(1.0, 1.6).toDouble();
    final rect = (Offset.zero & size).deflate(strokeW / 2);
    final trueAsc = trueAscendantSign ?? lagna;
    final houseOfTrueAsc = (trueAsc.index - lagna.index + 12) % 12;

    // Ground, Ascendant-house tint, frame, diagonals, inner diamond —
    // shared with the bindu (ashtakavarga) painter.
    drawNorthFrame(canvas, size, rect, strokeW,
        tintHouse: houseOfTrueAsc + 1);

    // Shared house geometry: sign numbers sit between vertex and
    // centroid; planet stacks are fitted inside each house's shape-
    // aware content rect, so they can't cross the diagonals into a
    // neighboring house or sit on the rashi number.
    final houses = northHouseGeometry(rect);

    final tune = chartTuning.value; // Settings > Chart text
    final planetSize = base * 0.036 * tune.baseScale;
    final signSize = base * 0.026 * tune.signScale;

    for (var n = 1; n <= 12; n++) {
      final h = houses[n - 1];
      final signNumber = ((lagna.index + n - 1) % 12) + 1;
      final sign = ZodiacSign.values[signNumber - 1];
      final isTrueAsc = (n - 1) == houseOfTrueAsc;

      // Sign number, tucked toward the house's inner corner. The TRUE
      // ascendant's house gets the maroon emphasis so it stays with
      // the Ascendant under "view from" rotation.
      final signTp = TextPainter(
        text: TextSpan(
          text: '$signNumber',
          style: TETheme.mono(
            size: signSize,
            color: isTrueAsc ? TEColors.maroon : TEColors.inkSoft,
            weight: isTrueAsc ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      _paintCentered(canvas, signTp, Offset.lerp(h.vertex, h.centroid, 0.25)!);

      // Planet labels, Parashar Light style: one planet per line when
      // degrees are shown, each planet+degree an unbreakable unit, the
      // ascendant stacked as the first line of its house, and the whole
      // block fitted inside the house's shape-aware content rect so it
      // stays clear of the diagonals and the sign number.
      final planets = placements[sign] ?? const <Planet>[];
      final transitPlanets = transitPlacements?[sign] ?? const <Planet>[];
      final padas = padaLabels[sign] ?? const <String>[];
      final deg = ascendantDegree;
      final ascLabel = isTrueAsc
          ? (deg != null ? 'As ${formatDegreeInSign(deg)}' : 'As')
          : null;
      if (planets.isEmpty &&
          transitPlanets.isEmpty &&
          padas.isEmpty &&
          ascLabel == null) {
        continue;
      }
      final planetTokens = [
        for (final p in planets)
          tokens[p] ?? PlanetToken(planet: p, retrograde: retrograde[p] ?? false),
      ];
      // Settings > Chart text: "Text area within house" inflates the
      // conservative content rects (the narrow corner/edge triangles
      // are what makes single planets tiny in the North chart).
      final content = Rect.fromCenter(
        center: h.content.center,
        width: h.content.width * tune.contentInflate,
        height: h.content.height * tune.contentInflate,
      );
      final layout = HouseLabelLayout(
        tokens: planetTokens,
        transitPlanets: transitPlanets,
        transitRetrograde: transitRetrograde,
        padaLabels: padas,
        ascLabel: ascLabel,
        maxWidth: content.width,
        maxHeight: content.height,
        baseFontSize: planetSize,
        showDegrees: showDegrees,
        showKarakas: showKarakas,
      );
      layout.paint(canvas, content.center);
    }
  }

  void _paintCentered(Canvas canvas, TextPainter tp, Offset center) =>
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));

  // Captured at construction: paint output depends on the active
  // palette, so a palette change must trigger a repaint.
  final TEPalette _palette = TEColors.current;

  @override
  bool shouldRepaint(covariant NorthChartPainter oldDelegate) =>
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
      oldDelegate._palette != _palette;
}

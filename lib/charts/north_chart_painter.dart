import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
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
    (
      centroid: at(0.50, 0.25),
      vertex: at(0.50, 0.50),
      content: box(0.38, 0.14, 0.24, 0.22)
    ),
    // 2: top-left edge triangle — content hugs the wide top edge
    (
      centroid: at(0.25, 1 / 12),
      vertex: at(0.25, 0.25),
      content: box(0.145, 0.025, 0.21, 0.11)
    ),
    // 3: left-top corner triangle — content stacks along the tall left edge
    (
      centroid: at(1 / 12, 0.25),
      vertex: at(0.25, 0.25),
      content: box(0.02, 0.14, 0.115, 0.22)
    ),
    // 4: left diamond
    (
      centroid: at(0.25, 0.50),
      vertex: at(0.50, 0.50),
      content: box(0.13, 0.39, 0.24, 0.22)
    ),
    // 5: left-bottom corner triangle
    (
      centroid: at(1 / 12, 0.75),
      vertex: at(0.25, 0.75),
      content: box(0.02, 0.64, 0.115, 0.22)
    ),
    // 6: bottom-left edge triangle
    (
      centroid: at(0.25, 11 / 12),
      vertex: at(0.25, 0.75),
      content: box(0.145, 0.865, 0.21, 0.11)
    ),
    // 7: bottom diamond
    (
      centroid: at(0.50, 0.75),
      vertex: at(0.50, 0.50),
      content: box(0.38, 0.64, 0.24, 0.22)
    ),
    // 8: bottom-right edge triangle
    (
      centroid: at(0.75, 11 / 12),
      vertex: at(0.75, 0.75),
      content: box(0.645, 0.865, 0.21, 0.11)
    ),
    // 9: right-bottom corner triangle
    (
      centroid: at(11 / 12, 0.75),
      vertex: at(0.75, 0.75),
      content: box(0.865, 0.64, 0.115, 0.22)
    ),
    // 10: right diamond
    (
      centroid: at(0.75, 0.50),
      vertex: at(0.50, 0.50),
      content: box(0.63, 0.39, 0.24, 0.22)
    ),
    // 11: right-top corner triangle
    (
      centroid: at(11 / 12, 0.25),
      vertex: at(0.75, 0.25),
      content: box(0.865, 0.14, 0.115, 0.22)
    ),
    // 12: top-right edge triangle
    (
      centroid: at(0.75, 1 / 12),
      vertex: at(0.75, 0.25),
      content: box(0.645, 0.025, 0.21, 0.11)
    ),
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
    if ((yi > y) != (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi) {
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
  canvas.drawRect(Offset.zero & size, Paint()..color = KJColors.paper);
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
    Paint()..color = KJColors.maroon.withValues(alpha: 0.06),
  );
  final line = Paint()
    ..color = KJColors.ink
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
    this.houseData,
    this.ascendantHouse,
    this.boundaryLabels,
    this.directionalStack = true,
    this.ascendantRank,
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
  /// grey trailing line in each house (Parashar Light style).
  final Map<ZodiacSign, List<String>> padaLabels;

  /// Cusp-bounded (chalit) mode: when set, drawn house n takes ITS OWN
  /// sign number, planets, and bhava-madhya line from `houseData[n-1]`
  /// instead of deriving them from [lagna]/[placements]. Necessary
  /// because chalit houses are not sign-aligned — two houses may share a
  /// sign and a sign may host no house, which a Map<ZodiacSign, …>
  /// cannot express. The sign-keyed overlays (transit, padas) don't
  /// apply in this mode. [cuspLabel] (e.g. "M 11°16'") is the grey
  /// madhya line; it renders slotted into the planet block after
  /// [cuspAfter] planets, so it reads as a before/after-madhya divider.
  final List<
      ({
        int signNumber,
        List<Planet> planets,
        String? cuspLabel,
        int cuspAfter,
      })>? houseData;

  /// Chalit mode only: which DRAWN house carries the "As" marker and
  /// the ascendant tint (1-based; house 1 unless rotated by cusp).
  final int? ascendantHouse;

  /// Chalit mode only: a label painted ON the dividing line at the
  /// START of each drawn house (index 0 = the boundary opening house 1)
  /// — the bhava sandhi degrees, sitting on the actual line they
  /// describe. Each pair of adjacent house polygons shares exactly one
  /// edge; the label centers on that edge's midpoint.
  final List<String>? boundaryLabels;

  /// Whether planet stacks follow the zodiacal progression spatially
  /// (right-flank houses reversed so each planet sits toward the
  /// neighbouring house it is near). True for charts whose boxes carry a
  /// real degree progression (D1, chalit, transit); divisional (D2+)
  /// charts pass false — their boxes list planets in traditional order.
  final bool directionalStack;

  /// How many planets in the true ascendant's house precede the
  /// ascendant in zodiacal order — the "As" marker slots there, reading
  /// like any other body in the progression (Parashar Light style).
  /// Null pins As as the house's first line instead.
  final int? ascendantRank;

  @override
  void paint(Canvas canvas, Size size) {
    final base = size.shortestSide;
    final strokeW = (base * 0.004).clamp(1.0, 1.6).toDouble();
    final rect = (Offset.zero & size).deflate(strokeW / 2);
    final trueAsc = trueAscendantSign ?? lagna;
    final houseOfTrueAsc = houseData != null
        ? (ascendantHouse ?? 1) - 1
        : (trueAsc.index - lagna.index + 12) % 12;

    // Ground, Ascendant-house tint, frame, diagonals, inner diamond —
    // shared with the bindu (ashtakavarga) painter.
    drawNorthFrame(canvas, size, rect, strokeW, tintHouse: houseOfTrueAsc + 1);

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
      final signNumber =
          houseData?[n - 1].signNumber ?? ((lagna.index + n - 1) % 12) + 1;
      final sign = ZodiacSign.values[signNumber - 1];
      final isTrueAsc = (n - 1) == houseOfTrueAsc;

      // Sign number, tucked toward the house's inner corner. The TRUE
      // ascendant's house gets the maroon emphasis so it stays with
      // the Ascendant under "view from" rotation.
      final signTp = TextPainter(
        text: TextSpan(
          text: '$signNumber',
          style: KJTheme.mono(
            size: signSize,
            color: isTrueAsc ? KJColors.maroon : KJColors.inkSoft,
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
      final planets =
          houseData?[n - 1].planets ?? placements[sign] ?? const <Planet>[];
      final transitPlanets = houseData != null
          ? const <Planet>[]
          : transitPlacements?[sign] ?? const <Planet>[];
      final padas = houseData != null
          ? const <String>[]
          : padaLabels[sign] ?? const <String>[];
      final cuspLabel = houseData?[n - 1].cuspLabel;
      final cuspAfter = houseData?[n - 1].cuspAfter ?? 0;
      final deg = ascendantDegree;
      final ascLabel = isTrueAsc
          ? (deg != null ? 'As ${formatDegreeInSign(deg)}' : 'As')
          : null;
      if (planets.isEmpty &&
          transitPlanets.isEmpty &&
          padas.isEmpty &&
          cuspLabel == null &&
          ascLabel == null) {
        continue;
      }
      final planetTokens = [
        for (final p in planets)
          tokens[p] ??
              PlanetToken(planet: p, retrograde: retrograde[p] ?? false),
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
        l10n: l10n,
        tokens: planetTokens,
        transitPlanets: transitPlanets,
        transitRetrograde: transitRetrograde,
        padaLabels: padas,
        cuspLabel: cuspLabel,
        cuspAfter: cuspAfter,
        ascLabel: ascLabel,
        ascAfter: ascendantRank,
        // Houses progress anticlockwise: down the left flank, up the
        // right. Drawn houses 8–12 (bottom-right corner up through
        // top-right) enter from below, so their stack reverses — each
        // planet sits toward the neighbouring house it is nearest.
        reverseStack: directionalStack && n >= 8,
        maxWidth: content.width,
        maxHeight: content.height,
        // Room before the chart FRAME, where text is really clipped —
        // the block is centred, so twice the distance to the nearer
        // vertical edge. Brushing internal diagonals is tolerated.
        clipWidth: 2 *
            math.min(content.center.dx - rect.left,
                rect.right - content.center.dx),
        baseFontSize: planetSize,
        showDegrees: showDegrees,
        showKarakas: showKarakas,
      );
      layout.paint(canvas, content.center);
    }

    // Sandhi labels ALONG and ON the dividing lines (chalit mode). The
    // boundary opening drawn house i+1 is the edge its polygon shares
    // with the previous house's polygon; the label is rotated parallel
    // to that edge and sits centered ON it over a paper wash — a label
    // nudged into a house reads as house data, but a sandhi belongs to
    // the boundary itself.
    final boundaries = boundaryLabels;
    if (houseData != null && boundaries != null) {
      final labelSize = base * 0.030 * tune.annotationScale;
      for (var i = 0; i < 12; i++) {
        final label = boundaries[i];
        if (label.isEmpty) continue;
        final prev = _northPolys[(i + 11) % 12];
        final own = _northPolys[i];
        final shared = [
          for (final v in own)
            if (prev.contains(v)) v
        ];
        if (shared.length < 2) continue;
        Offset at((double, double) v) => Offset(
            rect.left + rect.width * v.$1, rect.top + rect.height * v.$2);
        final p1 = at(shared[0]);
        final p2 = at(shared[1]);
        final mid = (p1 + p2) / 2;
        // Angle of the edge, normalized so text is never upside down.
        var angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);
        if (angle > math.pi / 2) angle -= math.pi;
        if (angle <= -math.pi / 2) angle += math.pi;
        final tp = TextPainter(
          // signsPassedSpans enlarges the ˢ so "10ˢ23°30'" stays
          // legible at this label size; plain labels pass through.
          text: TextSpan(
            children: signsPassedSpans(
              label,
              KJTheme.mono(size: labelSize, color: KJColors.inkSoft),
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        canvas.save();
        canvas.translate(mid.dx, mid.dy);
        canvas.rotate(angle);
        // Paper wash in the rotated frame, so the line disappears
        // behind the label instead of striking through it.
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
                center: Offset.zero,
                width: tp.width + 6,
                height: tp.height + 2),
            const Radius.circular(2),
          ),
          Paint()..color = KJColors.paper.withValues(alpha: 0.92),
        );
        tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
        canvas.restore();
      }
    }
  }

  void _paintCentered(Canvas canvas, TextPainter tp, Offset center) =>
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));

  // Captured at construction: paint output depends on the active
  // palette, so a palette change must trigger a repaint.
  final KJPalette _palette = KJColors.current;

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
      oldDelegate.houseData != houseData ||
      oldDelegate.ascendantHouse != ascendantHouse ||
      oldDelegate.boundaryLabels != boundaryLabels ||
      oldDelegate.directionalStack != directionalStack ||
      oldDelegate.ascendantRank != ascendantRank ||
      oldDelegate.l10n != l10n ||
      oldDelegate._palette != _palette;
}

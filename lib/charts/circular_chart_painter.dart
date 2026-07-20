import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import 'chart_tuning.dart';
import 'planet_token.dart';

/// Sector index (0 = the lagna sector, counter-clockwise) under [pos]
/// in a Circular chart of [size], or null outside the wheel.
int? circularSectorHit(Size size, Offset pos) {
  final center = Offset(size.width / 2, size.height / 2);
  final d = pos - center;
  if (d.distance > size.shortestSide / 2) return null;
  // Sector k spans angles [π − (k+1)·π/6, π − k·π/6] (see paint()).
  final a = math.atan2(d.dy, d.dx);
  var t = (math.pi - a) % (2 * math.pi);
  if (t < 0) t += 2 * math.pi;
  return (t / (math.pi / 6)).floor().clamp(0, 11);
}

/// Circular (wheel) chart.
///
/// Twelve equal 30° sectors. The [lagna] sign's sector starts at 9
/// o'clock (180°) and signs proceed counter-clockwise around the wheel
/// — [lagna] is the "view from" anchor and may differ from the true
/// ascendant. Sign names sit horizontally in the outer ring band;
/// planets are staggered at decreasing radii inside their sector to
/// avoid overlap. An "As" marker (+ degree, if known) always sits in
/// the true ascendant's sector, independent of the wheel's rotation.
class CircularChartPainter extends CustomPainter {
  CircularChartPainter({
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
    this.showNakshatras = true,
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

  /// Arudha pada codes ('1P' … '12P') per sign, rendered as a small
  /// light-grey label just inside the ring band (Parashar Light style).
  final Map<ZodiacSign, List<String>> padaLabels;

  /// Draws a thin outermost ring of the 27 nakshatras (13°20' segments,
  /// aligned to sidereal longitude, rotating with the wheel). Segment
  /// abbreviations are shown when the chart is large enough to keep
  /// them legible; on small cards only the boundary ticks render.
  final bool showNakshatras;

  @override
  void paint(Canvas canvas, Size size) {
    final base = size.shortestSide;
    final strokeW = (base * 0.004).clamp(1.0, 1.6).toDouble();
    final center = Offset(size.width / 2, size.height / 2);
    final r = base / 2 - strokeW / 2;
    // With the nakshatra ring on, the outermost band (r → nakInner)
    // holds the 27 nakshatra segments and the sign band moves inward;
    // with it off the geometry is unchanged from the classic layout.
    final nakInner = showNakshatras ? r * 0.93 : r;
    final bandInner = showNakshatras ? r * 0.77 : r * 0.82;
    final trueAsc = trueAscendantSign ?? lagna;

    Offset at(double angle, double radius) =>
        center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);

    // Canvas angles increase clockwise on screen, so a counter-clockwise
    // sign progression means each successive sector spans a smaller angle.
    // Sector k (k signs after the lagna) covers [π − (k+1)·π/6, π − k·π/6].
    double sectorStart(int k) => math.pi - (k + 1) * math.pi / 6;
    double sectorMid(int k) => math.pi - (k + 0.5) * math.pi / 6;

    // Ground.
    canvas.drawRect(Offset.zero & size, Paint()..color = KJColors.paper);

    // Ascendant sector tint (full wedge, hub to rim) — follows the
    // TRUE ascendant, not the "view from" rotation anchor.
    final ascK = (trueAsc.index - lagna.index + 12) % 12;
    final ascWedge = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: r),
        sectorStart(ascK),
        math.pi / 6,
        false,
      )
      ..close();
    canvas.drawPath(
      ascWedge,
      Paint()..color = KJColors.maroon.withValues(alpha: 0.08),
    );

    // Rim, ring-band boundary, and radial dividers.
    final line = Paint()
      ..color = KJColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;
    canvas.drawCircle(center, r, line);
    canvas.drawCircle(center, bandInner, line);
    final divider = Paint()
      ..color = KJColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW * 0.7;
    // Sector dividers stop at the nakshatra band (when shown) so sign
    // boundaries aren't mistaken for nakshatra boundaries inside it.
    for (var k = 0; k < 12; k++) {
      final a = sectorStart(k);
      canvas.drawLine(center, at(a, nakInner), divider);
    }

    // Nakshatra ring: 27 equal 13°20' segments in the outermost band.
    // Boundaries follow sidereal longitude, so they rotate with the
    // wheel and stay aligned to the signs (2¼ nakshatras per sign).
    if (showNakshatras) {
      canvas.drawCircle(center, nakInner, line);
      final lagnaStart = lagna.index * 30.0;
      double angleFor(double lon) {
        var d = (lon - lagnaStart) % 360;
        if (d < 0) d += 360;
        return math.pi - d * math.pi / 180;
      }

      final tick = Paint()
        ..color = KJColors.ink.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW * 0.6;
      final nakSize = base * 0.017;
      // Skip the tiny abbreviations on small dashboard cards — the
      // boundary ticks alone still convey the structure there.
      final drawLabels = nakSize >= 5.0;
      for (var n = 0; n < 27; n++) {
        final start = n * Nakshatra.span;
        final a = angleFor(start);
        canvas.drawLine(at(a, nakInner), at(a, r), tick);
        if (drawLabels) {
          final nak = Nakshatra.values[n];
          final tp = _layout(
            nak.abbrLabel(l10n),
            KJTheme.mono(
              size: nakSize,
              color: KJColors.inkSoft.withValues(alpha: 0.85),
            ),
            r,
          );
          _paintCentered(
            canvas,
            tp,
            at(angleFor(start + Nakshatra.span / 2), (r + nakInner) / 2),
          );
        }
      }
    }

    final tune = chartTuning.value; // Settings > Chart text
    final signSize = base * 0.02 * tune.signScale;
    final planetSize = base * 0.032 * tune.baseScale;
    final planetRadii = [0.65, 0.5, 0.35];

    for (var k = 0; k < 12; k++) {
      final sign = ZodiacSign.values[(lagna.index + k) % 12];
      final mid = sectorMid(k);

      // Sign name, horizontal, centered in the ring band at the mid-angle.
      final signTp = _layout(
        sign.label(l10n),
        KJTheme.mono(
          size: signSize,
          color: k == ascK ? KJColors.maroon : KJColors.inkSoft,
          weight: k == ascK ? FontWeight.w600 : FontWeight.w400,
        ),
        r,
      );
      _paintCentered(canvas, signTp, at(mid, (nakInner + bandInner) / 2));

      // Natal planets staggered at ~0.65 / 0.5 / 0.35 of the radius;
      // overflow beyond three planets nudges the angle to keep labels
      // apart.
      final planets = placements[sign] ?? const <Planet>[];
      for (var i = 0; i < planets.length; i++) {
        final p = planets[i];
        final token = tokens[p] ??
            PlanetToken(planet: p, retrograde: retrograde[p] ?? false);
        final radius = planetRadii[i % 3] * r;
        final angle = mid + (i ~/ 3) * 0.11;
        final tp = singleTokenPainter(
          token,
          l10n: l10n,
          fontSize: planetSize,
          showDegrees: showDegrees,
          showKarakas: showKarakas,
        )..layout(maxWidth: r);
        _paintCentered(canvas, tp, at(angle, radius));
      }

      // Arudha padas: small light-grey label just inside the ring band,
      // nudged off the mid-angle so it stays clear of the staggered
      // planet labels.
      final padas = padaLabels[sign] ?? const <String>[];
      if (padas.isNotEmpty) {
        final padaTp = _layout(
          padas.join(' '),
          KJTheme.mono(
            size: base * 0.022,
            color: KJColors.inkSoft.withValues(alpha: 0.65),
          ),
          r,
        );
        _paintCentered(canvas, padaTp, at(mid - 0.12, bandInner * 0.94));
      }

      // Transit overlay: a lighter, italic row hugging the outer rim of
      // the sector.
      final transitPlanets = transitPlacements?[sign] ?? const <Planet>[];
      for (var i = 0; i < transitPlanets.length; i++) {
        final p = transitPlanets[i];
        final tToken = PlanetToken(
          planet: p,
          retrograde: transitRetrograde[p] ?? false,
        );
        final angle = mid + (i - (transitPlanets.length - 1) / 2) * 0.09;
        final tp = singleTokenPainter(tToken,
            l10n: l10n, fontSize: planetSize, isTransit: true)
          ..layout(maxWidth: r);
        // Hugs the rim of the sign band (0.9·r when the nakshatra ring
        // is off, matching the classic layout).
        _paintCentered(canvas, tp, at(angle, nakInner * 0.9));
      }
    }

    // "As" marker, always at the true ascendant's sector regardless of
    // the wheel's rotation.
    final deg = ascendantDegree;
    final asTp = _layout(
      deg != null ? 'As ${formatDegreeInSign(deg)}' : 'As',
      KJTheme.mono(
        size: base * 0.026,
        color: KJColors.maroon,
        weight: FontWeight.w600,
      ),
      r,
    );
    _paintCentered(canvas, asTp, at(sectorMid(ascK), r * 0.14));
  }

  TextPainter _layout(String text, TextStyle style, double maxWidth) =>
      TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: maxWidth);

  void _paintCentered(Canvas canvas, TextPainter tp, Offset center) =>
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));

  // Captured at construction: paint output depends on the active
  // palette, so a palette change must trigger a repaint.
  final KJPalette _palette = KJColors.current;

  @override
  bool shouldRepaint(covariant CircularChartPainter oldDelegate) =>
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
      oldDelegate.showNakshatras != showNakshatras ||
      oldDelegate.l10n != l10n ||
      oldDelegate._palette != _palette;
}

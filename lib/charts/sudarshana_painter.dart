import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';

/// Sudarshana Chakra — three concentric 12-sector wheels read
/// together: Lagna chart innermost, Chandra (Moon) chart in the
/// middle, Surya (Sun) chart outermost. The sectors are radially
/// aligned so one sector spans the same house in all three charts;
/// house 1 sits at the top and houses proceed counter-clockwise.
class SudarshanaPainter extends CustomPainter {
  SudarshanaPainter({
    required this.l10n,
    required this.lagnaSign,
    required this.moonSign,
    required this.sunSign,
    required this.placements,
  });

  /// Localized strings for the graha/rashi tokens — a painter has no
  /// BuildContext at paint time, so the host widget injects it.
  final AppLocalizations l10n;

  final ZodiacSign lagnaSign;
  final ZodiacSign moonSign;
  final ZodiacSign sunSign;
  final Map<ZodiacSign, List<Planet>> placements;

  // Ring boundaries as fractions of the radius (hub, then L/M/S rings).
  static const _bounds = [0.14, 0.42, 0.70, 0.98];

  @override
  void paint(Canvas canvas, Size size) {
    final base = size.shortestSide;
    final strokeW = (base * 0.004).clamp(1.0, 1.5).toDouble();
    final center = Offset(size.width / 2, size.height / 2);
    final r = base / 2;

    canvas.drawRect(Offset.zero & size, Paint()..color = KJColors.paper);

    final line = Paint()
      ..color = KJColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;
    for (final f in _bounds) {
      canvas.drawCircle(center, f * r, line);
    }

    // House 1 centered at the top; houses counter-clockwise. Canvas
    // angles grow clockwise, so house k's mid-angle decreases.
    double sectorMid(int k) => -math.pi / 2 - k * math.pi / 6;
    double sectorStart(int k) => -math.pi / 2 + math.pi / 12 - k * math.pi / 6;

    final divider = Paint()
      ..color = KJColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW * 0.7;
    for (var k = 0; k < 12; k++) {
      final a = sectorStart(k);
      canvas.drawLine(
        center +
            Offset(math.cos(a) * _bounds[0] * r, math.sin(a) * _bounds[0] * r),
        center +
            Offset(math.cos(a) * _bounds[3] * r, math.sin(a) * _bounds[3] * r),
        divider,
      );
    }

    // House-1 sector tint across all rings.
    final wedge = Path()
      ..moveTo(center.dx + math.cos(sectorStart(0)) * _bounds[0] * r,
          center.dy + math.sin(sectorStart(0)) * _bounds[0] * r)
      ..arcTo(Rect.fromCircle(center: center, radius: _bounds[3] * r),
          sectorStart(1), math.pi / 6, false)
      ..arcTo(Rect.fromCircle(center: center, radius: _bounds[0] * r),
          sectorStart(0), -math.pi / 6, false)
      ..close();
    canvas.drawPath(
        wedge, Paint()..color = KJColors.maroon.withValues(alpha: 0.06));

    final signSize = base * 0.02;
    final planetSize = base * 0.022;
    final baseSigns = [lagnaSign, moonSign, sunSign];

    for (var ring = 0; ring < 3; ring++) {
      final innerF = _bounds[ring];
      final outerF = _bounds[ring + 1];
      final signR = (innerF + 0.22 * (outerF - innerF)) * r;
      final planetR = (innerF + 0.62 * (outerF - innerF)) * r;

      for (var k = 0; k < 12; k++) {
        final sign = ZodiacSign.values[(baseSigns[ring].index + k) % 12];
        final mid = sectorMid(k);

        final signTp = TextPainter(
          text: TextSpan(
            text: '${sign.index + 1}',
            style: KJTheme.mono(
              size: signSize,
              color: k == 0 ? KJColors.maroon : KJColors.inkSoft,
              weight: k == 0 ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final signAt =
            center + Offset(math.cos(mid) * signR, math.sin(mid) * signR);
        signTp.paint(
            canvas, signAt - Offset(signTp.width / 2, signTp.height / 2));

        final planets = placements[sign] ?? const <Planet>[];
        if (planets.isEmpty) continue;
        final tp = TextPainter(
          text: TextSpan(
            text: planets.map((p) => p.abbrLabel(l10n)).join(' '),
            style: KJTheme.mono(size: planetSize, color: KJColors.ink),
          ),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout(maxWidth: (outerF - innerF) * r * 1.4);
        final at =
            center + Offset(math.cos(mid) * planetR, math.sin(mid) * planetR);
        tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
      }
    }

    // Hub label.
    final hub = TextPainter(
      text: TextSpan(
        text: 'La\nMo\nSu',
        style: KJTheme.mono(size: base * 0.018, color: KJColors.inkSoft),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    hub.paint(canvas, center - Offset(hub.width / 2, hub.height / 2));
  }

  final KJPalette _palette = KJColors.current;

  @override
  bool shouldRepaint(covariant SudarshanaPainter oldDelegate) =>
      oldDelegate.lagnaSign != lagnaSign ||
      oldDelegate.moonSign != moonSign ||
      oldDelegate.sunSign != sunSign ||
      oldDelegate.placements != placements ||
      oldDelegate.l10n != l10n ||
      oldDelegate._palette != _palette;
}

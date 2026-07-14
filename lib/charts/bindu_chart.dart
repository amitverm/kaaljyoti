/// Ashtakavarga bindu chart: the classical presentation where each
/// house of the kundli shows a NUMBER (the sign's bindu score) instead
/// of planets. Renders in North or South Indian layout, reusing the
/// exact house geometry of the planet chart painters; the circular
/// style has no meaningful bindu form, so it falls back to North.
library;

import 'package:flutter/material.dart';

import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import 'chart_style.dart';
import 'north_chart_painter.dart';
import 'pinch_zoom.dart';

/// Score thresholds used to tint counts: strong = forest, weak =
/// maroon, otherwise ink. Classical reading: SAV ≥ 30 strong / ≤ 22
/// weak; BAV ≥ 5 strong / ≤ 2 weak.
Color _scoreInk(int score, {required bool isSav}) {
  final strong = isSav ? 30 : 5;
  final weak = isSav ? 22 : 2;
  if (score >= strong) return TEColors.forest;
  if (score <= weak) return TEColors.maroon;
  return TEColors.ink;
}

/// Square bindu chart in the requested [style].
///
/// [scores] is per SIGN (index 0 = Aries … 11 = Pisces); [lagna]
/// rotates the North layout (house 1 = lagna sign) exactly like the
/// planet charts. [isSav] only affects strong/weak tinting thresholds.
class BinduChartView extends StatelessWidget {
  const BinduChartView({
    super.key,
    required this.scores,
    required this.lagna,
    required this.style,
    this.isSav = false,
    this.size,
  });

  final List<int> scores;
  final ZodiacSign lagna;
  final ChartStyle style;
  final bool isSav;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final CustomPainter painter = style == ChartStyle.south
        ? _SouthBinduPainter(scores: scores, lagna: lagna, isSav: isSav)
        : _NorthBinduPainter(scores: scores, lagna: lagna, isSav: isSav);
    final chart = PinchZoom(child: CustomPaint(painter: painter));
    final side = size;
    return side != null
        ? SizedBox(width: side, height: side, child: chart)
        : AspectRatio(aspectRatio: 1, child: chart);
  }
}

class _NorthBinduPainter extends CustomPainter {
  _NorthBinduPainter({
    required this.scores,
    required this.lagna,
    required this.isSav,
  });

  final List<int> scores;
  final ZodiacSign lagna;
  final bool isSav;

  @override
  void paint(Canvas canvas, Size size) {
    final base = size.shortestSide;
    final strokeW = (base * 0.004).clamp(1.0, 1.6).toDouble();
    final rect = (Offset.zero & size).deflate(strokeW / 2);
    drawNorthFrame(canvas, size, rect, strokeW);
    final houses = northHouseGeometry(rect);

    final signSize = base * 0.026;
    final countSize = base * 0.055;

    for (var n = 1; n <= 12; n++) {
      final h = houses[n - 1];
      final signNumber = ((lagna.index + n - 1) % 12) + 1;
      final score = scores[signNumber - 1];

      final signTp = TextPainter(
        text: TextSpan(
          text: '$signNumber',
          style: TETheme.mono(
            size: signSize,
            color: n == 1 ? TEColors.maroon : TEColors.inkSoft,
            weight: n == 1 ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      _paintCentered(canvas, signTp, Offset.lerp(h.vertex, h.centroid, 0.25)!);

      final countTp = TextPainter(
        text: TextSpan(
          text: '$score',
          style: TETheme.mono(
            size: countSize,
            color: _scoreInk(score, isSav: isSav),
            weight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      _paintCentered(canvas, countTp, h.content.center);
    }
  }

  void _paintCentered(Canvas canvas, TextPainter tp, Offset center) =>
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));

  final TEPalette _palette = TEColors.current;

  @override
  bool shouldRepaint(covariant _NorthBinduPainter oldDelegate) =>
      oldDelegate.scores != scores ||
      oldDelegate.lagna != lagna ||
      oldDelegate.isSav != isSav ||
      oldDelegate._palette != _palette;
}

class _SouthBinduPainter extends CustomPainter {
  _SouthBinduPainter({
    required this.scores,
    required this.lagna,
    required this.isSav,
  });

  final List<int> scores;
  final ZodiacSign lagna;
  final bool isSav;

  /// Fixed (row, col) per sign — identical to SouthChartPainter.
  static const Map<ZodiacSign, (int, int)> _cells = {
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

    Rect cellRect(int row, int col) => Rect.fromLTWH(
        rect.left + col * cellW, rect.top + row * cellH, cellW, cellH);

    canvas.drawRect(Offset.zero & size, Paint()..color = TEColors.paper);

    final (lagnaRow, lagnaCol) = _cells[lagna]!;
    final lagnaCell = cellRect(lagnaRow, lagnaCol);
    canvas.drawRect(
      lagnaCell,
      Paint()..color = TEColors.maroon.withValues(alpha: 0.08),
    );

    final line = Paint()
      ..color = TEColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeJoin = StrokeJoin.miter;
    canvas.drawRect(rect, line);
    for (final (row, col) in _cells.values) {
      canvas.drawRect(cellRect(row, col), line);
    }

    final diagLen = cellW * 0.28;
    canvas.drawLine(
      Offset(lagnaCell.left + diagLen, lagnaCell.top),
      Offset(lagnaCell.left, lagnaCell.top + diagLen),
      Paint()
        ..color = TEColors.maroon
        ..strokeWidth = strokeW * 1.2
        ..strokeCap = StrokeCap.round,
    );

    final signSize = base * 0.024;
    final countSize = base * 0.055;
    final pad = cellW * 0.06;

    for (final sign in ZodiacSign.values) {
      final (row, col) = _cells[sign]!;
      final cell = cellRect(row, col);
      final score = scores[sign.index];

      final signTp = TextPainter(
        text: TextSpan(
          text: sign.western.substring(0, 3),
          style: TETheme.mono(
            size: signSize,
            color: sign == lagna ? TEColors.maroon : TEColors.inkSoft,
            weight: sign == lagna ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      signTp.paint(
          canvas, Offset(cell.right - pad - signTp.width, cell.top + pad));

      final countTp = TextPainter(
        text: TextSpan(
          text: '$score',
          style: TETheme.mono(
            size: countSize,
            color: _scoreInk(score, isSav: isSav),
            weight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      countTp.paint(canvas,
          cell.center - Offset(countTp.width / 2, countTp.height / 2));
    }
  }

  final TEPalette _palette = TEColors.current;

  @override
  bool shouldRepaint(covariant _SouthBinduPainter oldDelegate) =>
      oldDelegate.scores != scores ||
      oldDelegate.lagna != lagna ||
      oldDelegate.isSav != isSav ||
      oldDelegate._palette != _palette;
}

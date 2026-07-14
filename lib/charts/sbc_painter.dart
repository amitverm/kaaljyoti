import 'package:flutter/material.dart';

import '../core/astro/models.dart';
import '../core/astro/sarvatobhadra.dart';
import '../core/theme/theme.dart';

/// Sarvatobhadra Chakra — the fixed 9×9 grid. Natal anchor cells are
/// tinted maroon; cells under malefic vedha get a warm tint, under
/// benefic vedha a green tint (both when mixed). Natal planets render
/// in ink inside their nakshatra cell, transiting planets in the
/// transit style.
class SbcPainter extends CustomPainter {
  SbcPainter({
    required this.anchors,
    required this.maleficVedha,
    required this.beneficVedha,
    required this.natalByCell,
    required this.transitByCell,
  });

  /// Natal reference cells (janma nakshatra, rashi, lagna, tithi, vara).
  final Set<(int, int)> anchors;

  /// Cells under vedha from at least one transiting malefic / benefic.
  final Set<(int, int)> maleficVedha;
  final Set<(int, int)> beneficVedha;

  final Map<(int, int), List<Planet>> natalByCell;
  final Map<(int, int), List<Planet>> transitByCell;

  @override
  void paint(Canvas canvas, Size size) {
    final base = size.shortestSide;
    final cell = base / 9;
    final strokeW = (base * 0.0035).clamp(0.7, 1.2).toDouble();

    canvas.drawRect(Offset.zero & size, Paint()..color = TEColors.paper);

    Rect cellRect(int r, int c) =>
        Rect.fromLTWH(c * cell, r * cell, cell, cell);

    // Tints under the grid lines.
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final key = (r, c);
        final rect = cellRect(r, c);
        if (maleficVedha.contains(key)) {
          canvas.drawRect(
              rect, Paint()..color = TEColors.maroon.withValues(alpha: 0.10));
        }
        if (beneficVedha.contains(key)) {
          canvas.drawRect(
              rect, Paint()..color = TEColors.forest.withValues(alpha: 0.10));
        }
        if (anchors.contains(key)) {
          canvas.drawRect(
              rect, Paint()..color = TEColors.maroon.withValues(alpha: 0.14));
        }
      }
    }

    // Grid.
    final line = Paint()
      ..color = TEColors.inkSoft.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;
    for (var i = 0; i <= 9; i++) {
      canvas.drawLine(Offset(i * cell, 0), Offset(i * cell, base), line);
      canvas.drawLine(Offset(0, i * cell), Offset(base, i * cell), line);
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, base, base),
      Paint()
        ..color = TEColors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW * 1.6,
    );

    final labelSize = base * 0.0195;
    final planetSize = base * 0.019;

    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final sbcCell = sbcGrid[r][c];
        final key = (r, c);
        final natal = natalByCell[key] ?? const <Planet>[];
        final transit = transitByCell[key] ?? const <Planet>[];
        final isAnchor = anchors.contains(key);

        final labelColor = switch (sbcCell.type) {
          SbcCellType.nakshatra => isAnchor ? TEColors.maroon : TEColors.ink,
          SbcCellType.rashi => isAnchor ? TEColors.maroon : TEColors.ink,
          _ => isAnchor
              ? TEColors.maroon
              : TEColors.inkSoft.withValues(alpha: 0.8),
        };
        final spans = <InlineSpan>[
          TextSpan(
            text: sbcCell.display().replaceAll('·', '\n'),
            style: TETheme.mono(
              size: sbcCell.type == SbcCellType.tithiVara
                  ? labelSize * 0.82
                  : labelSize,
              color: labelColor,
              weight: isAnchor ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          if (natal.isNotEmpty)
            TextSpan(
              text: '\n${natal.map((p) => p.abbr).join(' ')}',
              style: TETheme.mono(
                  size: planetSize,
                  color: TEColors.ink,
                  weight: FontWeight.w600),
            ),
          if (transit.isNotEmpty)
            TextSpan(
              text: '\n${transit.map((p) => p.abbr.toLowerCase()).join(' ')}',
              style:
                  TETheme.mono(size: planetSize * 0.9, color: TEColors.transit)
                      .copyWith(fontStyle: FontStyle.italic),
            ),
        ];
        final tp = TextPainter(
          text: TextSpan(children: spans),
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
        )..layout(maxWidth: cell * 0.96);
        tp.paint(
          canvas,
          cellRect(r, c).center - Offset(tp.width / 2, tp.height / 2),
        );
      }
    }
  }

  final TEPalette _palette = TEColors.current;

  @override
  bool shouldRepaint(covariant SbcPainter oldDelegate) =>
      oldDelegate.anchors != anchors ||
      oldDelegate.maleficVedha != maleficVedha ||
      oldDelegate.beneficVedha != beneficVedha ||
      oldDelegate.natalByCell != natalByCell ||
      oldDelegate.transitByCell != transitByCell ||
      oldDelegate._palette != _palette;
}

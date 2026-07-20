import 'package:flutter/material.dart';

import '../core/astro/models.dart';
import '../core/astro/sarvatobhadra.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';

/// Sarvatobhadra Chakra — the fixed 9×9 grid. Natal anchor cells are
/// tinted maroon; cells under malefic vedha get a warm tint, under
/// benefic vedha a green tint (both when mixed). Natal planets render
/// in ink inside their nakshatra cell, transiting planets in the
/// transit style.
class SbcPainter extends CustomPainter {
  SbcPainter({
    required this.l10n,
    required this.anchors,
    required this.maleficVedha,
    required this.beneficVedha,
    required this.natalByCell,
    required this.transitByCell,
  });

  /// Localized strings for the graha/rashi tokens — a painter has no
  /// BuildContext at paint time, so the host widget injects it.
  final AppLocalizations l10n;

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

    canvas.drawRect(Offset.zero & size, Paint()..color = KJColors.paper);

    Rect cellRect(int r, int c) =>
        Rect.fromLTWH(c * cell, r * cell, cell, cell);

    // Tints under the grid lines.
    for (var r = 0; r < 9; r++) {
      for (var c = 0; c < 9; c++) {
        final key = (r, c);
        final rect = cellRect(r, c);
        if (maleficVedha.contains(key)) {
          canvas.drawRect(
              rect, Paint()..color = KJColors.maroon.withValues(alpha: 0.10));
        }
        if (beneficVedha.contains(key)) {
          canvas.drawRect(
              rect, Paint()..color = KJColors.forest.withValues(alpha: 0.10));
        }
        if (anchors.contains(key)) {
          canvas.drawRect(
              rect, Paint()..color = KJColors.maroon.withValues(alpha: 0.14));
        }
      }
    }

    // Grid.
    final line = Paint()
      ..color = KJColors.inkSoft.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;
    for (var i = 0; i <= 9; i++) {
      canvas.drawLine(Offset(i * cell, 0), Offset(i * cell, base), line);
      canvas.drawLine(Offset(0, i * cell), Offset(base, i * cell), line);
    }
    canvas.drawRect(
      Rect.fromLTWH(0, 0, base, base),
      Paint()
        ..color = KJColors.ink
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
          SbcCellType.nakshatra => isAnchor ? KJColors.maroon : KJColors.ink,
          SbcCellType.rashi => isAnchor ? KJColors.maroon : KJColors.ink,
          _ => isAnchor
              ? KJColors.maroon
              : KJColors.inkSoft.withValues(alpha: 0.8),
        };
        final spans = <InlineSpan>[
          TextSpan(
            text: sbcCellLabel(l10n, sbcCell).replaceAll('·', '\n'),
            style: KJTheme.mono(
              size: sbcCell.type == SbcCellType.tithiVara
                  ? labelSize * 0.82
                  : labelSize,
              color: labelColor,
              weight: isAnchor ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          if (natal.isNotEmpty)
            TextSpan(
              text: '\n${natal.map((p) => p.abbrLabel(l10n)).join(' ')}',
              style: KJTheme.mono(
                  size: planetSize,
                  color: KJColors.ink,
                  weight: FontWeight.w600),
            ),
          if (transit.isNotEmpty)
            TextSpan(
              text:
                  '\n${transit.map((p) => p.abbrLabel(l10n).toLowerCase()).join(' ')}',
              style:
                  KJTheme.mono(size: planetSize * 0.9, color: KJColors.transit)
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

  final KJPalette _palette = KJColors.current;

  @override
  bool shouldRepaint(covariant SbcPainter oldDelegate) =>
      oldDelegate.anchors != anchors ||
      oldDelegate.maleficVedha != maleficVedha ||
      oldDelegate.beneficVedha != beneficVedha ||
      oldDelegate.natalByCell != natalByCell ||
      oldDelegate.transitByCell != transitByCell ||
      oldDelegate.l10n != l10n ||
      oldDelegate._palette != _palette;
}

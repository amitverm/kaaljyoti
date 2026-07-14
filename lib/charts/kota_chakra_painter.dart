import 'package:flutter/material.dart';

import '../core/astro/kota_chakra.dart';
import '../core/astro/models.dart';
import '../core/astro/nakshatra28.dart';
import '../core/theme/theme.dart';

/// Kota Chakra — four nested square enclosures (Stambha, Madhya,
/// Prakara, Bahya). Nakshatras enter along the intercardinal
/// diagonals and exit along the cardinals; the Janma nakshatra sits at
/// the NE corner of the Bahya. Natal planets render in ink, transiting
/// planets in the transit style (lowercase italic green).
class KotaChakraPainter extends CustomPainter {
  KotaChakraPainter({required this.data});

  final KotaChakraData data;

  // Half-extents of the four squares as fractions of the half-size —
  // pushed close to the edge so the fort fills the card.
  static const _stambha = 0.20;
  static const _madhya = 0.44;
  static const _prakara = 0.68;
  static const _bahya = 0.92;

  // Slot distances (square half-extent fractions) for positions 1..7
  // within a direction group: entry bahya→stambha, then exit
  // madhya→bahya.
  static const _entryF = [0.80, 0.56, 0.32, 0.10];
  static const _exitF = [0.32, 0.56, 0.80];

  @override
  void paint(Canvas canvas, Size size) {
    final base = size.shortestSide;
    final strokeW = (base * 0.004).clamp(1.0, 1.5).toDouble();
    final center = Offset(size.width / 2, size.height / 2);
    final h = base / 2 * 0.99;

    canvas.drawRect(Offset.zero & size, Paint()..color = TEColors.paper);

    Rect sq(double f) =>
        Rect.fromCenter(center: center, width: 2 * f * h, height: 2 * f * h);

    // Heart of the fort tinted: Stambha + Madhya.
    canvas.drawRect(
        sq(_madhya), Paint()..color = TEColors.maroon.withValues(alpha: 0.05));

    final line = Paint()
      ..color = TEColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;
    for (final f in const [_stambha, _madhya, _prakara, _bahya]) {
      canvas.drawRect(sq(f), line);
    }

    // Entry diagonals (bahya corner → stambha corner) and exit
    // cardinals (stambha mid-side → bahya mid-side).
    final path = Paint()
      ..color = TEColors.hairline
      ..strokeWidth = strokeW;
    for (final (dx, dy) in const [(1, -1), (1, 1), (-1, 1), (-1, -1)]) {
      canvas.drawLine(
        center + Offset(dx * _bahya * h, dy * _bahya * h),
        center + Offset(dx * _stambha * h, dy * _stambha * h),
        path,
      );
    }
    for (final (dx, dy) in const [(1, 0), (0, 1), (-1, 0), (0, -1)]) {
      canvas.drawLine(
        center + Offset(dx * _bahya * h, dy * _bahya * h),
        center + Offset(dx * _stambha * h, dy * _stambha * h),
        path,
      );
    }

    // Direction groups clockwise from NE: entry corner + exit cardinal.
    const entryDirs = [(1, -1), (1, 1), (-1, 1), (-1, -1)]; // NE SE SW NW
    const exitDirs = [(1, 0), (0, 1), (-1, 0), (0, -1)]; // E S W N

    final nakSize = base * 0.024;
    final planetSize = base * 0.026;

    for (var off = 1; off <= 28; off++) {
      final g = kotaDirection(off);
      final pos = (off - 1) % 7; // 0..6
      final Offset anchor;
      if (pos < 4) {
        final (dx, dy) = entryDirs[g];
        final f = _entryF[pos];
        anchor = center + Offset(dx * f * h, dy * f * h);
      } else {
        final (dx, dy) = exitDirs[g];
        final f = _exitF[pos - 4];
        anchor = center + Offset(dx * f * h, dy * f * h);
      }

      final nak28 = (data.janmaNak28 + off - 1) % 28;
      final isJanma = off == 1;
      final natal = data.natal[off] ?? const <Planet>[];
      final transit = data.transit[off] ?? const <Planet>[];

      final spans = <InlineSpan>[
        TextSpan(
          text: Nakshatra28.abbrs[nak28],
          style: TETheme.mono(
            size: nakSize,
            color: isJanma
                ? TEColors.maroon
                : (natal.isEmpty && transit.isEmpty
                    ? TEColors.inkSoft.withValues(alpha: 0.75)
                    : TEColors.ink),
            weight: isJanma ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        if (natal.isNotEmpty)
          TextSpan(
            text: '\n${natal.map((p) => p.abbr).join(' ')}',
            style: TETheme.mono(
                size: planetSize, color: TEColors.ink, weight: FontWeight.w600),
          ),
        if (transit.isNotEmpty)
          TextSpan(
            text: '\n${transit.map((p) => p.abbr.toLowerCase()).join(' ')}',
            style: TETheme.mono(size: planetSize * 0.9, color: TEColors.transit)
                .copyWith(fontStyle: FontStyle.italic),
          ),
      ];
      final tp = TextPainter(
        text: TextSpan(children: spans),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      tp.paint(canvas, anchor - Offset(tp.width / 2, tp.height / 2));
    }
  }

  final TEPalette _palette = TEColors.current;

  @override
  bool shouldRepaint(covariant KotaChakraPainter oldDelegate) =>
      oldDelegate.data.janmaNak28 != data.janmaNak28 ||
      oldDelegate.data.natal != data.natal ||
      oldDelegate.data.transit != data.transit ||
      oldDelegate._palette != _palette;
}

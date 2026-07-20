import 'package:flutter/material.dart';

import '../core/astro/kota_chakra.dart';
import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';

/// Kota Chakra — four nested square enclosures (Stambha, Madhya,
/// Prakara, Bahya), shaded progressively darker toward the heart of
/// the fort and labelled in place. Nakshatras enter along the
/// intercardinal diagonals and exit along the cardinals (arrowed); the
/// Janma nakshatra sits highlighted at the NE corner of the Bahya.
/// Each cell shows its 1-based offset from Janma so the ring position
/// can be read without counting. Natal planets render in ink;
/// transiting planets in lowercase italic, maroon for malefics and
/// the transit green for benefics — the siege reading at a glance.
class KotaChakraPainter extends CustomPainter {
  KotaChakraPainter({required this.l10n, required this.data});

  /// Localized strings for the graha tokens — a painter has no
  /// BuildContext at paint time, so the host widget injects it.
  final AppLocalizations l10n;

  final KotaChakraData data;

  // Half-extents of the four squares as fractions of the half-size —
  // pushed close to the edge so the fort fills the card. Stambha is
  // roomier than the classic proportions so the four innermost cells
  // don't collide.
  static const _stambha = 0.27;
  static const _madhya = 0.51;
  static const _prakara = 0.74;
  static const _bahya = 0.96;

  // Slot distances (fractions of the half-size) for positions 1..7
  // within a direction group: entry bahya→stambha at each ring band's
  // midline, then exit madhya→bahya.
  static const _entryF = [0.85, 0.625, 0.39, 0.135];
  static const _exitF = [0.39, 0.625, 0.85];

  // Direction groups clockwise from NE: entry corner + exit cardinal.
  static const _entryDirs = [(1, -1), (1, 1), (-1, 1), (-1, -1)]; // NE SE SW NW
  static const _exitDirs = [(1, 0), (0, 1), (-1, 0), (0, -1)]; // E S W N

  @override
  void paint(Canvas canvas, Size size) {
    final base = size.shortestSide;
    final strokeW = (base * 0.004).clamp(1.0, 1.5).toDouble();
    final center = Offset(size.width / 2, size.height / 2);
    final h = base / 2 * 0.99;

    canvas.drawRect(Offset.zero & size, Paint()..color = KJColors.paper);

    Rect sq(double f) =>
        Rect.fromCenter(center: center, width: 2 * f * h, height: 2 * f * h);

    // Enclosures step darker toward the heart of the fort — the fills
    // stack, so each band reads one shade deeper than the last.
    // The extra stambha pass keeps the innermost box the deepest shade
    // even after the translucent path bands tint the outer bands.
    for (final f in const [_prakara, _madhya, _stambha, _stambha]) {
      canvas.drawRect(
          sq(f), Paint()..color = KJColors.maroon.withValues(alpha: 0.04));
    }

    // Entry/exit path bands — the translucent "roads" through the fort.
    final band = Paint()
      ..color = KJColors.maroon.withValues(alpha: 0.03)
      ..strokeWidth = 0.16 * h
      ..strokeCap = StrokeCap.butt;
    for (final dirs in const [_entryDirs, _exitDirs]) {
      for (final (dx, dy) in dirs) {
        canvas.drawLine(
          center + Offset(dx * _bahya * h, dy * _bahya * h),
          center + Offset(dx * _stambha * h, dy * _stambha * h),
          band,
        );
      }
    }

    final line = Paint()
      ..color = KJColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW;
    for (final f in const [_stambha, _madhya, _prakara, _bahya]) {
      canvas.drawRect(sq(f), line);
    }

    // Path hairlines: entry diagonals (bahya corner → stambha corner)
    // and exit cardinals (stambha mid-side → bahya mid-side).
    final path = Paint()
      ..color = KJColors.hairline
      ..strokeWidth = strokeW;
    for (final dirs in const [_entryDirs, _exitDirs]) {
      for (final (dx, dy) in dirs) {
        canvas.drawLine(
          center + Offset(dx * _bahya * h, dy * _bahya * h),
          center + Offset(dx * _stambha * h, dy * _stambha * h),
          path,
        );
      }
    }

    // Direction chevrons where the paths pierce the walls: inward on
    // the entry diagonals, outward on the exit cardinals.
    final arrow = Paint()
      ..color = KJColors.inkSoft
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;
    final s = base * 0.012;
    for (final (dx, dy) in _entryDirs) {
      final inward =
          Offset(-dx / 1.4142135, -dy / 1.4142135); // unit, toward center
      for (final f in const [_prakara, _madhya]) {
        _chevron(canvas, center + Offset(dx * f * h, dy * f * h), inward, s,
            arrow);
      }
    }
    for (final (dx, dy) in _exitDirs) {
      final outward = Offset(dx.toDouble(), dy.toDouble());
      for (final f in const [_madhya, _prakara]) {
        _chevron(canvas, center + Offset(dx * f * h, dy * f * h), outward, s,
            arrow);
      }
    }

    // Ring names in place, tucked into the quiet octant left of north
    // (Stambha's sits in the fort's empty center).
    final ringStyle = KJTheme.mono(
      size: base * 0.019,
      color: KJColors.inkSoft.withValues(alpha: 0.65),
    ).copyWith(letterSpacing: base * 0.002);
    void ringLabel(String text, Offset at) {
      final tp = TextPainter(
        text: TextSpan(text: text.toUpperCase(), style: ringStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, at - Offset(tp.width / 2, tp.height / 2));
    }

    for (final (ring, mid) in [
      (KotaRing.bahya, _entryF[0]),
      (KotaRing.prakara, _entryF[1]),
      (KotaRing.madhya, _entryF[2]),
    ]) {
      // Midway across the quiet gap between the north exit cell and
      // the NW entry cell of each band.
      ringLabel(ring.label(l10n), center + Offset(-0.5 * mid * h, -mid * h));
    }
    ringLabel(KotaRing.stambha.label(l10n), center);

    final nakSize = base * 0.025;
    final planetSize = base * 0.026;

    for (var off = 1; off <= 28; off++) {
      final g = kotaDirection(off);
      final pos = (off - 1) % 7; // 0..6
      final Offset anchor;
      if (pos < 4) {
        final (dx, dy) = _entryDirs[g];
        final f = _entryF[pos];
        anchor = center + Offset(dx * f * h, dy * f * h);
      } else {
        final (dx, dy) = _exitDirs[g];
        final f = _exitF[pos - 4];
        anchor = center + Offset(dx * f * h, dy * f * h);
      }

      final nak28 = (data.janmaNak28 + off - 1) % 28;
      final isJanma = off == 1;
      final natal = data.natal[off] ?? const <Planet>[];
      final transit = data.transit[off] ?? const <Planet>[];
      final occupied = natal.isNotEmpty || transit.isNotEmpty;

      final spans = <InlineSpan>[
        TextSpan(
          text: '$off ',
          style: KJTheme.mono(
            size: nakSize * 0.8,
            color: isJanma
                ? KJColors.maroon
                : KJColors.inkSoft.withValues(alpha: occupied ? 0.9 : 0.6),
          ).copyWith(height: 1.2),
        ),
        TextSpan(
          text: nakshatra28AbbrLabel(l10n, nak28),
          style: KJTheme.mono(
            size: nakSize,
            color: isJanma
                ? KJColors.maroon
                : (occupied
                    ? KJColors.ink
                    : KJColors.inkSoft.withValues(alpha: 0.75)),
            weight: isJanma ? FontWeight.w600 : FontWeight.w400,
          ).copyWith(height: 1.2),
        ),
        if (natal.isNotEmpty)
          TextSpan(
            text: '\n${natal.map((p) => p.abbrLabel(l10n)).join(' ')}',
            style: KJTheme.mono(
                    size: planetSize,
                    color: KJColors.ink,
                    weight: FontWeight.w600)
                .copyWith(height: 1.2),
          ),
        if (transit.isNotEmpty) ...[
          TextSpan(
              text: '\n',
              style: KJTheme.mono(size: planetSize * 0.9).copyWith(height: 1.2)),
          for (final (i, p) in transit.indexed)
            TextSpan(
              text: '${i == 0 ? '' : ' '}${p.abbrLabel(l10n).toLowerCase()}',
              style: KJTheme.mono(
                size: planetSize * 0.9,
                color: isChakraMalefic(p) ? KJColors.maroon : KJColors.transit,
              ).copyWith(fontStyle: FontStyle.italic, height: 1.2),
            ),
        ],
      ];
      final tp = TextPainter(
        text: TextSpan(children: spans),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      // Corner cells sit near the canvas edge — nudge inward rather
      // than clip (long localized abbreviations, wide planet rows).
      var topLeft = anchor - Offset(tp.width / 2, tp.height / 2);
      final pad = base * 0.005;
      topLeft = Offset(
        topLeft.dx.clamp(pad, size.width - pad - tp.width),
        topLeft.dy.clamp(pad, size.height - pad - tp.height),
      );
      if (isJanma) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            (topLeft & tp.size).inflate(base * 0.008),
            Radius.circular(base * 0.008),
          ),
          Paint()..color = KJColors.maroon.withValues(alpha: 0.08),
        );
      }
      tp.paint(canvas, topLeft);
    }
  }

  void _chevron(
      Canvas canvas, Offset tip, Offset dir, double s, Paint paint) {
    final perp = Offset(-dir.dy, dir.dx);
    final back = tip - dir * s;
    canvas.drawLine(back + perp * s * 0.8, tip, paint);
    canvas.drawLine(back - perp * s * 0.8, tip, paint);
  }

  final KJPalette _palette = KJColors.current;

  @override
  bool shouldRepaint(covariant KotaChakraPainter oldDelegate) =>
      oldDelegate.data.janmaNak28 != data.janmaNak28 ||
      oldDelegate.data.natal != data.natal ||
      oldDelegate.data.transit != data.transit ||
      oldDelegate.l10n != l10n ||
      oldDelegate._palette != _palette;
}

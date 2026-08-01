import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/theme.dart';

/// The Moon's phase at an instant, drawn from the Sun→Moon elongation
/// (0° new · 90° first quarter · 180° full · 270° last quarter) — the
/// same angle the tithi is cut from, so the disc and the tithi reading
/// beside it can never disagree.
///
/// Northern-hemisphere orientation: the lit limb is on the RIGHT while
/// waxing (Shukla paksha, elongation < 180°) and on the left while
/// waning. No text and no locale — a painter has no BuildContext, and
/// the card labels the disc itself.
///
/// Polarity follows the printed-panchang convention (● Amavasya,
/// ○ Purnima) and the sky: the LIT fraction is the light one. Inking
/// the lit side instead reads exactly backwards to a panchang-literate
/// eye — a Krishna gibbous would render as a near-black disc, i.e. as
/// almost-Amavasya.
class MoonPhasePainter extends CustomPainter {
  const MoonPhasePainter({
    required this.elongation,
    required this.lit,
    required this.dark,
    required this.rim,
  });

  /// Sun→Moon elongation in degrees; any value is accepted and reduced.
  final double elongation;

  final Color lit;
  final Color dark;
  final Color rim;

  /// Theme-coloured disc for the app's own surfaces.
  factory MoonPhasePainter.themed(double elongation) => MoonPhasePainter(
        elongation: elongation,
        lit: KJColors.paper,
        dark: KJColors.ink,
        rim: KJColors.hairline,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2 * 0.94;
    final c = Offset(size.width / 2, size.height / 2);
    final disc = Rect.fromCircle(center: c, radius: r);

    canvas.drawCircle(c, r, Paint()..color = dark);

    final rad = ((elongation % 360) + 360) % 360 * math.pi / 180;
    final waxing = rad < math.pi;
    final cosE = math.cos(rad);

    // The terminator is an ellipse sharing the disc's vertical axis; it
    // crosses the horizontal diameter at ±r·cos(elongation), measured
    // from the LIT limb. At new moon that puts it on the lit limb
    // (nothing lit); at full moon on the dark limb (all lit); at the
    // quarters it collapses to the straight diameter. Signing it this
    // way is what makes crescent and gibbous fall out of one formula
    // instead of four cases.
    final signedCrossing = cosE * (waxing ? 1 : -1);
    // A zero-width rect gives arcTo no arc to walk, so the quarters keep
    // a hairline of curvature rather than degenerating.
    final halfWidth = math.max((r * cosE).abs(), 0.01);
    final term = Rect.fromCenter(center: c, width: 2 * halfWidth, height: 2 * r);

    final path = Path();
    if (waxing) {
      // Right semicircle top→bottom, then the terminator back up.
      path.arcTo(disc, -math.pi / 2, math.pi, true);
      path.arcTo(term, math.pi / 2,
          signedCrossing >= 0 ? -math.pi : math.pi, false);
    } else {
      // Left semicircle bottom→top, then the terminator back down.
      path.arcTo(disc, math.pi / 2, math.pi, true);
      path.arcTo(term, -math.pi / 2,
          signedCrossing >= 0 ? math.pi : -math.pi, false);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = lit);

    canvas.drawCircle(
      c,
      r,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = rim,
    );
  }

  @override
  bool shouldRepaint(MoonPhasePainter old) =>
      old.elongation != elongation ||
      old.lit != lit ||
      old.dark != dark ||
      old.rim != rim;
}

/// The phase disc at a fixed size, theme-coloured.
class MoonPhaseDisc extends StatelessWidget {
  const MoonPhaseDisc({super.key, required this.elongation, this.size = 44});

  final double elongation;
  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: MoonPhasePainter.themed(elongation),
      );
}

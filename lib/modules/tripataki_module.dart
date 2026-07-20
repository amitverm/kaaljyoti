/// Tri-Pataki Chakra widget — the three-flag chart with progressed
/// planets and the vedha lists for the Moon and the lagna, for the
/// shared varsha year. Engine: core/astro/tripataki.dart (Charak
/// ch. VIII, golden-tested against both book figures). Vedha data is
/// shown as data — no interpretive prose.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pdf/pw.dart' as pw;

import '../charts/pinch_zoom.dart';
import '../core/astro/models.dart';
import '../core/astro/tripataki.dart';
import '../core/astro/varshphal.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import '../state/providers.dart';
import '../widgetsystem/astro_module.dart';

String _title(AppLocalizations l10n) => l10n.moduleTripatakiTitle;

class TripatakiModule extends AstroModule {
  const TripatakiModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'varshphal_tripataki',
        title: 'Tri-Pataki Chakra',
        localizedTitle: _title,
        icon: Icons.flag_outlined,
        category: 'Varshphal',
        defaultSpan: CardSpan.full,
      );

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) =>
      _TripatakiBody(ctx: ctx, detail: false);

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _TripatakiBody(ctx: ctx, detail: true),
      );

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) => const [];
}

class _TripatakiBody extends ConsumerWidget {
  const _TripatakiBody({required this.ctx, required this.detail});

  final ModuleContext ctx;
  final bool detail;

  /// "<label>: Su Ma …" with each planet in its own ink, matching the
  /// chakra above.
  Widget _vedhaLine(AppLocalizations l10n, String label, List<Planet> ps,
      {required double size, required Color labelColor}) {
    return Text.rich(
      TextSpan(children: [
        TextSpan(
            text: '$label: ',
            style: KJTheme.mono(size: size, color: labelColor)),
        if (ps.isEmpty)
          TextSpan(
              text: '—',
              style: KJTheme.mono(size: size, color: KJColors.inkSoft))
        else
          for (final p in ps)
            TextSpan(
              text: '${p.abbrLabel(l10n)}${p == ps.last ? '' : ' '}',
              style: KJTheme.mono(
                  size: size, color: planetInk(p), weight: FontWeight.w600),
            ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final natal = ctx.snapshot;
    final current =
        currentVarshaYear(natal.birth.dateTimeUtc, DateTime.now().toUtc());
    final year = ref.watch(varshphalYearProvider(ctx.kundli.id)) ?? current;
    final async = ref.watch(varshphalProvider((ctx.kundli.id, year)));

    return async.when(
      loading: () => const SizedBox(
          height: 120, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text(l10n.vpError('$e')),
      data: (d) {
        final data = tripataki(
          varshaLagna: d.snapshot.lagnaSign,
          natalSigns: {
            for (final p in natal.positions.values) p.planet: p.sign,
          },
          // The book's "current year": completed years + 1.
          currentYear: d.varshaYear + 1,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (detail) ...[
              Text(l10n.moduleTripatakiTitle, style: KJTheme.serif(size: 18)),
              const SizedBox(height: 4),
              Text(l10n.tpBlurb,
                  style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft)),
              const SizedBox(height: 8),
            ],
            Text(
              '${l10n.vpYearLine('${d.varshaYear}', '${d.returnUtc.toUtc().year}')}'
              ' · ${l10n.tpCurrentYear('${d.varshaYear + 1}')}',
              style: KJTheme.mono(size: 11, color: KJColors.inkSoft),
            ),
            const SizedBox(height: 6),
            AspectRatio(
              aspectRatio: 1.15,
              child: PinchZoom(
                child: CustomPaint(
                  painter: _TripatakiPainter(l10n: l10n, data: data),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _vedhaLine(l10n, l10n.tpVedhaToMoon, d0(data.vedhaToMoon),
                size: 11.5, labelColor: KJColors.ink),
            _vedhaLine(l10n, l10n.tpVedhaToLagna, d0(data.vedhaToLagna),
                size: 11.5, labelColor: KJColors.ink),
            if (detail) ...[
              const SizedBox(height: 8),
              for (final p in natal.positions.values.map((e) => e.planet))
                if (p != Planet.moon)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: _vedhaLine(
                      l10n,
                      l10n.tpVedhaTo(p.label(l10n)),
                      d0(data.vedhaToPoint(
                          data.pointPlanets.indexWhere((ps) => ps.contains(p)),
                          except: p)),
                      size: 11,
                      labelColor: KJColors.inkSoft,
                    ),
                  ),
            ],
          ],
        );
      },
    );
  }

  /// De-duplicates while keeping order.
  List<Planet> d0(List<Planet> ps) {
    final seen = <Planet>{};
    return [
      for (final p in ps)
        if (seen.add(p)) p,
    ];
  }
}

/// The three-flag figure: three verticals (flags on top), three
/// horizontals, and the twelve joining diagonals of the classical
/// chakra; sign numbers at the twelve points, progressed planets
/// stacked beside them.
class _TripatakiPainter extends CustomPainter {
  _TripatakiPainter({required this.l10n, required this.data});

  final AppLocalizations l10n;
  final TripatakiData data;

  /// Normalized coordinates of points a…l (index 0-11, anticlockwise).
  static const List<(double, double)> _pts = [
    (0.5, 0.14), // a
    (0.32, 0.14), // b
    (0.10, 0.34), // c
    (0.10, 0.50), // d
    (0.10, 0.66), // e
    (0.32, 0.86), // f
    (0.5, 0.86), // g
    (0.68, 0.86), // h
    (0.90, 0.66), // i
    (0.90, 0.50), // j
    (0.90, 0.34), // k
    (0.68, 0.14), // l
  ];

  /// The 18 lines (3 vertical, 3 horizontal, 12 diagonals) as point
  /// index pairs — consistent with [tripatakiPartners].
  static const List<(int, int)> _lines = [
    (1, 5), (0, 6), (11, 7), // verticals
    (2, 10), (3, 9), (4, 8), // horizontals
    (0, 3), (0, 9), (6, 3), (6, 9), // center diagonals
    (1, 2), (1, 8), (5, 4), (5, 10), // left diagonals
    (11, 10), (11, 4), (7, 2), (7, 8), // right diagonals
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final base = size.shortestSide;
    Offset at(int i) =>
        Offset(_pts[i].$1 * size.width, _pts[i].$2 * size.height);

    canvas.drawRect(Offset.zero & size, Paint()..color = KJColors.paper);
    final line = Paint()
      ..color = KJColors.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = (base * 0.004).clamp(1.0, 1.6);

    for (final (p, q) in _lines) {
      canvas.drawLine(at(p), at(q), line);
    }

    // Flags on the three top points (b, a, l).
    for (final i in const [1, 0, 11]) {
      final top = at(i);
      final mastTop = top - Offset(0, base * 0.06);
      canvas.drawLine(top, mastTop, line);
      final flag = Path()
        ..moveTo(mastTop.dx, mastTop.dy)
        ..lineTo(mastTop.dx + base * 0.05, mastTop.dy + base * 0.018)
        ..lineTo(mastTop.dx, mastTop.dy + base * 0.036)
        ..close();
      canvas.drawPath(
          flag, Paint()..color = KJColors.maroon.withValues(alpha: 0.7));
    }

    // Sign numbers + planets at every point, offset outward.
    for (var i = 0; i < 12; i++) {
      final pos = at(i);
      final outward = (pos - Offset(size.width / 2, size.height / 2));
      final dir = outward.distance == 0
          ? const Offset(0, -1)
          : outward / outward.distance;
      final sign = data.signOfPoint(i);
      final isLagna = i == 0;

      final signTp = TextPainter(
        text: TextSpan(
          text: '${sign.index + 1}',
          style: KJTheme.mono(
            size: base * 0.032,
            color: isLagna ? KJColors.maroon : KJColors.inkSoft,
            weight: isLagna ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      // Top points carry the flag masts — put their numbers up-LEFT of
      // the point so the mast/flag doesn't cover them.
      final signAt = (i == 0 || i == 1 || i == 11)
          ? pos + Offset(-base * 0.032, -base * 0.030)
          : pos + dir * (base * 0.035);
      signTp.paint(
          canvas, signAt - Offset(signTp.width / 2, signTp.height / 2));

      final planets = data.pointPlanets[i];
      if (planets.isNotEmpty) {
        final tp = TextPainter(
          text: TextSpan(children: [
            for (final p in planets)
              TextSpan(
                text: '${p.abbrLabel(l10n)}${planets.last == p ? '' : ' '}',
                style: KJTheme.mono(
                  size: base * 0.034,
                  color: planetInk(p),
                  weight: FontWeight.w600,
                ),
              ),
          ]),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: size.width * 0.24);
        // INWARD of the point — outward would fall off-canvas on the
        // side points (PinchZoom clips) and under the flags on top.
        // Axis-aligned, not radial: a radial (toward-center) offset
        // skews corner-point labels sideways off their point. Clamped
        // fully inside the canvas, on a paper wash so the chakra lines
        // underneath stay readable.
        final inward = switch (i) {
          0 || 1 || 11 => Offset(0, base * 0.085), // top → below
          5 || 6 || 7 => Offset(0, -base * 0.085), // bottom → above
          2 || 3 || 4 => Offset(base * 0.085, 0), // left → rightward
          _ => Offset(-base * 0.085, 0), // right → leftward
        };
        final planetsAt = pos + inward;
        final topLeft = Offset(
          (planetsAt.dx - tp.width / 2).clamp(2.0, size.width - tp.width - 2.0),
          (planetsAt.dy - tp.height / 2)
              .clamp(2.0, size.height - tp.height - 2.0),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            (topLeft & tp.size).inflate(base * 0.008),
            Radius.circular(base * 0.01),
          ),
          Paint()..color = KJColors.paper.withValues(alpha: 0.85),
        );
        tp.paint(canvas, topLeft);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TripatakiPainter oldDelegate) =>
      oldDelegate.data != data || oldDelegate.l10n != l10n;
}

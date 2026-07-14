import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;

import '../charts/pinch_zoom.dart';
import '../charts/sudarshana_painter.dart';
import '../core/astro/divisional.dart';
import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

/// Sudarshana Chakra — the Lagna, Chandra and Surya charts drawn as
/// three radially-aligned wheels (Lagna innermost), so every house is
/// read three ways at once, per BPHS.
class SudarshanaModule extends AstroModule {
  const SudarshanaModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'sudarshana',
        title: 'Sudarshana Chakra',
        icon: Icons.track_changes_outlined,
        category: 'Chakra',
        defaultSpan: CardSpan.full,
      );

  // Pinch to zoom (two fingers), card and detail alike.
  Widget _chart(AstroSnapshot s) => PinchZoom(
        child: AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(
            painter: SudarshanaPainter(
              lagnaSign: s.lagnaSign,
              moonSign: s.moonSign,
              sunSign: s.positions[Planet.sun]!.sign,
              placements: vargaPlacements(s, Varga.d1),
            ),
          ),
        ),
      );

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) {
    final s = ctx.snapshot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _chart(s),
        const SizedBox(height: 10),
        Text(
          'Inner → outer: Lagna (${s.lagnaSign.western}) · '
          'Chandra (${s.moonSign.western}) · '
          'Surya (${s.positions[Planet.sun]!.sign.western}). '
          'Each sector = the same house in all three charts.',
          style: TETheme.mono(size: 11.5, color: TEColors.inkSoft),
        ),
      ],
    );
  }

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) {
    final s = ctx.snapshot;
    final bases = [
      ('Lagna', s.lagnaSign),
      ('Chandra', s.moonSign),
      ('Surya', s.positions[Planet.sun]!.sign),
    ];
    final placements = vargaPlacements(s, Varga.d1);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sudarshana Chakra', style: TETheme.serif(size: 18)),
          const SizedBox(height: 4),
          Text(
            'Every bhava judged from three references at once — the'
            ' Lagna, the Moon and the Sun. A house strong from all three'
            ' gives dependable results; afflicted from all three, its'
            ' significations suffer.',
            style: TETheme.mono(size: 11.5, color: TEColors.inkSoft),
          ),
          const SizedBox(height: 12),
          _chart(s),
          const SizedBox(height: 8),
          Text(
            'Inner → outer: Lagna (${s.lagnaSign.western}) · '
            'Chandra (${s.moonSign.western}) · '
            'Surya (${s.positions[Planet.sun]!.sign.western}).',
            style: TETheme.mono(size: 11.5, color: TEColors.inkSoft),
          ),
          const SizedBox(height: 16),
          for (final (name, base) in bases) ...[
            Text('$name chart houses', style: TETheme.serif(size: 15)),
            const SizedBox(height: 6),
            for (var h = 1; h <= 12; h++)
              if ((placements[ZodiacSign.values[(base.index + h - 1) % 12]] ??
                      const [])
                  .isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    'H$h · ${ZodiacSign.values[(base.index + h - 1) % 12].western}'
                    ' — ${placements[ZodiacSign.values[(base.index + h - 1) % 12]]!.map((p) => p.displayName).join(', ')}',
                    style: TETheme.mono(size: 11.5),
                  ),
                ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final s = ctx.snapshot;
    final placements = vargaPlacements(s, Varga.d1);
    final bases = [
      ('Lagna', s.lagnaSign),
      ('Chandra', s.moonSign),
      ('Surya', s.positions[Planet.sun]!.sign),
    ];
    return [
      pdfSectionHeader('Sudarshana Chakra'),
      pw.TableHelper.fromTextArray(
        headers: ['House', for (final (name, _) in bases) name],
        data: [
          for (var h = 1; h <= 12; h++)
            [
              'H$h',
              for (final (_, base) in bases)
                () {
                  final sign = ZodiacSign.values[(base.index + h - 1) % 12];
                  final planets = placements[sign] ?? const [];
                  return '${sign.western.substring(0, 3)}'
                      '${planets.isEmpty ? '' : ' · ${planets.map((p) => p.abbr).join(' ')}'}';
                }(),
            ],
        ],
        headerStyle: pdfLabel(),
        cellStyle: pdfBody(size: 8),
        border: null,
        cellAlignment: pw.Alignment.centerLeft,
        headerAlignment: pw.Alignment.centerLeft,
      ),
    ];
  }
}

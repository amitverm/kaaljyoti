import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/widgets.dart' as pw;

import '../charts/kota_chakra_painter.dart';
import '../charts/pinch_zoom.dart';
import '../core/astro/kota_chakra.dart';
import '../core/astro/models.dart';
import '../core/astro/nakshatra28.dart';
import '../core/astro/transit.dart' as transit;
import '../core/theme/theme.dart';
import '../state/providers.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

/// Kota Chakra — the "fort" of 28 nakshatras from the Janma nakshatra,
/// with natal placements and a live transit overlay. Follows the
/// per-kundli transit scrub time shared with the Transit widget.
class KotaChakraModule extends AstroModule {
  const KotaChakraModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'kota_chakra',
        title: 'Kota Chakra',
        icon: Icons.security_outlined,
        category: 'Chakra',
        defaultSpan: CardSpan.full,
      );

  KotaChakraData _data(AstroSnapshot s, DateTime? fixed) => kotaChakra(
        s,
        transit.currentTransitPositions(
            ayanamsaId: s.ayanamsaId, at: fixed ?? DateTime.now()),
      );

  /// Transiting malefics currently inside the fort's heart.
  List<String> _alerts(KotaChakraData d) {
    final alerts = <String>[];
    d.transit.forEach((off, planets) {
      final ring = kotaRing(off);
      if (ring == KotaRing.stambha || ring == KotaRing.madhya) {
        for (final p in planets) {
          final nak = Nakshatra28.names[(d.janmaNak28 + off - 1) % 28];
          alerts.add(isChakraMalefic(p)
              ? '${p.displayName} (malefic) in ${ring.displayName} · $nak'
              : '${p.displayName} (benefic) guards ${ring.displayName} · $nak');
        }
      }
    });
    return alerts;
  }

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) =>
      _KotaBody(module: this, ctx: ctx, detail: false);

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _KotaBody(module: this, ctx: ctx, detail: true),
      );

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final d = _data(ctx.snapshot, null);
    String ringOf(int off) => kotaRing(off).displayName;
    return [
      pdfSectionHeader('Kota Chakra'),
      pw.Text(
        'Janma: ${Nakshatra28.names[d.janmaNak28]} · '
        'Kota Swami: ${d.kotaSwami.displayName} · '
        'Kota Pala: ${d.kotaPala.displayName}',
        style: pdfBody(),
      ),
      pw.SizedBox(height: 8),
      pw.TableHelper.fromTextArray(
        headers: ['Planet', 'Nakshatra', 'Ring', 'Path'],
        data: [
          for (final e in d.natal.entries)
            for (final p in e.value)
              [
                p.displayName,
                Nakshatra28.names[(d.janmaNak28 + e.key - 1) % 28],
                ringOf(e.key),
                kotaIsEntry(e.key) ? 'Entry' : 'Exit',
              ],
        ],
        headerStyle: pdfLabel(),
        cellStyle: pdfBody(size: 9),
        border: null,
        cellAlignment: pw.Alignment.centerLeft,
        headerAlignment: pw.Alignment.centerLeft,
      ),
    ];
  }
}

class _KotaBody extends ConsumerWidget {
  const _KotaBody(
      {required this.module, required this.ctx, required this.detail});

  final KotaChakraModule module;
  final ModuleContext ctx;
  final bool detail;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ctx.snapshot;
    final fixed = ref.watch(transitFixedTimeProvider(ctx.kundli.id));
    final d = module._data(s, fixed);
    final alerts = module._alerts(d);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (detail) ...[
          Text('Kota Chakra', style: TETheme.serif(size: 18)),
          const SizedBox(height: 4),
          Text(
            'The fort: 28 nakshatras from the Janma nakshatra in four'
            ' enclosures. Malefics advancing along the entry paths toward'
            ' Stambha besiege the fort; benefics within defend it.',
            style: TETheme.mono(size: 11.5, color: TEColors.inkSoft),
          ),
          const SizedBox(height: 12),
        ],
        // Pinch to zoom (two fingers), card and detail alike — the
        // fort's labels are dense.
        PinchZoom(
          child: AspectRatio(
            aspectRatio: 1,
            child: CustomPaint(painter: KotaChakraPainter(data: d)),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Janma ${Nakshatra28.names[d.janmaNak28]} · '
          'Kota Swami ${d.kotaSwami.displayName} · '
          'Kota Pala ${d.kotaPala.displayName}'
          '${fixed != null ? '\nTransit as of chosen time' : ' · transit live'}',
          style: TETheme.mono(size: 11.5, color: TEColors.inkSoft),
        ),
        if (detail) ...[
          const SizedBox(height: 8),
          TransitTimeBar(
            fixed: fixed,
            onChanged: (f) => ref
                .read(transitFixedTimeProvider(ctx.kundli.id).notifier)
                .state = f,
          ),
        ],
        if (alerts.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final a in alerts)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                a,
                style: TETheme.mono(
                  size: 11,
                  color: a.contains('malefic')
                      ? TEColors.maroon
                      : TEColors.forest,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../pdf/pw.dart' as pw;

import '../charts/kota_chakra_painter.dart';
import '../charts/pinch_zoom.dart';
import '../core/astro/kota_chakra.dart';
import '../core/astro/models.dart';
import '../core/astro/transit.dart' as transit;
import '../core/theme/theme.dart';
import '../state/providers.dart';
import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

String _kotaChakraTitle(AppLocalizations l10n) => l10n.moduleKotaChakraTitle;

/// Kota Chakra — the "fort" of 28 nakshatras from the Janma nakshatra,
/// with natal placements and a live transit overlay. Follows the
/// per-kundli transit scrub time shared with the Transit widget.
class KotaChakraModule extends AstroModule {
  const KotaChakraModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'kota_chakra',
        title: 'Kota Chakra',
        localizedTitle: _kotaChakraTitle,
        icon: Icons.security_outlined,
        category: 'Chakra',
        defaultSpan: CardSpan.full,
      );

  KotaChakraData _data(AstroSnapshot s, DateTime? fixed) => kotaChakra(
        s,
        transit.currentTransitPositions(
            ayanamsaId: s.ayanamsaId, at: fixed ?? DateTime.now()),
      );

  /// Transiting malefics currently inside the fort's heart. The malefic
  /// flag travels as data — colouring must not sniff the localized text
  /// (`label.contains('malefic')` breaks in every non-English locale).
  List<({String label, bool malefic})> _alerts(
      AppLocalizations l10n, KotaChakraData d) {
    final alerts = <({String label, bool malefic})>[];
    d.transit.forEach((off, planets) {
      final ring = kotaRing(off);
      if (ring == KotaRing.stambha || ring == KotaRing.madhya) {
        for (final p in planets) {
          final nak = nakshatra28Label(l10n, (d.janmaNak28 + off - 1) % 28);
          final malefic = isChakraMalefic(p);
          alerts.add((
            label: malefic
                ? l10n.kotaAlertMalefic(p.label(l10n), ring.label(l10n), nak)
                : l10n.kotaAlertBenefic(p.label(l10n), ring.label(l10n), nak),
            malefic: malefic,
          ));
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
    final l10n = ctx.l10n;
    final d = _data(ctx.snapshot, null);
    String ringOf(int off) => kotaRing(off).label(l10n);
    return [
      pdfSectionHeader(l10n.moduleKotaChakraTitle),
      pw.Text(
        l10n.kotaSummary(
          nakshatra28Label(l10n, d.janmaNak28),
          d.kotaSwami.label(l10n),
          d.kotaPala.label(l10n),
        ),
        style: pdfBody(),
      ),
      pw.SizedBox(height: 8),
      pw.TableHelper.fromTextArray(
        headers: [
          l10n.labelGraha,
          l10n.labelNakshatra,
          l10n.kotaRing,
          l10n.kotaPath,
        ],
        data: [
          for (final e in d.natal.entries)
            for (final p in e.value)
              [
                p.label(l10n),
                nakshatra28Label(l10n, (d.janmaNak28 + e.key - 1) % 28),
                ringOf(e.key),
                kotaIsEntry(e.key) ? l10n.kotaEntry : l10n.kotaExit,
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
    final alerts = module._alerts(context.l10n, d);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (detail) ...[
          Text(context.l10n.moduleKotaChakraTitle,
              style: KJTheme.serif(size: 18)),
          const SizedBox(height: 4),
          Text(
            context.l10n.kotaBlurb,
            style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
          ),
          const SizedBox(height: 12),
        ],
        // Pinch to zoom (two fingers), card and detail alike — the
        // fort's labels are dense. The AspectRatio must wrap PinchZoom
        // (not the reverse) so its viewport is bounded — see chart_view;
        // inside-out nesting leaves an infinite height in a scrollable
        // and the pan clamp locks to zero.
        AspectRatio(
          aspectRatio: 1,
          child: PinchZoom(
            child: CustomPaint(
                painter: KotaChakraPainter(l10n: context.l10n, data: d)),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${context.l10n.kotaSummary(
            nakshatra28Label(context.l10n, d.janmaNak28),
            d.kotaSwami.label(context.l10n),
            d.kotaPala.label(context.l10n),
          )}'
          '${fixed != null ? '\n${context.l10n.kotaTransitAsOf}' : ' · ${context.l10n.kotaTransitLive}'}',
          style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
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
                a.label,
                style: KJTheme.mono(
                  size: 11,
                  color: a.malefic ? KJColors.maroon : KJColors.forest,
                ),
              ),
            ),
        ],
      ],
    );
  }
}

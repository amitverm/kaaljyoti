import 'package:flutter/material.dart';
import '../pdf/pw.dart' as pw;

import '../core/astro/jaimini_lagna.dart';
import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

String _jaiminiLagnaTitle(AppLocalizations l10n) =>
    l10n.moduleJaiminiLagnaTitle;

/// Karakamsha Lagna — the Jaimini special ascendant (Atmakaraka's
/// Navamsha sign). See core/astro/jaimini_lagna.dart.
class JaiminiLagnaModule extends AstroModule {
  const JaiminiLagnaModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'jaimini_lagna',
        title: 'Jaimini Lagna',
        localizedTitle: _jaiminiLagnaTitle,
        icon: Icons.explore_outlined,
        category: 'Jaimini',
        defaultSpan: CardSpan.half,
      );

  List<Planet> _occupants(AstroSnapshot s, ZodiacSign sign) =>
      s.positions.values
          .where((p) => p.sign == sign)
          .map((p) => p.planet)
          .toList();

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) {
    final l10n = context.l10n;
    final k = karakamshaLagna(ctx.snapshot);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.karakamshaHeading, style: KJTheme.serif(size: 16)),
        const SizedBox(height: 2),
        Text(k.sign.label(l10n), style: KJTheme.serif(size: 22)),
        const SizedBox(height: 6),
        Text(
          l10n.jlNavamshaLine(k.atmakaraka.label(l10n)),
          style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
        ),
      ],
    );
  }

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) {
    final l10n = context.l10n;
    final s = ctx.snapshot;
    final k = karakamshaLagna(s);
    final occupants = _occupants(s, k.sign);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.karakamshaHeading, style: KJTheme.serif(size: 18)),
          const SizedBox(height: 4),
          Text(
            l10n.jlBlurb,
            style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
          ),
          const SizedBox(height: 16),
          Text(k.sign.label(l10n), style: KJTheme.serif(size: 26)),
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: const TextStyle(fontSize: 13.5),
              children: [
                TextSpan(text: l10n.jlAtmakarakaLabel),
                TextSpan(
                    text: k.atmakaraka.label(l10n),
                    style: TextStyle(
                        color: planetInk(k.atmakaraka),
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            occupants.isEmpty
                ? l10n.jlNoOccupants
                : l10n.jlOccupants(k.sign.label(l10n),
                    occupants.map((p) => p.label(l10n)).join(', ')),
            style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
          ),
        ],
      ),
    );
  }

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final l10n = ctx.l10n;
    final k = karakamshaLagna(ctx.snapshot);
    return [
      pdfSectionHeader(l10n.jlPdfHeader),
      pw.Text(
        l10n.jlPdfLine(k.sign.label(l10n), k.atmakaraka.label(l10n)),
        style: pdfBody(),
      ),
    ];
  }
}

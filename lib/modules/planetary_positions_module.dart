import 'package:flutter/material.dart';
import '../pdf/pw.dart' as pw;

import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

String _planetaryPositionsTitle(AppLocalizations l10n) =>
    l10n.modulePlanetaryPositionsTitle;

class PlanetaryPositionsModule extends AstroModule {
  const PlanetaryPositionsModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'planetary_positions',
        title: 'Planetary Positions',
        localizedTitle: _planetaryPositionsTitle,
        icon: Icons.table_rows_outlined,
        category: 'Chart & Grahas',
        defaultSpan: CardSpan.full,
      );

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) => PositionsTable(
      snapshot: ctx.snapshot, compact: true, showAscendant: true);

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: PositionsTable(snapshot: ctx.snapshot, showAscendant: true),
      );

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) => [
        pdfSectionHeader(ctx.l10n.modulePlanetaryPositionsTitle),
        pdfPositionsTable(ctx.snapshot, ctx.l10n),
      ];
}

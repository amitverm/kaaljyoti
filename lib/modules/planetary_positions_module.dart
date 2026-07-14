import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;

import '../widgetsystem/astro_module.dart';
import 'common.dart';

class PlanetaryPositionsModule extends AstroModule {
  const PlanetaryPositionsModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'planetary_positions',
        title: 'Planetary Positions',
        icon: Icons.table_rows_outlined,
        category: 'Chart & Grahas',
        defaultSpan: CardSpan.full,
      );

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) =>
      PositionsTable(
          snapshot: ctx.snapshot, compact: true, showAscendant: true);

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: PositionsTable(snapshot: ctx.snapshot, showAscendant: true),
      );

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) => [
        pdfSectionHeader('Planetary Positions'),
        pdfPositionsTable(ctx.snapshot),
      ];
}

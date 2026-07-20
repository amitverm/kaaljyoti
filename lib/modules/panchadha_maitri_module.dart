import 'package:flutter/material.dart';
import '../pdf/pw.dart' as pw;

import '../core/astro/maitri.dart';
import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

/// Panchadha Maitri (fivefold relationship): a 7×7 graha grid where each
/// cell reads "how the ROW graha regards the COLUMN graha" — the
/// compound of the fixed natural (Naisargika) friendship and the
/// chart-specific temporary (Tatkalika) relationship, on the classical
/// Ati Mitra / Mitra / Sama / Satru / Ati Satru scale. The detail view
/// lets the reader peel the compound apart into its natural and temporary
/// layers. Rahu/Ketu are excluded, matching the node-free scoping of
/// dignity.dart and shadbala.dart.
class PanchadhaMaitriModule extends AstroModule {
  const PanchadhaMaitriModule();

  static String _title(AppLocalizations l10n) =>
      l10n.modulePanchadhaMaitriTitle;

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'panchadha_maitri',
        title: 'Panchadha Maitri',
        localizedTitle: _title,
        icon: Icons.hub_outlined,
        category: 'Chart & Grahas',
        defaultSpan: CardSpan.full,
      );

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: _MaitriGrid(
                snapshot: ctx.snapshot,
                mode: _MaitriMode.compound,
                cell: 32,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.maitriCardBlurb,
            style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
          ),
        ],
      );

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      _MaitriDetailBody(snapshot: ctx.snapshot);

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final s = ctx.snapshot;
    final l10n = ctx.l10n;
    // Abbr legend derived from the same keys the grid renders with, so a
    // translation can never drift from its own table.
    final legend = PanchadhaMaitri.values
        .map((m) => '${m.abbrLabel(l10n)} ${m.tierLabel(l10n)}')
        .join(' · ');
    return [
      pdfSectionHeader(l10n.modulePanchadhaMaitriTitle),
      pw.TableHelper.fromTextArray(
        headers: [
          l10n.maitriFromTo,
          ...kShadbalaPlanets.map((p) => p.abbrLabel(l10n)),
        ],
        data: [
          for (final from in kShadbalaPlanets)
            [
              from.abbrLabel(l10n),
              for (final to in kShadbalaPlanets)
                from == to
                    ? '—'
                    : maitriBetween(from, to, s).compound.abbrLabel(l10n),
            ],
        ],
        headerStyle: pdfLabel(),
        cellStyle: pdfBody(size: 9),
        border: null,
        cellAlignment: pw.Alignment.center,
        headerAlignment: pw.Alignment.center,
      ),
      pw.SizedBox(height: 4),
      pw.Text(
        '${l10n.maitriPdfLegendPrefix} $legend.',
        style: pdfLabel(),
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Which layer the grid is showing.
// ---------------------------------------------------------------------------

enum _MaitriMode { compound, natural, temporary }

extension on _MaitriMode {
  String label(AppLocalizations l10n) => switch (this) {
        _MaitriMode.compound => l10n.maitriModeCompound,
        _MaitriMode.natural => l10n.maitriModeNatural,
        _MaitriMode.temporary => l10n.maitriModeTemporary,
      };
}

/// (background, foreground, cell token) for a rendered relationship.
typedef _CellSpec = ({Color bg, Color fg, String text});

_CellSpec _compoundSpec(PanchadhaMaitri m, AppLocalizations l10n) =>
    switch (m) {
      PanchadhaMaitri.atiMitra => (
          bg: KJColors.forest.withValues(alpha: 0.24),
          fg: KJColors.forest,
          text: m.abbrLabel(l10n)
        ),
      PanchadhaMaitri.mitra => (
          bg: KJColors.forest.withValues(alpha: 0.12),
          fg: KJColors.forest,
          text: m.abbrLabel(l10n)
        ),
      PanchadhaMaitri.sama => (
          bg: KJColors.paperAlt,
          fg: KJColors.inkSoft,
          text: m.abbrLabel(l10n)
        ),
      PanchadhaMaitri.satru => (
          bg: KJColors.maroon.withValues(alpha: 0.12),
          fg: KJColors.maroon,
          text: m.abbrLabel(l10n)
        ),
      PanchadhaMaitri.atiSatru => (
          bg: KJColors.maroon.withValues(alpha: 0.24),
          fg: KJColors.maroon,
          text: m.abbrLabel(l10n)
        ),
    };

_CellSpec _relSpec(PlanetaryRel r, AppLocalizations l10n) => switch (r) {
      PlanetaryRel.friend => (
          bg: KJColors.forest.withValues(alpha: 0.14),
          fg: KJColors.forest,
          text: r.abbrLabel(l10n)
        ),
      PlanetaryRel.neutral => (
          bg: KJColors.paperAlt,
          fg: KJColors.inkSoft,
          text: r.abbrLabel(l10n)
        ),
      PlanetaryRel.enemy => (
          bg: KJColors.maroon.withValues(alpha: 0.12),
          fg: KJColors.maroon,
          text: r.abbrLabel(l10n)
        ),
    };

// ---------------------------------------------------------------------------
// The grid.
// ---------------------------------------------------------------------------

class _MaitriGrid extends StatelessWidget {
  const _MaitriGrid({
    required this.snapshot,
    required this.mode,
    required this.cell,
  });

  final AstroSnapshot snapshot;
  final _MaitriMode mode;
  final double cell;

  _CellSpec _spec(Planet from, Planet to, AppLocalizations l10n) {
    final rel = maitriBetween(from, to, snapshot);
    return switch (mode) {
      _MaitriMode.compound => _compoundSpec(rel.compound, l10n),
      _MaitriMode.natural => _relSpec(rel.natural, l10n),
      _MaitriMode.temporary => _relSpec(rel.temporary, l10n),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final fs = cell <= 28 ? 9.0 : 11.0;
    final headFs = cell <= 28 ? 9.5 : 11.5;
    return Table(
      defaultColumnWidth: FixedColumnWidth(cell),
      children: [
        TableRow(children: [
          SizedBox(width: cell, height: cell),
          for (final p in kShadbalaPlanets)
            _headerCell(p.abbrLabel(l10n), planetInk(p), headFs),
        ]),
        for (final from in kShadbalaPlanets)
          TableRow(children: [
            _headerCell(from.abbrLabel(l10n), planetInk(from), headFs),
            for (final to in kShadbalaPlanets)
              from == to ? _selfCell() : _relCell(_spec(from, to, l10n), fs),
          ]),
      ],
    );
  }

  Widget _headerCell(String t, Color c, double fs) => SizedBox(
        width: cell,
        height: cell,
        child: Center(
          child: Text(t,
              style: TextStyle(
                  fontSize: fs, color: c, fontWeight: FontWeight.w700)),
        ),
      );

  Widget _selfCell() => Container(
        width: cell,
        height: cell,
        margin: const EdgeInsets.all(1.5),
        alignment: Alignment.center,
        child: Text('·',
            style: TextStyle(color: KJColors.hairline, fontSize: cell * 0.4)),
      );

  Widget _relCell(_CellSpec s, double fs) => Container(
        width: cell,
        height: cell,
        margin: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          color: s.bg,
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(s.text,
            style: TextStyle(
                fontSize: fs, color: s.fg, fontWeight: FontWeight.w600)),
      );
}

// ---------------------------------------------------------------------------
// Detail view — grid at full size with a layer toggle and a legend.
// ---------------------------------------------------------------------------

class _MaitriDetailBody extends StatefulWidget {
  const _MaitriDetailBody({required this.snapshot});

  final AstroSnapshot snapshot;

  @override
  State<_MaitriDetailBody> createState() => _MaitriDetailBodyState();
}

class _MaitriDetailBodyState extends State<_MaitriDetailBody> {
  _MaitriMode _mode = _MaitriMode.compound;

  String _blurb(AppLocalizations l10n) => switch (_mode) {
        _MaitriMode.compound => l10n.maitriBlurbCompound,
        _MaitriMode.natural => l10n.maitriBlurbNatural,
        _MaitriMode.temporary => l10n.maitriBlurbTemporary,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.modulePanchadhaMaitriTitle, style: KJTheme.serif(size: 18)),
          const SizedBox(height: 4),
          Text(
            l10n.maitriDirectionalNote,
            style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final m in _MaitriMode.values)
                ChoiceChip(
                  label: Text(m.label(l10n)),
                  selected: _mode == m,
                  labelStyle: TextStyle(
                      color: _mode == m ? KJColors.paper : KJColors.ink),
                  onSelected: (_) => setState(() => _mode = m),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _MaitriGrid(
              snapshot: widget.snapshot,
              mode: _mode,
              cell: 40,
            ),
          ),
          const SizedBox(height: 16),
          _Legend(mode: _mode),
          const SizedBox(height: 14),
          Text(_blurb(l10n),
              style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft)),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.mode});

  final _MaitriMode mode;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final entries = <(_CellSpec, String)>[
      if (mode == _MaitriMode.compound)
        for (final m in PanchadhaMaitri.values)
          (
            _compoundSpec(m, l10n),
            '${m.abbrLabel(l10n)} — ${m.tierLabel(l10n)} · '
                '${m.glossLabel(l10n)}'
          )
      else ...[
        (
          _relSpec(PlanetaryRel.friend, l10n),
          '${PlanetaryRel.friend.abbrLabel(l10n)} — ${l10n.maitriLegendFriend}'
        ),
        if (mode == _MaitriMode.natural)
          (
            _relSpec(PlanetaryRel.neutral, l10n),
            '${PlanetaryRel.neutral.abbrLabel(l10n)} — '
                '${l10n.maitriLegendNeutral}'
          ),
        (
          _relSpec(PlanetaryRel.enemy, l10n),
          '${PlanetaryRel.enemy.abbrLabel(l10n)} — ${l10n.maitriLegendEnemy}'
        ),
      ],
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (spec, label) in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: spec.bg,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: Text(spec.text,
                      style: TextStyle(
                          fontSize: 9.5,
                          color: spec.fg,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 6),
                Text(label,
                    style: KJTheme.mono(size: 11, color: KJColors.inkSoft)),
              ],
            ),
          ),
      ],
    );
  }
}

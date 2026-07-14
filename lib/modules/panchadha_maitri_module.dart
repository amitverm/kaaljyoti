import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/astro/maitri.dart';
import '../core/astro/models.dart';
import '../core/theme/theme.dart';
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

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'panchadha_maitri',
        title: 'Panchadha Maitri',
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
            'Fivefold relationship — each row graha toward the column '
            'graha (natural + temporary combined).',
            style: TETheme.mono(size: 11.5, color: TEColors.inkSoft),
          ),
        ],
      );

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      _MaitriDetailBody(snapshot: ctx.snapshot);

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final s = ctx.snapshot;
    return [
      pdfSectionHeader('Panchadha Maitri'),
      pw.TableHelper.fromTextArray(
        headers: ['From \\ To', ...kShadbalaPlanets.map((p) => p.abbr)],
        data: [
          for (final from in kShadbalaPlanets)
            [
              from.abbr,
              for (final to in kShadbalaPlanets)
                from == to ? '—' : maitriBetween(from, to, s).compound.abbr,
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
        'Row graha\'s compound relationship to the column graha. '
        'AM Ati Mitra · Mi Mitra · Sm Sama · St Satru · AS Ati Satru.',
        style: pdfLabel(),
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Which layer the grid is showing.
// ---------------------------------------------------------------------------

enum _MaitriMode {
  compound('Compound'),
  natural('Natural'),
  temporary('Temporary');

  const _MaitriMode(this.label);
  final String label;
}

/// (background, foreground, cell token) for a rendered relationship.
typedef _CellSpec = ({Color bg, Color fg, String text});

_CellSpec _compoundSpec(PanchadhaMaitri m) => switch (m) {
      PanchadhaMaitri.atiMitra =>
        (bg: TEColors.forest.withValues(alpha: 0.24), fg: TEColors.forest, text: m.abbr),
      PanchadhaMaitri.mitra =>
        (bg: TEColors.forest.withValues(alpha: 0.12), fg: TEColors.forest, text: m.abbr),
      PanchadhaMaitri.sama =>
        (bg: TEColors.paperAlt, fg: TEColors.inkSoft, text: m.abbr),
      PanchadhaMaitri.satru =>
        (bg: TEColors.maroon.withValues(alpha: 0.12), fg: TEColors.maroon, text: m.abbr),
      PanchadhaMaitri.atiSatru =>
        (bg: TEColors.maroon.withValues(alpha: 0.24), fg: TEColors.maroon, text: m.abbr),
    };

_CellSpec _relSpec(PlanetaryRel r) => switch (r) {
      PlanetaryRel.friend =>
        (bg: TEColors.forest.withValues(alpha: 0.14), fg: TEColors.forest, text: 'F'),
      PlanetaryRel.neutral =>
        (bg: TEColors.paperAlt, fg: TEColors.inkSoft, text: 'N'),
      PlanetaryRel.enemy =>
        (bg: TEColors.maroon.withValues(alpha: 0.12), fg: TEColors.maroon, text: 'E'),
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

  _CellSpec _spec(Planet from, Planet to) {
    final rel = maitriBetween(from, to, snapshot);
    return switch (mode) {
      _MaitriMode.compound => _compoundSpec(rel.compound),
      _MaitriMode.natural => _relSpec(rel.natural),
      _MaitriMode.temporary => _relSpec(rel.temporary),
    };
  }

  @override
  Widget build(BuildContext context) {
    final fs = cell <= 28 ? 9.0 : 11.0;
    final headFs = cell <= 28 ? 9.5 : 11.5;
    return Table(
      defaultColumnWidth: FixedColumnWidth(cell),
      children: [
        TableRow(children: [
          SizedBox(width: cell, height: cell),
          for (final p in kShadbalaPlanets)
            _headerCell(p.abbr, planetInk(p), headFs),
        ]),
        for (final from in kShadbalaPlanets)
          TableRow(children: [
            _headerCell(from.abbr, planetInk(from), headFs),
            for (final to in kShadbalaPlanets)
              from == to ? _selfCell() : _relCell(_spec(from, to), fs),
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
            style: TextStyle(color: TEColors.hairline, fontSize: cell * 0.4)),
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

  String get _blurb => switch (_mode) {
        _MaitriMode.compound =>
          'The Panchadha (fivefold) relationship: the natural friendship '
              'blended with the temporary one, on the Ati Mitra … Ati '
              'Satru scale. A graha fares best in a sign owned by its '
              'compound friend.',
        _MaitriMode.natural =>
          'Naisargika (natural) relationship — the fixed classical table, '
              'the same for every chart.',
        _MaitriMode.temporary =>
          'Tatkalika (temporary) relationship — chart-specific: a graha in '
              'the 2nd/3rd/4th/10th/11th/12th sign from another is its '
              'temporary friend, otherwise its enemy.',
      };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Panchadha Maitri', style: TETheme.serif(size: 18)),
          const SizedBox(height: 4),
          Text(
            'Read a cell as the ROW graha\'s view of the COLUMN graha — '
            'these relationships are directional, so the grid is not '
            'symmetric.',
            style: TETheme.mono(size: 11.5, color: TEColors.inkSoft),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final m in _MaitriMode.values)
                ChoiceChip(
                  label: Text(m.label),
                  selected: _mode == m,
                  labelStyle: TextStyle(
                      color: _mode == m ? TEColors.paper : TEColors.ink),
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
          Text(_blurb,
              style: TETheme.mono(size: 11.5, color: TEColors.inkSoft)),
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
    final entries = <(_CellSpec, String)>[
      if (mode == _MaitriMode.compound)
        for (final m in PanchadhaMaitri.values)
          (_compoundSpec(m), '${m.abbr} — ${m.label} · ${m.english}')
      else ...[
        (_relSpec(PlanetaryRel.friend), 'F — Friend (Mitra)'),
        if (mode == _MaitriMode.natural)
          (_relSpec(PlanetaryRel.neutral), 'N — Neutral (Sama)'),
        (_relSpec(PlanetaryRel.enemy), 'E — Enemy (Satru)'),
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
                    style: TETheme.mono(size: 11, color: TEColors.inkSoft)),
              ],
            ),
          ),
      ],
    );
  }
}

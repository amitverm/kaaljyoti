import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/astro/dasha/dasha.dart';
import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

/// Yogas & Doshas — rule-engine results grouped by category, with a
/// dasha filter: All / active in the current Mahadasha / ripe in
/// MD + AD (participants include BOTH running Vimshottari lords).
///
/// The dashboard card stays compact (most-relevant few + "+N more");
/// the detail view carries the full grouped list. Everything is
/// computed offline; Mahakosh only ever reads the codes.
class YogasModule extends AstroModule {
  const YogasModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'yogas',
        title: 'Yogas & Doshas',
        icon: Icons.auto_awesome_outlined,
        category: 'Strength & Doshas',
      );

  @override
  List<ModuleConfigChoice> configChoices() => const [
        ModuleConfigChoice(
          key: 'dasha_basis',
          label: 'Active filter dasha',
          options: [
            ('vimshottari', 'Vimshottari'),
            ('chara', 'Jaimini Chara'),
          ],
        ),
      ];

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) =>
      _YogasBody(ctx: ctx, detail: false);

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _YogasBody(ctx: ctx, detail: true),
      );

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final grouped = _groupByCategory(ctx.snapshot.yogas);
    return [
      pdfSectionHeader('Yogas & Doshas'),
      if (ctx.snapshot.yogas.isEmpty)
        pw.Text('No major yogas detected.', style: pdfBody())
      else
        for (final e in grouped.entries) ...[
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 4, bottom: 2),
            child: pw.Text(e.key.toUpperCase(), style: pdfLabel()),
          ),
          for (final y in e.value)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 3),
              child: pw.Text(
                '${y.name}${y.detail != null ? ' — ${y.detail}' : ''}',
                style: pdfBody(size: 9.5),
              ),
            ),
        ],
    ];
  }
}

const _categoryOrder = [
  'Raj', 'Dhana', 'Vipreet Raj', 'Parivartana', 'Mahapurusha', 'Chandra',
  'Other', 'Dosha',
];

Map<String, List<DetectedYoga>> _groupByCategory(List<DetectedYoga> yogas) {
  final map = <String, List<DetectedYoga>>{};
  for (final c in _categoryOrder) {
    final inCat = yogas.where((y) => y.category == c).toList();
    if (inCat.isNotEmpty) map[c] = inCat;
  }
  final known = _categoryOrder.toSet();
  final rest = yogas.where((y) => !known.contains(y.category)).toList();
  if (rest.isNotEmpty) (map['Other'] ??= []).addAll(rest);
  return map;
}

enum _Filter {
  all('All'),
  md('Mahadasha'),
  mdAd('MD + AD');

  const _Filter(this.label);
  final String label;
}

/// How many yoga rows the dashboard CARD shows before "+N more".
const _cardCap = 6;

class _YogasBody extends StatefulWidget {
  const _YogasBody({required this.ctx, required this.detail});

  final ModuleContext ctx;
  final bool detail;

  @override
  State<_YogasBody> createState() => _YogasBodyState();
}

class _YogasBodyState extends State<_YogasBody> {
  // The active-filter basis is a declared config choice, so changing it
  // in the detail view persists to the widget row (via ctx.onConfigChanged)
  // and the card follows. Seeded from that config.
  late String _basis =
      widget.ctx.config['dasha_basis'] as String? ?? 'vimshottari';

  // The All / MD / MD+AD filter is exploration, not configuration: it's
  // kept session-local (static) so it survives leaving and returning
  // without ever touching the compact card. Detail view only.
  static _Filter? _detailFilter;
  late _Filter _filter =
      widget.detail ? (_detailFilter ?? _Filter.all) : _Filter.all;

  void _persistBasis(String value) =>
      widget.ctx.onConfigChanged?.call({...widget.ctx.config, 'dasha_basis': value});

  DashaPeriod? _maha;
  DashaPeriod? _antar;

  /// A yoga "involves" a dasha period when a participant IS the
  /// period's planet lord (Vimshottari), or — for a sign period
  /// (Jaimini Chara) — lords the dasha rashi or occupies it.
  bool _involves(DashaPeriod? period, DetectedYoga y) {
    if (period == null) return false;
    final planet = period.planet;
    if (planet != null) return y.participants.contains(planet);
    final sign = period.sign;
    if (sign != null) {
      return y.participants.any((p) =>
          sign.lord == p ||
          widget.ctx.snapshot.positions[p]!.sign == sign);
    }
    return false;
  }

  bool _activeMd(DetectedYoga y) => _involves(_maha, y);
  bool _activeMdAd(DetectedYoga y) =>
      _involves(_maha, y) && _involves(_antar, y);

  @override
  Widget build(BuildContext context) {
    final yogas = widget.ctx.snapshot.yogas;
    final basis =
        _basis == 'chara' ? DashaSystem.jaimini : DashaSystem.vimshottari;
    final (maha, antar, _) =
        widget.ctx.dasha(basis).activeAt(DateTime.now());
    _maha = maha;
    _antar = antar;

    final filtered = switch (_filter) {
      _Filter.all => yogas,
      _Filter.md => yogas.where(_activeMd).toList(),
      _Filter.mdAd => yogas.where(_activeMdAd).toList(),
    };
    final grouped = _groupByCategory(filtered);
    final flat = [for (final e in grouped.entries) ...e.value];

    // Card: most-relevant first (MD+AD, then MD, then category order),
    // capped. Detail: the full grouped list with headers.
    List<Widget> body;
    String? footer;
    if (widget.detail) {
      body = [
        for (final e in grouped.entries) ...[
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 2),
            child: Text(
              e.key.toUpperCase(),
              style: TETheme.mono(
                  size: 10.5,
                  color: TEColors.inkSoft,
                  weight: FontWeight.w700),
            ),
          ),
          for (final y in e.value) _row(y),
        ],
      ];
    } else {
      int score(DetectedYoga y) => _activeMdAd(y) ? 0 : (_activeMd(y) ? 1 : 2);
      // List.sort isn't stable — decorate with the original index so
      // equal scores keep category order.
      final indexed = flat.asMap().entries.toList()
        ..sort((a, b) {
          final s = score(a.value).compareTo(score(b.value));
          return s != 0 ? s : a.key.compareTo(b.key);
        });
      final capped = [for (final e in indexed.take(_cardCap)) e.value];
      final more = flat.length - capped.length;
      body = [for (final y in capped) _row(y, showCategory: true)];
      if (more > 0) footer = '+$more more — open the widget for all';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.detail) ...[
          // No page title here — the detail screen's app bar already
          // shows 'Yogas & Doshas'.
          Text(
            'A yoga fructifies in the periods of its participants —'
            ' filter by the running dasha lords to see which'
            ' combinations are live now.',
            style: TETheme.mono(size: 11.5, color: TEColors.inkSoft),
          ),
          const SizedBox(height: 10),
          _basisSelector(),
          const SizedBox(height: 8),
        ],
        Wrap(
          spacing: 6,
          children: [
            for (final o in _Filter.values)
              ChoiceChip(
                label: Text(o.label, style: const TextStyle(fontSize: 11.5)),
                selected: _filter == o,
                labelStyle: TextStyle(
                    fontSize: 11.5,
                    color: _filter == o ? TEColors.paper : TEColors.ink),
                visualDensity: VisualDensity.compact,
                onSelected: (_) => setState(() {
                  _filter = o;
                  if (widget.detail) _detailFilter = o;
                }),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Now: ${maha?.lordLabel ?? '—'} MD'
          '${antar != null ? ' · ${antar.lordLabel} AD' : ''}',
          style: TETheme.mono(size: 10.5, color: TEColors.inkSoft),
        ),
        const SizedBox(height: 6),
        if (filtered.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              _filter == _Filter.all
                  ? 'No major yogas detected.'
                  : 'No yogas involve the running'
                      ' ${_filter == _Filter.md ? 'Mahadasha lord' : 'MD and AD lords'}.',
              style: TextStyle(fontSize: 13, color: TEColors.inkSoft),
            ),
          )
        else
          ...body,
        if (footer != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              footer,
              style: TETheme.mono(
                  size: 10.5,
                  color: TEColors.maroon,
                  weight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  /// Detail-view control mirroring the card's 'Active filter dasha'
  /// config: which dasha lords drive the MD / MD+AD filters.
  Widget _basisSelector() => Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 4,
        children: [
          Text('Active filter dasha:',
              style: TETheme.mono(size: 11, color: TEColors.inkSoft)),
          for (final (val, label) in const [
            ('vimshottari', 'Vimshottari'),
            ('chara', 'Jaimini Chara'),
          ])
            ChoiceChip(
              label: Text(label, style: const TextStyle(fontSize: 11.5)),
              selected: _basis == val,
              labelStyle: TextStyle(
                  fontSize: 11.5,
                  color: _basis == val ? TEColors.paper : TEColors.ink),
              visualDensity: VisualDensity.compact,
              onSelected: (_) => setState(() {
                _basis = val;
                _persistBasis(val);
              }),
            ),
        ],
      );

  Widget _row(DetectedYoga y, {bool showCategory = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(y.name,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600)),
                ),
                if (showCategory) ...[
                  const SizedBox(width: 6),
                  Text(y.category,
                      style:
                          TETheme.mono(size: 9.5, color: TEColors.inkSoft)),
                ],
                if (_activeMd(y)) ...[
                  const SizedBox(width: 6),
                  _badge('MD', TEColors.maroon),
                ],
                if (_involves(_antar, y) &&
                    _antar?.lordLabel != _maha?.lordLabel) ...[
                  const SizedBox(width: 4),
                  _badge('AD', TEColors.forest),
                ],
              ],
            ),
            if (y.detail != null)
              Text(y.detail!,
                  style: TextStyle(fontSize: 12, color: TEColors.inkSoft)),
          ],
        ),
      );

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(text,
            style: TETheme.mono(
                size: 9.5, color: color, weight: FontWeight.w700)),
      );
}

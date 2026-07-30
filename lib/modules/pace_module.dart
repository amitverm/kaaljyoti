/// PACE — Position, Aspect, Conjunction, Exchange: everything acting
/// on each graha, in one card.
///
/// This is the "what is influencing this graha" view. Drishti alone is
/// the weakest of the four channels, so a card showing aspects but not
/// conjunction misleads by omission — see core/astro/pace.dart.
///
/// Position here means dignity + bhava nature, NOT sign and house
/// coordinates: those are already on Planetary Positions, and repeating
/// them would make this a duplicate card.
library;

import 'package:flutter/material.dart';
import '../pdf/pw.dart' as pw;

import '../charts/planet_token.dart' show dignityMark;
import '../core/astro/dignity.dart';
import '../core/astro/pace.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

String _paceTitle(AppLocalizations l10n) => l10n.modulePaceTitle;

class PaceModule extends AstroModule {
  const PaceModule();

  static const _kNodes = 'nodes';
  static const _kLayout = 'layout';

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'pace',
        title: 'PACE',
        localizedTitle: _paceTitle,
        icon: Icons.hub_outlined,
        category: 'Chart & Grahas',
        defaultSpan: CardSpan.full,
      );

  bool _includeNodes(Map<String, dynamic> config) =>
      (config[_kNodes] as String?) == 'on';

  /// How much of each graha the CARD shows — a standing user preference,
  /// named to match the kundli list's density presets so the app has one
  /// vocabulary for this.
  ///
  /// Detailed is the full P/A/C/E stack: readable, but nine of them run
  /// to ~860px, which is more than a phone screen for one card. Compact
  /// folds each graha onto one line (~340px) without dropping a single
  /// influence. Compact is the default for that reason; readers who want
  /// the stack on the dashboard itself can have it.
  ///
  /// The DETAIL view is always the stack — it has the room, and the
  /// setting is explicitly about the card.
  bool _compactCard(Map<String, dynamic> config) =>
      (config[_kLayout] as String?) != 'blocks';

  PaceTable _table(ModuleContext ctx) => PaceTable(
        positions: ctx.snapshot.positions,
        ascendant: ctx.snapshot.ascendant,
        includeNodes: _includeNodes(ctx.config),
      );

  @override
  List<ModuleConfigChoice> configChoices(AppLocalizations l10n) => [
        ModuleConfigChoice(
          key: _kLayout,
          label: l10n.paceCfgLayout,
          options: [
            ('compact', l10n.paceLayoutCompact),
            ('blocks', l10n.paceLayoutBlocks),
          ],
          defaultValue: 'compact',
        ),
        ModuleConfigChoice(
          key: _kNodes,
          label: l10n.gdCfgNodes,
          options: onOffOptions(l10n),
          defaultValue: 'off',
          toggleOnValue: 'on',
        ),
      ];

  /// Dignity as a short phrase, or null when the graha holds none —
  /// the nodes always, since their dignity is disputed and this app
  /// deliberately leaves it unmarked (see dignity.dart).
  String? _dignityLabel(PlanetDignity d, AppLocalizations l10n) => switch (d) {
        PlanetDignity.exalted => l10n.cmpDignExalted,
        PlanetDignity.debilitated => l10n.cmpDignDebilitated,
        PlanetDignity.ownSign => l10n.cmpDignOwn,
        PlanetDignity.none => null,
      };

  String _natureLabel(Set<BhavaNature> nature, AppLocalizations l10n) => [
        for (final n in nature)
          switch (n) {
            BhavaNature.kendra => l10n.paceKendra,
            BhavaNature.trikona => l10n.paceTrikona,
            BhavaNature.dusthana => l10n.paceDusthana,
            BhavaNature.upachaya => l10n.paceUpachaya,
          },
      ].join(' · ');

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) =>
      _compactCard(ctx.config)
          ? _compactList(context, ctx)
          : _blockList(context, ctx);

  /// The full P/A/C/E stack — one lettered row per channel.
  Widget _blockList(BuildContext context, ModuleContext ctx) {
    final table = _table(ctx);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in table.entries)
          _PaceBlock(
            entry: e,
            natureLabel: _natureLabel(e.position.nature, context.l10n),
          ),
      ],
    );
  }

  /// One line per graha, abbreviated — the same four channels, folded
  /// onto a single row so all nine fit on a card.
  Widget _compactList(BuildContext context, ModuleContext ctx) {
    final table = _table(ctx);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final e in table.entries)
          _PaceLine(
            entry: e,
            natureLabel: _natureLabel(e.position.nature, context.l10n),
          ),
      ],
    );
  }

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) {
    final l10n = context.l10n;
    final table = _table(ctx);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.paceHeading, style: KJTheme.serif(size: 18)),
          const SizedBox(height: 4),
          Text(l10n.paceBlurb,
              style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft)),
          const SizedBox(height: 4),
          Text(
            _includeNodes(ctx.config)
                ? l10n.gdNodesOnNote
                : l10n.gdNodesOffNote,
            style: KJTheme.mono(size: 11, color: KJColors.inkSoft),
          ),
          const SizedBox(height: 16),
          // Detail always gets the block layout regardless of the card
          // setting — there is room for it here, and it is the readable
          // form. The compact line exists only to fit a card.
          _blockList(context, ctx),
          const SizedBox(height: 20),
          // The house-first view of lordship. The P row already says
          // which houses a graha lords; this says it the other way round
          // — "the 10th lord went to the 6th" — which is how the
          // bhava-by-bhava reading actually runs.
          Text(l10n.paceBhavaLordsHeading, style: KJTheme.serif(size: 15)),
          const SizedBox(height: 8),
          for (final b in table.bhavaLords)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 34,
                    child: Text(l10n.gdHouseN('${b.house}'),
                        style:
                            KJTheme.mono(size: 11.5, color: KJColors.inkSoft)),
                  ),
                  Expanded(
                    child: Text.rich(TextSpan(children: [
                      TextSpan(
                        text: b.lord.label(l10n),
                        style: TextStyle(
                            fontSize: 12.5,
                            color: planetInk(b.lord),
                            fontWeight: FontWeight.w600),
                      ),
                      TextSpan(
                        text: '  →  ${l10n.gdHouseN('${b.lordHouse}')}'
                            ' · ${b.lordSign.label(l10n)}',
                        style:
                            KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
                      ),
                      // A lord sitting in its own bhava is a distinct
                      // reading, worth marking rather than leaving the
                      // reader to spot two equal numbers.
                      if (b.isInOwnBhava)
                        TextSpan(
                          text: '  ${l10n.paceOwnBhava}',
                          style: KJTheme.mono(size: 11, color: KJColors.forest),
                        ),
                    ])),
                  ),
                ],
              ),
            ),
          // Parivartana is chart-wide and rare — most charts have none,
          // so the section appears only when there is something to say
          // rather than printing an empty heading.
          if (table.hasExchange) ...[
            const SizedBox(height: 20),
            Text(l10n.paceExchangeHeading, style: KJTheme.serif(size: 15)),
            const SizedBox(height: 8),
            for (final (a, b) in table.exchanges)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text.rich(TextSpan(children: [
                  TextSpan(
                      text: a.label(l10n),
                      style: TextStyle(
                          fontSize: 13,
                          color: planetInk(a),
                          fontWeight: FontWeight.w600)),
                  const TextSpan(text: '  ⇄  '),
                  TextSpan(
                      text: b.label(l10n),
                      style: TextStyle(
                          fontSize: 13,
                          color: planetInk(b),
                          fontWeight: FontWeight.w600)),
                ])),
              ),
          ],
        ],
      ),
    );
  }

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final l10n = ctx.l10n;
    final table = _table(ctx);

    String positionCell(PaceEntry e) {
      final dignity = _dignityLabel(e.position.dignity, l10n);
      final nature = _natureLabel(e.position.nature, l10n);
      return [
        '${e.position.sign.label(l10n)} · H${e.position.house}',
        if (dignity != null) dignity,
        if (nature.isNotEmpty) nature,
        if (e.position.lordOf.isNotEmpty)
          l10n.paceLordOf(e.position.lordOf.map((h) => 'H$h').join(', ')),
      ].join(' · ');
    }

    return [
      ...pdfSection(
        header: pdfSectionHeader(l10n.paceHeading),
        rest: [
          pdfDataTable(
            headers: [
              l10n.labelGraha,
              l10n.pacePosition,
              l10n.paceAspect,
              l10n.paceConjunction,
              l10n.paceExchange,
            ],
            fontSize: 8.5,
            rows: [
              for (final e in table.entries)
                [
                  e.graha.label(l10n),
                  positionCell(e),
                  e.aspectedBy.isEmpty
                      ? '—'
                      : e.aspectedBy
                          .map((d) =>
                              '${d.from.abbrLabel(l10n)} (${d.distance})')
                          .join(', '),
                  e.conjunctWith.isEmpty
                      ? '—'
                      : e.conjunctWith.map((p) => p.abbrLabel(l10n)).join(', '),
                  e.exchangeWith?.abbrLabel(l10n) ?? '—',
                ],
            ],
          ),
          pdfSectionGap(),
        ],
      ),
      ...pdfSection(
        header: pdfSectionHeader(l10n.paceBhavaLordsHeading),
        rest: [
          pdfDataTable(
            headers: [l10n.gdHouseColumn, l10n.labelGraha, l10n.pacePosition],
            rows: [
              for (final b in table.bhavaLords)
                [
                  'H${b.house}',
                  b.lord.label(l10n),
                  'H${b.lordHouse} · ${b.lordSign.label(l10n)}'
                      '${b.isInOwnBhava ? ' · ${l10n.paceOwnBhava}' : ''}',
                ],
            ],
          ),
          pdfSectionGap(),
        ],
      ),
    ];
  }
}

/// One graha on a single line: abbreviation + dignity glyph, its
/// position in muted mono, then each non-empty channel as a lettered
/// group. Same information as [_PaceBlock] at roughly 40% the height
/// (~340px vs ~860px for nine grahas at phone width), which is what
/// lets all nine sit on a dashboard card.
///
/// Wraps rather than truncating — a graha with four aspects and two
/// conjunctions takes a second line, and losing an influence to an
/// ellipsis would be worse than an uneven row height.
class _PaceLine extends StatelessWidget {
  const _PaceLine({required this.entry, required this.natureLabel});

  final PaceEntry entry;
  final String natureLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final p = entry.position;
    final mark = dignityMark(p.dignity);
    final muted = KJTheme.mono(size: 11, color: KJColors.inkSoft);

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed gutter so the graha column stays aligned down the card
          // even as the content beside it wraps.
          SizedBox(
            width: 34,
            child: Text.rich(TextSpan(children: [
              TextSpan(
                text: entry.graha.abbrLabel(l10n),
                style: TextStyle(
                    fontSize: 12.5,
                    color: planetInk(entry.graha),
                    fontWeight: FontWeight.w600),
              ),
              if (mark != null)
                TextSpan(
                  text: ' ${mark.glyph}',
                  style: KJTheme.mono(
                      size: 10.5, color: mark.color ?? KJColors.inkSoft),
                ),
            ])),
          ),
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 3,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  [
                    '${p.sign.abbrLabel(l10n)}·${l10n.gdHouseN('${p.house}')}',
                    if (natureLabel.isNotEmpty) natureLabel,
                    if (p.lordOf.isNotEmpty) 'L${p.lordOf.join(',')}',
                  ].join(' · '),
                  style: muted,
                ),
                if (entry.conjunctWith.isNotEmpty)
                  _group(l10n.paceC, [
                    for (final g in entry.conjunctWith)
                      (g.abbrLabel(l10n), planetInk(g)),
                  ]),
                if (entry.aspectedBy.isNotEmpty)
                  _group(
                      l10n.paceA,
                      [
                        for (final d in entry.aspectedBy)
                          (
                            '${d.from.abbrLabel(l10n)}${d.distance}',
                            planetInk(d.from)
                          ),
                      ],
                      prefix: '←'),
                if (entry.exchangeWith != null)
                  _group(
                      l10n.paceE,
                      [
                        (
                          entry.exchangeWith!.abbrLabel(l10n),
                          planetInk(entry.exchangeWith!)
                        ),
                      ],
                      prefix: '⇄'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// One channel as `C Sa Ju` — the letter muted, the grahas in their
  /// own colours so the eye picks them out of the run.
  Widget _group(String letter, List<(String, Color)> items, {String? prefix}) {
    return Text.rich(TextSpan(children: [
      TextSpan(
        text: '$letter ${prefix ?? ''}',
        style: KJTheme.mono(size: 10.5, color: KJColors.inkSoft),
      ),
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const TextSpan(text: ' '),
        TextSpan(
          text: items[i].$1,
          style: TextStyle(
              fontSize: 12, color: items[i].$2, fontWeight: FontWeight.w600),
        ),
      ],
    ]));
  }
}

/// One graha's block: a heading line carrying Position, then a row per
/// non-empty channel. Empty channels are omitted rather than printed as
/// "none" — with four channels across nine grahas, printing the absences
/// would be most of the card.
class _PaceBlock extends StatelessWidget {
  const _PaceBlock({
    required this.entry,
    required this.natureLabel,
  });

  final PaceEntry entry;
  final String natureLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ink = planetInk(entry.graha);
    final p = entry.position;
    // Same glyph the chart uses (↑ exalted, ↓ debilitated, ○ own sign),
    // shared from planet_token.dart so the two can't drift.
    final mark = dignityMark(p.dignity);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The graha's name stands alone; everything about it lines up
          // underneath, one channel per row.
          Text.rich(TextSpan(children: [
            TextSpan(
              text: entry.graha.label(l10n),
              style: TextStyle(
                  fontSize: 13.5, color: ink, fontWeight: FontWeight.w600),
            ),
            if (mark != null)
              TextSpan(
                text: ' ${mark.glyph}',
                style: KJTheme.mono(
                    size: 12, color: mark.color ?? KJColors.inkSoft),
              ),
          ])),
          _channel(
              context,
              l10n.paceP,
              [
                (
                  [
                    p.sign.label(l10n),
                    l10n.gdHouseN('${p.house}'),
                    if (natureLabel.isNotEmpty) natureLabel,
                    if (p.lordOf.isNotEmpty)
                      l10n.paceLordOf(p.lordOf.map((h) => 'H$h').join(', ')),
                  ].join(' · '),
                  KJColors.inkSoft,
                ),
              ],
              muted: true),
          if (entry.conjunctWith.isNotEmpty)
            _channel(context, l10n.paceC, [
              for (final g in entry.conjunctWith) (g.label(l10n), planetInk(g)),
            ]),
          if (entry.aspectedBy.isNotEmpty)
            _channel(
              context,
              l10n.paceA,
              [
                for (final d in entry.aspectedBy)
                  ('${d.from.label(l10n)} ${d.distance}', planetInk(d.from)),
              ],
              prefix: '←',
            ),
          if (entry.exchangeWith != null)
            _channel(context, l10n.paceE, [
              (
                '${entry.exchangeWith!.label(l10n)} ⇄ ${entry.graha.label(l10n)}',
                planetInk(entry.exchangeWith!),
              ),
            ]),
          if (entry.isUntouched)
            Padding(
              padding: const EdgeInsets.only(left: 22, top: 3),
              child: Text(l10n.paceUntouched,
                  style: KJTheme.mono(size: 11, color: KJColors.inkSoft)),
            ),
        ],
      ),
    );
  }

  /// One lettered row. [prefix] carries the direction marker on the
  /// aspect row, where the drishti travels toward this graha.
  Widget _channel(
    BuildContext context,
    String letter,
    List<(String, Color)> items, {
    String? prefix,
    bool muted = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, top: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 16,
            child: Text(letter,
                style: KJTheme.mono(size: 11, color: KJColors.inkSoft)),
          ),
          if (prefix != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Text(prefix,
                  style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft)),
            ),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 3,
              children: [
                for (final (label, color) in items)
                  Text(
                    label,
                    style: muted
                        ? KJTheme.mono(size: 11.5, color: color)
                        : TextStyle(
                            fontSize: 12.5,
                            color: color,
                            fontWeight: FontWeight.w600),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

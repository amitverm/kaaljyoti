/// Parashari graha drishti — which grahas aspect which, and which
/// aspect each house. The rules live in core/astro/graha_drishti.dart,
/// shared with the yoga rule engine so the two can never disagree.
///
/// Two config choices, rendered generically by the hosts:
///   * direction — aspects RECEIVED (default) or CAST
///   * nodes — off by default, since classical practice doesn't reckon
///     Rahu/Ketu drishti; on gives them 5/7/9
///
/// Aspects on HOUSES (including empty ones, which a planets-only view
/// would silently drop) live in the detail view and the PDF, not on the
/// card: twelve more rows turn a half-span card into a wall, and as a
/// card toggle it was meaningless in the CAST direction — "which houses
/// does a house aspect" is not a question.
library;

import 'package:flutter/material.dart';
import '../pdf/pw.dart' as pw;

import '../core/astro/graha_drishti.dart';
import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

String _grahaDrishtiTitle(AppLocalizations l10n) =>
    l10n.moduleGrahaDrishtiTitle;

class GrahaDrishtiModule extends AstroModule {
  const GrahaDrishtiModule();

  static const _kDirection = 'direction';
  static const _kNodes = 'nodes';

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'graha_drishti',
        title: 'Graha Drishti',
        localizedTitle: _grahaDrishtiTitle,
        icon: Icons.visibility_outlined,
        category: 'Chart & Grahas',
        defaultSpan: CardSpan.half,
      );

  bool _received(Map<String, dynamic> config) =>
      (config[_kDirection] as String?) != 'cast';

  bool _includeNodes(Map<String, dynamic> config) =>
      (config[_kNodes] as String?) == 'on';

  GrahaDrishtiTable _table(ModuleContext ctx) => GrahaDrishtiTable(
        positions: ctx.snapshot.positions,
        ascendant: ctx.snapshot.ascendant,
        includeNodes: _includeNodes(ctx.config),
      );

  @override
  List<ModuleConfigChoice> configChoices(AppLocalizations l10n) => [
        ModuleConfigChoice(
          key: _kDirection,
          label: l10n.gdCfgDirection,
          options: [
            ('received', l10n.gdReceived),
            ('cast', l10n.gdCast),
          ],
          defaultValue: 'received',
        ),
        ModuleConfigChoice(
          key: _kNodes,
          label: l10n.gdCfgNodes,
          options: onOffOptions(l10n),
          defaultValue: 'off',
          toggleOnValue: 'on',
        ),
      ];

  @override
  String? configSummary(Map<String, dynamic> config, AppLocalizations l10n) =>
      _received(config) ? l10n.gdReceived : l10n.gdCast;

  /// Grahas in their canonical order, nodes last — they always appear as
  /// RECEIVERS even when they cast nothing.
  List<Planet> _grahas(ModuleContext ctx) => [
        for (final p in Planet.values)
          if (ctx.snapshot.positions.containsKey(p)) p,
      ];

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) {
    final l10n = context.l10n;
    final table = _table(ctx);
    final received = _received(ctx.config);
    final rows = <Widget>[];

    for (final p in _grahas(ctx)) {
      final links = received ? table.receivedBy(p) : table.castBy(p);
      rows.add(_DrishtiRow(
        subject: p.abbrLabel(l10n),
        subjectColor: planetInk(p),
        received: received,
        others: [
          for (final d in links)
            (
              label: (received ? d.from : d.to!).abbrLabel(l10n),
              color: planetInk(received ? d.from : d.to!),
              distance: d.distance,
            ),
        ],
        emptyLabel: l10n.gdNone,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }

  /// Aspects falling on each of the twelve bhavas, occupied or not.
  /// Always "received" — a house casts nothing — so this section is
  /// independent of the direction setting.
  Widget _houseSection(BuildContext context, ModuleContext ctx) {
    final l10n = context.l10n;
    final table = _table(ctx);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var h = 1; h <= 12; h++)
          _DrishtiRow(
            subject: l10n.gdHouseN('$h'),
            subjectColor: KJColors.inkSoft,
            received: true,
            others: [
              for (final d in table.onHouse(h))
                (
                  label: d.from.abbrLabel(l10n),
                  color: planetInk(d.from),
                  distance: d.distance,
                ),
            ],
            emptyLabel: l10n.gdNone,
          ),
      ],
    );
  }

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) {
    final l10n = context.l10n;
    final received = _received(ctx.config);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.gdHeading, style: KJTheme.serif(size: 18)),
          const SizedBox(height: 4),
          Text(l10n.gdBlurb,
              style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft)),
          const SizedBox(height: 4),
          Text(
            _includeNodes(ctx.config)
                ? l10n.gdNodesOnNote
                : l10n.gdNodesOffNote,
            style: KJTheme.mono(size: 11, color: KJColors.inkSoft),
          ),
          const SizedBox(height: 16),
          Text(received ? l10n.gdReceivedHeading : l10n.gdCastHeading,
              style: KJTheme.serif(size: 15)),
          const SizedBox(height: 8),
          cardView(context, ctx),
          const SizedBox(height: 20),
          Text(l10n.gdHouseHeading, style: KJTheme.serif(size: 15)),
          const SizedBox(height: 8),
          _houseSection(context, ctx),
          const SizedBox(height: 20),
          Text(l10n.gdRulesHeading, style: KJTheme.serif(size: 15)),
          const SizedBox(height: 8),
          // The rule table, so the reader can check the widget's working
          // rather than take it on trust.
          for (final p in _grahas(ctx))
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 92,
                    child: Text(p.label(l10n),
                        style: TextStyle(
                            fontSize: 12.5,
                            color: planetInk(p),
                            fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                    child: Text(
                      () {
                        final houses = drishtiHousesOf(p,
                            includeNodes: _includeNodes(ctx.config));
                        return houses.isEmpty
                            ? l10n.gdCastsNothing
                            : houses.join(' · ');
                      }(),
                      style: KJTheme.mono(size: 12, color: KJColors.inkSoft),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final l10n = ctx.l10n;
    final table = _table(ctx);
    final received = _received(ctx.config);

    List<String> linkCell(Planet p) {
      final links = received ? table.receivedBy(p) : table.castBy(p);
      if (links.isEmpty) return [l10n.gdNone];
      return [
        for (final d in links)
          '${(received ? d.from : d.to!).abbrLabel(l10n)} (${d.distance})',
      ];
    }

    return [
      ...pdfSection(
        header: pdfSectionHeader(
            received ? l10n.gdReceivedHeading : l10n.gdCastHeading),
        rest: [
          pdfDataTable(
            headers: [l10n.labelGraha, l10n.labelSign, l10n.gdAspectsColumn],
            rows: [
              for (final p in _grahas(ctx))
                [
                  p.label(l10n),
                  ctx.snapshot.positions[p]!.sign.label(l10n),
                  linkCell(p).join(', '),
                ],
            ],
          ),
          pdfSectionGap(),
        ],
      ),
      // The PDF is a document, not a card — the house table always rides
      // along rather than hiding behind a setting.
      ...pdfSection(
        header: pdfSectionHeader(l10n.gdHouseHeading),
        rest: [
          pdfDataTable(
            headers: [l10n.gdHouseColumn, l10n.gdAspectsColumn],
            columnWidths: const {
              0: pw.FixedColumnWidth(46),
              1: pw.FlexColumnWidth(),
            },
            rows: [
              for (var h = 1; h <= 12; h++)
                [
                  '$h',
                  table.onHouse(h).isEmpty
                      ? l10n.gdNone
                      : table
                          .onHouse(h)
                          .map((d) =>
                              '${d.from.abbrLabel(l10n)} (${d.distance})')
                          .join(', '),
                ],
            ],
          ),
          pdfSectionGap(),
        ],
      ),
    ];
  }
}

/// One "subject ← aspecting grahas" line. The arrow points the way the
/// drishti travels, so RECEIVED reads right-to-left and CAST reads
/// left-to-right — the direction is legible without the header.
class _DrishtiRow extends StatelessWidget {
  const _DrishtiRow({
    required this.subject,
    required this.subjectColor,
    required this.received,
    required this.others,
    required this.emptyLabel,
  });

  final String subject;
  final Color subjectColor;
  final bool received;
  final List<({String label, Color color, int distance})> others;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 34,
            child: Text(
              subject,
              style: TextStyle(
                  fontSize: 12.5,
                  color: subjectColor,
                  fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              received ? '←' : '→',
              style: KJTheme.mono(size: 12, color: KJColors.inkSoft),
            ),
          ),
          Expanded(
            child: others.isEmpty
                ? Text(emptyLabel,
                    style: KJTheme.mono(size: 12, color: KJColors.inkSoft))
                : Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final o in others)
                        Text.rich(
                          TextSpan(children: [
                            TextSpan(
                              text: o.label,
                              style: TextStyle(
                                  fontSize: 12.5,
                                  color: o.color,
                                  fontWeight: FontWeight.w600),
                            ),
                            // The aspect number is what distinguishes a
                            // Saturn 3rd from a Saturn 10th — the whole
                            // reason to show more than a bare pair.
                            TextSpan(
                              text: ' ${o.distance}',
                              style: KJTheme.mono(
                                  size: 10.5, color: KJColors.inkSoft),
                            ),
                          ]),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

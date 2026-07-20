/// Varsha Dasha — the three annual dashas (Mudda / Yogini / Patyayini)
/// switched per instance like the natal Dasha widget, computed for the
/// shared varsha year. Engine: core/astro/varsha_dasha.dart
/// (Charak ch. V, golden-tested).
///
/// Presentation: the card shows the running MD/AD chain (natal-card
/// style) over a proportional year strip plus the dated MD list — the
/// year overview an annual technique lives on. The detail view keeps
/// that overview and nests inline: an ACCORDION of MD cards, each
/// expanding to its antardasha mini-strip and rows (running MD opens
/// itself; strip segments jump-open their MD). Varsha dashas go two
/// levels only — Charak's tables stop at the antardasha; a pratyantar
/// in a 360-day year lasts hours.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../pdf/pw.dart' as pw;

import '../core/astro/dignity.dart';
import '../core/astro/models.dart';
import '../core/astro/varsha_dasha.dart';
import '../core/astro/varshphal.dart';
import '../core/theme/theme.dart';
import '../core/theme/type_scale.dart';
import '../l10n/astro_l10n.dart';
import '../state/providers.dart';
import '../widgetsystem/astro_module.dart';

String _title(AppLocalizations l10n) => l10n.moduleVarshphalDashaTitle;

DateFormat get _fmt => DateFormat('d MMM yy');

VarshaDashaSystem _system(Map<String, dynamic> config) =>
    switch (config['system']) {
      'yogini' => VarshaDashaSystem.yogini,
      'patyayini' => VarshaDashaSystem.patyayini,
      _ => VarshaDashaSystem.mudda,
    };

String _systemLabel(AppLocalizations l10n, VarshaDashaSystem s) => switch (s) {
      VarshaDashaSystem.mudda => l10n.vdMudda,
      VarshaDashaSystem.yogini => l10n.vdYogini,
      VarshaDashaSystem.patyayini => l10n.vdPatyayini,
    };

String _lordLabel(
    AppLocalizations l10n, VarshaDashaSystem system, VarshaDashaPeriod p) {
  final lord = p.lord;
  if (lord == null) return l10n.labelLagna;
  if (system == VarshaDashaSystem.yogini) {
    final idx = yoginiVarshaIndexOf(lord);
    if (idx >= 0) {
      return '${yoginiLabelForIndex(l10n, idx)} (${lord.label(l10n)})';
    }
  }
  return lord.label(l10n);
}

String _lordAbbr(AppLocalizations l10n, VarshaDashaPeriod p) =>
    p.lord?.abbrLabel(l10n) ?? l10n.vdLagnaAbbr;

Color _lordInk(VarshaDashaPeriod p) =>
    p.lord != null ? planetInk(p.lord!) : KJColors.maroon;

String _daysText(AppLocalizations l10n, VarshaDashaPeriod p) {
  final days = p.length.inMilliseconds / Duration.millisecondsPerDay;
  return l10n.vdDays('${days.toStringAsFixed(days < 10 ? 1 : 0)}');
}

String _rangeText(VarshaDashaPeriod p) =>
    '${_fmt.format(p.start.toLocal())} — ${_fmt.format(p.end.toLocal())}';

/// Lord's standing in the VARSHA chart — what a Tajika period is
/// judged by: sign · house · degree, plus the chart-token glyphs
/// (® retro, ↑ exalted, ↓ debilitated, ○ own sign, • combust). The
/// Patyayini Lagna period shows the ascendant itself.
String? _placementText(
    AppLocalizations l10n, AstroSnapshot varsha, VarshaDashaPeriod p) {
  final lord = p.lord;
  if (lord == null) {
    return '${varsha.lagnaSign.label(l10n)} · '
        '${formatDegreeInSign(varsha.ascendant % 30)}';
  }
  final pos = varsha.positions[lord];
  if (pos == null) return null;
  final house = ((pos.sign.index - varsha.lagnaSign.index + 12) % 12) + 1;
  final glyphs = StringBuffer();
  if (pos.isRetrograde) glyphs.write('®');
  switch (dignityOf(pos)) {
    case PlanetDignity.exalted:
      glyphs.write('↑');
    case PlanetDignity.debilitated:
      glyphs.write('↓');
    case PlanetDignity.ownSign:
      glyphs.write('○');
    case PlanetDignity.none:
      break;
  }
  if (lord != Planet.sun && isCombust(pos, varsha.positions[Planet.sun]!)) {
    glyphs.write('•');
  }
  // House ownership from the varsha lagna — benefic/malefic lordship
  // at a glance, same as the natal widget (empty for Rahu/Ketu).
  final owned = [
    for (final s in ZodiacSign.values)
      if (s.lord == lord) ((s.index - varsha.lagnaSign.index + 12) % 12) + 1,
  ]..sort();
  return '${pos.sign.label(l10n)} · H$house · '
      '${formatDegreeInSign(pos.degreesInSign)}'
      '${glyphs.isEmpty ? '' : ' $glyphs'}'
      '${owned.isEmpty ? '' : ' · ${l10n.dmLordOf(owned.map((h) => 'H$h').join(', '))}'}';
}

List<VarshaDashaPeriod> _computePeriods(
  VarshaDashaSystem system,
  VarshphalData d,
  AstroSnapshot natal,
) =>
    switch (system) {
      VarshaDashaSystem.mudda => muddaDasha(
          praveshUtc: d.returnUtc,
          natalMoonLongitude: natal.positions[Planet.moon]!.longitude,
          varshaYear: d.varshaYear,
        ),
      VarshaDashaSystem.yogini => yoginiVarshaDasha(
          praveshUtc: d.returnUtc,
          natalMoonLongitude: natal.positions[Planet.moon]!.longitude,
          varshaYear: d.varshaYear,
        ),
      VarshaDashaSystem.patyayini =>
        patyayiniDasha(praveshUtc: d.returnUtc, varsha: d.snapshot),
    };

class VarshphalDashaModule extends AstroModule {
  const VarshphalDashaModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'varshphal_dasha',
        title: 'Varsha Dasha',
        localizedTitle: _title,
        icon: Icons.timelapse_outlined,
        category: 'Varshphal',
        defaultSpan: CardSpan.full,
      );

  @override
  List<ModuleConfigChoice> configChoices(AppLocalizations l10n) => [
        ModuleConfigChoice(
          key: 'system',
          label: l10n.cfgDashaSystem,
          options: [
            ('mudda', l10n.vdMudda),
            ('yogini', l10n.vdYogini),
            ('patyayini', l10n.vdPatyayini),
          ],
          defaultValue: 'mudda',
        ),
        // Same key/label as the natal Dasha widget's toggle.
        ModuleConfigChoice(
          key: 'placements',
          label: l10n.cfgLordPositions,
          options: [('hide', l10n.hide), ('show', l10n.show)],
          toggleOnValue: 'show',
          defaultValue: 'hide',
        ),
      ];

  @override
  String? configSummary(Map<String, dynamic> config, AppLocalizations l10n) =>
      _systemLabel(l10n, _system(config));

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) =>
      _VarshaDashaCard(ctx: ctx);

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      _VarshaDashaDetail(ctx: ctx);

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) => const [];
}

// ---------------------------------------------------------------------------
// Shared header: kicker · year line · running MD headline · running AD row
// ---------------------------------------------------------------------------

class _ChainHeader extends StatelessWidget {
  const _ChainHeader({
    required this.system,
    required this.data,
    required this.running,
    required this.runningSub,
    this.showPlacements = false,
  });

  final VarshaDashaSystem system;
  final VarshphalData data;
  final VarshaDashaPeriod? running;
  final VarshaDashaPeriod? runningSub;
  final bool showPlacements;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_systemLabel(l10n, system).toUpperCase(), style: KJType.kicker()),
        const SizedBox(height: 6),
        Text(
          l10n.vpYearLine(
              '${data.varshaYear}', '${data.returnUtc.toUtc().year}'),
          style: KJTheme.mono(size: 11, color: KJColors.inkSoft),
        ),
        if (running != null) ...[
          const SizedBox(height: 6),
          Text.rich(
            TextSpan(
              style: KJTheme.serif(size: 17),
              children: [
                TextSpan(
                  text: _lordLabel(l10n, system, running!),
                  style: TextStyle(color: _lordInk(running!)),
                ),
                TextSpan(text: ' ${dashaLevelLabel(l10n, 1)}'),
              ],
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${_rangeText(running!)} · ${_daysText(l10n, running!)}',
            style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
          ),
          if (showPlacements)
            if (_placementText(l10n, data.snapshot, running!)
                case final place?) ...[
              const SizedBox(height: 3),
              Text('${_lordAbbr(l10n, running!)}: $place',
                  style: KJTheme.mono(size: 10.5, color: KJColors.inkSoft)),
            ],
          if (runningSub != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: KJColors.maroon,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      style: const TextStyle(fontSize: 12),
                      children: [
                        TextSpan(
                            text: _lordLabel(l10n, system, runningSub!),
                            style: TextStyle(
                                color: _lordInk(runningSub!),
                                fontWeight: FontWeight.w600)),
                        TextSpan(
                          text: ' ${dashaLevelLabel(l10n, 2)} · '
                              '${_rangeText(runningSub!)}'
                              ' · ${_daysText(l10n, runningSub!)}',
                          style: TextStyle(color: KJColors.inkSoft),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (showPlacements)
              if (_placementText(l10n, data.snapshot, runningSub!)
                  case final place?) ...[
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.only(left: 15),
                  child: Text('${_lordAbbr(l10n, runningSub!)}: $place',
                      style: KJTheme.mono(size: 10.5, color: KJColors.inkSoft)),
                ),
              ],
          ],
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Card: chain header + proportional year strip
// ---------------------------------------------------------------------------

class _VarshaDashaCard extends ConsumerWidget {
  const _VarshaDashaCard({required this.ctx});

  final ModuleContext ctx;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final natal = ctx.snapshot;
    final system = _system(ctx.config);
    final current =
        currentVarshaYear(natal.birth.dateTimeUtc, DateTime.now().toUtc());
    final year = ref.watch(varshphalYearProvider(ctx.kundli.id)) ?? current;
    final async = ref.watch(varshphalProvider((ctx.kundli.id, year)));

    return async.when(
      loading: () => const SizedBox(
          height: 100, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text(l10n.vpError('$e')),
      data: (d) {
        final periods = _computePeriods(system, d, natal);
        final now = DateTime.now().toUtc();
        final running = periods.where((p) => p.contains(now)).firstOrNull;
        final runningSub =
            running?.subPeriods.where((s) => s.contains(now)).firstOrNull;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ChainHeader(
                system: system,
                data: d,
                running: running,
                runningSub: runningSub,
                showPlacements: ctx.config['placements'] == 'show'),
            const SizedBox(height: 10),
            _VarshaTimeline(l10n: l10n, periods: periods, now: now),
            const SizedBox(height: 8),
            // The dated MD list — the year overview at a glance.
            for (final p in periods)
              _overviewRow(l10n, system, p, now,
                  place: ctx.config['placements'] == 'show'
                      ? _placementText(l10n, d.snapshot, p)
                      : null),
          ],
        );
      },
    );
  }

  Widget _overviewRow(AppLocalizations l10n, VarshaDashaSystem system,
      VarshaDashaPeriod p, DateTime now,
      {String? place}) {
    final running = p.contains(now);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: running ? KJColors.maroon : Colors.transparent,
                    border:
                        running ? null : Border.all(color: KJColors.hairline),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  _lordLabel(l10n, system, p),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: running ? FontWeight.w600 : FontWeight.w500,
                    color: _lordInk(p),
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  _rangeText(p),
                  style: KJTheme.mono(
                      size: 11,
                      color: running ? KJColors.ink : KJColors.inkSoft,
                      weight: running ? FontWeight.w600 : FontWeight.w400),
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  _daysText(l10n, p),
                  textAlign: TextAlign.right,
                  style: KJTheme.mono(size: 11, color: KJColors.inkSoft),
                ),
              ),
            ],
          ),
          if (place != null)
            Padding(
              padding: const EdgeInsets.only(left: 15, top: 1),
              child: Text('${_lordAbbr(l10n, p)}: $place',
                  style: KJTheme.mono(size: 10, color: KJColors.inkSoft)),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Detail: chain header + strip + MD accordion (ADs expand inline)
// ---------------------------------------------------------------------------

class _VarshaDashaDetail extends ConsumerStatefulWidget {
  const _VarshaDashaDetail({required this.ctx});

  final ModuleContext ctx;

  @override
  ConsumerState<_VarshaDashaDetail> createState() => _VarshaDashaDetailState();
}

class _VarshaDashaDetailState extends ConsumerState<_VarshaDashaDetail> {
  /// Expanded mahadasha indices. Keyed by year+system so stepping the
  /// year or reconfiguring resets to just the running MD.
  Set<int> _open = {};
  String _key = '';

  @override
  Widget build(BuildContext context) {
    final ctx = widget.ctx;
    final l10n = context.l10n;
    final natal = ctx.snapshot;
    final system = _system(ctx.config);
    final current =
        currentVarshaYear(natal.birth.dateTimeUtc, DateTime.now().toUtc());
    final year = ref.watch(varshphalYearProvider(ctx.kundli.id)) ?? current;
    final async = ref.watch(varshphalProvider((ctx.kundli.id, year)));

    return async.when(
      loading: () => const SizedBox(
          height: 100, child: Center(child: CircularProgressIndicator())),
      error: (e, _) => Text(l10n.vpError('$e')),
      data: (d) {
        final periods = _computePeriods(system, d, natal);
        final now = DateTime.now().toUtc();
        final runningIdx = periods.indexWhere((p) => p.contains(now));
        final running = runningIdx >= 0 ? periods[runningIdx] : null;
        final runningSub =
            running?.subPeriods.where((s) => s.contains(now)).firstOrNull;

        final key = '$year·$system';
        if (key != _key) {
          // Fresh year/system: open the running MD (if this is the
          // live year), everything else collapsed.
          _key = key;
          _open = {if (runningIdx >= 0) runningIdx};
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.moduleVarshphalDashaTitle,
                  style: KJTheme.serif(size: 18)),
              const SizedBox(height: 8),
              _ChainHeader(
                  system: system,
                  data: d,
                  running: running,
                  runningSub: runningSub,
                  showPlacements: ctx.config['placements'] == 'show'),
              const SizedBox(height: 10),
              _VarshaTimeline(
                l10n: l10n,
                periods: periods,
                now: now,
                onTapSegment: (i) => setState(() {
                  _open.contains(i) ? _open.remove(i) : _open.add(i);
                }),
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < periods.length; i++)
                _mdCard(l10n, system, periods[i], now,
                    isCurrent: i == runningIdx,
                    expanded: _open.contains(i),
                    place: ctx.config['placements'] == 'show'
                        ? _placementText(l10n, d.snapshot, periods[i])
                        : null,
                    onToggle: () => setState(() {
                          _open.contains(i) ? _open.remove(i) : _open.add(i);
                        })),
            ],
          ),
        );
      },
    );
  }

  /// One accordion card: the dated MD row stays visible always (the
  /// year overview); tapping expands its antardashas inline — mini
  /// strip + dense rows — natal-card visual language throughout.
  Widget _mdCard(
    AppLocalizations l10n,
    VarshaDashaSystem system,
    VarshaDashaPeriod p,
    DateTime now, {
    required bool isCurrent,
    required bool expanded,
    required VoidCallback onToggle,
    String? place,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isCurrent
            ? KJColors.maroon.withValues(alpha: 0.06)
            : KJColors.paper,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isCurrent ? KJColors.maroon : KJColors.hairline,
              width: isCurrent ? 1.2 : 1,
            ),
          ),
          child: Column(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onToggle,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(_lordLabel(l10n, system, p),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _lordInk(p))),
                                ),
                                if (isCurrent) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: KJColors.maroon,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(l10n.dmCurrent,
                                        style: TextStyle(
                                            fontSize: 8.5,
                                            letterSpacing: 0.8,
                                            fontWeight: FontWeight.w600,
                                            color: KJColors.paper)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${_rangeText(p)} · ${_daysText(l10n, p)}',
                              style: KJTheme.mono(
                                  size: 10.5, color: KJColors.inkSoft),
                            ),
                            if (place != null) ...[
                              const SizedBox(height: 2),
                              Text('${_lordAbbr(l10n, p)}: $place',
                                  style: KJTheme.mono(
                                      size: 10, color: KJColors.inkSoft)),
                            ],
                          ],
                        ),
                      ),
                      AnimatedRotation(
                        turns: expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 150),
                        child: Icon(Icons.expand_more,
                            size: 18, color: KJColors.inkSoft),
                      ),
                    ],
                  ),
                ),
              ),
              if (expanded) ...[
                Container(height: 0.7, color: KJColors.hairline),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dashaLevelLabel(l10n, 2, plural: true).toUpperCase(),
                          style: KJType.kicker()),
                      const SizedBox(height: 6),
                      _VarshaTimeline(
                          l10n: l10n,
                          periods: p.subPeriods,
                          now: now,
                          height: 18),
                      const SizedBox(height: 6),
                      for (final sub in p.subPeriods)
                        _adRow(l10n, system, sub,
                            running: p.contains(now) && sub.contains(now)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _adRow(
      AppLocalizations l10n, VarshaDashaSystem system, VarshaDashaPeriod p,
      {required bool running}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              _lordLabel(l10n, system, p),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: running ? FontWeight.w600 : FontWeight.w500,
                color: _lordInk(p),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              _rangeText(p),
              style: KJTheme.mono(
                  size: 10,
                  color: running ? KJColors.ink : KJColors.inkSoft,
                  weight: running ? FontWeight.w600 : FontWeight.w400),
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              _daysText(l10n, p),
              textAlign: TextAlign.right,
              style: KJTheme.mono(size: 10, color: KJColors.inkSoft),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Proportional year strip (natal antardasha-timeline styling)
// ---------------------------------------------------------------------------

/// The year's periods as a proportional strip — same look as the natal
/// card's antardasha timeline: current maroon, past dimmed, future on
/// paperAlt, ink needle at "now" when this varsha is running.
class _VarshaTimeline extends StatelessWidget {
  const _VarshaTimeline({
    required this.l10n,
    required this.periods,
    required this.now,
    this.height = 26,
    this.onTapSegment,
  });

  final AppLocalizations l10n;
  final List<VarshaDashaPeriod> periods;
  final DateTime now;
  final double height;

  /// Tap on segment i (detail view: jump-opens that MD's accordion).
  final ValueChanged<int>? onTapSegment;

  @override
  Widget build(BuildContext context) {
    if (periods.isEmpty) return const SizedBox.shrink();
    final start = periods.first.start;
    final end = periods.last.end;
    final totalSec = end.difference(start).inSeconds;
    if (totalSec <= 0) return const SizedBox.shrink();

    return LayoutBuilder(builder: (context, constraints) {
      // Inner width: the wrapping Container draws a 1px border on each
      // side, so segments must fit in maxWidth - 2 to avoid overflow.
      final w = constraints.maxWidth - 2;
      final widths = <double>[];
      var used = 0.0;
      for (var i = 0; i < periods.length; i++) {
        if (i == periods.length - 1) {
          widths.add(w - used);
        } else {
          final seg = w * periods[i].length.inSeconds / totalSec;
          widths.add(seg);
          used += seg;
        }
      }
      final inYear = !now.isBefore(start) && now.isBefore(end);
      final needleX = inYear
          ? (1 + w * now.difference(start).inSeconds / totalSec)
              .clamp(1.0, w + 1.0)
              .toDouble()
          : null;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: KJColors.hairline),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Row(
                    children: [
                      for (var i = 0; i < periods.length; i++)
                        GestureDetector(
                          onTap: onTapSegment == null
                              ? null
                              : () => onTapSegment!(i),
                          child: _segment(periods[i], widths[i],
                              last: i == periods.length - 1),
                        ),
                    ],
                  ),
                ),
              ),
              if (needleX != null)
                // Paper halo behind the ink needle so it stays visible
                // over both the maroon current segment and muted past.
                Positioned(
                  left: needleX - 2,
                  top: -4,
                  bottom: -4,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: KJColors.paper,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    alignment: Alignment.center,
                    child: Container(width: 2, color: KJColors.ink),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(_fmt.format(start.toLocal()),
                  style: KJTheme.mono(size: 9.5, color: KJColors.inkSoft)),
              const Spacer(),
              Text(_fmt.format(end.toLocal()),
                  style: KJTheme.mono(size: 9.5, color: KJColors.inkSoft)),
            ],
          ),
        ],
      );
    });
  }

  Widget _segment(VarshaDashaPeriod p, double width, {required bool last}) {
    final isCurrent = p.contains(now);
    final isPast = !p.end.isAfter(now);
    final color = isCurrent
        ? KJColors.maroon
        : isPast
            ? KJColors.inkSoft.withValues(alpha: 0.22)
            : KJColors.paperAlt;
    return Tooltip(
      message: '${p.lord?.label(l10n) ?? l10n.labelLagna}\n'
          '${_rangeText(p)} · ${_daysText(l10n, p)}',
      textAlign: TextAlign.center,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: color,
          border: last
              ? null
              : Border(
                  right: BorderSide(
                      color: KJColors.inkSoft.withValues(alpha: 0.45),
                      width: 0.7)),
        ),
        alignment: Alignment.center,
        // Horizontal label when the segment is wide enough; rotated
        // 90° for narrow slivers (e.g. Moon 10/360 in Yogini) so every
        // period stays named.
        child: width >= 16
            ? Text(
                _lordAbbr(l10n, p),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: isCurrent ? KJColors.paper : KJColors.inkSoft,
                ),
              )
            : width >= 8
                ? RotatedBox(
                    quarterTurns: 3,
                    child: Text(
                      _lordAbbr(l10n, p),
                      style: TextStyle(
                        fontSize: 7.5,
                        fontWeight: FontWeight.w600,
                        color: isCurrent ? KJColors.paper : KJColors.inkSoft,
                      ),
                    ),
                  )
                : null,
      ),
    );
  }
}

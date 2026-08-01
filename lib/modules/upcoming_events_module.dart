/// Upcoming Events — the single consultation-prep timeline, merging
/// three sources into one sorted feed. Assembly only: every date comes
/// from an existing engine (dasha period tree, [gocharEventsProvider],
/// [sadeSatiPhasesProvider]); this module adds no new astrological
/// math. (Round 2, Task 7: this replaces the standalone Gochar module
/// — transit events are still the same [scanGochar] feed, just no
/// longer duplicated as a separate card.)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../pdf/pw.dart' as pw;

import '../core/astro/dasha/dasha.dart';
import '../core/astro/event_feed.dart';
import '../core/astro/models.dart';
import '../core/astro/transit_scan.dart';
import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../core/theme/type_scale.dart';
import '../state/providers.dart';
import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

String _upcomingEventsTitle(AppLocalizations l10n) =>
    l10n.moduleUpcomingEventsTitle;

/// The 5 planets worth a dedicated filter chip — the same "watch"
/// list the old Gochar module used (Rahu/Ketu/Saturn/Jupiter/Mars are
/// the slow movers whose ingresses and natal hits matter most for
/// consultation prep).
const _kFilterPlanets = [
  Planet.saturn,
  Planet.jupiter,
  Planet.rahu,
  Planet.ketu,
  Planet.mars,
];

// Full-date formatters follow the user's app-wide date-format choice; the
// month-only formatter stays fixed.
DateFormat get _dateTimeFmt => DateFormat('${KJDate.pref.datePattern}, h:mm a');
DateFormat get _dateFmt => DateFormat(KJDate.pref.datePattern);
DateFormat get _timeFmt => DateFormat('h:mm a');
final _monthFmt = DateFormat('MMMM yyyy');

class UpcomingEventsModule extends AstroModule {
  const UpcomingEventsModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'upcoming_events',
        title: 'Upcoming Events',
        localizedTitle: _upcomingEventsTitle,
        icon: Icons.event_note_outlined,
        category: 'Timing & Dashas',
      );

  @override
  List<ModuleConfigChoice> configChoices(AppLocalizations l10n) => [
        ModuleConfigChoice(
          key: 'system',
          label: l10n.cfgDashaSystem,
          options: [
            for (final s in DashaSystem.values) (s.name, s.label(l10n)),
          ],
        ),
        ModuleConfigChoice(
          key: 'months',
          label: l10n.cfgWindow,
          options: [
            for (final m in const [3, 6, 12, 24]) ('$m', l10n.windowMonths(m)),
          ],
          defaultValue: '12',
        ),
        ModuleConfigChoice(
          key: 'fine',
          label: l10n.cfgFineLevels,
          options: [('hide', l10n.hide), ('show', l10n.show)],
          toggleOnValue: 'show',
          defaultValue: 'hide',
        ),
      ];

  DashaSystem _system(ModuleContext ctx) {
    final name = ctx.config['system'] as String?;
    return DashaSystem.values.firstWhere((s) => s.name == name,
        orElse: () => DashaSystem.vimshottari);
  }

  int _months(ModuleContext ctx) =>
      int.tryParse(ctx.config['months'] as String? ?? '12') ?? 12;

  bool _fineLevels(ModuleContext ctx) =>
      (ctx.config['fine'] as String? ?? 'hide') == 'show';

  @override
  Widget cardView(BuildContext context, ModuleContext ctx) => _FeedBody(
        ctx: ctx,
        system: _system(ctx),
        months: _months(ctx),
        fineLevels: _fineLevels(ctx),
        cardMode: true,
      );

  @override
  Widget detailView(BuildContext context, ModuleContext ctx) =>
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _FeedBody(
          ctx: ctx,
          system: _system(ctx),
          months: _months(ctx),
          fineLevels: _fineLevels(ctx),
          cardMode: false,
        ),
      );

  @override
  List<pw.Widget> pdfView(ModuleContext ctx) {
    final l10n = ctx.l10n;
    final system = _system(ctx);
    final months = _months(ctx);
    final fine = _fineLevels(ctx);
    final now = DateTime.now().toUtc();
    final to = DateTime.utc(now.year, now.month + months, now.day);

    final dashaEvents =
        dashaChangeEvents(l10n, ctx.dasha(system), now, to, fineLevels: fine);
    final s = ctx.snapshot;
    final transitEvents = scanGochar(
      natalPoints: natalPointsFor(s),
      from: now,
      to: to,
      ayanamsaId: s.ayanamsaId,
    );
    final phases = sadeSatiPhases(
      moonSign: s.moonSign,
      from: s.birth.dateTimeUtc,
      to: s.birth.dateTimeUtc.add(const Duration(days: 36525)),
      ayanamsaId: s.ayanamsaId,
    );
    final sadeSatiEvents = sadeSatiFeedEvents(l10n, phases, now, to);
    final all = [
      ...dashaEvents,
      ...transitFeedEvents(l10n, transitEvents),
      ...sadeSatiEvents,
    ]..sort((a, b) => a.time.compareTo(b.time));

    return pdfSection(
      header: pdfSectionHeader(l10n.uePdfHeader('$months')),
      rest: [
        pdfDataTable(
          headers: [l10n.ueColDate, l10n.ueColSource, l10n.ueColEvent],
          columnWidths: const {
            0: pw.FlexColumnWidth(1.1),
            1: pw.FlexColumnWidth(0.8),
            2: pw.FlexColumnWidth(2.4),
          },
          rows: [
            for (final e in all)
              [
                _dateTimeFmt.format(e.time.toLocal()),
                e.sourceLabel(l10n),
                e.label,
              ],
          ],
        ),
        pdfSectionGap(),
      ],
    );
  }
}

class _FeedBody extends ConsumerStatefulWidget {
  const _FeedBody({
    required this.ctx,
    required this.system,
    required this.months,
    required this.fineLevels,
    required this.cardMode,
  });

  final ModuleContext ctx;
  final DashaSystem system;
  final int months;
  final bool fineLevels;
  final bool cardMode;

  @override
  ConsumerState<_FeedBody> createState() => _FeedBodyState();
}

class _FeedBodyState extends ConsumerState<_FeedBody> {
  Set<FeedSource> _sourceFilter = {};
  Set<Planet> _planetFilter = {};

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final ctx = widget.ctx;
    final gocharAsync =
        ref.watch(gocharEventsProvider((ctx.kundli.id, widget.months)));
    final sadeSatiAsync = ref.watch(sadeSatiPhasesProvider(ctx.kundli.id));

    if (gocharAsync.isLoading || sadeSatiAsync.isLoading) {
      return const SizedBox(
          height: 60, child: Center(child: CircularProgressIndicator()));
    }
    if (gocharAsync.hasError) {
      return Text(l10n.ueScanTransitError('${gocharAsync.error}'));
    }
    if (sadeSatiAsync.hasError) {
      return Text(l10n.ueScanSadeSatiError('${sadeSatiAsync.error}'));
    }

    final now = DateTime.now().toUtc();
    final to = DateTime.utc(now.year, now.month + widget.months, now.day);
    final dashaEvents = dashaChangeEvents(
        l10n, ctx.dasha(widget.system), now, to,
        fineLevels: widget.fineLevels);
    final sadeSatiEvents =
        sadeSatiFeedEvents(l10n, sadeSatiAsync.value!, now, to);
    final transitEvents = transitFeedEvents(l10n, gocharAsync.value!);
    var all = [...dashaEvents, ...transitEvents, ...sadeSatiEvents]
      ..sort((a, b) => a.time.compareTo(b.time));

    if (widget.cardMode) {
      final next = all.take(4).toList();
      if (next.isEmpty) return Text(l10n.ueNoEventsWindow);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (final e in next) _eventRow(e, dateOnly: true)],
      );
    }

    if (_sourceFilter.isNotEmpty) {
      all = all.where((e) => _sourceFilter.contains(e.source)).toList();
    }
    if (_planetFilter.isNotEmpty) {
      all = all
          .where((e) => e.planet != null && _planetFilter.contains(e.planet))
          .toList();
    }

    // Group by calendar month (local time), with a "Today" divider
    // inserted at the top of whichever month group contains `now` —
    // every event in this feed is >= now (the window starts there),
    // so this marks how far into that first month the feed begins.
    final byMonth = <String, List<FeedEvent>>{};
    for (final e in all) {
      final key = _monthFmt.format(e.time.toLocal());
      (byMonth[key] ??= []).add(e);
    }
    final todayKey = _monthFmt.format(now.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final src in FeedSource.values)
              FilterChip(
                label: Text(switch (src) {
                  FeedSource.dasha => l10n.ueSourceDasha,
                  FeedSource.transit => l10n.ueFilterTransits,
                  FeedSource.sadeSati => l10n.ueSourceSadeSati,
                }),
                selected: _sourceFilter.contains(src),
                onSelected: (sel) => setState(() {
                  _sourceFilter = {..._sourceFilter};
                  sel ? _sourceFilter.add(src) : _sourceFilter.remove(src);
                }),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final p in _kFilterPlanets)
              FilterChip(
                label: Text(p.abbrLabel(l10n)),
                selected: _planetFilter.contains(p),
                onSelected: (sel) => setState(() {
                  _planetFilter = {..._planetFilter};
                  sel ? _planetFilter.add(p) : _planetFilter.remove(p);
                }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (all.isEmpty) Text(l10n.ueNoEventsFilter),
        for (final entry in byMonth.entries) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              entry.key.toUpperCase(),
              style: KJType.kicker(),
            ),
          ),
          if (entry.key == todayKey)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(
                      child: Container(
                          height: 1,
                          color: KJColors.maroon.withValues(alpha: 0.4))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                        l10n.ueTodayDivider(_dateFmt.format(now.toLocal())),
                        style: TextStyle(
                            fontSize: 10,
                            color: KJColors.maroon,
                            fontWeight: FontWeight.w600)),
                  ),
                  Expanded(
                      child: Container(
                          height: 1,
                          color: KJColors.maroon.withValues(alpha: 0.4))),
                ],
              ),
            ),
          for (final e in entry.value) _eventRow(e, dateOnly: false),
        ],
      ],
    );
  }

  /// Colours the leading graha name when the label starts with it —
  /// compared against the LOCALIZED name (feed and transit lines are
  /// both localized now).
  ///
  /// Date and time stack on two lines: a single-line "date, h:mm AM"
  /// either wrapped the meridiem onto its own orphan line or crowded
  /// the event text, depending on the date-format preference's width.
  Widget _eventRow(FeedEvent e, {required bool dateOnly}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 86,
              child: dateOnly
                  ? Text(
                      _dateFmt.format(e.time.toLocal()),
                      style: KJTheme.mono(size: 11, color: KJColors.inkSoft),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _dateFmt.format(e.time.toLocal()),
                          style:
                              KJTheme.mono(size: 11, color: KJColors.inkSoft),
                        ),
                        Text(
                          _timeFmt.format(e.time.toLocal()),
                          style:
                              KJTheme.mono(size: 10.5, color: KJColors.inkSoft),
                        ),
                      ],
                    ),
            ),
            Expanded(
              child: e.planet != null &&
                      e.label.startsWith(e.planet!.label(context.l10n))
                  ? Text.rich(
                      TextSpan(
                        style: const TextStyle(fontSize: 13),
                        children: [
                          TextSpan(
                            text: e.planet!.label(context.l10n),
                            style: TextStyle(
                                color: planetInk(e.planet!),
                                fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                              text: e.label.substring(
                                  e.planet!.label(context.l10n).length)),
                        ],
                      ),
                    )
                  : Text(e.label, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
      );
}

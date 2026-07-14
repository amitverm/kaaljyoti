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
import 'package:pdf/widgets.dart' as pw;

import '../core/astro/dasha/dasha.dart';
import '../core/astro/models.dart';
import '../core/astro/transit_scan.dart';
import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../core/theme/type_scale.dart';
import '../state/providers.dart';
import '../widgetsystem/astro_module.dart';
import 'common.dart';

enum FeedSource { dasha, transit, sadeSati }

class FeedEvent {
  const FeedEvent({
    required this.time,
    required this.label,
    required this.source,
    this.planet,
  });

  final DateTime time;
  final String label;
  final FeedSource source;
  final Planet? planet; // colors + filters the label, where known

  String get sourceLabel => switch (source) {
        FeedSource.dasha => 'Dasha',
        FeedSource.transit => 'Transit',
        FeedSource.sadeSati => 'Sade Sati',
      };
}

const _levelTag = {1: 'MD', 2: 'AD', 3: 'PD', 4: 'SD', 5: 'PrD'};

/// The 5 planets worth a dedicated filter chip — the same "watch"
/// list the old Gochar module used (Rahu/Ketu/Saturn/Jupiter/Mars are
/// the slow movers whose ingresses and natal hits matter most for
/// consultation prep).
const _kFilterPlanets = [
  Planet.saturn, Planet.jupiter, Planet.rahu, Planet.ketu, Planet.mars,
];

/// Walks the WHOLE dasha tree (not just the currently-active chain),
/// recursing only into branches that overlap [now, to], and emits an
/// event for every period at level <= [maxLevel] whose `end` falls
/// inside the window — this is the fix for the original bug, which
/// only ever looked at `chainAt(now)` (one period per level: whatever
/// is active RIGHT now) and so silently dropped every subsequent
/// change within a longer window (e.g. a 24-month window spanning two
/// antardasha changes only ever showed the first).
void _walkDashaLevel(
  List<DashaPeriod> siblings,
  DateTime now,
  DateTime to,
  int maxLevel,
  List<FeedEvent> out,
) {
  for (var i = 0; i < siblings.length; i++) {
    final p = siblings[i];
    final overlapsWindow = p.start.isBefore(to) && p.end.isAfter(now);
    if (!overlapsWindow) continue;
    if (p.level <= maxLevel && p.end.isAfter(now) && !p.end.isAfter(to)) {
      final next = i + 1 < siblings.length ? siblings[i + 1] : null;
      final tag = _levelTag[p.level] ?? p.levelName;
      out.add(FeedEvent(
        time: p.end,
        label: next == null
            ? '$tag ${p.lordLabel} ends'
            : '$tag ${p.lordLabel} ends → ${next.lordLabel} begins',
        source: FeedSource.dasha,
        planet: p.planet,
      ));
    }
    if (p.level < maxLevel) {
      _walkDashaLevel(p.children, now, to, maxLevel, out);
    }
  }
}

List<FeedEvent> _dashaChangeEvents(
  ModuleContext ctx,
  DashaSystem system,
  DateTime now,
  DateTime to, {
  required bool fineLevels,
}) {
  final result = ctx.dasha(system);
  final maxLevel = fineLevels ? 5 : 3;
  final out = <FeedEvent>[];
  _walkDashaLevel(result.periods, now, to, maxLevel, out);
  return out;
}

/// Sade Sati phase starts/ends clipped to [now, to] (the full-lifetime
/// series is shared via [sadeSatiPhasesProvider] — this just filters).
List<FeedEvent> _sadeSatiFeedEvents(
    List<SadeSatiPhase> phases, DateTime now, DateTime to) {
  final out = <FeedEvent>[];
  bool within(DateTime t) => !t.isBefore(now) && !t.isAfter(to);
  for (final ph in phases) {
    if (within(ph.start)) {
      out.add(FeedEvent(
          time: ph.start,
          label: 'Sade Sati ${ph.label} begins',
          source: FeedSource.sadeSati));
    }
    if (within(ph.end)) {
      out.add(FeedEvent(
          time: ph.end,
          label: 'Sade Sati ${ph.label} ends',
          source: FeedSource.sadeSati));
    }
  }
  return out;
}

// Full-date formatters follow the user's app-wide date-format choice; the
// month-only formatter stays fixed.
DateFormat get _dateTimeFmt =>
    DateFormat('${TEDate.pref.datePattern}, h:mm a');
DateFormat get _dateFmt => DateFormat(TEDate.pref.datePattern);
final _monthFmt = DateFormat('MMMM yyyy');

class UpcomingEventsModule extends AstroModule {
  const UpcomingEventsModule();

  @override
  ModuleMeta get meta => const ModuleMeta(
        id: 'upcoming_events',
        title: 'Upcoming Events',
        icon: Icons.event_note_outlined,
        category: 'Timing & Dashas',
      );

  @override
  List<ModuleConfigChoice> configChoices() => [
        ModuleConfigChoice(
          key: 'system',
          label: 'Dasha system',
          options: [
            for (final s in DashaSystem.values) (s.name, s.displayName),
          ],
        ),
        const ModuleConfigChoice(
          key: 'months',
          label: 'Window',
          options: [
            ('3', '3 months'),
            ('6', '6 months'),
            ('12', '12 months'),
            ('24', '24 months'),
          ],
          defaultValue: '12',
        ),
        const ModuleConfigChoice(
          key: 'fine',
          label: 'Fine levels (Sookshma/Pran)',
          options: [('hide', 'Hide'), ('show', 'Show')],
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
    final system = _system(ctx);
    final months = _months(ctx);
    final fine = _fineLevels(ctx);
    final now = DateTime.now().toUtc();
    final to = DateTime.utc(now.year, now.month + months, now.day);

    final dashaEvents =
        _dashaChangeEvents(ctx, system, now, to, fineLevels: fine);
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
    final sadeSatiEvents = _sadeSatiFeedEvents(phases, now, to);
    final all = [
      ...dashaEvents,
      for (final e in transitEvents)
        FeedEvent(
            time: e.time, label: e.label, source: FeedSource.transit, planet: e.planet),
      ...sadeSatiEvents,
    ]..sort((a, b) => a.time.compareTo(b.time));

    return [
      pdfSectionHeader('Upcoming Events — next $months months'),
      pw.TableHelper.fromTextArray(
        headers: const ['Date', 'Source', 'Event'],
        data: [
          for (final e in all)
            [_dateTimeFmt.format(e.time.toLocal()), e.sourceLabel, e.label],
        ],
        headerStyle: pw.TextStyle(
            fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: pdfInkSoft),
        cellStyle: pdfBody(size: 9.5),
        border: null,
        headerDecoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: pdfInk, width: 0.8)),
        ),
        rowDecoration: const pw.BoxDecoration(
          border:
              pw.Border(bottom: pw.BorderSide(color: pdfHairline, width: 0.5)),
        ),
        cellAlignment: pw.Alignment.centerLeft,
        headerAlignment: pw.Alignment.centerLeft,
      ),
    ];
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
    final ctx = widget.ctx;
    final gocharAsync =
        ref.watch(gocharEventsProvider((ctx.kundli.id, widget.months)));
    final sadeSatiAsync = ref.watch(sadeSatiPhasesProvider(ctx.kundli.id));

    if (gocharAsync.isLoading || sadeSatiAsync.isLoading) {
      return const SizedBox(
          height: 60, child: Center(child: CircularProgressIndicator()));
    }
    if (gocharAsync.hasError) {
      return Text('Could not scan transits: ${gocharAsync.error}');
    }
    if (sadeSatiAsync.hasError) {
      return Text('Could not scan Sade Sati: ${sadeSatiAsync.error}');
    }

    final now = DateTime.now().toUtc();
    final to = DateTime.utc(now.year, now.month + widget.months, now.day);
    final dashaEvents = _dashaChangeEvents(ctx, widget.system, now, to,
        fineLevels: widget.fineLevels);
    final sadeSatiEvents =
        _sadeSatiFeedEvents(sadeSatiAsync.value!, now, to);
    final transitEvents = [
      for (final e in gocharAsync.value!)
        FeedEvent(
            time: e.time, label: e.label, source: FeedSource.transit, planet: e.planet),
    ];
    var all = [...dashaEvents, ...transitEvents, ...sadeSatiEvents]
      ..sort((a, b) => a.time.compareTo(b.time));

    if (widget.cardMode) {
      final next = all.take(4).toList();
      if (next.isEmpty) return const Text('No events in the coming window.');
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
                  FeedSource.dasha => 'Dasha',
                  FeedSource.transit => 'Transits',
                  FeedSource.sadeSati => 'Sade Sati',
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
                label: Text(p.abbr),
                selected: _planetFilter.contains(p),
                onSelected: (sel) => setState(() {
                  _planetFilter = {..._planetFilter};
                  sel ? _planetFilter.add(p) : _planetFilter.remove(p);
                }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (all.isEmpty) const Text('No events match this filter.'),
        for (final entry in byMonth.entries) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              entry.key.toUpperCase(),
              style: TEType.kicker(),
            ),
          ),
          if (entry.key == todayKey)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(child: Container(height: 1, color: TEColors.maroon.withValues(alpha: 0.4))),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('TODAY · ${_dateFmt.format(now.toLocal())}',
                        style: TextStyle(
                            fontSize: 10, color: TEColors.maroon,
                            fontWeight: FontWeight.w600)),
                  ),
                  Expanded(child: Container(height: 1, color: TEColors.maroon.withValues(alpha: 0.4))),
                ],
              ),
            ),
          for (final e in entry.value) _eventRow(e, dateOnly: false),
        ],
      ],
    );
  }

  Widget _eventRow(FeedEvent e, {required bool dateOnly}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: dateOnly ? 78 : 130,
              child: Text(
                (dateOnly ? _dateFmt : _dateTimeFmt).format(e.time.toLocal()),
                style: TETheme.mono(size: 11, color: TEColors.inkSoft),
              ),
            ),
            Expanded(
              child: e.planet != null && e.label.startsWith(e.planet!.displayName)
                  ? Text.rich(
                      TextSpan(
                        style: const TextStyle(fontSize: 13),
                        children: [
                          TextSpan(
                            text: e.planet!.displayName,
                            style: TextStyle(
                                color: planetInk(e.planet!),
                                fontWeight: FontWeight.w600),
                          ),
                          TextSpan(
                              text: e.label.substring(e.planet!.displayName.length)),
                        ],
                      ),
                    )
                  : Text(e.label, style: const TextStyle(fontSize: 13)),
            ),
          ],
        ),
      );
}

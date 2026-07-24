/// Compare subjects — the source abstraction over the two kinds of chart
/// a comparison can mix (spec §4.4): a local [Kundli] and a Mahakosh
/// [AnonymizedChart]. Each subject produces the engine's [CompareEntry]
/// (a positions-only [CompareChart], an optional full [AstroSnapshot],
/// and unified [CompareEvent]s), so lib/core/astro/compare.dart never has
/// to know where a chart came from.
///
/// Capabilities drive graceful degradation, not exclusion: a legacy
/// Mahakosh chart (no birth instant) still contributes placement and
/// transit findings from its stored longitudes; only dasha-based rules
/// are skipped.
library;

import '../core/astro/compare.dart';
import '../core/astro/models.dart';
import '../data/models.dart';
import 'models.dart';

/// What a subject can contribute to the comparison (spec §4.4 table).
class CompareCapabilities {
  const CompareCapabilities({
    required this.placements,
    required this.dashaToday,
    required this.eventDasha,
    required this.eventTransits,
  });

  /// Placement rules §4.2 (1–6): sign/house/dignity from longitudes +
  /// ascendant. Always available once we have positions.
  final bool placements;

  /// Rule §4.2.7 — current mahadasha today. Needs a full snapshot.
  final bool dashaToday;

  /// Event MD/AD lords (§4.3.1–2). Needs a birth instant.
  final bool eventDasha;

  /// Event transits (§4.3) — needs only the event date + natal
  /// reference longitudes, so it works for legacy charts too.
  final bool eventTransits;

  static const full = CompareCapabilities(
    placements: true,
    dashaToday: true,
    eventDasha: true,
    eventTransits: true,
  );

  static const positionsOnly = CompareCapabilities(
    placements: true,
    dashaToday: false,
    eventDasha: false,
    eventTransits: true,
  );
}

/// A chart selected for comparison. Mix freely from local and Mahakosh
/// sources (spec §2).
sealed class CompareSubject {
  const CompareSubject();

  /// Stable id used in [CompareFinding.subjectIds].
  String get id;

  /// Kundli name or MK code.
  String get displayName;

  /// Full snapshot when computable; null for legacy Mahakosh charts.
  AstroSnapshot? get snapshot;

  /// Positions-only view — always available.
  CompareChart get chart;

  /// Unified life events.
  List<CompareEvent> get events;

  CompareCapabilities get caps;

  /// Birth year, to anchor age-only events. Null when unknown.
  int? get birthYear;

  /// The engine input for this subject.
  CompareEntry toEntry() => CompareEntry(
        id: id,
        displayName: displayName,
        chart: chart,
        events: events,
        snapshot: snapshot,
        birthYear: birthYear,
      );
}

/// A local kundli. Its snapshot is built by the caller (Stage-2 providers
/// pre-warm it) and its events are injected — the engine layer does no
/// I/O.
class LocalSubject extends CompareSubject {
  const LocalSubject({
    required this.kundli,
    required AstroSnapshot snapshot,
    List<KundliEvent> kundliEvents = const [],
  })  : _snapshot = snapshot,
        _events = kundliEvents;

  final Kundli kundli;
  final AstroSnapshot _snapshot;
  final List<KundliEvent> _events;

  @override
  String get id => kundli.id;

  @override
  String get displayName => kundli.name;

  @override
  AstroSnapshot get snapshot => _snapshot;

  @override
  CompareChart get chart => _chartFromSnapshot(_snapshot);

  @override
  List<CompareEvent> get events => [
        for (final e in _events)
          CompareEvent(
            category: e.category,
            customTag: e.customTag,
            date: e.eventDate,
            precision: e.datePrecision.name,
            ageYears: e.ageYears,
            isHealth: e.isHealthRelated,
          ),
      ];

  @override
  CompareCapabilities get caps => CompareCapabilities.full;

  @override
  int? get birthYear => kundli.birthUtc.year;
}

/// A Mahakosh community chart. When it carries full birth data the caller
/// supplies a rebuilt [snapshot] (via the existing SnapshotBuilder,
/// pinned to the chart's own ayanamsa); legacy charts pass null and the
/// engine runs on stored longitudes alone.
class MahakoshSubject extends CompareSubject {
  const MahakoshSubject({
    required this.mkChart,
    AstroSnapshot? snapshot,
  }) : _snapshot = snapshot;

  final AnonymizedChart mkChart;
  final AstroSnapshot? _snapshot;

  @override
  String get id => 'mk:${mkChart.mkCode}';

  @override
  String get displayName => mkChart.mkCode;

  @override
  AstroSnapshot? get snapshot => _snapshot;

  @override
  CompareChart get chart {
    final snap = _snapshot;
    if (snap != null) return _chartFromSnapshot(snap);
    // Legacy: positions-only, from stored longitudes + ascendant. No
    // stored speeds → retrograde (rule 6) is unavailable, not wrong.
    return CompareChart(
      ascendant: mkChart.ascendant,
      longitudes: {
        for (final p in Planet.values)
          if (mkChart.longitudes[p.name] case final lon?) p: lon,
      },
    );
  }

  @override
  List<CompareEvent> get events => [
        for (final e in mkChart.events) _eventFromRecord(e),
      ];

  @override
  CompareCapabilities get caps => mkChart.hasBirthData
      ? CompareCapabilities.full
      : CompareCapabilities.positionsOnly;

  @override
  int? get birthYear => mkChart.birthYear;
}

/// Build a [CompareChart] from a full snapshot (carries speeds, so
/// retrograde is known).
CompareChart _chartFromSnapshot(AstroSnapshot s) => CompareChart(
      ascendant: s.ascendant,
      longitudes: {
        for (final e in s.positions.entries) e.key: e.value.longitude,
      },
      speeds: {
        for (final e in s.positions.entries) e.key: e.value.speed,
      },
    );

/// Adapt an [AnonymizedChart] event record to a [CompareEvent].
///
/// Mahakosh events store a free-text [tag] (the contribute flow writes
/// the event's title, or the category label when untitled — see
/// lifeEventsFromStored / contribute_screen.dart), NOT the enum code. So
/// we resolve it to a category by code first, then by label, and fall
/// back to 'other' carrying the original tag as the custom label.
CompareEvent _eventFromRecord(
  ({String tag, String? date, String precision, int? ageYears, bool isHealth})
      e,
) {
  final (category, customTag) = _resolveTag(e.tag);
  return CompareEvent(
    category: category,
    customTag: customTag,
    date: e.date == null ? null : DateTime.tryParse(e.date!),
    precision: e.precision,
    ageYears: e.ageYears,
    isHealth: e.isHealth,
  );
}

/// (category code, customTag) for a Mahakosh event tag. Known categories
/// resolve to their code with no custom tag; anything else becomes
/// 'other' carrying the tag.
(String, String?) _resolveTag(String tag) {
  final trimmed = tag.trim();
  // Exact enum-code match ('marriage', …).
  final byCode = EventCategory.byCode(trimmed.toLowerCase());
  if (byCode != EventCategory.other ||
      trimmed.toLowerCase() == EventCategory.other.name) {
    return (byCode.name, null);
  }
  // Category label match ('Marriage', 'Childbirth', …), case-insensitive.
  for (final c in EventCategory.values) {
    if (c.label.toLowerCase() == trimmed.toLowerCase()) {
      return (c.name, null);
    }
  }
  // Free-text title → the 'other' bucket, keeping the tag for display
  // and to keep unrelated custom events from correlating.
  return (EventCategory.other.name, trimmed.isEmpty ? null : trimmed);
}

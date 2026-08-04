/// Local persistence models.
library;

import 'dart:convert';

import '../core/astro/models.dart';

class Kundli {
  const Kundli({
    required this.id,
    required this.name,
    required this.relationTag, // 'Self', 'Spouse', 'Client', …
    this.note, // free-text label to remember who this person is
    this.labels = const [], // user-defined groupings, multi-valued
    required this.birthUtc,
    required this.latitude,
    required this.longitude,
    required this.timezoneName,
    required this.utcOffsetMinutes,
    required this.placeName,
    this.ayanamsaOverrideId, // null → app default
    this.chartStyle = 'north',
    this.isPrashna = false,
    this.isEphemeral = false, // instant Prashna, not yet kept
    this.isArchived = false, // out of the main list, never out of reach
    this.syncEnabled = false,
    this.mahakoshCode, // e.g. 'MK-4831' when shared
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String relationTag;
  final String? note;

  /// Free-form user groupings ("2026 clients", "matchmaking"). Unlike
  /// [relationTag] — single-valued and drawn from a closed list — a
  /// kundli carries as many labels as the astrologer wants, which is
  /// what makes this the folder replacement: a chart can be a client
  /// AND family, something no folder can express.
  final List<String> labels;
  final DateTime birthUtc;
  final double latitude;
  final double longitude;
  final String timezoneName;
  final int utcOffsetMinutes;
  final String placeName;
  final int? ayanamsaOverrideId;
  final String chartStyle;
  final bool isPrashna;
  final bool isEphemeral;

  /// Archived: the chart leaves the main list (and the filter chips) but
  /// stays complete, openable and restorable from the list's own
  /// "Archived" section. NOT a soft delete — nothing is hidden from the
  /// chart itself, only from the roll call.
  ///
  /// Rides cross-device inside the sync payload ([toRow]), and archiving
  /// goes through `KundliRepository.update`, which bumps `updated_at` —
  /// so last-writer-wins carries the flag like any other edit. One
  /// accepted mixed-version edge: a device on an older build editing the
  /// same chart re-pushes a payload with no `is_archived` key at all, and
  /// a newer device pulling that payload reads it as unarchived. Same
  /// class of tradeoff as the journal's LWW — the loss is a flag the user
  /// can flip back, never a chart.
  final bool isArchived;
  final bool syncEnabled;
  final String? mahakoshCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isSharedToMahakosh => mahakoshCode != null;

  BirthData toBirthData() => BirthData(
        dateTimeUtc: birthUtc,
        latitude: latitude,
        longitude: longitude,
        timezoneName: timezoneName,
        utcOffsetMinutes: utcOffsetMinutes,
        placeName: placeName,
      );

  Kundli copyWith({
    String? name,
    String? relationTag,
    String? note,
    bool clearNote = false,
    List<String>? labels,
    DateTime? birthUtc,
    double? latitude,
    double? longitude,
    String? timezoneName,
    int? utcOffsetMinutes,
    String? placeName,
    int? ayanamsaOverrideId,
    bool clearAyanamsaOverride = false,
    String? chartStyle,
    bool? isEphemeral,
    bool? isArchived,
    bool? syncEnabled,
    String? mahakoshCode,
    bool clearMahakoshCode = false,
    DateTime? updatedAt,
  }) =>
      Kundli(
        id: id,
        name: name ?? this.name,
        relationTag: relationTag ?? this.relationTag,
        note: clearNote ? null : (note ?? this.note),
        labels: labels ?? this.labels,
        birthUtc: birthUtc ?? this.birthUtc,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        timezoneName: timezoneName ?? this.timezoneName,
        utcOffsetMinutes: utcOffsetMinutes ?? this.utcOffsetMinutes,
        placeName: placeName ?? this.placeName,
        ayanamsaOverrideId: clearAyanamsaOverride
            ? null
            : (ayanamsaOverrideId ?? this.ayanamsaOverrideId),
        chartStyle: chartStyle ?? this.chartStyle,
        isPrashna: isPrashna,
        isEphemeral: isEphemeral ?? this.isEphemeral,
        isArchived: isArchived ?? this.isArchived,
        syncEnabled: syncEnabled ?? this.syncEnabled,
        mahakoshCode:
            clearMahakoshCode ? null : (mahakoshCode ?? this.mahakoshCode),
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now().toUtc(),
      );

  Map<String, Object?> toRow() => {
        'id': id,
        'name': name,
        'relation_tag': relationTag,
        'note': note,
        // JSON rather than a join table: the sync payload IS the row
        // (sync_service pushes toRow()), so labels ride cross-device for
        // free. Label queries are done in Dart over a few hundred rows.
        'labels': labels.isEmpty ? null : jsonEncode(labels),
        'birth_utc': birthUtc.millisecondsSinceEpoch,
        'lat': latitude,
        'lon': longitude,
        'tz_name': timezoneName,
        'utc_offset_min': utcOffsetMinutes,
        'place_name': placeName,
        'ayanamsa_id': ayanamsaOverrideId,
        'chart_style': chartStyle,
        'is_prashna': isPrashna ? 1 : 0,
        'is_ephemeral': isEphemeral ? 1 : 0,
        'is_archived': isArchived ? 1 : 0,
        'sync_enabled': syncEnabled ? 1 : 0,
        'mahakosh_code': mahakoshCode,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  static Kundli fromRow(Map<String, Object?> r) => Kundli(
        id: r['id'] as String,
        name: r['name'] as String,
        relationTag: r['relation_tag'] as String,
        note: r['note'] as String?,
        labels: _decodeLabels(r['labels'] as String?),
        birthUtc: DateTime.fromMillisecondsSinceEpoch(r['birth_utc'] as int,
            isUtc: true),
        latitude: r['lat'] as double,
        longitude: r['lon'] as double,
        timezoneName: r['tz_name'] as String,
        utcOffsetMinutes: r['utc_offset_min'] as int,
        placeName: r['place_name'] as String,
        ayanamsaOverrideId: r['ayanamsa_id'] as int?,
        chartStyle: (r['chart_style'] as String?) ?? 'north',
        isPrashna: (r['is_prashna'] as int) == 1,
        isEphemeral: ((r['is_ephemeral'] as int?) ?? 0) == 1,
        // Absent key → false, not a crash: a sync payload written by a
        // build that predates archiving carries no `is_archived` at all.
        isArchived: ((r['is_archived'] as int?) ?? 0) == 1,
        syncEnabled: (r['sync_enabled'] as int) == 1,
        mahakoshCode: r['mahakosh_code'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int,
            isUtc: true),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(r['updated_at'] as int,
            isUtc: true),
      );

  /// Tolerant of anything that isn't a clean list of strings — a row
  /// written by a future version (or a corrupted sync payload) costs the
  /// user their labels, never their kundli.
  static List<String> _decodeLabels(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final e in decoded)
          if (e is String && e.trim().isNotEmpty) e.trim(),
      ];
    } on FormatException {
      return const [];
    }
  }
}

/// Curated life-event categories. Free-text tagging is layered on top via
/// [KundliEvent.customTag], so this list stays small and correlation-friendly
/// while still allowing anything the astrologer wants to record.
enum EventCategory {
  marriage,
  childbirth,
  relationship,
  career,
  education,
  health,
  relocation,
  bereavement,
  accident,
  financial,
  spiritual,
  other;

  String get label => switch (this) {
        marriage => 'Marriage',
        childbirth => 'Childbirth',
        relationship => 'Relationship',
        career => 'Career',
        education => 'Education',
        health => 'Health',
        relocation => 'Relocation',
        bereavement => 'Bereavement',
        accident => 'Accident',
        financial => 'Financial',
        spiritual => 'Spiritual',
        other => 'Other',
      };

  static EventCategory byCode(String? c) => EventCategory.values
      .firstWhere((e) => e.name == c, orElse: () => EventCategory.other);
}

/// How precisely a life-event date is known. Natives often recall only a
/// year or an age, so we store the precision alongside the value rather than
/// forcing a false exact day.
enum EventDatePrecision {
  exact,
  month,
  year,
  age;

  static EventDatePrecision byName(String? n) => EventDatePrecision.values
      .firstWhere((e) => e.name == n, orElse: () => EventDatePrecision.exact);
}

/// A recorded biographical event on a kundli (marriage, childbirth, …).
/// First-class per-kundli data — NOT a dashboard widget, since the dashboard
/// is a global lens shared by every chart. Used for the astrologer's own
/// reference, prediction verification, and (with consent) Mahakosh sharing.
class KundliEvent {
  const KundliEvent({
    required this.id,
    required this.kundliId,
    this.category = 'other',
    this.customTag, // free-text label, overrides the category label when set
    this.title,
    this.description,
    this.eventDate, // canonical local-midnight date; null when age-only
    this.datePrecision = EventDatePrecision.exact,
    this.ageYears, // set when datePrecision == age
    this.isHealthRelated = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String kundliId;
  final String category;
  final String? customTag;
  final String? title;
  final String? description;
  final DateTime? eventDate;
  final EventDatePrecision datePrecision;
  final int? ageYears;
  final bool isHealthRelated;
  final DateTime createdAt;
  final DateTime updatedAt;

  EventCategory get categoryEnum => EventCategory.byCode(category);

  /// Display label: the custom tag if present, else the category name.
  String get label => (customTag != null && customTag!.trim().isNotEmpty)
      ? customTag!.trim()
      : categoryEnum.label;

  /// A date usable for chronological sorting. Age-only events are anchored
  /// to (birth year + age) using the kundli's [birthYear].
  DateTime? sortDate(int? birthYear) {
    if (eventDate != null) return eventDate;
    if (datePrecision == EventDatePrecision.age &&
        ageYears != null &&
        birthYear != null) {
      return DateTime(birthYear + ageYears!);
    }
    return null;
  }

  KundliEvent copyWith({
    String? category,
    String? customTag,
    bool clearCustomTag = false,
    String? title,
    bool clearTitle = false,
    String? description,
    bool clearDescription = false,
    DateTime? eventDate,
    bool clearEventDate = false,
    EventDatePrecision? datePrecision,
    int? ageYears,
    bool clearAgeYears = false,
    bool? isHealthRelated,
    DateTime? updatedAt,
  }) =>
      KundliEvent(
        id: id,
        kundliId: kundliId,
        category: category ?? this.category,
        customTag: clearCustomTag ? null : (customTag ?? this.customTag),
        title: clearTitle ? null : (title ?? this.title),
        description:
            clearDescription ? null : (description ?? this.description),
        eventDate: clearEventDate ? null : (eventDate ?? this.eventDate),
        datePrecision: datePrecision ?? this.datePrecision,
        ageYears: clearAgeYears ? null : (ageYears ?? this.ageYears),
        isHealthRelated: isHealthRelated ?? this.isHealthRelated,
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now().toUtc(),
      );

  Map<String, Object?> toRow() => {
        'id': id,
        'kundli_id': kundliId,
        'category': category,
        'custom_tag': customTag,
        'title': title,
        'description': description,
        'event_date': eventDate?.millisecondsSinceEpoch,
        'date_precision': datePrecision.name,
        'age_years': ageYears,
        'is_health_related': isHealthRelated ? 1 : 0,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  static KundliEvent fromRow(Map<String, Object?> r) => KundliEvent(
        id: r['id'] as String,
        kundliId: r['kundli_id'] as String,
        category: (r['category'] as String?) ?? 'other',
        customTag: r['custom_tag'] as String?,
        title: r['title'] as String?,
        description: r['description'] as String?,
        eventDate: r['event_date'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(r['event_date'] as int),
        datePrecision:
            EventDatePrecision.byName(r['date_precision'] as String?),
        ageYears: r['age_years'] as int?,
        isHealthRelated: ((r['is_health_related'] as int?) ?? 0) == 1,
        createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at'] as int,
            isUtc: true),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(r['updated_at'] as int,
            isUtc: true),
      );
}

/// One dated journal entry on a kundli — the practitioner's own running
/// record (consultation notes, event correlations, research remarks).
///
/// Distinct from [KundliEvent]: an event is a fact about the native's life
/// on a curated timeline; a journal entry is the astrologer's free-text
/// observation, stamped with the astro context of the date it refers to
/// ([contextJson], written once at save time). That frozen context is what
/// makes an old entry re-readable years later without recomputing — and
/// keeping it as opaque JSON here means [JournalEntry] stays a plain data
/// model with no dependency on the astro layer.
class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.kundliId,
    required this.at, // the date the entry is ABOUT (backdating allowed)
    required this.text,
    this.contextJson, // encoded JournalContext; null when capture failed
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String kundliId;
  final DateTime at;
  final String text;
  final String? contextJson;
  final DateTime createdAt;
  final DateTime updatedAt;

  JournalEntry copyWith({
    DateTime? at,
    String? text,
    String? contextJson,
    bool clearContextJson = false,
    DateTime? updatedAt,
  }) =>
      JournalEntry(
        id: id,
        kundliId: kundliId,
        at: at ?? this.at,
        text: text ?? this.text,
        contextJson:
            clearContextJson ? null : (contextJson ?? this.contextJson),
        createdAt: createdAt,
        updatedAt: updatedAt ?? DateTime.now().toUtc(),
      );

  Map<String, Object?> toRow() => {
        'id': id,
        'kundli_id': kundliId,
        'at': at.millisecondsSinceEpoch,
        'text': text,
        'context_json': contextJson,
        'created_at': createdAt.millisecondsSinceEpoch,
        'updated_at': updatedAt.millisecondsSinceEpoch,
      };

  static JournalEntry fromRow(Map<String, Object?> r) => JournalEntry(
        id: r['id'] as String,
        kundliId: r['kundli_id'] as String,
        at: DateTime.fromMillisecondsSinceEpoch((r['at'] as int?) ?? 0),
        text: (r['text'] as String?) ?? '',
        contextJson: r['context_json'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
            (r['created_at'] as int?) ?? 0,
            isUtc: true),
        updatedAt: DateTime.fromMillisecondsSinceEpoch(
            (r['updated_at'] as int?) ?? 0,
            isUtc: true),
      );
}

/// A named GLOBAL dashboard layout ("Overview", "Today", …). Layouts
/// are lenses applied to whichever kundli is open — arrange once,
/// applies to every chart (the professional's 50 clients share one
/// set of views).
class DashboardView {
  const DashboardView({
    required this.id,
    required this.name,
    required this.position,
  });

  final String id;
  final String name;
  final int position;

  Map<String, Object?> toRow() => {
        'id': id,
        'name': name,
        'position': position,
      };

  static DashboardView fromRow(Map<String, Object?> r) => DashboardView(
        id: r['id'] as String,
        name: r['name'] as String,
        position: r['position'] as int,
      );
}

/// How wide a widget instance renders in the dashboard grid.
/// full = all columns; half = 1/2; third = 1/3 (on ≥3-column layouts
/// a 'third' takes one of three columns; on phones it renders as half).
enum CardSpan {
  full,
  half,
  third;

  static CardSpan byName(String? name) => CardSpan.values
      .firstWhere((s) => s.name == name, orElse: () => CardSpan.half);

  String get label => switch (this) {
        full => 'Full width',
        half => 'Half width',
        third => 'Third (tablet)',
      };
}

/// A widget INSTANCE placed on a dashboard view. Instance-based (not
/// type-based) so the same module can appear multiple times with
/// different configs — e.g. three Divisional Chart widgets showing
/// D3 / D7 / D9, or two Birth Charts in different styles.
class PlacedWidget {
  const PlacedWidget({
    required this.instanceId,
    required this.viewId,
    required this.widgetId,
    required this.position,
    this.span = CardSpan.half,
    this.config = const {},
  });

  final String instanceId;
  final String viewId;
  final String widgetId; // module type id in the registry
  final int position;
  final CardSpan span;
  final Map<String, dynamic> config;

  PlacedWidget copyWith({
    int? position,
    CardSpan? span,
    Map<String, dynamic>? config,
  }) =>
      PlacedWidget(
        instanceId: instanceId,
        viewId: viewId,
        widgetId: widgetId,
        position: position ?? this.position,
        span: span ?? this.span,
        config: config ?? this.config,
      );
}

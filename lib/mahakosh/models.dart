/// Mahakosh (community research repository) client-side models.
library;

import '../data/models.dart';

class MahakoshChartSummary {
  const MahakoshChartSummary({
    required this.mkCode,
    required this.birthYear,
    required this.locationGeneral,
    required this.ayanamsaId,
    required this.createdAt,
    this.yogaCount = 0,
    this.eventCount = 0,
  });

  final String mkCode;
  final int? birthYear;
  final String locationGeneral;
  final int ayanamsaId;
  final DateTime createdAt;
  final int yogaCount;
  final int eventCount;

  static MahakoshChartSummary fromJson(Map<String, dynamic> j) =>
      MahakoshChartSummary(
        mkCode: j['mk_code'] as String,
        birthYear: j['birth_year'] as int?,
        locationGeneral: (j['location_general'] as String?) ?? '',
        ayanamsaId: (j['ayanamsa_id'] as int?) ?? 1,
        createdAt: DateTime.parse(j['created_at'] as String),
        yogaCount: (j['yoga_count'] as int?) ?? 0,
        eventCount: (j['event_count'] as int?) ?? 0,
      );
}

/// A chart the current user has hidden from their own Mahakosh view
/// (§2.7a — App Store Guideline 1.2 content filtering). Distinct from
/// MahakoshChartSummary only in also carrying hiddenAt, for the "Hidden
/// charts" management screen.
class HiddenMahakoshChart {
  const HiddenMahakoshChart({
    required this.mkCode,
    required this.birthYear,
    required this.locationGeneral,
    required this.ayanamsaId,
    required this.createdAt,
    required this.hiddenAt,
  });

  final String mkCode;
  final int? birthYear;
  final String locationGeneral;
  final int ayanamsaId;
  final DateTime createdAt;
  final DateTime hiddenAt;

  static HiddenMahakoshChart fromJson(Map<String, dynamic> j) =>
      HiddenMahakoshChart(
        mkCode: j['mk_code'] as String,
        birthYear: j['birth_year'] as int?,
        locationGeneral: (j['location_general'] as String?) ?? '',
        ayanamsaId: (j['ayanamsa_id'] as int?) ?? 1,
        createdAt: DateTime.parse(j['created_at'] as String),
        hiddenAt: DateTime.parse(j['hidden_at'] as String),
      );
}

/// A full anonymized community chart, reconstructed from the stored
/// chart_payload (raw sidereal longitudes — no name, no exact birth
/// data). Everything displayable is derived client-side.
class AnonymizedChart {
  const AnonymizedChart({
    required this.mkCode,
    required this.birthYear,
    required this.locationGeneral,
    required this.ayanamsaId,
    required this.ascendant,
    required this.longitudes, // Planet.name -> sidereal longitude
    required this.createdAt,
    this.events = const [],
    this.birthUtc,
    this.latitude,
    this.longitude,
    this.timezoneName,
    this.utcOffsetMinutes,
    this.placeName,
  });

  final String mkCode;
  final int? birthYear;
  final String locationGeneral;
  final int ayanamsaId;
  final double ascendant;
  final Map<String, double> longitudes;
  final DateTime createdAt;
  final List<
      ({
        String tag,
        String? date,
        String precision,
        int? ageYears,
        bool isHealth
      })> events;

  /// Full birth details (name withheld) — present on charts shared
  /// after the birth-data change; null on legacy contributions.
  final DateTime? birthUtc;
  final double? latitude;
  final double? longitude;
  final String? timezoneName;
  final int? utcOffsetMinutes;
  final String? placeName;

  bool get hasBirthData => birthUtc != null;

  static AnonymizedChart fromRow(
    Map<String, dynamic> row,
    List<Map<String, dynamic>> eventRows,
  ) {
    final payload = (row['chart_payload'] as Map).cast<String, dynamic>();
    final positions = (payload['positions'] as Map).cast<String, dynamic>();
    return AnonymizedChart(
      mkCode: row['mk_code'] as String,
      birthYear: row['birth_year'] as int?,
      locationGeneral: (row['location_general'] as String?) ?? '',
      ayanamsaId: (payload['ayanamsa_id'] as num?)?.toInt() ??
          (row['ayanamsa_id'] as num?)?.toInt() ??
          1,
      ascendant: (payload['ascendant'] as num).toDouble(),
      longitudes: {
        for (final e in positions.entries)
          e.key: ((e.value as Map)['lon'] as num).toDouble(),
      },
      createdAt: DateTime.parse(row['created_at'] as String),
      events: [
        for (final e in eventRows)
          (
            tag: e['tag'] as String,
            date: e['event_date'] as String?,
            precision: (e['date_precision'] as String?) ?? 'exact',
            ageYears: (e['age_years'] as num?)?.toInt(),
            isHealth: (e['is_health_related'] as bool?) ?? false,
          ),
      ],
      birthUtc: row['birth_utc'] == null
          ? null
          : DateTime.parse(row['birth_utc'] as String).toUtc(),
      latitude: (row['latitude'] as num?)?.toDouble(),
      longitude: (row['longitude'] as num?)?.toDouble(),
      timezoneName: row['timezone_name'] as String?,
      utcOffsetMinutes: (row['utc_offset_min'] as num?)?.toInt(),
      placeName: row['place_name'] as String?,
    );
  }
}

/// A chart report row as seen by an admin working the moderation queue
/// (§ Admin — App Store Guideline 1.2 enforcement). Deliberately does NOT
/// carry reporter_id — the app never surfaces who filed a report, even
/// to admins, consistent with Mahakosh's anonymization stance. The
/// identity still exists in chart_reports for anti-abuse investigation
/// directly via SQL if that's ever genuinely needed.
class AdminChartReport {
  const AdminChartReport({
    required this.id,
    required this.mkCode,
    required this.birthYear,
    required this.locationGeneral,
    required this.reason,
    required this.details,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String mkCode;
  final int? birthYear;
  final String locationGeneral;
  final String reason;
  final String details;
  final String status;
  final DateTime createdAt;

  /// Kept in sync with kReportReasons (lib/mahakosh/report_chart.dart)
  /// and the chart_reports.reason check constraint.
  static const reasonLabels = {
    'deanonymization': 'Could identify a real, named person',
    'health_privacy': 'Sensitive health information',
    'harassment': 'Harassing, hateful, or abusive content',
    'spam': 'Spam or fake/test data',
    'other': 'Something else',
  };

  String get reasonLabel => reasonLabels[reason] ?? reason;

  static AdminChartReport fromJson(Map<String, dynamic> j) {
    final chart = (j['mahakosh_charts'] as Map).cast<String, dynamic>();
    return AdminChartReport(
      id: j['id'] as String,
      mkCode: chart['mk_code'] as String,
      birthYear: chart['birth_year'] as int?,
      locationGeneral: (chart['location_general'] as String?) ?? '',
      reason: j['reason'] as String,
      details: (j['details'] as String?) ?? '',
      status: j['status'] as String,
      createdAt: DateTime.parse(j['created_at'] as String),
    );
  }
}

/// A bookmarked community chart. [chart] is null when the chart is no longer
/// available on Mahakosh (withdrawn/removed) — the bookmark is still shown so
/// the user understands it's gone, not an error.
typedef BookmarkEntry = ({String mkCode, MahakoshChartSummary? chart});

class LifeEventInput {
  const LifeEventInput({
    required this.tag,
    this.eventDate,
    this.datePrecision = 'exact', // exact | month | year | age
    this.ageYears,
    this.isHealthRelated = false,
    this.note = '',
  });

  final String tag;
  final DateTime? eventDate;
  final String datePrecision;
  final int? ageYears;
  final bool isHealthRelated;
  final String note;
}

/// Map a kundli's stored [KundliEvent]s to the Mahakosh contribution shape,
/// shared by the contribute and update-events flows. Precision (exact/month/
/// year/age) is carried through so the community card can show the date exactly
/// as entered; the tag prefers a specific title (custom labels were removed)
/// and falls back to the category.
List<LifeEventInput> lifeEventsFromStored(List<KundliEvent> stored) => [
      for (final e in stored)
        LifeEventInput(
          tag: (e.title != null && e.title!.trim().isNotEmpty)
              ? e.title!.trim()
              : e.label,
          eventDate: e.eventDate,
          datePrecision: e.datePrecision.name,
          ageYears: e.ageYears,
          isHealthRelated: e.isHealthRelated,
          note: e.description ?? '',
        ),
    ];

/// Atomic filter node for the combination query builder (§2.6).
/// Mirrors the FilterNode shape the edge functions expect.
sealed class FilterNode {
  Map<String, dynamic> toJson();
}

class GroupFilter extends FilterNode {
  GroupFilter(this.op, this.children);
  final String op; // AND | OR | NOT
  final List<FilterNode> children;

  @override
  Map<String, dynamic> toJson() => {
        'op': op,
        'children': children.map((c) => c.toJson()).toList(),
      };
}

class AtomicFilter extends FilterNode {
  AtomicFilter({
    required this.type,
    this.planet,
    this.sign,
    this.house,
    this.nakshatra,
    this.yogaCode,
    this.tag,
    this.dateFrom,
    this.dateTo,
    this.timeFrom,
    this.timeTo,
  });

  final String type;
  final String? planet;
  final int? sign;
  final int? house;
  final int? nakshatra;
  final String? yogaCode;
  final String? tag;

  /// birth_range bounds — local dates 'yyyy-MM-dd', times 'HH:mm'.
  final String? dateFrom;
  final String? dateTo;
  final String? timeFrom;
  final String? timeTo;

  @override
  Map<String, dynamic> toJson() => {
        'type': type,
        if (planet != null) 'planet': planet,
        if (sign != null) 'sign': sign,
        if (house != null) 'house': house,
        if (nakshatra != null) 'nakshatra': nakshatra,
        if (yogaCode != null) 'yoga_code': yogaCode,
        if (tag != null) 'tag': tag,
        if (dateFrom != null) 'date_from': dateFrom,
        if (dateTo != null) 'date_to': dateTo,
        if (timeFrom != null) 'time_from': timeFrom,
        if (timeTo != null) 'time_to': timeTo,
      };

  /// The birth date/time range as punctuation-only text (no leading
  /// word), e.g. "1990 → 1995 · 06:00–12:00". The display label is
  /// assembled in the presentation layer (mahakoshFilterLabel), which
  /// wraps this in the localized "Born …" phrasing — so no English lives
  /// here for it to un-bake. The other filter types are labelled purely
  /// from their structured fields (planet/sign/house/…), needing no
  /// string on the model at all.
  String get birthRangeSpan => [
        if (dateFrom != null || dateTo != null)
          '${dateFrom ?? '…'} → ${dateTo ?? '…'}',
        if (timeFrom != null || timeTo != null)
          '${timeFrom ?? '…'}–${timeTo ?? '…'}',
      ].join(' · ');
}

class ResearchRequest {
  const ResearchRequest({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.criteria,
    required this.createdAt,
    this.isMine = false,
    this.matchCount = 0,
  });

  final String id;
  final String title;
  final String description;
  final String status; // pending_review | live | rejected | closed
  final Map<String, dynamic> criteria;
  final DateTime createdAt;
  final bool isMine;
  final int matchCount;

  static ResearchRequest fromJson(Map<String, dynamic> j,
          {String? currentUserId}) =>
      ResearchRequest(
        id: j['id'] as String,
        title: j['title'] as String,
        description: (j['description'] as String?) ?? '',
        status: j['status'] as String,
        criteria: (j['criteria'] as Map?)?.cast<String, dynamic>() ?? {},
        createdAt: DateTime.parse(j['created_at'] as String),
        isMine: currentUserId != null && j['requester_id'] == currentUserId,
        matchCount: (j['match_count'] as int?) ?? 0,
      );
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.payload,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final bool read;
  final DateTime createdAt;

  // The user-facing title lives in the presentation layer
  // (notificationTitle in astro_l10n.dart) so it reads in the UI locale;
  // this model stays pure data (type + payload).

  static AppNotification fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'] as String,
        type: j['type'] as String,
        payload: (j['payload'] as Map?)?.cast<String, dynamic>() ?? {},
        read: (j['read'] as bool?) ?? false,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

/// One comment in a chart's discussion (0016). Flat list + reply-to:
/// [parentId] references another comment on the same chart, resolved
/// client-side against the loaded list for the quote header. Deleted /
/// removed comments arrive with an empty body (wiped server-side) and
/// render as placeholders so reply context survives.
class ChartComment {
  const ChartComment({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.parentId,
    required this.body,
    required this.status,
    required this.createdAt,
    required this.editedAt,
    required this.isMine,
  });

  final String id;

  /// Null when the author has deleted their account — the row survives
  /// as a 'deleted' placeholder (migration 0024) with no one to block.
  final String? authorId;
  final String authorName;
  final String? parentId;
  final String body;
  final String status; // visible | held | deleted | removed
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool isMine;

  bool get isVisible => status == 'visible';

  // Placeholder text for non-visible rows (deleted/removed/held) lives in
  // the presentation layer (commentPlaceholder in astro_l10n.dart).

  static ChartComment fromJson(Map<String, dynamic> j, {String? myUserId}) =>
      ChartComment(
        id: j['id'] as String,
        authorId: j['author_id'] as String?,
        // A missing profile embed with a null author_id means the author
        // deleted their account (0024) — the comment stays, unlinked.
        // Left EMPTY (not an English fallback) so the presentation layer
        // can localize the deleted/anonymous label — see commentAuthor in
        // astro_l10n.dart. Real display names are never empty.
        authorName: ((j['profiles'] as Map?)?['display_name'] as String?) ?? '',
        parentId: j['parent_id'] as String?,
        body: j['body'] as String,
        status: j['status'] as String,
        createdAt: DateTime.parse(j['created_at'] as String),
        editedAt: j['edited_at'] == null
            ? null
            : DateTime.parse(j['edited_at'] as String),
        isMine: myUserId != null && j['author_id'] == myUserId,
      );
}

/// A pending comment report in the admin moderation queue. Shows the
/// body SNAPSHOT taken at report time (the live comment may have been
/// edited or deleted since) — that snapshot is the moderation evidence.
/// Reporter identity is deliberately not selected (same stance as
/// AdminChartReport above).
class AdminCommentReport {
  const AdminCommentReport({
    required this.id,
    required this.commentId,
    required this.mkCode,
    required this.reason,
    required this.details,
    required this.bodySnapshot,
    required this.createdAt,
  });

  final String id;
  final String commentId;
  final String mkCode;
  final String reason;
  final String details;
  final String bodySnapshot;
  final DateTime createdAt;

  String get reasonLabel => AdminChartReport.reasonLabels[reason] ?? reason;

  static AdminCommentReport fromJson(Map<String, dynamic> j) {
    // Defensive: the embeds are null if RLS ever hides the joined rows
    // from the reviewing admin (bit us once — 0019); the snapshot-based
    // card must still render rather than crash the whole queue.
    final comment =
        ((j['chart_comments'] as Map?) ?? const {}).cast<String, dynamic>();
    final chart = ((comment['mahakosh_charts'] as Map?) ?? const {})
        .cast<String, dynamic>();
    return AdminCommentReport(
      id: j['id'] as String,
      commentId: (comment['id'] as String?) ?? '',
      mkCode: (chart['mk_code'] as String?) ?? '?',
      reason: j['reason'] as String,
      details: (j['details'] as String?) ?? '',
      bodySnapshot: j['body_snapshot'] as String,
      createdAt: DateTime.parse(j['created_at'] as String),
    );
  }
}

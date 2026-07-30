/// Client for Mahakosh: contribution (with consent), combination
/// search (edge function), withdrawal, and notifications.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/astro/models.dart';
import 'chart_index.dart';
import 'models.dart';

class MahakoshRepository {
  MahakoshRepository(this._client);
  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;
  bool get isSignedIn => _userId != null;

  /// Contribute a chart atomically via the contribute_chart RPC: the
  /// anonymized chart, its consent records, the precomputed index,
  /// yogas and life events land in ONE transaction (the deferred
  /// consent-invariant trigger requires this — separate PostgREST
  /// requests each commit alone and would be rejected). Then pings the
  /// matching engine. Returns the assigned MK code.
  Future<String> contribute({
    required AstroSnapshot snapshot,
    required bool isOwn,
    required bool consentConfirmed,
    required List<LifeEventInput> events,
    String locationGeneral = '',
    bool notifyOnMatch = true,
    String consentTextVersion = 'v1',
  }) async {
    if (!isSignedIn) throw StateError('Sign in to contribute.');
    if (!consentConfirmed) throw StateError('Consent is required.');
    final hasHealth = events.any((e) => e.isHealthRelated);

    final rows = await _client.rpc('contribute_chart', params: {
      'p_is_own': isOwn,
      'p_birth_year': snapshot.birth.localDateTime.year,
      'p_location_general': locationGeneral,
      'p_ayanamsa_id': snapshot.ayanamsaId,
      'p_chart_payload': buildAnonymizedPayload(snapshot),
      'p_notify_on_match': notifyOnMatch,
      'p_consent_kinds': [
        isOwn ? 'self' : 'third_party',
        if (hasHealth) 'health',
      ],
      'p_consent_text_version': consentTextVersion,
      'p_index': [
        for (final row in buildChartIndex(snapshot)) row.toJson(),
      ],
      'p_yoga_codes': buildYogaCodes(snapshot),
      'p_events': [for (final e in events) _eventJson(e)],
      // Full birth details (name is the only thing withheld) — needed
      // so viewers can run complete calculations, dashas included.
      'p_birth_utc': snapshot.birth.dateTimeUtc.toIso8601String(),
      'p_latitude': snapshot.birth.latitude,
      'p_longitude': snapshot.birth.longitude,
      'p_timezone_name': snapshot.birth.timezoneName,
      'p_utc_offset_min': snapshot.birth.utcOffsetMinutes,
      'p_place_name': snapshot.birth.placeName,
    }) as List;
    final chart = (rows.first as Map).cast<String, dynamic>();
    final chartId = chart['chart_id'] as String;

    // Fire-and-forget: match this new chart against live requests.
    try {
      await _client.functions.invoke('request-matching',
          body: {'kind': 'new_chart', 'chart_id': chartId});
    } catch (_) {
      // Matching is best-effort from the client; the backend can also
      // run it on a schedule.
    }

    return chart['mk_code'] as String;
  }

  /// The contribution wire shape for one life event, shared by [contribute]
  /// and [updateEvents].
  Map<String, dynamic> _eventJson(LifeEventInput e) => {
        'tag': e.tag,
        'event_date': e.eventDate?.toIso8601String().split('T').first ?? '',
        'date_precision': e.datePrecision,
        'age_years': e.ageYears,
        'is_health_related': e.isHealthRelated,
        'note': e.note,
      };

  /// Replace the life events on an ALREADY-SHARED active chart, keeping the
  /// same MK code (no withdraw + re-share). Runs the update_mahakosh_events
  /// RPC, which records the health-consent row automatically when needed (the
  /// single share consent covers it — see migration 0012).
  Future<void> updateEvents({
    required String mkCode,
    required List<LifeEventInput> events,
    String consentTextVersion = 'v1',
  }) async {
    if (!isSignedIn) throw StateError('Sign in to update a chart.');
    await _client.rpc('update_mahakosh_events', params: {
      'p_mk_code': mkCode,
      'p_events': [for (final e in events) _eventJson(e)],
      'p_consent_text_version': consentTextVersion,
    });
  }

  Future<void> withdraw(String mkCode) async {
    if (!isSignedIn) throw StateError('Sign in to withdraw a chart.');
    await _client
        .from('mahakosh_charts')
        .update({
          'status': 'withdrawn',
          'withdrawn_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('mk_code', mkCode)
        .eq('contributor_id', _userId as Object);
  }

  /// List rows come from the summary VIEW, not the table: the yoga and
  /// life-event counts are subqueries there (migration 0027), because
  /// they are not columns on mahakosh_charts and a plain select reported
  /// zero for both on every browsed and bookmarked row.
  ///
  /// A view rather than PostgREST's `life_events(count)` embed —
  /// that needs db-aggregates-enabled, off by default in PostgREST 12+
  /// and unset in this project's config.toml.
  static const _summaryTable = 'mahakosh_chart_summaries';

  /// Columns for a [MahakoshChartSummary]. NEVER contributor_id or
  /// chart_payload — the view excludes both, and this list is explicit
  /// so a future column can't leak in through a `select(*)`.
  static const _summaryColumns =
      'mk_code, birth_year, location_general, ayanamsa_id, created_at, '
      'yoga_count, life_event_count';

  /// The same columns minus the counts — what the base table can answer
  /// on its own.
  static const _fallbackColumns =
      'mk_code, birth_year, location_general, ayanamsa_id, created_at';

  /// True when a failure means "the summary view isn't in this project
  /// yet". PGRST205 is PostgREST's schema-cache miss for an unknown
  /// relation.
  ///
  /// The app and the database deploy on completely different clocks — a
  /// build can sit in App Store review for weeks after, or before, a
  /// migration goes out — so a client that hard-depends on the newest
  /// schema is a client that bricks a screen for whoever is on the wrong
  /// side of that gap. Degrade to the base table and lose the counts,
  /// which is what the list did for its whole life until now.
  static bool _missingSummaryView(Object e) =>
      e is PostgrestException &&
      (e.code == 'PGRST205' ||
          (e.message.contains('mahakosh_chart_summaries') &&
              e.message.contains('schema cache')));

  /// Latest active community charts + total count — the default
  /// "browse" state of the Mahakosh screen before any search runs.
  /// Plain RLS-governed select (active charts are readable by any
  /// signed-in user; contributor_id is never selected).
  /// [offset] pages through the corpus — the browse list is capped per
  /// call, and without paging the charts past the first page were simply
  /// unreachable however large the community grew.
  Future<({int total, List<MahakoshChartSummary> results})> recent(
      {int limit = 20, int offset = 0}) async {
    Future<({int total, List<MahakoshChartSummary> results})> query(
        String from, String columns) async {
      final res = await _client
          .from(from)
          .select(columns)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          // range() is inclusive at both ends, hence the -1.
          .range(offset, offset + limit - 1)
          .count(CountOption.exact);
      return (
        total: res.count,
        results: [
          for (final r in res.data)
            MahakoshChartSummary.fromJson((r as Map).cast<String, dynamic>()),
        ],
      );
    }

    try {
      return await query(_summaryTable, _summaryColumns);
    } catch (e) {
      if (!_missingSummaryView(e)) rethrow;
      return query('mahakosh_charts', _fallbackColumns);
    }
  }

  // --- Bookmarks (private, per-user, synced) --------------------------------

  /// The set of MK codes this user has bookmarked — drives the star state on
  /// rows and the detail screen.
  Future<Set<String>> bookmarkCodes() async {
    if (!isSignedIn) return {};
    final rows = await _client.from('mahakosh_bookmarks').select('mk_code');
    return {for (final r in rows) r['mk_code'] as String};
  }

  /// The user's bookmarked charts, newest bookmark first. Withdrawn/removed
  /// charts stay in the list with a null [BookmarkEntry.chart] so the UI can
  /// show "no longer available" rather than silently dropping them.
  Future<List<BookmarkEntry>> bookmarks() async {
    if (!isSignedIn) return [];
    final bm = await _client
        .from('mahakosh_bookmarks')
        .select('mk_code, created_at')
        .order('created_at', ascending: false);
    final codes = [for (final r in bm) r['mk_code'] as String];
    if (codes.isEmpty) return [];
    Future<List<dynamic>> chartsFrom(String from, String columns) =>
        _client
            .from(from)
            .select(columns)
            .inFilter('mk_code', codes)
            .eq('status', 'active');

    List<dynamic> charts;
    try {
      charts = await chartsFrom(_summaryTable, _summaryColumns);
    } catch (e) {
      if (!_missingSummaryView(e)) rethrow;
      charts = await chartsFrom('mahakosh_charts', _fallbackColumns);
    }
    final byCode = {
      for (final r in charts)
        (r['mk_code'] as String):
            MahakoshChartSummary.fromJson((r as Map).cast<String, dynamic>()),
    };
    // Preserve bookmark recency order; missing charts get a null summary.
    return [
      for (final c in codes) (mkCode: c, chart: byCode[c]),
    ];
  }

  Future<void> addBookmark(String mkCode) async {
    if (!isSignedIn) throw StateError('Sign in to bookmark charts.');
    await _client.from('mahakosh_bookmarks').upsert({
      'user_id': _userId,
      'mk_code': mkCode,
    });
  }

  Future<void> removeBookmark(String mkCode) async {
    if (!isSignedIn) return;
    await _client
        .from('mahakosh_bookmarks')
        .delete()
        .eq('user_id', _userId as Object)
        .eq('mk_code', mkCode);
  }

  /// Fetch one anonymized community chart by MK code (RLS: active
  /// charts are readable by any signed-in user; contributor identity
  /// is never selected).
  Future<AnonymizedChart> fetchChart(String mkCode) async {
    final row = await _client
        .from('mahakosh_charts')
        .select('id, mk_code, birth_year, location_general, ayanamsa_id, '
            'chart_payload, created_at, birth_utc, latitude, longitude, '
            'timezone_name, utc_offset_min, place_name')
        .eq('mk_code', mkCode)
        .single();
    List<Map<String, dynamic>> events = const [];
    try {
      final rows = await _client
          .from('life_events')
          .select(
              'tag, event_date, is_health_related, date_precision, age_years')
          .eq('chart_id', row['id'] as String);
      events = [for (final r in rows) (r as Map).cast<String, dynamic>()];
    } catch (_) {
      // Events are optional context; the chart still renders.
    }
    return AnonymizedChart.fromRow(
        (row as Map).cast<String, dynamic>(), events);
  }

  /// Combination search via the edge function (§2.6).
  Future<({int total, List<MahakoshChartSummary> results})> search(
    FilterNode filters, {
    int limit = 25,
    int offset = 0,
  }) async {
    final res = await _client.functions.invoke('combination-search', body: {
      'filters': filters.toJson(),
      'limit': limit,
      'offset': offset,
    });
    final data = res.data as Map<String, dynamic>;
    return (
      total: (data['total'] as num).toInt(),
      results: [
        for (final r in (data['results'] as List))
          MahakoshChartSummary.fromJson((r as Map).cast<String, dynamic>()),
      ],
    );
  }

  /// Hide a chart from this user's own Mahakosh view (§2.7a — App Store
  /// Guideline 1.2 content filtering). Instant, personal, silent: no
  /// moderator involved, and it never touches the chart's public status —
  /// every other user still sees it normally. Reversible via [unhideChart].
  Future<void> hideChart(String mkCode) async {
    if (!isSignedIn) throw StateError('Sign in to hide a chart.');
    await _client.rpc('hide_mahakosh_chart', params: {'p_mk_code': mkCode});
  }

  /// Undo [hideChart].
  Future<void> unhideChart(String mkCode) async {
    if (!isSignedIn) throw StateError('Sign in to manage hidden charts.');
    await _client.rpc('unhide_mahakosh_chart', params: {'p_mk_code': mkCode});
  }

  /// Report a chart to the moderation team (§2.7b — App Store Guideline
  /// 1.2 content reporting), distinct from [hideChart]: after review, a
  /// report can get the chart withdrawn for EVERYONE, not just hidden for
  /// this user. Also hides it from the reporter's own view right away
  /// (best-effort — a failure here doesn't undo the report itself), so
  /// the reporter isn't stuck looking at content they just flagged while
  /// it's under review.
  Future<void> reportChart(
    String mkCode, {
    required String reason,
    String details = '',
  }) async {
    if (!isSignedIn) throw StateError('Sign in to report a chart.');
    await _client.rpc('report_mahakosh_chart', params: {
      'p_mk_code': mkCode,
      'p_reason': reason,
      'p_details': details,
    });
    try {
      await hideChart(mkCode);
    } catch (_) {
      // Best-effort: the report itself already succeeded above.
    }
  }

  /// This user's own hidden-charts list, for the management/unhide screen.
  /// Goes through a SECURITY DEFINER RPC because the plain RLS-governed
  /// select on mahakosh_charts deliberately excludes hidden charts.
  Future<List<HiddenMahakoshChart>> hiddenCharts() async {
    if (!isSignedIn) return [];
    final rows = await _client.rpc('list_hidden_mahakosh_charts') as List;
    return [
      for (final r in rows)
        HiddenMahakoshChart.fromJson((r as Map).cast<String, dynamic>()),
    ];
  }

  Future<List<AppNotification>> notifications() async {
    if (!isSignedIn) return [];
    final rows = await _client
        .from('notifications')
        .select()
        .order('created_at', ascending: false)
        .limit(100);
    return [
      for (final r in rows) AppNotification.fromJson(r),
    ];
  }

  Future<void> markRead(String notificationId) async {
    await _client
        .from('notifications')
        .update({'read': true}).eq('id', notificationId);
  }

  Future<int> unreadCount() async {
    if (!isSignedIn) return 0;
    final rows =
        await _client.from('notifications').select('id').eq('read', false);
    return rows.length;
  }
}

/// Client for the research request board (§2.7): structured requests,
/// matches, and manual responses.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

class ResearchRepository {
  ResearchRepository(this._client);
  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;

  /// Live requests + the current user's own (any status).
  Future<List<ResearchRequest>> board() async {
    final rows = await _client
        .from('research_requests')
        .select()
        .order('created_at', ascending: false)
        .limit(100);
    return [
      for (final r in rows) ResearchRequest.fromJson(r, currentUserId: _userId),
    ];
  }

  /// Submit a structured request — criteria is a FilterNode tree, not
  /// free-form text. Goes into the moderation queue (pending_review).
  Future<void> submit({
    required String title,
    required String description,
    required FilterNode criteria,
  }) async {
    if (_userId == null) throw StateError('Sign in to post a request.');
    await _client.from('research_requests').insert({
      'requester_id': _userId,
      'title': title,
      'description': description,
      'criteria': criteria.toJson(),
    });
  }

  Future<List<MahakoshChartSummary>> matchesFor(String requestId) async {
    final rows = await _client
        .from('request_matches')
        .select('chart_id, mahakosh_charts(mk_code, birth_year, '
            'location_general, ayanamsa_id, created_at)')
        .eq('request_id', requestId);
    return [
      for (final r in rows)
        if (r['mahakosh_charts'] != null)
          MahakoshChartSummary.fromJson(
              (r['mahakosh_charts'] as Map).cast<String, dynamic>()),
    ];
  }

  /// Manually tag one of the user's contributed charts against an
  /// open request (screen 12 — Respond to Request).
  Future<void> respondWithChart({
    required String requestId,
    required String mkCode,
  }) async {
    final chart = await _client
        .from('mahakosh_charts')
        .select('id')
        .eq('mk_code', mkCode)
        .eq('contributor_id', _userId as Object)
        .single();
    await _client.from('request_matches').upsert({
      'request_id': requestId,
      'chart_id': chart['id'],
      'source': 'manual',
      'matched_by': _userId,
    }, onConflict: 'request_id,chart_id', ignoreDuplicates: true);
  }
}

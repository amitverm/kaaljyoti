/// Admin-only moderation operations — how you actually work through the
/// research requests (§2.7) and chart reports (§2.7b) that pile up in
/// pending_review.
///
/// SECURITY MODEL (read before touching this file):
///   * This repository enforces NOTHING on its own — it is not the
///     security boundary. A non-admin calling these methods gets empty
///     lists back (RLS) or a 403 from the edge functions (a server-side
///     admin check) — never client-trusted logic.
///   * [pendingRequests] / [pendingChartReports] are plain RLS-governed
///     reads: the `is_admin()` bypass in the SELECT policies
///     (0008_admin_role.sql) is what actually lets an admin see other
///     users' pending rows. A non-admin's identical query just comes
///     back empty, silently.
///   * [moderateRequest] / [moderateChartReport] call edge functions with
///     the CALLER'S OWN session JWT — same as any other functions.invoke
///     call. No service-role key ever touches this app. The edge
///     function verifies that JWT belongs to an admin via
///     requireInternalOrAdmin() (supabase/functions/_shared/edge.ts)
///     before doing anything privileged — THAT server-side check is the
///     real security boundary, not this file or the UI that hides it.
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import '../mahakosh/models.dart';

class AdminRepository {
  AdminRepository(this._client);
  final SupabaseClient _client;

  /// Whether the signed-in user is an admin. Drives whether the Admin
  /// entry point is even shown in the UI — a UX convenience, NOT the
  /// security boundary (see file header): hiding the nav item grants or
  /// denies no capability by itself.
  Future<bool> isAdmin() async {
    if (_client.auth.currentUser == null) return false;
    try {
      final result = await _client.rpc('is_admin');
      return result as bool? ?? false;
    } catch (_) {
      // Fail closed: if the check itself errors, treat as non-admin
      // rather than risk showing admin UI on an ambiguous result.
      return false;
    }
  }

  /// Every research request awaiting moderation, across all requesters —
  /// visible to admins only (RLS).
  Future<List<ResearchRequest>> pendingRequests() async {
    final rows = await _client
        .from('research_requests')
        .select()
        .eq('status', 'pending_review')
        .order('created_at');
    return [for (final r in rows) ResearchRequest.fromJson(r)];
  }

  Future<void> moderateRequest({
    required String requestId,
    required bool approve,
    String? note,
  }) async {
    await _client.functions.invoke('moderate-request', body: {
      'request_id': requestId,
      'action': approve ? 'approve' : 'reject',
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  /// Every chart report awaiting moderation, across all reporters —
  /// visible to admins only (RLS). Reporter identity is deliberately not
  /// selected here (see AdminChartReport's doc comment).
  Future<List<AdminChartReport>> pendingChartReports() async {
    final rows = await _client
        .from('chart_reports')
        .select('id, reason, details, status, created_at, '
            'mahakosh_charts(mk_code, birth_year, location_general)')
        .eq('status', 'pending_review')
        .order('created_at');
    return [for (final r in rows) AdminChartReport.fromJson(r)];
  }

  /// [action] true = the report was valid, withdraw the chart for
  /// EVERYONE; false = dismiss, the chart stays active.
  Future<void> moderateChartReport({
    required String reportId,
    required bool action,
    String? note,
  }) async {
    await _client.functions.invoke('moderate-chart-report', body: {
      'report_id': reportId,
      'action': action ? 'action' : 'dismiss',
      if (note != null && note.isNotEmpty) 'note': note,
    });
  }

  /// Every discussion-comment report awaiting moderation — visible to
  /// admins only (RLS, 0016). The embedded comment/chart give the queue
  /// its context; body_snapshot (not the live body) is the evidence.
  Future<List<AdminCommentReport>> pendingCommentReports() async {
    final rows = await _client
        .from('comment_reports')
        .select('id, reason, details, body_snapshot, status, created_at, '
            'chart_comments(id, mahakosh_charts(mk_code))')
        .eq('status', 'pending_review')
        .order('created_at');
    return [for (final r in rows) AdminCommentReport.fromJson(r)];
  }

  /// [remove] true = the report was valid, remove the comment for
  /// EVERYONE (and close all its pending reports); false = dismiss.
  /// Unlike the two edge-function moderations above, this is an
  /// is_admin()-gated SECURITY DEFINER RPC (moderate_comment_report,
  /// 0016) — same server-side boundary, no function deploy.
  Future<void> moderateCommentReport({
    required String reportId,
    required bool remove,
    String? note,
  }) async {
    await _client.rpc('moderate_comment_report', params: {
      'p_report_id': reportId,
      'p_action': remove ? 'remove' : 'dismiss',
      'p_note': (note != null && note.isNotEmpty) ? note : null,
    });
  }
}

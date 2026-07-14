/// Client for per-chart discussion on Mahakosh community charts
/// (0016_mahakosh_discussion.sql).
///
/// Reads are plain RLS-governed selects (the SELECT policy already
/// filters out authors this user has blocked). ALL writes go through
/// SECURITY DEFINER RPCs — there are deliberately no INSERT/UPDATE
/// policies on chart_comments, so rate limiting and the
/// visible→deleted/removed transitions can't be bypassed with raw
/// PostgREST calls.
///
/// UGC obligations (App Store Guideline 1.2 / Play UGC policy) are
/// covered by [reportComment] (moderator review; the RPC snapshots the
/// body as evidence) and [blockUser] (one-way, silent: their comments
/// disappear from MY view only — same philosophy as "hide chart from my
/// view", §2.7a).
library;

import 'package:supabase_flutter/supabase_flutter.dart';

import 'models.dart';

class DiscussionRepository {
  DiscussionRepository(this._client);
  final SupabaseClient _client;

  String? get _userId => _client.auth.currentUser?.id;
  bool get isSignedIn => _userId != null;

  /// All comments on a chart, oldest first (flat list; reply quoting is
  /// resolved client-side from this same list via [ChartComment.parentId]).
  /// Deleted/removed rows come back too — body already wiped server-side —
  /// so replies to them keep their context placeholder.
  Future<List<ChartComment>> comments(String mkCode) async {
    if (!isSignedIn) return [];
    final rows = await _client
        .from('chart_comments')
        .select('id, author_id, parent_id, body, status, created_at, '
            'edited_at, profiles(display_name), mahakosh_charts!inner(mk_code)')
        .eq('mahakosh_charts.mk_code', mkCode)
        .order('created_at', ascending: true);
    return [
      for (final r in rows)
        ChartComment.fromJson((r as Map).cast<String, dynamic>(),
            myUserId: _userId),
    ];
  }

  /// Number of visible comments — drives the Discussion entry card on the
  /// chart screen without loading the whole thread.
  Future<int> commentCount(String mkCode) async {
    if (!isSignedIn) return 0;
    final res = await _client
        .from('chart_comments')
        .select('id, mahakosh_charts!inner(mk_code)')
        .eq('mahakosh_charts.mk_code', mkCode)
        .eq('status', 'visible')
        .count(CountOption.exact);
    return res.count;
  }

  /// Post a comment (or a reply when [parentId] is set) via the
  /// add_chart_comment RPC — which enforces the rate limit (10s cooldown,
  /// 30/hour) and requires a display name: pass [displayName] on the
  /// user's first-ever comment (see [myDisplayName]); afterwards the
  /// stored profile name is used and the parameter is ignored.
  Future<void> addComment({
    required String mkCode,
    required String body,
    String? parentId,
    String? displayName,
  }) async {
    if (!isSignedIn) throw StateError('Sign in to join the discussion.');
    await _client.rpc('add_chart_comment', params: {
      'p_mk_code': mkCode,
      'p_body': body,
      'p_parent_id': parentId,
      'p_display_name': displayName,
    });
  }

  /// Edit own visible comment (server re-checks author + status).
  Future<void> editComment(String commentId, String body) async {
    if (!isSignedIn) throw StateError('Sign in to edit comments.');
    await _client.rpc('edit_chart_comment', params: {
      'p_comment_id': commentId,
      'p_body': body,
    });
  }

  /// Delete own comment. The row stays as a "deleted" placeholder (replies
  /// may reference it) with the body wiped server-side.
  Future<void> deleteComment(String commentId) async {
    if (!isSignedIn) throw StateError('Sign in to delete comments.');
    await _client.rpc('delete_chart_comment', params: {
      'p_comment_id': commentId,
    });
  }

  /// Report a comment for moderator review (reason codes shared with
  /// chart reporting — kReportReasons). Unlike chart reporting there is
  /// no auto-hide half: blocking the author is offered separately in the
  /// same action sheet.
  Future<void> reportComment(
    String commentId, {
    required String reason,
    String details = '',
  }) async {
    if (!isSignedIn) throw StateError('Sign in to report comments.');
    await _client.rpc('report_chart_comment', params: {
      'p_comment_id': commentId,
      'p_reason': reason,
      'p_details': details,
    });
  }

  /// One-way block: [authorId]'s comments vanish from MY view everywhere
  /// (enforced in the chart_comments SELECT policy). Silent — they are
  /// never notified — and reversible via [unblockUser].
  Future<void> blockUser(String authorId) async {
    if (!isSignedIn) throw StateError('Sign in to block users.');
    await _client.from('user_blocks').upsert({
      'blocker_id': _userId,
      'blocked_id': authorId,
    });
  }

  Future<void> unblockUser(String authorId) async {
    if (!isSignedIn) return;
    await _client
        .from('user_blocks')
        .delete()
        .eq('blocker_id', _userId as Object)
        .eq('blocked_id', authorId);
  }

  /// The signed-in user's chosen display name, or null when they have
  /// never set one — the UI prompts for it before their first comment.
  Future<String?> myDisplayName() async {
    if (!isSignedIn) return null;
    final row = await _client
        .from('profiles')
        .select('display_name')
        .eq('id', _userId as Object)
        .maybeSingle();
    final name = row?['display_name'] as String?;
    return (name == null || name.trim().isEmpty) ? null : name;
  }
}

/// Per-chart discussion on a Mahakosh community chart — the flat,
/// oldest-first comment thread with reply-to quoting (0016).
///
/// Interaction model:
///   * tap the reply arrow on a bubble → composer enters reply mode
///     (banner shows the quoted comment; × cancels)
///   * long-press a bubble → action sheet: Edit/Delete on own comments;
///     Report / Block author on others' (Guideline 1.2 UGC controls)
///   * first-ever comment prompts once for a public display name
///     (profiles.display_name — until then the user has none)
///
/// Deleted/removed comments stay in the list as placeholders (their
/// bodies are wiped server-side) so replies keep their context.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/theme.dart';
import '../mahakosh/models.dart';
import '../mahakosh/report_chart.dart' show kReportReasons;
import '../state/providers.dart';
import '../ui/common.dart';

class DiscussionScreen extends ConsumerStatefulWidget {
  const DiscussionScreen({super.key, required this.mkCode});
  final String mkCode;

  @override
  ConsumerState<DiscussionScreen> createState() => _DiscussionScreenState();
}

class _DiscussionScreenState extends ConsumerState<DiscussionScreen> {
  final _composer = TextEditingController();
  final _scroll = ScrollController();
  ChartComment? _replyTo; // composer in reply mode
  ChartComment? _editing; // composer in edit mode (mutually exclusive)
  bool _sending = false;

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(chartCommentsProvider(widget.mkCode));
    ref.invalidate(chartCommentCountProvider(widget.mkCode));
  }

  /// Human-readable message for RPC failures — the raise texts from the
  /// SQL functions (rate limit etc.) are already user-appropriate.
  String _errText(Object e) {
    final s = e.toString();
    final m = RegExp(r'message: ([^,]+)').firstMatch(s);
    return m?.group(1) ?? s;
  }

  Future<void> _send() async {
    final body = _composer.text.trim();
    if (body.isEmpty || _sending) return;
    final repo = ref.read(discussionRepoProvider);
    if (repo == null) return;
    final messenger = ScaffoldMessenger.of(context);

    // First-ever comment: ask for the public display name once.
    String? displayName;
    if (_editing == null) {
      final existing = await ref.read(myDisplayNameProvider.future);
      if (existing == null) {
        displayName = await _askDisplayName();
        if (displayName == null) return; // cancelled
      }
    }

    setState(() => _sending = true);
    try {
      if (_editing != null) {
        await repo.editComment(_editing!.id, body);
      } else {
        await repo.addComment(
          mkCode: widget.mkCode,
          body: body,
          parentId: _replyTo?.id,
          displayName: displayName,
        );
        if (displayName != null) ref.invalidate(myDisplayNameProvider);
      }
      _composer.clear();
      setState(() {
        _replyTo = null;
        _editing = null;
      });
      _refresh();
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('Could not post: ${_errText(e)}')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<String?> _askDisplayName() => showDialog<String>(
        context: context,
        builder: (ctx) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text('Choose a display name'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Shown publicly next to your comments and research '
                  'posts. You don\'t need to use your real name.',
                  style: TextStyle(fontSize: 12.5, color: TEColors.inkSoft),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: 40,
                  decoration:
                      const InputDecoration(labelText: 'Display name'),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) Navigator.pop(ctx, name);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      );

  // --- per-comment actions --------------------------------------------------

  Future<void> _actions(ChartComment c) async {
    // Edit is a typo window, not a revision mechanism — after 24h the
    // comment is locked (enforced server-side in edit_chart_comment;
    // hiding the action here just spares a doomed round-trip). Delete
    // deliberately has no window.
    final editable = c.isMine &&
        DateTime.now().toUtc().difference(c.createdAt.toUtc()) <
            const Duration(hours: 24);
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: TEColors.paper,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (c.isMine) ...[
              if (editable)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Edit'),
                  onTap: () => Navigator.pop(ctx, 'edit'),
                ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: TEColors.maroon),
                title: Text('Delete',
                    style: TextStyle(color: TEColors.maroon)),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () => Navigator.pop(ctx, 'reply'),
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: const Text('Report…'),
                onTap: () => Navigator.pop(ctx, 'report'),
              ),
              // A deleted account has no one to block.
              if (c.authorId != null)
              ListTile(
                leading: const Icon(Icons.block),
                title: Text('Block ${c.authorName}'),
                subtitle: const Text(
                    'Hides all their comments from your view and '
                    'reports this comment to our moderators. '
                    'They won’t be notified.',
                    style: TextStyle(fontSize: 11.5)),
                onTap: () => Navigator.pop(ctx, 'block'),
              ),
            ],
          ],
        ),
      ),
    );
    if (action == null || !mounted) return;
    switch (action) {
      case 'reply':
        setState(() {
          _editing = null;
          _replyTo = c;
        });
      case 'edit':
        setState(() {
          _replyTo = null;
          _editing = c;
          _composer.text = c.body;
        });
      case 'delete':
        await _delete(c);
      case 'report':
        await _report(c);
      case 'block':
        await _block(c);
    }
  }

  Future<void> _delete(ChartComment c) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete comment?'),
        content: const Text(
            'The comment is removed for everyone. Replies to it stay, '
            'quoting a deleted comment.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  Text('Delete', style: TextStyle(color: TEColors.maroon))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(discussionRepoProvider)?.deleteComment(c.id);
      _refresh();
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('Could not delete: ${_errText(e)}')));
    }
  }

  Future<void> _report(ChartComment c) async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showModalBottomSheet<(String, String)>(
      context: context,
      backgroundColor: TEColors.paper,
      isScrollControlled: true,
      builder: (ctx) => _ReportCommentSheet(comment: c),
    );
    if (result == null || !mounted) return;
    try {
      await ref.read(discussionRepoProvider)?.reportComment(c.id,
          reason: result.$1, details: result.$2);
      messenger.showSnackBar(const SnackBar(
          content: Text(
              'Comment reported — our team will review it. You can also '
              'block the author to hide their comments.')));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('Could not report: ${_errText(e)}')));
    }
  }

  Future<void> _block(ChartComment c) async {
    // Placeholder rows never reach here (no actions menu), but a
    // deleted-account author has no id to block — guard anyway.
    final authorId = c.authorId;
    if (authorId == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(discussionRepoProvider);
      await repo?.blockUser(authorId);
      // Guideline 1.2: blocking must also notify the developer of the
      // content that prompted it. Filed silently; a duplicate report
      // (already reported, then blocked) must not fail the block.
      try {
        await repo?.reportComment(c.id,
            reason: 'other',
            details: 'Auto-report: the reporter blocked this comment\'s '
                'author.');
      } catch (_) {}
      _refresh();
      messenger.showSnackBar(SnackBar(
        content: Text('${c.authorName} blocked — their comments are '
            'hidden from your view and our moderators were notified.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await ref.read(discussionRepoProvider)?.unblockUser(authorId);
            _refresh();
          },
        ),
      ));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text('Could not block: ${_errText(e)}')));
    }
  }

  // --- build ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authUserProvider).valueOrNull;
    final commentsAsync = ref.watch(chartCommentsProvider(widget.mkCode));

    return Scaffold(
      appBar: AppBar(title: Text('Discussion · ${widget.mkCode}')),
      body: user == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sign in to read and join the discussion on '
                      'community charts.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 13.5, color: TEColors.inkSoft),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.push('/signin'),
                      child: const Text('Sign in'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: commentsAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => EmptyState(
                        message: 'Could not load the discussion: $e'),
                    data: (comments) => comments.isEmpty
                        ? const EmptyState(
                            message: 'No comments yet — share your '
                                'reading of this chart.')
                        : RefreshIndicator(
                            onRefresh: () async => _refresh(),
                            child: ListView.builder(
                              controller: _scroll,
                              padding:
                                  const EdgeInsets.fromLTRB(16, 10, 16, 10),
                              itemCount: comments.length,
                              itemBuilder: (_, i) => _bubble(
                                  comments[i],
                                  {for (final c in comments) c.id: c}),
                            ),
                          ),
                  ),
                ),
                _composerBar(),
              ],
            ),
    );
  }

  Widget _bubble(ChartComment c, Map<String, ChartComment> byId) {
    final parent = c.parentId == null ? null : byId[c.parentId];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onLongPress: c.isVisible ? () => _actions(c) : null,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.isMine
                ? TEColors.maroon.withValues(alpha: 0.05)
                : TEColors.ink.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      c.authorName,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: c.isMine ? TEColors.maroon : TEColors.ink,
                      ),
                    ),
                  ),
                  Text(
                    '${DateFormat('d MMM, HH:mm').format(c.createdAt.toLocal())}'
                    '${c.editedAt != null ? ' · edited' : ''}',
                    style:
                        TETheme.mono(size: 10, color: TEColors.inkSoft),
                  ),
                ],
              ),
              if (c.parentId != null) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: TEColors.ink.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                        left: BorderSide(
                            color: TEColors.maroon.withValues(alpha: 0.5),
                            width: 2)),
                  ),
                  child: Text(
                    parent == null
                        ? 'Original comment unavailable'
                        : parent.isVisible
                            ? '${parent.authorName}: ${parent.body}'
                            : parent.placeholder,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 11.5, color: TEColors.inkSoft),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              c.isVisible
                  ? Text(c.body, style: const TextStyle(fontSize: 13.5))
                  : Text(c.placeholder,
                      style: TextStyle(
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          color: TEColors.inkSoft)),
              if (c.isVisible && !c.isMine)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 30)),
                    onPressed: () => setState(() {
                      _editing = null;
                      _replyTo = c;
                    }),
                    icon: const Icon(Icons.reply, size: 15),
                    label:
                        const Text('Reply', style: TextStyle(fontSize: 12)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _composerBar() {
    final banner = _editing != null
        ? 'Editing your comment'
        : _replyTo != null
            ? 'Replying to ${_replyTo!.authorName}: ${_replyTo!.body}'
            : null;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        decoration: BoxDecoration(
          color: TEColors.paper,
          border: Border(
              top: BorderSide(color: TEColors.ink.withValues(alpha: 0.08))),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (banner != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        banner,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 11.5, color: TEColors.inkSoft),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() {
                        _replyTo = null;
                        if (_editing != null) _composer.clear();
                        _editing = null;
                      }),
                      child: Icon(Icons.close,
                          size: 16, color: TEColors.inkSoft),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Public — avoid names or identifying details.',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, color: TEColors.inkSoft),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _composer,
                    minLines: 1,
                    maxLines: 4,
                    maxLength: 2000,
                    decoration: const InputDecoration(
                      hintText: 'Share your reading…',
                      counterText: '',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _sending ? null : _send,
                  icon: _sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Report sheet for a comment — same reason codes as chart reporting
/// (kReportReasons), with the comment quoted for context.
class _ReportCommentSheet extends StatefulWidget {
  const _ReportCommentSheet({required this.comment});
  final ChartComment comment;

  @override
  State<_ReportCommentSheet> createState() => _ReportCommentSheetState();
}

class _ReportCommentSheetState extends State<_ReportCommentSheet> {
  String _reason = kReportReasons.keys.first;
  final _details = TextEditingController();

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Report comment', style: TETheme.serif(size: 18)),
          const SizedBox(height: 6),
          Text(
            '“${widget.comment.body}” — ${widget.comment.authorName}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: TEColors.inkSoft),
          ),
          const SizedBox(height: 4),
          Text(
            'Sends the comment for review by our team. The author is '
            'never told who reported it.',
            style: TextStyle(fontSize: 12.5, color: TEColors.inkSoft),
          ),
          const SizedBox(height: 10),
          for (final e in kReportReasons.entries)
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: e.key,
              groupValue: _reason,
              activeColor: TEColors.maroon,
              title: Text(e.value, style: const TextStyle(fontSize: 13.5)),
              onChanged: (v) => setState(() => _reason = v!),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _details,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Additional details (optional)',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, (_reason, _details.text.trim())),
            child: const Text('Submit report'),
          ),
        ],
      ),
    );
  }
}

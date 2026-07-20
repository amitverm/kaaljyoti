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
import '../l10n/astro_l10n.dart';

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
    // Captured before the first await — context must not be used across
    // suspension points.
    final l10n = context.l10n;
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
      messenger
          .showSnackBar(SnackBar(content: Text(l10n.dsPostError(_errText(e)))));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<String?> _askDisplayName() => showDialog<String>(
        context: context,
        builder: (ctx) {
          final controller = TextEditingController();
          return AlertDialog(
            title: Text(ctx.l10n.dsChooseDisplayName),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ctx.l10n.dsDisplayNameHint,
                  style: TextStyle(fontSize: 12.5, color: KJColors.inkSoft),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  autofocus: true,
                  maxLength: 40,
                  decoration:
                      InputDecoration(labelText: ctx.l10n.dsDisplayName),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(ctx.l10n.cancel)),
              FilledButton(
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) Navigator.pop(ctx, name);
                },
                child: Text(ctx.l10n.save),
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
      backgroundColor: KJColors.paper,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (c.isMine) ...[
              if (editable)
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: Text(context.l10n.dsEdit),
                  onTap: () => Navigator.pop(ctx, 'edit'),
                ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: KJColors.maroon),
                title: Text(context.l10n.delete,
                    style: TextStyle(color: KJColors.maroon)),
                onTap: () => Navigator.pop(ctx, 'delete'),
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.reply),
                title: Text(context.l10n.dsReply),
                onTap: () => Navigator.pop(ctx, 'reply'),
              ),
              ListTile(
                leading: const Icon(Icons.flag_outlined),
                title: Text(context.l10n.dsReportEllipsis),
                onTap: () => Navigator.pop(ctx, 'report'),
              ),
              // A deleted account has no one to block.
              if (c.authorId != null)
                ListTile(
                  leading: const Icon(Icons.block),
                  title: Text(
                      context.l10n.dsBlockUser(commentAuthor(context.l10n, c))),
                  subtitle: Text(context.l10n.dsBlockSubtitle,
                      style: const TextStyle(fontSize: 11.5)),
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
    // Captured before the first await — context must not be used across
    // suspension points.
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.dsDeleteTitle),
        content: Text(ctx.l10n.dsDeleteBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.l10n.delete,
                  style: TextStyle(color: KJColors.maroon))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(discussionRepoProvider)?.deleteComment(c.id);
      _refresh();
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.dsDeleteError(_errText(e)))));
    }
  }

  Future<void> _report(ChartComment c) async {
    // Captured before the first await — context must not be used across
    // suspension points.
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final result = await showModalBottomSheet<(String, String)>(
      context: context,
      backgroundColor: KJColors.paper,
      isScrollControlled: true,
      builder: (ctx) => _ReportCommentSheet(comment: c),
    );
    if (result == null || !mounted) return;
    try {
      await ref
          .read(discussionRepoProvider)
          ?.reportComment(c.id, reason: result.$1, details: result.$2);
      messenger.showSnackBar(SnackBar(content: Text(l10n.dsReported)));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.dsReportError(_errText(e)))));
    }
  }

  Future<void> _block(ChartComment c) async {
    // Placeholder rows never reach here (no actions menu), but a
    // deleted-account author has no id to block — guard anyway.
    final authorId = c.authorId;
    if (authorId == null) return;
    // Captured before the first await — context must not be used
    // across suspension points.
    final l10n = context.l10n;
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
        content: Text(l10n.dsBlocked(commentAuthor(l10n, c))),
        action: SnackBarAction(
          label: l10n.dsUndo,
          onPressed: () async {
            await ref.read(discussionRepoProvider)?.unblockUser(authorId);
            _refresh();
          },
        ),
      ));
    } catch (e) {
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.dsBlockError(_errText(e)))));
    }
  }

  // --- build ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authUserProvider).valueOrNull;
    final commentsAsync = ref.watch(chartCommentsProvider(widget.mkCode));

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.dsTitle(widget.mkCode))),
      body: user == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.l10n.dsSignInPrompt,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.5, color: KJColors.inkSoft),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.push('/signin'),
                      child: Text(context.l10n.signIn),
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
                    error: (e, _) =>
                        EmptyState(message: context.l10n.dsLoadError('$e')),
                    data: (comments) => comments.isEmpty
                        ? EmptyState(message: context.l10n.dsEmpty)
                        : RefreshIndicator(
                            onRefresh: () async => _refresh(),
                            child: ListView.builder(
                              controller: _scroll,
                              padding:
                                  const EdgeInsets.fromLTRB(16, 10, 16, 10),
                              itemCount: comments.length,
                              itemBuilder: (_, i) => _bubble(comments[i],
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
                ? KJColors.maroon.withValues(alpha: 0.05)
                : KJColors.ink.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      commentAuthor(context.l10n, c),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: c.isMine ? KJColors.maroon : KJColors.ink,
                      ),
                    ),
                  ),
                  Text(
                    '${DateFormat('d MMM, HH:mm', context.l10n.localeName).format(c.createdAt.toLocal())}'
                    '${c.editedAt != null ? ' · ${context.l10n.dsEdited}' : ''}',
                    style: KJTheme.mono(size: 10, color: KJColors.inkSoft),
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
                    color: KJColors.ink.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(8),
                    border: Border(
                        left: BorderSide(
                            color: KJColors.maroon.withValues(alpha: 0.5),
                            width: 2)),
                  ),
                  child: Text(
                    parent == null
                        ? context.l10n.dsOriginalUnavailable
                        : parent.isVisible
                            ? '${commentAuthor(context.l10n, parent)}: ${parent.body}'
                            : commentPlaceholder(context.l10n, parent.status),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: KJColors.inkSoft),
                  ),
                ),
              ],
              const SizedBox(height: 6),
              c.isVisible
                  ? Text(c.body, style: const TextStyle(fontSize: 13.5))
                  : Text(commentPlaceholder(context.l10n, c.status),
                      style: TextStyle(
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          color: KJColors.inkSoft)),
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
                    label: Text(context.l10n.dsReply,
                        style: const TextStyle(fontSize: 12)),
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
        ? context.l10n.dsEditingBanner
        : _replyTo != null
            ? context.l10n.dsReplyingBanner(
                commentAuthor(context.l10n, _replyTo!), _replyTo!.body)
            : null;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
        decoration: BoxDecoration(
          color: KJColors.paper,
          border: Border(
              top: BorderSide(color: KJColors.ink.withValues(alpha: 0.08))),
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
                        style:
                            TextStyle(fontSize: 11.5, color: KJColors.inkSoft),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() {
                        _replyTo = null;
                        if (_editing != null) _composer.clear();
                        _editing = null;
                      }),
                      child:
                          Icon(Icons.close, size: 16, color: KJColors.inkSoft),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                context.l10n.dsPublicHint,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 10.5, color: KJColors.inkSoft),
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
                    decoration: InputDecoration(
                      hintText: context.l10n.dsComposerHint,
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
          Text(context.l10n.dsReportComment, style: KJTheme.serif(size: 18)),
          const SizedBox(height: 6),
          Text(
            context.l10n
                .dsReportQuote(widget.comment.body, widget.comment.authorName),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: KJColors.inkSoft),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.dsReportBlurb,
            style: TextStyle(fontSize: 12.5, color: KJColors.inkSoft),
          ),
          const SizedBox(height: 10),
          for (final e in kReportReasons.entries)
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: e.key,
              groupValue: _reason,
              activeColor: KJColors.maroon,
              title: Text(reportReasonLabel(context.l10n, e.key),
                  style: const TextStyle(fontSize: 13.5)),
              onChanged: (v) => setState(() => _reason = v!),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _details,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: context.l10n.dsReportDetails,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, (_reason, _details.text.trim())),
            child: Text(context.l10n.dsSubmitReport),
          ),
        ],
      ),
    );
  }
}

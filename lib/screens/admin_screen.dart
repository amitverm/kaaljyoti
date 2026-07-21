/// Admin — moderation queue for research requests (§2.7) and chart
/// reports (§2.7b). Hidden from the nav for non-admins (see Profile);
/// the actual security boundary is server-side (RLS + the edge
/// functions' own admin check — see admin_repository.dart's doc
/// comment). This screen additionally checks [isAdminProvider] itself
/// so a non-admin who guesses the route sees nothing, rather than an
/// empty scaffold whose buttons would just fail server-side anyway.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../mahakosh/models.dart';
import '../state/providers.dart';
import '../ui/common.dart';

// autoDispose so the queue refetches every time the (pushed) Admin screen
// is opened — a kept-alive FutureProvider fetches once per app session and
// then serves that cache forever, so a request created after the first
// visit wouldn't appear until a manual pull-to-refresh invalidated it.
final _pendingRequestsProvider =
    FutureProvider.autoDispose<List<ResearchRequest>>((ref) {
  final repo = ref.watch(adminRepoProvider);
  if (repo == null) return Future.value([]);
  return repo.pendingRequests();
});

final _pendingReportsProvider =
    FutureProvider.autoDispose<List<AdminChartReport>>((ref) {
  final repo = ref.watch(adminRepoProvider);
  if (repo == null) return Future.value([]);
  return repo.pendingChartReports();
});

final _pendingCommentReportsProvider =
    FutureProvider.autoDispose<List<AdminCommentReport>>((ref) {
  final repo = ref.watch(adminRepoProvider);
  if (repo == null) return Future.value([]);
  return repo.pendingCommentReports();
});

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  /// Ids optimistically removed from the queue while their moderation call
  /// is in flight (or after it succeeds) — filtered out of every list so
  /// the row disappears the instant the admin confirms, rather than after
  /// two network round-trips (the edge-function call, then the refetch).
  /// Reverted on failure. Ids are UUIDs, unique across all three queues.
  final Set<String> _removing = {};

  @override
  Widget build(BuildContext context) {
    final isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: isAdmin.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const EmptyState(message: 'Not available.'),
        data: (admin) => !admin
            ? const EmptyState(message: 'Not available.')
            : _body(context, ref),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(_pendingRequestsProvider);
    final reports = ref.watch(_pendingReportsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(_pendingRequestsProvider);
        ref.invalidate(_pendingReportsProvider);
        ref.invalidate(_pendingCommentReportsProvider);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          _label('PENDING RESEARCH REQUESTS'),
          requests.when(
            loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('Could not load: $e'),
            data: (items) {
              final visible =
                  items.where((r) => !_removing.contains(r.id)).toList();
              return visible.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('Nothing pending.',
                          style:
                              TextStyle(fontSize: 13, color: KJColors.inkSoft)),
                    )
                  : Column(children: [
                      for (final r in visible) _requestCard(context, ref, r),
                    ]);
            },
          ),
          const SizedBox(height: 24),
          _label('PENDING CHART REPORTS'),
          reports.when(
            loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('Could not load: $e'),
            data: (items) {
              final visible =
                  items.where((r) => !_removing.contains(r.id)).toList();
              return visible.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('Nothing pending.',
                          style:
                              TextStyle(fontSize: 13, color: KJColors.inkSoft)),
                    )
                  : Column(children: [
                      for (final r in visible) _reportCard(context, ref, r),
                    ]);
            },
          ),
          const SizedBox(height: 24),
          _label('PENDING COMMENT REPORTS'),
          ref.watch(_pendingCommentReportsProvider).when(
                loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Text('Could not load: $e'),
                data: (items) {
                  final visible =
                      items.where((r) => !_removing.contains(r.id)).toList();
                  return visible.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text('Nothing pending.',
                              style: TextStyle(
                                  fontSize: 13, color: KJColors.inkSoft)),
                        )
                      : Column(children: [
                          for (final r in visible)
                            _commentReportCard(context, ref, r),
                        ]);
                },
              ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: TextStyle(
                fontSize: 10.5,
                letterSpacing: 1.1,
                color: KJColors.inkSoft,
                fontWeight: FontWeight.w600)),
      );

  Widget _requestCard(BuildContext context, WidgetRef ref, ResearchRequest r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(r.title,
                style: const TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w600)),
            if (r.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(r.description, style: const TextStyle(fontSize: 12.5)),
            ],
            const SizedBox(height: 6),
            Text(KJDate.date(r.createdAt),
                style: KJTheme.mono(size: 10.5, color: KJColors.inkSoft)),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => _moderate(
                    context,
                    ref,
                    id: r.id,
                    title: 'Reject request',
                    success: 'Request rejected.',
                    onConfirm: (note) => ref
                        .read(adminRepoProvider)!
                        .moderateRequest(
                            requestId: r.id, approve: false, note: note),
                    after: () => ref.invalidate(_pendingRequestsProvider),
                  ),
                  child: const Text('Reject'),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: () => _moderate(
                    context,
                    ref,
                    id: r.id,
                    title: 'Approve request',
                    success: 'Request approved — it is live now.',
                    onConfirm: (note) => ref
                        .read(adminRepoProvider)!
                        .moderateRequest(
                            requestId: r.id, approve: true, note: note),
                    after: () => ref.invalidate(_pendingRequestsProvider),
                  ),
                  child: const Text('Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportCard(BuildContext context, WidgetRef ref, AdminChartReport r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chart ${r.mkCode}',
                style: const TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            KJTag(r.reasonLabel, maroon: true),
            if (r.details.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(r.details, style: const TextStyle(fontSize: 12.5)),
            ],
            const SizedBox(height: 6),
            Text(KJDate.date(r.createdAt),
                style: KJTheme.mono(size: 10.5, color: KJColors.inkSoft)),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => _moderate(
                    context,
                    ref,
                    id: r.id,
                    title: 'Dismiss report',
                    success: 'Report dismissed.',
                    onConfirm: (note) => ref
                        .read(adminRepoProvider)!
                        .moderateChartReport(
                            reportId: r.id, action: false, note: note),
                    after: () => ref.invalidate(_pendingReportsProvider),
                  ),
                  child: const Text('Dismiss'),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  style:
                      FilledButton.styleFrom(backgroundColor: KJColors.maroon),
                  onPressed: () => _moderate(
                    context,
                    ref,
                    id: r.id,
                    title: 'Withdraw chart',
                    success: 'Chart withdrawn.',
                    onConfirm: (note) => ref
                        .read(adminRepoProvider)!
                        .moderateChartReport(
                            reportId: r.id, action: true, note: note),
                    after: () => ref.invalidate(_pendingReportsProvider),
                  ),
                  child: const Text('Withdraw chart'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _commentReportCard(
      BuildContext context, WidgetRef ref, AdminCommentReport r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comment on ${r.mkCode}',
                style: const TextStyle(
                    fontSize: 14.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            KJTag(r.reasonLabel, maroon: true),
            const SizedBox(height: 6),
            // The snapshot taken at report time — the live comment may
            // have been edited or deleted since; this is the evidence.
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: KJColors.ink.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('“${r.bodySnapshot}”',
                  style: const TextStyle(fontSize: 12.5)),
            ),
            if (r.details.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(r.details, style: const TextStyle(fontSize: 12.5)),
            ],
            const SizedBox(height: 6),
            Text(KJDate.date(r.createdAt),
                style: KJTheme.mono(size: 10.5, color: KJColors.inkSoft)),
            const SizedBox(height: 10),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () => _moderate(
                    context,
                    ref,
                    id: r.id,
                    title: 'Dismiss report',
                    success: 'Report dismissed.',
                    onConfirm: (note) => ref
                        .read(adminRepoProvider)!
                        .moderateCommentReport(
                            reportId: r.id, remove: false, note: note),
                    after: () => ref.invalidate(_pendingCommentReportsProvider),
                  ),
                  child: const Text('Dismiss'),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  style:
                      FilledButton.styleFrom(backgroundColor: KJColors.maroon),
                  onPressed: () => _moderate(
                    context,
                    ref,
                    id: r.id,
                    title: 'Remove comment',
                    success: 'Comment removed.',
                    onConfirm: (note) => ref
                        .read(adminRepoProvider)!
                        .moderateCommentReport(
                            reportId: r.id, remove: true, note: note),
                    after: () => ref.invalidate(_pendingCommentReportsProvider),
                  ),
                  child: const Text('Remove comment'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _moderate(
    BuildContext context,
    WidgetRef ref, {
    required String id,
    required String title,
    required String success,
    required Future<void> Function(String? note) onConfirm,
    required VoidCallback after,
  }) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Note (optional)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    // Optimistic: hide the row immediately so feedback is instant, then do
    // the (slow) edge-function call. Keep it hidden on success; revert on
    // failure so the row and its buttons come back.
    setState(() => _removing.add(id));
    try {
      await onConfirm(controller.text.trim());
      messenger.showSnackBar(SnackBar(content: Text(success)));
      // Reconcile with true server state (also picks up anything another
      // admin changed). The row stays hidden via _removing until then.
      after();
    } catch (e) {
      if (mounted) setState(() => _removing.remove(id));
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
      // The server may have applied the transition before erroring; refetch
      // so the list reflects reality rather than our reverted guess.
      after();
    }
  }
}

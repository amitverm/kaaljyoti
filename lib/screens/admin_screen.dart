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

final _pendingRequestsProvider = FutureProvider<List<ResearchRequest>>((ref) {
  final repo = ref.watch(adminRepoProvider);
  if (repo == null) return Future.value([]);
  return repo.pendingRequests();
});

final _pendingReportsProvider = FutureProvider<List<AdminChartReport>>((ref) {
  final repo = ref.watch(adminRepoProvider);
  if (repo == null) return Future.value([]);
  return repo.pendingChartReports();
});

final _pendingCommentReportsProvider =
    FutureProvider<List<AdminCommentReport>>((ref) {
  final repo = ref.watch(adminRepoProvider);
  if (repo == null) return Future.value([]);
  return repo.pendingCommentReports();
});

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            data: (items) => items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Nothing pending.',
                        style:
                            TextStyle(fontSize: 13, color: KJColors.inkSoft)),
                  )
                : Column(children: [
                    for (final r in items) _requestCard(context, ref, r),
                  ]),
          ),
          const SizedBox(height: 24),
          _label('PENDING CHART REPORTS'),
          reports.when(
            loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator())),
            error: (e, _) => Text('Could not load: $e'),
            data: (items) => items.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Nothing pending.',
                        style:
                            TextStyle(fontSize: 13, color: KJColors.inkSoft)),
                  )
                : Column(children: [
                    for (final r in items) _reportCard(context, ref, r),
                  ]),
          ),
          const SizedBox(height: 24),
          _label('PENDING COMMENT REPORTS'),
          ref.watch(_pendingCommentReportsProvider).when(
                loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator())),
                error: (e, _) => Text('Could not load: $e'),
                data: (items) => items.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('Nothing pending.',
                            style: TextStyle(
                                fontSize: 13, color: KJColors.inkSoft)),
                      )
                    : Column(children: [
                        for (final r in items)
                          _commentReportCard(context, ref, r),
                      ]),
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
                    title: 'Reject request',
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
                    title: 'Approve request',
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
                    title: 'Dismiss report',
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
                    title: 'Withdraw chart',
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
                    title: 'Dismiss report',
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
                    title: 'Remove comment',
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
    required String title,
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
    try {
      await onConfirm(controller.text.trim());
      after();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }
}

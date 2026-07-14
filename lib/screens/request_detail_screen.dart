/// Screen 11 — Request Detail (requester view): criteria, status, and
/// matching charts, with a path back to Mahakosh and a respond action.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../mahakosh/models.dart';
import '../mahakosh/report_chart.dart';
import '../state/providers.dart';
import '../ui/common.dart';
import 'research_board_screen.dart';

final requestMatchesProvider =
    FutureProvider.family<List<MahakoshChartSummary>, String>((ref, id) {
  final repo = ref.watch(researchRepoProvider);
  if (repo == null) return Future.value([]);
  return repo.matchesFor(id);
});

class RequestDetailScreen extends ConsumerWidget {
  const RequestDetailScreen({super.key, required this.requestId});
  final String requestId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final board = ref.watch(researchBoardProvider);
    final matches = ref.watch(requestMatchesProvider(requestId));

    return Scaffold(
      appBar: AppBar(title: const Text('Research Request')),
      body: board.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(message: 'Could not load: $e'),
        data: (requests) {
          final request =
              requests.where((r) => r.id == requestId).firstOrNull;
          if (request == null) {
            return const EmptyState(message: 'Request not found.');
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(request.title, style: TETheme.serif(size: 20)),
              const SizedBox(height: 6),
              Row(
                children: [
                  TETag(
                    switch (request.status) {
                      'pending_review' => 'In review',
                      'live' => 'Live',
                      'rejected' => 'Not approved',
                      _ => request.status,
                    },
                    maroon: request.status == 'live',
                  ),
                  const SizedBox(width: 8),
                  Text(
                    TEDate.date(request.createdAt),
                    style:
                        TETheme.mono(size: 11, color: TEColors.inkSoft),
                  ),
                ],
              ),
              if (request.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(request.description,
                    style: const TextStyle(fontSize: 13.5)),
              ],
              const Divider(height: 32),
              Text('MATCHING CHARTS',
                  style: TextStyle(
                      fontSize: 10.5,
                      letterSpacing: 1.1,
                      color: TEColors.inkSoft,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              matches.when(
                loading: () => const Center(
                    child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator())),
                error: (e, _) => Text('Could not load matches: $e'),
                data: (charts) => charts.isEmpty
                    ? Text(
                        'No matches yet. Contributors are notified when '
                        'their charts match.',
                        style: TextStyle(
                            fontSize: 13, color: TEColors.inkSoft))
                    : Column(
                        children: [
                          for (final c in charts)
                            Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(
                                    'Chart ${c.mkCode} (anonymized)'),
                                subtitle: Text([
                                  if (c.birthYear != null)
                                    'b. ${c.birthYear}',
                                  if (c.locationGeneral.isNotEmpty)
                                    c.locationGeneral,
                                ].join(' · ')),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    PopupMenuButton<void>(
                                      tooltip: 'More',
                                      icon: Icon(Icons.more_vert,
                                          size: 20, color: TEColors.inkSoft),
                                      itemBuilder: (ctx) => [
                                        PopupMenuItem(
                                          onTap: () => _hideChart(
                                              context, ref, c.mkCode),
                                          child: const Text(
                                              'Hide from my view'),
                                        ),
                                        PopupMenuItem(
                                          onTap: () => showReportChartSheet(
                                              context, ref, c.mkCode,
                                              onReported: () => ref.invalidate(
                                                  requestMatchesProvider)),
                                          child: const Text('Report...'),
                                        ),
                                      ],
                                    ),
                                    Icon(Icons.chevron_right,
                                        size: 20, color: TEColors.inkSoft),
                                  ],
                                ),
                                onTap: () => context.push(
                                    '/mahakosh/chart/${c.mkCode}'),
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              if (!request.isMine && request.status == 'live')
                FilledButton(
                  onPressed: () =>
                      context.push('/research/$requestId/respond'),
                  child: const Text('Respond with a chart'),
                ),
              TextButton(
                onPressed: () => context.go('/mahakosh'),
                child: const Text('Explore these patterns in Mahakosh'),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Hide a matched chart from THIS user's Mahakosh view only (§2.7a) —
/// same personal, reversible filter as the Mahakosh screens, reachable
/// wherever a chart summary is shown to a user.
Future<void> _hideChart(
    BuildContext context, WidgetRef ref, String mkCode) async {
  final repo = ref.read(mahakoshRepoProvider);
  if (repo == null) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await repo.hideChart(mkCode);
    ref.invalidate(requestMatchesProvider);
    messenger.showSnackBar(SnackBar(
      content: Text('Hidden Chart $mkCode from your view.'),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () async {
          await repo.unhideChart(mkCode);
          ref.invalidate(requestMatchesProvider);
        },
      ),
    ));
  } catch (e) {
    messenger
        .showSnackBar(SnackBar(content: Text('Could not hide chart: $e')));
  }
}

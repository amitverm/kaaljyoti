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
import '../l10n/astro_l10n.dart';
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
      appBar: AppBar(title: Text(context.l10n.rdTitle)),
      body: board.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(message: context.l10n.uiCouldNotLoad('$e')),
        data: (requests) {
          final request = requests.where((r) => r.id == requestId).firstOrNull;
          if (request == null) {
            return EmptyState(message: context.l10n.rdNotFound);
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(request.title, style: KJTheme.serif(size: 20)),
              const SizedBox(height: 6),
              Row(
                children: [
                  KJTag(
                    switch (request.status) {
                      'pending_review' => context.l10n.rdStatusInReview,
                      'live' => context.l10n.rdStatusLive,
                      'rejected' => context.l10n.rdStatusNotApproved,
                      _ => request.status,
                    },
                    maroon: request.status == 'live',
                  ),
                  const SizedBox(width: 8),
                  Text(
                    KJDate.date(request.createdAt),
                    style: KJTheme.mono(size: 11, color: KJColors.inkSoft),
                  ),
                ],
              ),
              if (request.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(request.description,
                    style: const TextStyle(fontSize: 13.5)),
              ],
              const Divider(height: 32),
              Text(context.l10n.rdMatchingCharts,
                  style: TextStyle(
                      fontSize: 10.5,
                      letterSpacing: 1.1,
                      color: KJColors.inkSoft,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              matches.when(
                loading: () => const Center(
                    child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator())),
                error: (e, _) => Text(context.l10n.rdMatchesError('$e')),
                data: (charts) => charts.isEmpty
                    ? Text(context.l10n.rdNoMatches,
                        style: TextStyle(fontSize: 13, color: KJColors.inkSoft))
                    : Column(
                        children: [
                          for (final c in charts)
                            Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(
                                    context.l10n.hcChartAnonymized(c.mkCode)),
                                subtitle: Text([
                                  if (c.birthYear != null)
                                    context.l10n
                                        .labelBornYear('${c.birthYear}'),
                                  if (c.locationGeneral.isNotEmpty)
                                    c.locationGeneral,
                                ].join(' · ')),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    PopupMenuButton<void>(
                                      tooltip: context.l10n.rdMore,
                                      icon: Icon(Icons.more_vert,
                                          size: 20, color: KJColors.inkSoft),
                                      itemBuilder: (ctx) => [
                                        PopupMenuItem(
                                          onTap: () => _hideChart(
                                              context, ref, c.mkCode),
                                          child:
                                              Text(context.l10n.rdHideFromView),
                                        ),
                                        PopupMenuItem(
                                          onTap: () => showReportChartSheet(
                                              context, ref, c.mkCode,
                                              onReported: () => ref.invalidate(
                                                  requestMatchesProvider)),
                                          child: Text(context.l10n.rdReport),
                                        ),
                                      ],
                                    ),
                                    Icon(Icons.chevron_right,
                                        size: 20, color: KJColors.inkSoft),
                                  ],
                                ),
                                onTap: () =>
                                    context.push('/mahakosh/chart/${c.mkCode}'),
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              if (!request.isMine && request.status == 'live')
                FilledButton(
                  onPressed: () => context.push('/research/$requestId/respond'),
                  child: Text(context.l10n.respondWithChart),
                ),
              TextButton(
                onPressed: () => context.go('/mahakosh'),
                child: Text(context.l10n.rdExplore),
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
  // Captured before the first await — context must not be used across
  // suspension points.
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await repo.hideChart(mkCode);
    ref.invalidate(requestMatchesProvider);
    messenger.showSnackBar(SnackBar(
      content: Text(l10n.rdHidden(mkCode)),
      action: SnackBarAction(
        label: l10n.rdUndo,
        onPressed: () async {
          await repo.unhideChart(mkCode);
          ref.invalidate(requestMatchesProvider);
        },
      ),
    ));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.rdHideError('$e'))));
  }
}

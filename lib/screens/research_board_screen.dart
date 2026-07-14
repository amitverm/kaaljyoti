/// Screen 10 — Research Board. Open research requests with a "YOURS"
/// section, + new request entry.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../mahakosh/models.dart';
import '../state/providers.dart';
import '../ui/common.dart';

final researchBoardProvider = FutureProvider<List<ResearchRequest>>((ref) {
  final repo = ref.watch(researchRepoProvider);
  if (repo == null) return Future.value([]);
  return repo.board();
});

class ResearchBoardScreen extends ConsumerWidget {
  const ResearchBoardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(researchRepoProvider);
    final user = ref.watch(authUserProvider).value;
    final board = ref.watch(researchBoardProvider);

    return TEScaffold(
      section: TESection.research,
      appBar: AppBar(
        title: const Text('Research'),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton(
                onPressed: () => context.push('/research/new'),
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 8)),
                child: const Text('+ Request'),
              ),
            ),
        ],
      ),
      body: repo == null
          ? const EmptyState(
              message: 'The research board needs the backend configured. '
                  'See supabase/README.md.')
          : user == null
              ? EmptyState(
                  message:
                      'Sign in to browse and post research requests.',
                  actionLabel: 'Sign in',
                  onAction: () => context.push('/signin'),
                )
              : board.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) =>
                      EmptyState(message: 'Could not load board: $e'),
                  data: (requests) {
                    final mine =
                        requests.where((r) => r.isMine).toList();
                    final open = requests
                        .where((r) => !r.isMine && r.status == 'live')
                        .toList();
                    if (requests.isEmpty) {
                      return const EmptyState(
                          message:
                              'No research requests yet. Post the first '
                              'one — describe a pattern you want to study.');
                    }
                    return RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(researchBoardProvider),
                      child: ListView(
                        padding:
                            const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        children: [
                          Text(
                            '${open.length} open requests · pattern research',
                            style: TETheme.mono(
                                size: 11.5, color: TEColors.inkSoft),
                          ),
                          const SizedBox(height: 10),
                          if (mine.isNotEmpty) ...[
                            _label('YOURS'),
                            for (final r in mine)
                              _RequestCard(request: r),
                            const SizedBox(height: 14),
                            _label('OPEN REQUESTS'),
                          ],
                          for (final r in open)
                            _RequestCard(request: r),
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: TextStyle(
                fontSize: 10.5,
                letterSpacing: 1.1,
                color: TEColors.inkSoft,
                fontWeight: FontWeight.w600)),
      );
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request});
  final ResearchRequest request;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/research/${request.id}'),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text(request.title,
                          style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600))),
                  TETag(
                    switch (request.status) {
                      'pending_review' => 'In review',
                      'live' => 'Live',
                      'rejected' => 'Not approved',
                      _ => request.status,
                    },
                    maroon: request.status == 'live',
                  ),
                ],
              ),
              if (request.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(request.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5, color: TEColors.inkSoft)),
              ],
              const SizedBox(height: 6),
              Text(
                TEDate.date(request.createdAt),
                style: TETheme.mono(size: 10.5, color: TEColors.inkSoft),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen — Hidden Charts (§2.7a). Management/undo surface for the
/// per-user "hide from my view" filter (App Store Guideline 1.2, User-
/// Generated Content: users must be able to filter content they don't
/// want to see, separately from reporting it for moderation). Purely
/// personal and reversible — unhiding here never affects other users.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../mahakosh/models.dart';
import '../state/providers.dart';
import '../ui/common.dart';

final hiddenChartsProvider = FutureProvider<List<HiddenMahakoshChart>>((ref) {
  final repo = ref.watch(mahakoshRepoProvider);
  if (repo == null) return Future.value([]);
  return repo.hiddenCharts();
});

class HiddenChartsScreen extends ConsumerWidget {
  const HiddenChartsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(mahakoshRepoProvider);
    final user = ref.watch(authUserProvider).value;
    final hidden = ref.watch(hiddenChartsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Hidden charts')),
      body: repo == null || user == null
          ? EmptyState(
              message: user == null && repo != null
                  ? 'Sign in to manage hidden charts.'
                  : 'Needs the backend configured. See supabase/README.md.',
            )
          : hidden.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(message: 'Could not load: $e'),
              data: (items) => items.isEmpty
                  ? const EmptyState(
                      message: 'Nothing hidden. Charts you hide from '
                          'Mahakosh — search, browse, or a chart\'s own '
                          '"..." menu — show up here so you can undo it '
                          'any time.')
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(hiddenChartsProvider),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        children: [
                          Text(
                            'Hidden charts are only hidden for you — '
                            'everyone else still sees them normally.',
                            style: TextStyle(
                                fontSize: 12.5, color: TEColors.inkSoft),
                          ),
                          const SizedBox(height: 14),
                          for (final h in items) _row(context, ref, h),
                        ],
                      ),
                    ),
            ),
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, HiddenMahakoshChart h) {
    final parts = [
      if (h.birthYear != null) 'b. ${h.birthYear}',
      if (h.locationGeneral.isNotEmpty) h.locationGeneral,
      'hidden ${TEDate.date(h.hiddenAt.toLocal())}',
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('Chart ${h.mkCode} (anonymized)',
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle:
            Text(parts.join(' · '), style: const TextStyle(fontSize: 12)),
        trailing: TextButton(
          onPressed: () async {
            final repo = ref.read(mahakoshRepoProvider);
            if (repo == null) return;
            final messenger = ScaffoldMessenger.of(context);
            try {
              await repo.unhideChart(h.mkCode);
              ref.invalidate(hiddenChartsProvider);
            } catch (e) {
              messenger.showSnackBar(
                  SnackBar(content: Text('Could not unhide: $e')));
            }
          },
          child: const Text('Unhide'),
        ),
      ),
    );
  }
}

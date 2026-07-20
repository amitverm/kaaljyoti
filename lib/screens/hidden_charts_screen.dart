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
import '../l10n/astro_l10n.dart';

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
      appBar: AppBar(title: Text(context.l10n.mnHiddenCharts)),
      body: repo == null || user == null
          ? EmptyState(
              message: user == null && repo != null
                  ? context.l10n.hcSignInPrompt
                  : context.l10n.hcBackendMissing,
            )
          : hidden.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  EmptyState(message: context.l10n.uiCouldNotLoad('$e')),
              data: (items) => items.isEmpty
                  ? EmptyState(message: context.l10n.hcEmpty)
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(hiddenChartsProvider),
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                        children: [
                          Text(
                            context.l10n.hcNote,
                            style: TextStyle(
                                fontSize: 12.5, color: KJColors.inkSoft),
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
      if (h.birthYear != null) context.l10n.labelBornYear('${h.birthYear}'),
      if (h.locationGeneral.isNotEmpty) h.locationGeneral,
      context.l10n.hcHiddenOn(KJDate.date(h.hiddenAt.toLocal())),
    ];
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(context.l10n.hcChartAnonymized(h.mkCode),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(parts.join(' · '), style: const TextStyle(fontSize: 12)),
        trailing: TextButton(
          onPressed: () async {
            final repo = ref.read(mahakoshRepoProvider);
            if (repo == null) return;
            // Captured before the first await — this row has no State to
            // guard with, so context must not be used after the call.
            final l10n = context.l10n;
            final messenger = ScaffoldMessenger.of(context);
            try {
              await repo.unhideChart(h.mkCode);
              ref.invalidate(hiddenChartsProvider);
            } catch (e) {
              messenger.showSnackBar(
                  SnackBar(content: Text(l10n.hcUnhideError('$e'))));
            }
          },
          child: Text(context.l10n.hcUnhide),
        ),
      ),
    );
  }
}

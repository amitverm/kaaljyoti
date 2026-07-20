/// Screen 13 — Notifications. Two-way research notifications:
/// "new match for your request" and "your chart matched a request".
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/date_format.dart';
import '../core/notification_routes.dart';
import '../core/theme/theme.dart';
import '../mahakosh/models.dart';
import '../state/providers.dart';
import '../ui/common.dart';
import '../l10n/astro_l10n.dart';

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) {
  final repo = ref.watch(mahakoshRepoProvider);
  if (repo == null) return Future.value([]);
  return repo.notifications();
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(mahakoshRepoProvider);
    final user = ref.watch(authUserProvider).value;
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.notificationsTitle)),
      body: repo == null || user == null
          ? EmptyState(
              message: user == null && repo != null
                  ? context.l10n.ntSignInPrompt
                  : context.l10n.ntBackendMissing,
              actionLabel:
                  repo != null && user == null ? context.l10n.signIn : null,
              onAction: repo != null && user == null
                  ? () => context.push('/signin')
                  : null,
            )
          : notifications.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  EmptyState(message: context.l10n.uiCouldNotLoad('$e')),
              data: (items) => items.isEmpty
                  ? EmptyState(message: context.l10n.nfEmpty)
                  : RefreshIndicator(
                      onRefresh: () async =>
                          ref.invalidate(notificationsProvider),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          for (final n in items)
                            Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: Icon(
                                  switch (n.type) {
                                    'request_match_new' => Icons.travel_explore,
                                    'your_chart_matched' =>
                                      Icons.insights_outlined,
                                    'request_approved' =>
                                      Icons.check_circle_outline,
                                    'request_rejected' => Icons.block_outlined,
                                    'report_actioned' => Icons.flag_outlined,
                                    'report_dismissed' => Icons.outlined_flag,
                                    _ => Icons.notifications_none,
                                  },
                                  color: n.read
                                      ? KJColors.inkSoft
                                      : KJColors.maroon,
                                  size: 22,
                                ),
                                title: Text(notificationTitle(context.l10n, n),
                                    style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: n.read
                                            ? FontWeight.w400
                                            : FontWeight.w600)),
                                subtitle: Text(
                                  KJDate.dateDotTime(n.createdAt.toLocal()),
                                  style: KJTheme.mono(
                                      size: 10.5, color: KJColors.inkSoft),
                                ),
                                onTap: () async {
                                  await ref
                                      .read(mahakoshRepoProvider)!
                                      .markRead(n.id);
                                  ref.invalidate(notificationsProvider);
                                  // Same mapping as push-notification
                                  // taps (core/notification_routes.dart).
                                  final route = notificationRoute(
                                    n.type,
                                    mkCode: n.payload['mk_code'] as String?,
                                    requestId:
                                        n.payload['request_id'] as String?,
                                  );
                                  if (route != null && context.mounted) {
                                    context.push(route);
                                  }
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
            ),
    );
  }
}

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

final notificationsProvider =
    FutureProvider<List<AppNotification>>((ref) {
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
      appBar: AppBar(title: const Text('Notifications')),
      body: repo == null || user == null
          ? EmptyState(
              message: user == null && repo != null
                  ? 'Sign in to receive research notifications.'
                  : 'Notifications arrive once the backend is configured '
                      'and you are signed in.',
              actionLabel: repo != null && user == null ? 'Sign in' : null,
              onAction: repo != null && user == null
                  ? () => context.push('/signin')
                  : null,
            )
          : notifications.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(message: 'Could not load: $e'),
              data: (items) => items.isEmpty
                  ? const EmptyState(
                      message: 'Nothing yet. You\'ll hear about research '
                          'matches here.')
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
                                    'request_match_new' =>
                                      Icons.travel_explore,
                                    'your_chart_matched' =>
                                      Icons.insights_outlined,
                                    'request_approved' =>
                                      Icons.check_circle_outline,
                                    'request_rejected' =>
                                      Icons.block_outlined,
                                    'report_actioned' =>
                                      Icons.flag_outlined,
                                    'report_dismissed' =>
                                      Icons.outlined_flag,
                                    _ => Icons.notifications_none,
                                  },
                                  color: n.read
                                      ? TEColors.inkSoft
                                      : TEColors.maroon,
                                  size: 22,
                                ),
                                title: Text(n.title,
                                    style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: n.read
                                            ? FontWeight.w400
                                            : FontWeight.w600)),
                                subtitle: Text(
                                  TEDate.dateDotTime(n.createdAt.toLocal()),
                                  style: TETheme.mono(
                                      size: 10.5,
                                      color: TEColors.inkSoft),
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
                                    mkCode:
                                        n.payload['mk_code'] as String?,
                                    requestId: n.payload['request_id']
                                        as String?,
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

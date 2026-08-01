/// Screen 13 — Notifications. A record of what has HAPPENED: one
/// chronological list mixing kundli alerts whose moment has passed with
/// server-backed research and Mahakosh replies.
///
/// WHAT IS COMING lives on its own screen, one tap down (see the pinned
/// bottom option and [ScheduledAlertsScreen]). Inline, the schedule was
/// up to 60 things that have not happened sitting above the handful that
/// had — the wrong way round for a screen you open to see what you
/// missed.
///
/// DELIBERATELY UNIFIED. The app has two unrelated notification
/// mechanisms — on-device kundli alerts computed here, and server-backed
/// research/Mahakosh replies — and users neither know nor care which is
/// which. Splitting them by mechanism (tabs, badges, "local"/"server"
/// labels) exports our plumbing as the user's mental model, and QA
/// showed the cost: the server side's sign-in wall taught people that
/// the local alerts needed an account too. So: no tabs, no source
/// labels, identical row treatment, one list.
///
/// NO SIGN-IN PROMPT. This screen asks for nothing. Signed out, it shows
/// past kundli alerts and simply has no server items to mix in. The
/// sign-in gates stay where real server functionality lives — Mahakosh,
/// sync, Settings ▸ Kundli data.
///
/// HONESTY. Past alerts are not "delivered" alerts and nothing here says
/// they are: neither platform gives an app a delivery receipt. What the
/// OS WILL answer is whether it would show them at all — so when
/// notifications are blocked the screen says so plainly, with a way to
/// fix it, instead of listing rows nobody ever saw.
library;

import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/date_format.dart';
import '../core/notification_routes.dart';
import '../core/theme/theme.dart';
import '../core/theme/tokens.dart';
import '../core/theme/type_scale.dart';
import '../data/settings_repository.dart';
import '../l10n/astro_l10n.dart';
import '../mahakosh/models.dart';
import '../state/providers.dart';
import '../ui/common.dart';
import 'scheduled_alerts_screen.dart';

final notificationsProvider = FutureProvider<List<AppNotification>>((ref) {
  final repo = ref.watch(mahakoshRepoProvider);
  if (repo == null) return Future.value([]);
  return repo.notifications();
});

/// One row of the Past list, whatever produced it.
///
/// The two sources collapse into this ON PURPOSE: once an item is in
/// here, nothing downstream can render a badge or sort by origin,
/// because the origin is no longer available to render. [serverId] and
/// [alert] exist solely to route the swipe to the right removal
/// mechanism, which is plumbing, not presentation.
class _PastItem {
  const _PastItem({
    required this.when,
    required this.icon,
    required this.title,
    required this.dismissKey,
    this.body,
    this.route,
    this.serverId,
    this.alert,
  });

  final DateTime when;
  final IconData icon;
  final String title;
  final String? body;
  final String dismissKey;
  final String? route;

  /// Set for a server notification — dismissal hides it locally.
  final String? serverId;

  /// Set for a kundli alert — dismissal drops it from local history.
  final ScheduledAlertRecord? alert;
}

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with WidgetsBindingObserver {
  /// Rows swiped away in this build, by dismiss key.
  ///
  /// Dismissible demands the widget leave the tree in the SAME frame the
  /// swipe completes, but both removal paths are async (prefs write, then
  /// a provider refresh) — so the list would still contain the row on the
  /// next build and Flutter would assert. This is the synchronous half:
  /// the key goes in here immediately, the durable removal follows.
  final _removed = <String>{};

  /// Set once the OS has refused the permission and there is nothing
  /// left to ask it — on Android that is a dead end for the app, so the
  /// banner spells out the settings path instead.
  bool _showSettingsPath = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// The permission is edited OUTSIDE the app — in the OS Settings the
  /// blocked banner itself sends people to — so the one moment the
  /// cached answer is suspect is exactly when the app comes back to the
  /// foreground. Without this, the banner would linger (or stay absent)
  /// until a manual pull-to-refresh.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(notificationsEnabledProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final history = ref.watch(alertHistoryProvider).valueOrNull ?? const [];
    final server = ref.watch(notificationsProvider).valueOrNull ?? const [];
    final dismissed = ref.watch(dismissedNotificationsProvider);
    final past = _mergePast(l10n, history, server, dismissed);
    // Optimistic while the platform is still answering: a warning shown
    // to someone whose alerts work is worse than a beat of no warning.
    final enabled = ref.watch(notificationsEnabledProvider).valueOrNull ?? true;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsTitle)),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(notificationsProvider);
          ref.invalidate(alertHistoryProvider);
          ref.invalidate(alertScheduleSummaryProvider);
          ref.invalidate(notificationsEnabledProvider);
        },
        child: past.isEmpty
            ? _empty(enabled)
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  if (!enabled)
                    _blockedBanner()
                  else
                    Text(
                      l10n.kaPastNote,
                      style: TextStyle(fontSize: 12, color: KJColors.inkSoft),
                    ),
                  const SizedBox(height: 10),
                  for (final item in past) _pastRow(item),
                ],
              ),
      ),
      // Pinned, not the last row of the scroll: with a long history the
      // way to the schedule would otherwise be a hundred swipes away,
      // and it is the one thing on this screen that looks forward.
      // Never gated — seeing what is scheduled is ordinary user content.
      bottomNavigationBar: _scheduledOption(),
    );
  }

  /// The way through to [ScheduledAlertsScreen], carrying the count so
  /// the number is legible without the trip.
  Widget _scheduledOption() {
    final l10n = context.l10n;
    final count =
        upcomingAlerts(ref.watch(alertScheduleSummaryProvider).valueOrNull)
            .length;

    // Material, not a DecoratedBox: ListTile paints its ink splash onto
    // the nearest Material ancestor, so a coloured box in between would
    // swallow the tap feedback (Flutter asserts on exactly this).
    return Material(
      color: KJColors.paper,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Divider(height: 1, color: KJColors.hairline),
          SafeArea(
            top: false,
            child: ListTile(
              leading: Icon(Icons.schedule_outlined,
                  color: KJColors.maroon, size: 22),
              title: Text(l10n.naScheduledCount('$count'),
                  style: const TextStyle(fontSize: 14)),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => context.push('/notifications/scheduled'),
            ),
          ),
        ],
      ),
    );
  }

  /// One line, whatever the reason there is nothing to show. It does not
  /// mention accounts, because nothing on this screen needs one.
  ///
  /// The blocked banner belongs here too, and arguably most of all:
  /// notifications off is a very good reason for an empty history, and
  /// this is the person who most needs telling.
  Widget _empty(bool enabled) => ListView(
        children: [
          if (!enabled)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _blockedBanner(),
            ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: EmptyState(message: context.l10n.naEmpty),
          ),
        ],
      );

  // --- Blocked ---------------------------------------------------------

  /// The one thing about delivery the OS does tell us. Without this,
  /// every row above is an alert nobody saw and the screen looks fine.
  Widget _blockedBanner() {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: KJColors.maroon.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: KJColors.maroon.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.naNotificationsOff,
            style: TextStyle(fontSize: 12.5, color: KJColors.maroon),
          ),
          const SizedBox(height: 8),
          if (_showSettingsPath)
            // No button: the OS will not ask again, so one would be a
            // control that does nothing.
            Text(
              l10n.naNotificationsOffPath,
              style: TextStyle(fontSize: 12.5, color: KJColors.maroon),
            )
          else
            FilledButton(
              onPressed: _enableNotifications,
              style: FilledButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 8)),
              child: Text(l10n.naEnableNotifications),
            ),
        ],
      ),
    );
  }

  Future<void> _enableNotifications() async {
    final granted =
        await ref.read(kundliAlertServiceProvider).requestPermissions();
    if (!mounted) return;
    if (granted) {
      ref.invalidate(notificationsEnabledProvider);
      return;
    }
    // Refused. iOS hands the user straight to our own settings pane;
    // Android has no equivalent without another dependency, so the path
    // is written out instead.
    if (Platform.isIOS) {
      await launchUrl(Uri.parse('app-settings:'));
    } else {
      setState(() => _showSettingsPath = true);
    }
  }

  // --- Past ----------------------------------------------------------

  /// Both sources, newest first, with dismissed server items filtered
  /// out. No stable tiebreak by origin: they are one list.
  List<_PastItem> _mergePast(
    AppLocalizations l10n,
    List<ScheduledAlertRecord> history,
    List<AppNotification> server,
    Set<String> dismissed,
  ) {
    final items = <_PastItem>[
      for (final a in history)
        _PastItem(
          when: a.when,
          icon: Icons.event_available_outlined,
          title: a.title,
          body: a.body,
          dismissKey: 'alert:${a.dedupeKey}',
          route: a.kundliId.isEmpty ? null : '/kundli/${a.kundliId}',
          alert: a,
        ),
      for (final n in server)
        if (!dismissed.contains(n.id))
          _PastItem(
            when: n.createdAt,
            icon: switch (n.type) {
              'request_match_new' => Icons.travel_explore,
              'your_chart_matched' => Icons.insights_outlined,
              'request_approved' => Icons.check_circle_outline,
              'request_rejected' => Icons.block_outlined,
              'report_actioned' => Icons.flag_outlined,
              'report_dismissed' => Icons.outlined_flag,
              _ => Icons.notifications_none,
            },
            title: notificationTitle(l10n, n),
            dismissKey: 'server:${n.id}',
            route: notificationRoute(
              n.type,
              mkCode: n.payload['mk_code'] as String?,
              requestId: n.payload['request_id'] as String?,
            ),
            serverId: n.id,
          ),
    ]..sort((a, b) => b.when.compareTo(a.when));
    return [
      for (final i in items)
        if (!_removed.contains(i.dismissKey)) i
    ];
  }

  Widget _pastRow(_PastItem item) => Dismissible(
        key: ValueKey(item.dismissKey),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: KJColors.maroon.withValues(alpha: KJTint.faint),
            borderRadius: KJRadius.all(KJRadius.lg),
          ),
          child: Icon(Icons.delete_outline, color: KJColors.maroon, size: 20),
        ),
        onDismissed: (_) {
          // Synchronous, so the row is gone from the next build; the
          // durable removal runs after.
          setState(() => _removed.add(item.dismissKey));
          unawaited(_dismiss(item));
        },
        child: Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(item.icon, color: KJColors.inkSoft, size: 22),
            title: Text(item.title,
                style: const TextStyle(fontSize: 13.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.body != null)
                  Text(item.body!,
                      style: KJType.data(size: 12, color: KJColors.inkSoft)),
                Text(
                  KJDate.dateDotTime(item.when.toLocal()),
                  style: KJTheme.mono(size: 10.5, color: KJColors.inkSoft),
                ),
              ],
            ),
            onTap: item.route == null ? null : () => _openPast(item),
          ),
        ),
      );

  Future<void> _openPast(_PastItem item) async {
    // Server items are marked read on open, exactly as before.
    if (item.serverId != null) {
      final repo = ref.read(mahakoshRepoProvider);
      if (repo != null) {
        await repo.markRead(item.serverId!);
        ref.invalidate(notificationsProvider);
      }
    }
    if (!mounted || item.route == null) return;
    context.push(item.route!);
  }

  Future<void> _dismiss(_PastItem item) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(kundliAlertServiceProvider);
    final dismissedIds = ref.read(dismissedNotificationsProvider.notifier);

    if (item.alert != null) {
      await service.removePastAlert(item.alert!);
      ref.invalidate(alertHistoryProvider);
    } else if (item.serverId != null) {
      // The server has no delete (RLS is select+update only), so hide it
      // here and mark it read upstream — a dismissed item should not
      // keep the bell lit on another device either.
      dismissedIds.dismiss(item.serverId!);
      unawaited(ref.read(mahakoshRepoProvider)?.markRead(item.serverId!));
    }

    messenger.showSnackBar(SnackBar(
      content: Text(l10n.naDismissed),
      action: SnackBarAction(
        label: l10n.rdUndo,
        onPressed: () async {
          if (item.alert != null) {
            await service.restorePastAlert(item.alert!);
            ref.invalidate(alertHistoryProvider);
          } else if (item.serverId != null) {
            dismissedIds.restore(item.serverId!);
          }
          if (mounted) setState(() => _removed.remove(item.dismissKey));
        },
      ),
    ));
  }

  // --- Actions -------------------------------------------------------
}

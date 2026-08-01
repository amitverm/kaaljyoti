/// Screen — Scheduled kundli alerts. What the last scheduling pass
/// handed to the OS, day by day.
///
/// A SEPARATE SCREEN, not a section of Notifications. Notifications is a
/// record of what has happened; this is a forecast of what will. Mixing
/// them put a 60-item list of things that have NOT happened above the
/// handful that had, which is the wrong way round for a screen you open
/// to see what you missed.
///
/// DIAGNOSTICS LIVE HERE. The test-alert button and the OS pending-count
/// cross-check are both `!kReleaseMode` — they belong with the schedule
/// they interrogate, and neither is user content. The way IN to this
/// screen is not gated: seeing what is scheduled is ordinary.
///
/// TWO SOURCES for the count, shown separately and on purpose: the list
/// is a summary the app persisted (what it BELIEVES it asked for);
/// `pendingNotificationRequests()` is what the OS actually holds. When
/// they disagree, that disagreement is the useful part, so it is shown
/// rather than reconciled away.
library;

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../core/theme/type_scale.dart';
import '../data/settings_repository.dart';
import '../l10n/astro_l10n.dart';
import '../services/kundli_alert_service.dart';
import '../state/providers.dart';
import '../ui/common.dart';

/// Upcoming alerts from the last pass, soonest first.
///
/// The persisted summary records a pass and is not trimmed as entries
/// age out, so this filters rather than trusting the file — an alert
/// whose moment has passed belongs in the Past list, not here.
List<ScheduledAlertRecord> upcomingAlerts(
  AlertScheduleSummary? summary, {
  DateTime? now,
}) {
  final cutoff = now ?? DateTime.now();
  return [
    for (final a in summary?.byTime ?? const <ScheduledAlertRecord>[])
      if (a.when.isAfter(cutoff)) a
  ];
}

class ScheduledAlertsScreen extends ConsumerStatefulWidget {
  const ScheduledAlertsScreen({super.key});

  @override
  ConsumerState<ScheduledAlertsScreen> createState() =>
      _ScheduledAlertsScreenState();
}

class _ScheduledAlertsScreenState extends ConsumerState<ScheduledAlertsScreen> {
  bool _rebuilding = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final summary = ref.watch(alertScheduleSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.saTitle),
        actions: [
          IconButton(
            icon: _rebuilding
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: l10n.saRebuildNow,
            onPressed: _rebuilding ? null : _rebuild,
          ),
        ],
      ),
      body: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(message: l10n.saReadFailed('$e')),
        data: (data) {
          final upcoming = upcomingAlerts(data);
          if (upcoming.isEmpty) {
            return Column(
              children: [
                _header(data, 0),
                Expanded(child: EmptyState(message: l10n.naEmpty)),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              _header(data, upcoming.length),
              ..._byDay(upcoming),
            ],
          );
        },
      ),
      // Diagnostics, not user content: absent from the release binary
      // rather than merely hidden in it. A button that pushes a real
      // notification is a support ticket waiting to happen.
      bottomNavigationBar: kReleaseMode ? null : _testAlertBar(),
    );
  }

  /// "Computed <when> · N scheduled", plus the OS cross-check when the
  /// two disagree.
  Widget _header(AlertScheduleSummary summary, int count) {
    final l10n = context.l10n;
    final pending = ref.watch(alertPendingCountProvider).valueOrNull;
    // Two numbers that should match is a developer's question, not a
    // practitioner's.
    final mismatch = !kReleaseMode && pending != null && pending != count;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (summary.computedAt != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l10n.saComputedLine(
                  KJDate.dateCommaTime12(summary.computedAt!.toLocal()),
                  '$count'),
              style: TextStyle(fontSize: 12.5, color: KJColors.inkSoft),
            ),
          ),
        if (mismatch)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 14, color: KJColors.maroon),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    l10n.saCountMismatch('$count', '$pending'),
                    style: TextStyle(fontSize: 12, color: KJColors.maroon),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Day headers + cards, soonest first.
  List<Widget> _byDay(List<ScheduledAlertRecord> alerts) {
    final byDay = <String, List<ScheduledAlertRecord>>{};
    for (final a in alerts) {
      (byDay[KJDate.date(a.when.toLocal())] ??= []).add(a);
    }
    return [
      for (final entry in byDay.entries) ...[
        Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: KJSectionLabel(entry.key),
        ),
        Card(
          child: Column(
            children: [
              for (var i = 0; i < entry.value.length; i++) ...[
                if (i > 0) const Divider(height: 1),
                _alertRow(entry.value[i]),
              ],
            ],
          ),
        ),
      ],
    ];
  }

  Widget _alertRow(ScheduledAlertRecord a) => InkWell(
        onTap: a.kundliId.isEmpty
            ? null
            : () => context.push('/kundli/${a.kundliId}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 62,
                child: Text(
                  DateFormat('h:mm a').format(a.when.toLocal()),
                  style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.title,
                        style: KJTheme.serif(size: 14.5),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(a.body,
                        style: KJType.data(size: 12, color: KJColors.inkSoft)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _testAlertBar() => SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: _sendTest,
              icon: const Icon(Icons.notifications_active_outlined, size: 18),
              label: Text(context.l10n.saSendTest),
            ),
            const SizedBox(height: 4),
            Text(
              context.l10n.saSendTestNote('${kTestAlertDelay.inSeconds}'),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: KJColors.inkSoft),
            ),
          ],
        ),
      );

  /// Force a full scheduling pass now, skipping the app root's 2-second
  /// debounce — the whole point of the button is not to wait.
  Future<void> _rebuild() async {
    setState(() => _rebuilding = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    // No manual invalidation: AlertRefresher.run does it in a finally,
    // so every caller — this button, the app root's debounced pass —
    // refreshes identically. Two mechanisms doing the same job is how
    // one of them silently stops being maintained.
    final count = await ref.read(alertRefresherProvider).run();
    if (!mounted) return;
    setState(() => _rebuilding = false);
    messenger.showSnackBar(SnackBar(
      content:
          Text(count == null ? l10n.saRebuildFailed : l10n.saRebuilt('$count')),
    ));
  }

  Future<void> _sendTest() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    // Tapping the test should land somewhere useful when it can: a
    // followed chart's dashboard. With nothing followed the payload is
    // empty and the tap just opens the app.
    final followed = ref.read(followedKundlisProvider);
    final ok = await ref.read(kundliAlertServiceProvider).sendTestAlert(
          title: l10n.saTestTitle,
          body: l10n.saTestBody,
          payload: followed.isEmpty ? '' : followed.first,
        );
    ref.invalidate(alertPendingCountProvider);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(ok
          ? l10n.saTestScheduled('${kTestAlertDelay.inSeconds}')
          : l10n.saTestFailed),
    ));
  }
}

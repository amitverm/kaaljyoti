/// Screen 02 — Kundli List. Landing screen: saved kundlis with quick-
/// read chips (lagna/moon sign), sync tags, sign-in banner, "+ New"
/// (long-press → Prashna), notifications bell.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../data/models.dart';
import '../l10n/astro_l10n.dart';
import '../services/location_service.dart';
import '../state/providers.dart';
import '../ui/common.dart';

class KundliListScreen extends ConsumerWidget {
  const KundliListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final kundlis = ref.watch(kundlisProvider);
    final user = ref.watch(authUserProvider).value;

    return KJScaffold(
      section: KJSection.kundlis,
      appBar: AppBar(
        title: Text(l10n.kundlisTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () => context.push('/notifications'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onLongPress: () => _castPrashna(context, ref),
              child: FilledButton(
                onPressed: () => context.push('/new'),
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 8)),
                child: Text(l10n.plusNew),
              ),
            ),
          ),
        ],
      ),
      body: kundlis.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(message: l10n.klLoadError('$e')),
        data: (list) {
          if (list.isEmpty) {
            return Column(
              children: [
                Expanded(
                  child: EmptyState(
                    leading:
                        Image.asset('assets/emblem.png', width: 64, height: 64),
                    message: l10n.klEmpty,
                    actionLabel: l10n.newKundli,
                    onAction: () => context.push('/new'),
                  ),
                ),
                // Secondary, value-framed sign-in nudge — an account is
                // never required to cast charts (brief: value-driven,
                // not a login wall).
                if (user == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                    child: Column(
                      children: [
                        Text(
                          l10n.klRestoreNudge,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 12.5, color: KJColors.inkSoft),
                        ),
                        TextButton(
                          onPressed: () => context.push('/signin'),
                          child: Text(l10n.signIn),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  l10n.savedEncrypted(list.length),
                  style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
                ),
              ),
              if (user == null) _signInBanner(context),
              for (final k in list) _KundliRow(kundli: k),
              const SizedBox(height: 8),
              Center(
                child: Text(l10n.klLongPressPrashna,
                    style: KJTheme.mono(size: 10.5, color: KJColors.inkSoft)),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Instant Prashna: current place + current instant, chart shown
  /// immediately as an EPHEMERAL kundli — the dashboard offers
  /// Keep / Discard. Falls back to the manual form if location is
  /// unavailable.
  Future<void> _castPrashna(BuildContext context, WidgetRef ref) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(
      content: Text(l10n.klCastingPrashna),
      duration: const Duration(seconds: 10),
    ));
    try {
      final place = await LocationService().currentPlace();
      final now = DateTime.now();
      final kundli = await ref.read(kundliRepoProvider).create(
            name: l10n.klPrashnaName(
                DateFormat('d MMM, HH:mm', l10n.localeName).format(now)),
            relationTag: 'Prashna',
            birthUtc: now.toUtc(),
            latitude: place.latitude,
            longitude: place.longitude,
            timezoneName: place.timezoneName,
            utcOffsetMinutes: now.timeZoneOffset.inMinutes,
            placeName: place.displayName,
            isPrashna: true,
            isEphemeral: true,
          );
      messenger.hideCurrentSnackBar();
      ref.invalidate(kundlisProvider);
      if (context.mounted) context.push('/kundli/${kundli.id}');
    } on LocationDenied catch (denied) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(
        content: Text(denied.permanently
            ? l10n.klLocationDisabled
            : l10n.klLocationUnavailable),
      ));
      if (context.mounted) context.push('/new?prashna=1');
    } catch (_) {
      messenger.hideCurrentSnackBar();
      if (context.mounted) context.push('/new?prashna=1');
    }
  }

  Widget _signInBanner(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  context.l10n.signInBanner,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/signin'),
                child: Text(context.l10n.signIn),
              ),
            ],
          ),
        ),
      );
}

class _KundliRow extends ConsumerWidget {
  const _KundliRow({required this.kundli});
  final Kundli kundli;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final snapshot = ref.watch(snapshotProvider(kundli.id));
    final birthFmt = DateFormat('${KJDate.pref.datePattern} · HH:mm');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          ref.read(activeKundliIdProvider.notifier).state = kundli.id;
          context.push('/kundli/${kundli.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(kundli.name, style: KJTheme.serif(size: 18)),
                  ),
                  KJTag(relationTagLabel(l10n, kundli.relationTag)),
                  IconButton(
                    icon: Icon(Icons.edit_outlined,
                        size: 18, color: KJColors.inkSoft),
                    onPressed: () => context.push('/kundli/${kundli.id}/edit'),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              Text(
                '${birthFmt.format(kundli.toBirthData().localDateTime)} · '
                '${kundli.placeName}',
                style: TextStyle(fontSize: 12.5, color: KJColors.inkSoft),
              ),
              if (kundli.note != null && kundli.note!.trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    kundli.note!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        color: KJColors.inkSoft),
                  ),
                ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  snapshot.when(
                    data: (s) => KJTag(
                        '${l10n.labelLagna} ${s.lagnaSign.label(l10n)}',
                        maroon: true),
                    loading: () => KJTag('${l10n.labelLagna} …'),
                    error: (_, __) => KJTag('${l10n.labelLagna} ?'),
                  ),
                  snapshot.when(
                    data: (s) =>
                        KJTag('${l10n.planetMoon} ${s.moonSign.label(l10n)}'),
                    loading: () => KJTag('${l10n.planetMoon} …'),
                    error: (_, __) => KJTag('${l10n.planetMoon} ?'),
                  ),
                  if (kundli.isPrashna) KJTag(l10n.tagPrashna),
                  KJTag(kundli.syncEnabled ? l10n.synced : l10n.deviceOnly),
                  if (kundli.isSharedToMahakosh)
                    KJTag(context.l10n.klMahakoshTag(kundli.mahakoshCode!)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

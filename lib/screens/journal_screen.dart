/// Screen — Journal. The practitioner's own running record on a kundli:
/// dated, free-text observations from consultations, prediction follow-ups
/// and research notes.
///
/// Each entry freezes the astro context of the date it is ABOUT (running
/// dasha chain + transit sky), so a note read three years later still says
/// what was running when it was written — that is what separates a journal
/// from a text file. Backdating is first-class: practitioners write up
/// consultations after the fact, and the context follows the entry's date,
/// not the moment of typing.
///
/// Text only, deliberately: the OS keyboard's dictation key already gives
/// voice-to-text everywhere, so a speech plugin would add permissions and
/// binary size for something the platform hands us free.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/astro/journal_context.dart';
import '../core/astro/models.dart';
import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../data/models.dart';
import '../l10n/astro_l10n.dart';
import '../state/providers.dart';
import '../ui/common.dart';

class JournalScreen extends ConsumerWidget {
  const JournalScreen({super.key, required this.kundliId});
  final String kundliId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(journalEntriesProvider(kundliId));
    final kundli = ref.watch(kundliByIdProvider(kundliId)).value;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.jrTitle),
        actions: [
          if (kundli != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Text(
                  kundli.name,
                  style: KJTheme.mono(size: 11, color: KJColors.inkSoft),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add),
        label: Text(context.l10n.jrAdd),
      ),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(message: context.l10n.jrLoadError('$e')),
        data: (entries) {
          if (entries.isEmpty) {
            return EmptyState(
              message: context.l10n.jrEmpty,
              actionLabel: context.l10n.jrAdd,
              onAction: () => _openEditor(context, ref),
            );
          }
          final count = '${entries.length}';
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  (kundli?.syncEnabled ?? false)
                      ? context.l10n.jrCountSynced(count)
                      : context.l10n.jrCountLocal(count),
                  style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
                ),
              ),
              // The repository already returns newest-first — a journal is
              // read backwards from the latest observation.
              for (final e in entries)
                _EntryCard(
                  entry: e,
                  onTap: () => _openEditor(context, ref, existing: e),
                  onDelete: () => _confirmDelete(context, ref, e),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref,
      {JournalEntry? existing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: KJColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EntryEditor(kundliId: kundliId, existing: existing),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, JournalEntry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.jrDeleteTitle),
        content: Text(ctx.l10n.jrDeleteBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.l10n.delete,
                  style: TextStyle(color: KJColors.maroon))),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(journalRepoProvider).delete(e.id, kundliId: e.kundliId);
    ref.invalidate(journalEntriesProvider(kundliId));
    ref.read(syncServiceProvider)?.pushAll();
  }
}

/// Short chain token for a card — "Sa–Ve–Mo". Localized through the same
/// helpers the dasha timelines use, from the stable enum names stored on
/// the entry.
String journalDashaAbbr(AppLocalizations l10n, JournalContext ctx) => [
      for (final s in ctx.chain)
        s.planet?.abbrLabel(l10n) ?? s.sign?.abbrLabel(l10n) ?? '?',
    ].join('–');

/// Spelled-out chain for the chip's tooltip — "Mahadasha Saturn ·
/// Antardasha Venus · …".
String journalDashaFull(AppLocalizations l10n, JournalContext ctx) => [
      for (final s in ctx.chain)
        '${dashaLevelLabel(l10n, s.level)} '
                '${s.planet?.label(l10n) ?? s.sign?.fullLabel(l10n) ?? ''}'
            .trim(),
    ].join(' · ');

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.entry,
    required this.onTap,
    required this.onDelete,
  });
  final JournalEntry entry;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    // A missing or unreadable context is not an error state — the entry's
    // text is the content, the chips are enrichment.
    final ctx = JournalContext.decode(entry.contextJson);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(KJDate.date(entry.at),
                        style: KJTheme.serif(size: 15.5)),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(entry.text,
                          style: const TextStyle(fontSize: 13.5, height: 1.35)),
                    ),
                    if (ctx != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _chips(l10n, ctx),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 20, color: KJColors.inkSoft),
                tooltip: l10n.jrDeleteEntry,
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Dasha chain, Moon, and the two slow movers — the handful of things a
  /// practitioner actually correlates an observation against. The rest of
  /// the captured sky stays in the record for export and research rather
  /// than crowding the card.
  List<Widget> _chips(AppLocalizations l10n, JournalContext ctx) {
    final chips = <Widget>[];
    if (ctx.chain.isNotEmpty) {
      chips.add(Tooltip(
        message: journalDashaFull(l10n, ctx),
        child: KJTag(journalDashaAbbr(l10n, ctx), maroon: true),
      ));
    }
    final moonSign = ctx.moonSign;
    final moonNak = ctx.moonNakshatra;
    if (moonSign != null && moonNak != null) {
      chips.add(KJTag(l10n.jrMoonChip(
        Planet.moon.abbrLabel(l10n),
        moonSign.abbrLabel(l10n),
        moonNak.abbrLabel(l10n),
      )));
    }
    for (final p in const [Planet.jupiter, Planet.saturn]) {
      final sign = ctx.sky[p];
      if (sign != null) {
        chips.add(
            KJTag(l10n.jrTransitChip(p.abbrLabel(l10n), sign.abbrLabel(l10n))));
      }
    }
    return chips;
  }
}

/// Add / edit sheet. Persists directly and invalidates the list provider.
class _EntryEditor extends ConsumerStatefulWidget {
  const _EntryEditor({required this.kundliId, this.existing});
  final String kundliId;
  final JournalEntry? existing;

  @override
  ConsumerState<_EntryEditor> createState() => _EntryEditorState();
}

class _EntryEditorState extends ConsumerState<_EntryEditor> {
  final _textController = TextEditingController();
  late DateTime _date;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _date = e?.at ?? DateTime.now();
    _textController.text = e?.text ?? '';
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1800),
      lastDate: DateTime(2100),
      initialEntryMode: DatePickerEntryMode.input,
    );
    // Keep the time-of-day of the entry we started from, so re-picking the
    // same day doesn't silently move the entry to midnight.
    if (d != null) {
      setState(() =>
          _date = DateTime(d.year, d.month, d.day, _date.hour, _date.minute));
    }
  }

  /// Compute the astro context for [_date]. Never throws: an ephemeris or
  /// snapshot failure must cost the entry its chips, not its save.
  Future<String?> _captureContext() async {
    try {
      final snapshot = await ref.read(snapshotProvider(widget.kundliId).future);
      return buildJournalContext(snapshot: snapshot, at: _date).encode();
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _toast(context.l10n.jrNeedText);
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(journalRepoProvider);
    try {
      if (_isEdit) {
        final e = widget.existing!;
        // Recapture only when the date moved. Editing a typo must not risk
        // trading a good stored context for a null one if capture fails.
        final dateChanged = !e.at.isAtSameMomentAs(_date);
        final contextJson = dateChanged ? await _captureContext() : null;
        await repo.update(e.copyWith(
          at: _date,
          text: text,
          contextJson: contextJson,
          clearContextJson: dateChanged && contextJson == null,
        ));
      } else {
        await repo.create(
          kundliId: widget.kundliId,
          at: _date,
          text: text,
          contextJson: await _captureContext(),
        );
      }
      ref.invalidate(journalEntriesProvider(widget.kundliId));
      ref.read(syncServiceProvider)?.pushAll();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isEdit ? context.l10n.jrEditEntry : context.l10n.jrAdd,
                style: KJTheme.serif(size: 18)),
            const SizedBox(height: 14),
            _label(context.l10n.jrWhen),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.event, size: 18),
              label: Text(KJDate.date(_date)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _textController,
              textCapitalization: TextCapitalization.sentences,
              autofocus: !_isEdit,
              minLines: 4,
              maxLines: 12,
              decoration: InputDecoration(
                labelText: context.l10n.jrObservation,
                hintText: context.l10n.jrObservationHint,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.jrContextNote,
              style: TextStyle(fontSize: 11.5, color: KJColors.inkSoft),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving
                  ? context.l10n.jrSaving
                  : (_isEdit
                      ? context.l10n.jrSaveChanges
                      : context.l10n.jrSaveEntry)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: TextStyle(
                fontSize: 10.5,
                letterSpacing: 1.1,
                color: KJColors.inkSoft,
                fontWeight: FontWeight.w600)),
      );
}

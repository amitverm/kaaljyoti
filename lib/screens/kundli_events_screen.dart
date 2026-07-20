/// Screen — Life Events. A dedicated, per-kundli timeline of biographical
/// events (marriage, childbirth, career, …). Deliberately separate from the
/// dashboard, which is a GLOBAL lens shared by every chart; events are unique
/// to the native. Feeds prediction verification and Mahakosh contribution.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../data/models.dart';
import '../state/providers.dart';
import '../ui/common.dart';
import '../l10n/astro_l10n.dart';

class KundliEventsScreen extends ConsumerWidget {
  const KundliEventsScreen({super.key, required this.kundliId});
  final String kundliId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(kundliEventsProvider(kundliId));
    final kundli = ref.watch(kundliByIdProvider(kundliId)).value;
    final birthYear = kundli?.toBirthData().localDateTime.year;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.evTitle),
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
        label: Text(context.l10n.evAddEvent),
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(message: context.l10n.evLoadError('$e')),
        data: (events) {
          if (events.isEmpty) {
            return EmptyState(
              message: context.l10n.evEmpty,
              actionLabel: context.l10n.evAddEvent,
              onAction: () => _openEditor(context, ref),
            );
          }
          final sorted = [...events]..sort((a, b) {
              final da = a.sortDate(birthYear);
              final db = b.sortDate(birthYear);
              if (da == null && db == null) return 0;
              if (da == null) return 1;
              if (db == null) return -1;
              return da.compareTo(db);
            });
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${events.length} event${events.length == 1 ? '' : 's'}'
                  '${(kundli?.syncEnabled ?? false) ? ' · synced to your account' : ' · on this device'}',
                  style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft),
                ),
              ),
              for (final e in sorted)
                _EventCard(
                  event: e,
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
      {KundliEvent? existing}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: KJColors.paper,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EventEditor(kundliId: kundliId, existing: existing),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, KundliEvent e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.evDeleteTitle),
        content: Text(ctx.l10n.evDeleteBody(e.label)),
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
    await ref.read(kundliEventRepoProvider).delete(e.id, kundliId: e.kundliId);
    ref.invalidate(kundliEventsProvider(kundliId));
    ref.read(syncServiceProvider)?.pushAll();
  }
}

String eventDateLabel(AppLocalizations l10n, KundliEvent e) {
  switch (e.datePrecision) {
    case EventDatePrecision.age:
      return e.ageYears == null
          ? l10n.kevAgeUnknown
          : l10n.kevAge('${e.ageYears}');
    case EventDatePrecision.year:
      return e.eventDate == null ? '—' : '${e.eventDate!.year}';
    case EventDatePrecision.month:
      return e.eventDate == null
          ? '—'
          : DateFormat('MMM yyyy').format(e.eventDate!);
    case EventDatePrecision.exact:
      return e.eventDate == null ? '—' : KJDate.date(e.eventDate!);
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.onTap,
    required this.onDelete,
  });
  final KundliEvent event;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
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
                    Row(
                      children: [
                        Flexible(
                          child:
                              Text(event.label, style: KJTheme.serif(size: 16)),
                        ),
                        const SizedBox(width: 8),
                        KJTag(eventDateLabel(context.l10n, event),
                            maroon: true),
                      ],
                    ),
                    if (event.title != null && event.title!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(event.title!,
                            style: const TextStyle(fontSize: 13.5)),
                      ),
                    if (event.description != null &&
                        event.description!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          event.description!,
                          style: TextStyle(
                              fontSize: 12.5, color: KJColors.inkSoft),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 20, color: KJColors.inkSoft),
                tooltip: context.l10n.kevDeleteEvent,
                visualDensity: VisualDensity.compact,
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Add / edit sheet. Persists directly and invalidates the list provider.
class _EventEditor extends ConsumerStatefulWidget {
  const _EventEditor({required this.kundliId, this.existing});
  final String kundliId;
  final KundliEvent? existing;

  @override
  ConsumerState<_EventEditor> createState() => _EventEditorState();
}

class _EventEditorState extends ConsumerState<_EventEditor> {
  late EventCategory _category;
  late EventDatePrecision _precision;
  DateTime? _date;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _ageController = TextEditingController();
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  // Health is derived from the category, not a separate flag — the 'Health'
  // category IS the health signal (and drives Mahakosh's extra consent step).
  bool get _isHealth => _category == EventCategory.health;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _category = e?.categoryEnum ?? EventCategory.other;
    _precision = e?.datePrecision ?? EventDatePrecision.exact;
    _date = e?.eventDate;
    _titleController.text = e?.title ?? '';
    _descController.text = e?.description ?? '';
    _ageController.text = e?.ageYears?.toString() ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime(2000),
      firstDate: DateTime(1800),
      lastDate: DateTime(2100),
      initialEntryMode: DatePickerEntryMode.input,
    );
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    final ageYears = int.tryParse(_ageController.text.trim());
    // Validate the date/age that matches the chosen precision.
    if (_precision == EventDatePrecision.age) {
      if (ageYears == null || ageYears < 0 || ageYears > 150) {
        _toast(context.l10n.kevInvalidAge);
        return;
      }
    } else if (_date == null) {
      _toast(context.l10n.kevPickDate);
      return;
    }

    setState(() => _saving = true);
    final repo = ref.read(kundliEventRepoProvider);
    final isAge = _precision == EventDatePrecision.age;
    try {
      if (_isEdit) {
        final e = widget.existing!;
        await repo.update(e.copyWith(
          category: _category.name,
          clearCustomTag: true,
          title: _titleController.text.trim().isEmpty
              ? null
              : _titleController.text.trim(),
          clearTitle: _titleController.text.trim().isEmpty,
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          clearDescription: _descController.text.trim().isEmpty,
          eventDate: isAge ? null : _date,
          clearEventDate: isAge,
          datePrecision: _precision,
          ageYears: isAge ? ageYears : null,
          clearAgeYears: !isAge,
          isHealthRelated: _isHealth,
        ));
      } else {
        await repo.create(
          kundliId: widget.kundliId,
          category: _category.name,
          title: _titleController.text.trim().isEmpty
              ? null
              : _titleController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          eventDate: isAge ? null : _date,
          datePrecision: _precision,
          ageYears: isAge ? ageYears : null,
          isHealthRelated: _isHealth,
        );
      }
      ref.invalidate(kundliEventsProvider(widget.kundliId));
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
    final isAge = _precision == EventDatePrecision.age;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isEdit ? context.l10n.evEditEvent : context.l10n.evAddEvent,
                style: KJTheme.serif(size: 18)),
            const SizedBox(height: 14),
            // Compact dropdown rather than a 12-chip Wrap — mobile screens are
            // small, and 'Other' covers anything outside the curated set.
            DropdownButtonFormField<EventCategory>(
              value: _category,
              isExpanded: true,
              decoration: InputDecoration(labelText: context.l10n.evCategory),
              items: [
                for (final c in EventCategory.values)
                  DropdownMenuItem(
                      value: c,
                      child: Text(eventCategoryLabel(context.l10n, c))),
              ],
              onChanged: (c) => setState(() => _category = c ?? _category),
            ),
            const SizedBox(height: 16),
            _label(context.l10n.kevWhen),
            Wrap(
              spacing: 8,
              children: [
                for (final p in EventDatePrecision.values)
                  ChoiceChip(
                    label: Text(_precisionLabel(p)),
                    selected: _precision == p,
                    labelStyle: TextStyle(
                        color: _precision == p ? KJColors.paper : KJColors.ink),
                    onSelected: (_) => setState(() => _precision = p),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (isAge)
              TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: context.l10n.evAgeInYears,
                  hintText: context.l10n.evAgeHint,
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event, size: 18),
                label: Text(_date == null
                    ? context.l10n.evPickDate
                    : eventDateLabel(
                        context.l10n,
                        KundliEvent(
                          id: '',
                          kundliId: '',
                          eventDate: _date,
                          datePrecision: _precision,
                          createdAt: _date!,
                          updatedAt: _date!,
                        ))),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: context.l10n.evTitleOptional,
                hintText: context.l10n.evTitleHint,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: context.l10n.evNotesOptional,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.evPrivacyHint,
              style: TextStyle(fontSize: 11.5, color: KJColors.inkSoft),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving
                  ? context.l10n.kevSaving
                  : (_isEdit
                      ? context.l10n.kevSaveChanges
                      : context.l10n.kevAddEvent)),
            ),
          ],
        ),
      ),
    );
  }

  String _precisionLabel(EventDatePrecision p) => switch (p) {
        EventDatePrecision.exact => context.l10n.kevPrecisionExact,
        EventDatePrecision.month => context.l10n.kevPrecisionMonth,
        EventDatePrecision.year => context.l10n.kevPrecisionYear,
        EventDatePrecision.age => context.l10n.kevPrecisionAge,
      };

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

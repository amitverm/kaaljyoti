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
        title: const Text('Life Events'),
        actions: [
          if (kundli != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Center(
                child: Text(
                  kundli.name,
                  style: TETheme.mono(size: 11, color: TEColors.inkSoft),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add event'),
      ),
      body: eventsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(message: 'Could not load events: $e'),
        data: (events) {
          if (events.isEmpty) {
            return EmptyState(
              message:
                  'No events recorded yet. Add marriages, births, career '
                  'moves and other milestones — they power prediction '
                  'verification and can be shared to Mahakosh.',
              actionLabel: 'Add event',
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
                  style: TETheme.mono(size: 11.5, color: TEColors.inkSoft),
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
      backgroundColor: TEColors.paper,
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
        title: const Text('Delete this event?'),
        content: Text('"${e.label}" will be removed from this kundli.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  Text('Delete', style: TextStyle(color: TEColors.maroon))),
        ],
      ),
    );
    if (ok != true) return;
    await ref.read(kundliEventRepoProvider).delete(e.id, kundliId: e.kundliId);
    ref.invalidate(kundliEventsProvider(kundliId));
    ref.read(syncServiceProvider)?.pushAll();
  }
}

String eventDateLabel(KundliEvent e) {
  switch (e.datePrecision) {
    case EventDatePrecision.age:
      return e.ageYears == null ? 'Age —' : 'Age ${e.ageYears}';
    case EventDatePrecision.year:
      return e.eventDate == null ? '—' : '${e.eventDate!.year}';
    case EventDatePrecision.month:
      return e.eventDate == null
          ? '—'
          : DateFormat('MMM yyyy').format(e.eventDate!);
    case EventDatePrecision.exact:
      return e.eventDate == null
          ? '—'
          : TEDate.date(e.eventDate!);
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
                          child: Text(event.label,
                              style: TETheme.serif(size: 16)),
                        ),
                        const SizedBox(width: 8),
                        TETag(eventDateLabel(event), maroon: true),
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
                              fontSize: 12.5, color: TEColors.inkSoft),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 20, color: TEColors.inkSoft),
                tooltip: 'Delete event',
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
        _toast('Enter a valid age in years.');
        return;
      }
    } else if (_date == null) {
      _toast('Pick a date for this event.');
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

  void _toast(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

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
            Text(_isEdit ? 'Edit event' : 'Add event',
                style: TETheme.serif(size: 18)),
            const SizedBox(height: 14),
            // Compact dropdown rather than a 12-chip Wrap — mobile screens are
            // small, and 'Other' covers anything outside the curated set.
            DropdownButtonFormField<EventCategory>(
              value: _category,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                for (final c in EventCategory.values)
                  DropdownMenuItem(value: c, child: Text(c.label)),
              ],
              onChanged: (c) => setState(() => _category = c ?? _category),
            ),
            const SizedBox(height: 16),
            _label('WHEN'),
            Wrap(
              spacing: 8,
              children: [
                for (final p in EventDatePrecision.values)
                  ChoiceChip(
                    label: Text(_precisionLabel(p)),
                    selected: _precision == p,
                    labelStyle: TextStyle(
                        color: _precision == p ? TEColors.paper : TEColors.ink),
                    onSelected: (_) => setState(() => _precision = p),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (isAge)
              TextField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age in years',
                  hintText: 'e.g. 27',
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event, size: 18),
                label: Text(_date == null
                    ? 'Pick date'
                    : eventDateLabel(KundliEvent(
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
              decoration: const InputDecoration(
                labelText: 'Title (optional)',
                hintText: 'Short headline for this event',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              textCapitalization: TextCapitalization.sentences,
              minLines: 1,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'If this kundli is ever shared to Mahakosh, event titles and '
              'notes become visible to researchers — avoid names or other '
              'identifying details.',
              style: TextStyle(fontSize: 11.5, color: TEColors.inkSoft),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving
                  ? 'Saving…'
                  : (_isEdit ? 'Save changes' : 'Add event')),
            ),
          ],
        ),
      ),
    );
  }

  String _precisionLabel(EventDatePrecision p) => switch (p) {
        EventDatePrecision.exact => 'Exact date',
        EventDatePrecision.month => 'Month',
        EventDatePrecision.year => 'Year',
        EventDatePrecision.age => 'Age',
      };

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

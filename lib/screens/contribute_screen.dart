/// Screen 09 — Contribute + Consent. The governance-critical screen:
/// anonymization preview, explicit "My own / Someone else's" choice
/// (third-party consent branch), life events with a flagged
/// health-consent step, and the final consent checkbox.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/theme.dart';
import '../mahakosh/models.dart';
import '../state/providers.dart';
import '../ui/common.dart';

class ContributeScreen extends ConsumerStatefulWidget {
  const ContributeScreen({super.key, required this.kundliId});
  final String kundliId;

  @override
  ConsumerState<ContributeScreen> createState() => _ContributeScreenState();
}

class _ContributeScreenState extends ConsumerState<ContributeScreen> {
  bool _isOwn = true;
  bool _thirdPartyConsent = false;
  bool _mainConsent = false;
  bool _submitting = false;
  final List<LifeEventInput> _events = [];
  final _tagController = TextEditingController();
  final _noteController = TextEditingController();
  bool _eventIsHealth = false;
  DateTime? _eventDate;

  @override
  void initState() {
    super.initState();
    _loadStoredEvents();
  }

  /// Pre-fill from the kundli's stored life events so the astrologer doesn't
  /// re-type what they already recorded. Age-only events are anchored to the
  /// birth year for a usable date. Edits here affect only this submission —
  /// the permanent record lives on the kundli's Life Events screen.
  Future<void> _loadStoredEvents() async {
    final stored =
        await ref.read(kundliEventRepoProvider).forKundli(widget.kundliId);
    if (!mounted) return;
    setState(() {
      _events
        ..clear()
        ..addAll(lifeEventsFromStored(stored));
    });
  }

  Future<void> _submit() async {
    final repo = ref.read(mahakoshRepoProvider);
    if (repo == null) return;
    setState(() => _submitting = true);
    try {
      final snapshot =
          await ref.read(snapshotProvider(widget.kundliId).future);
      final kundli =
          await ref.read(kundliRepoProvider).byId(widget.kundliId);
      // Location generalized: keep only the trailing (country/region)
      // parts, never the exact place.
      final parts = kundli!.placeName.split(', ');
      final locationGeneral =
          parts.length >= 2 ? parts.sublist(parts.length - 2).join(', ') : '';

      final mkCode = await repo.contribute(
        snapshot: snapshot,
        isOwn: _isOwn,
        consentConfirmed: _mainConsent && (_isOwn || _thirdPartyConsent),
        events: _events,
        locationGeneral: locationGeneral,
      );
      await ref
          .read(kundliRepoProvider)
          .update(kundli.copyWith(mahakoshCode: mkCode));
      ref.invalidate(kundlisProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Chart contributed to Mahakosh · community research ($mkCode)')));
        context.go('/mahakosh');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not contribute: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  bool get _canSubmit =>
      _mainConsent && (_isOwn || _thirdPartyConsent) && !_submitting;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authUserProvider).value;
    final repo = ref.watch(mahakoshRepoProvider);

    if (repo == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Share to Mahakosh')),
        body: const EmptyState(
            message: 'Mahakosh needs the backend configured. '
                'See supabase/README.md.'),
      );
    }
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Share to Mahakosh')),
        body: EmptyState(
          message: 'Sign in to contribute charts to community research.',
          actionLabel: 'Sign in',
          onAction: () => context.push('/signin'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Share to Mahakosh')),
      body: ListView(
        padding: formPadding(context),
        children: [
          Text('This chart will be shared',
              style: TETheme.serif(size: 18)),
          Text('anonymously with the research community.',
              style: TextStyle(fontSize: 13.5, color: TEColors.inkSoft)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  _AnonRow('Name removed — never stored or shown'),
                  _AnonRow('Birth date & place are shown to researchers'),
                  _AnonRow('Exact birth time is used for calculations '
                      'but never displayed'),
                  _AnonRow('Life events you add are visible to '
                      'researchers'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('This is:',
              style: TextStyle(fontSize: 13.5, color: TEColors.inkSoft)),
          const SizedBox(height: 8),
          Row(
            children: [
              ChoiceChip(
                label: const Text('My own'),
                selected: _isOwn,
                labelStyle: TextStyle(
                    color: _isOwn ? TEColors.paper : TEColors.ink),
                onSelected: (_) => setState(() => _isOwn = true),
              ),
              const SizedBox(width: 10),
              ChoiceChip(
                label: const Text("Someone else's"),
                selected: !_isOwn,
                labelStyle: TextStyle(
                    color: !_isOwn ? TEColors.paper : TEColors.ink),
                onSelected: (_) => setState(() => _isOwn = false),
              ),
            ],
          ),
          if (!_isOwn)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: TEColors.maroon,
              value: _thirdPartyConsent,
              onChanged: (v) =>
                  setState(() => _thirdPartyConsent = v ?? false),
              title: const Text(
                'I confirm I have this person\'s consent to share their '
                'birth data for research',
                style: TextStyle(fontSize: 13),
              ),
            ),
          const Divider(height: 32),
          Text('Life events', style: TETheme.serif(size: 16)),
          const SizedBox(height: 4),
          Text(
            _events.isEmpty
                ? 'Dated, tagged events make a chart useful for pattern '
                    'research (e.g. Marriage · 2014, Career change · 2019).'
                : 'Pulled from this kundli\'s Life Events. Add more below for '
                    'this submission; manage them permanently on the kundli\'s '
                    'Life Events screen.',
            style: TextStyle(fontSize: 12.5, color: TEColors.inkSoft),
          ),
          const SizedBox(height: 10),
          for (final e in _events)
            Card(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                dense: true,
                title: Text(
                    '${e.tag}${e.eventDate != null ? ' · ${e.eventDate!.year}' : ''}'),
                subtitle: e.isHealthRelated
                    ? Text('Health-related event',
                        style: TextStyle(
                            fontSize: 11.5, color: TEColors.maroon))
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _events.remove(e)),
                ),
              ),
            ),
          TextField(
            controller: _tagController,
            decoration:
                const InputDecoration(hintText: 'e.g. Organ transplant'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration:
                const InputDecoration(hintText: 'Notes for researchers'),
          ),
          const SizedBox(height: 6),
          Text(
            'Event text is visible to researchers on the anonymized chart — '
            'don\'t include names, contact details, hospitals or other '
            'places, or anything that could identify a real person.',
            style: TextStyle(fontSize: 11.5, color: TEColors.inkSoft),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Checkbox(
                value: _eventIsHealth,
                activeColor: TEColors.maroon,
                onChanged: (v) =>
                    setState(() => _eventIsHealth = v ?? false),
              ),
              const Expanded(
                  child: Text('Health-related',
                      style: TextStyle(fontSize: 12.5))),
              TextButton(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => _eventDate = d);
                },
                child: Text(_eventDate == null
                    ? 'Date…'
                    : '${_eventDate!.year}'),
              ),
              TextButton(
                onPressed: () {
                  final tag = _tagController.text.trim();
                  if (tag.isEmpty) return;
                  setState(() {
                    _events.add(LifeEventInput(
                      tag: tag,
                      eventDate: _eventDate,
                      isHealthRelated: _eventIsHealth,
                      note: _noteController.text.trim(),
                    ));
                    _tagController.clear();
                    _noteController.clear();
                    _eventIsHealth = false;
                    _eventDate = null;
                  });
                },
                child: const Text('Add event'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: TEColors.maroon,
            value: _mainConsent,
            onChanged: (v) => setState(() => _mainConsent = v ?? false),
            title: const Text(
                'I consent to share this chart and the life events above — '
                'including any health-related ones — for community research',
                style: TextStyle(fontSize: 13.5)),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _canSubmit ? _submit : null,
            child: Text(
                _submitting ? 'Publishing…' : 'Publish to Mahakosh'),
          ),
          const SizedBox(height: 8),
          Text(
            'You can withdraw this chart at any time from Kundli Details.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: TEColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _AnonRow extends StatelessWidget {
  const _AnonRow(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.check, size: 15, color: TEColors.forest),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: const TextStyle(fontSize: 13.5)),
            ),
          ],
        ),
      );
}

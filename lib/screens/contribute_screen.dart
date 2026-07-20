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
import '../l10n/astro_l10n.dart';

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
    // Captured before the first await — context must not be used across
    // suspension points.
    final l10n = context.l10n;
    setState(() => _submitting = true);
    try {
      final snapshot = await ref.read(snapshotProvider(widget.kundliId).future);
      final kundli = await ref.read(kundliRepoProvider).byId(widget.kundliId);
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
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.cbContributed(mkCode))));
        context.go('/mahakosh');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.cbError('$e'))));
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
        appBar: AppBar(title: Text(context.l10n.cbTitle)),
        body: EmptyState(message: context.l10n.cbBackendMissing),
      );
    }
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.cbTitle)),
        body: EmptyState(
          message: context.l10n.cbSignInPrompt,
          actionLabel: context.l10n.signIn,
          onAction: () => context.push('/signin'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.cbTitle)),
      body: ListView(
        padding: formPadding(context),
        children: [
          Text(context.l10n.cbHeading, style: KJTheme.serif(size: 18)),
          Text(context.l10n.cbSubheading,
              style: TextStyle(fontSize: 13.5, color: KJColors.inkSoft)),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AnonRow(context.l10n.cbAnonName),
                  _AnonRow(context.l10n.cbAnonBirth),
                  _AnonRow(context.l10n.cbAnonTime),
                  _AnonRow(context.l10n.cbAnonEvents),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(context.l10n.cbThisIs,
              style: TextStyle(fontSize: 13.5, color: KJColors.inkSoft)),
          const SizedBox(height: 8),
          Row(
            children: [
              ChoiceChip(
                label: Text(context.l10n.myOwn),
                selected: _isOwn,
                labelStyle:
                    TextStyle(color: _isOwn ? KJColors.paper : KJColors.ink),
                onSelected: (_) => setState(() => _isOwn = true),
              ),
              const SizedBox(width: 10),
              ChoiceChip(
                label: Text(context.l10n.someoneElses),
                selected: !_isOwn,
                labelStyle:
                    TextStyle(color: !_isOwn ? KJColors.paper : KJColors.ink),
                onSelected: (_) => setState(() => _isOwn = false),
              ),
            ],
          ),
          if (!_isOwn)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: KJColors.maroon,
              value: _thirdPartyConsent,
              onChanged: (v) => setState(() => _thirdPartyConsent = v ?? false),
              title: Text(
                context.l10n.cbThirdPartyConsent,
                style: const TextStyle(fontSize: 13),
              ),
            ),
          const Divider(height: 32),
          Text(context.l10n.cbLifeEvents, style: KJTheme.serif(size: 16)),
          const SizedBox(height: 4),
          Text(
            _events.isEmpty
                ? context.l10n.cbEventsEmptyHint
                : context.l10n.cbEventsPulledHint,
            style: TextStyle(fontSize: 12.5, color: KJColors.inkSoft),
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
                    ? Text(context.l10n.cbHealthRelatedEvent,
                        style:
                            TextStyle(fontSize: 11.5, color: KJColors.maroon))
                    : null,
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => setState(() => _events.remove(e)),
                ),
              ),
            ),
          TextField(
            controller: _tagController,
            decoration: InputDecoration(hintText: context.l10n.cbTagHint),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: InputDecoration(hintText: context.l10n.cbNotesHint),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.cbEventPrivacyWarning,
            style: TextStyle(fontSize: 11.5, color: KJColors.inkSoft),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Checkbox(
                value: _eventIsHealth,
                activeColor: KJColors.maroon,
                onChanged: (v) => setState(() => _eventIsHealth = v ?? false),
              ),
              Expanded(
                  child: Text(context.l10n.cbHealthRelated,
                      style: const TextStyle(fontSize: 12.5))),
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
                    ? context.l10n.cbDate
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
                child: Text(context.l10n.cbAddEvent),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: KJColors.maroon,
            value: _mainConsent,
            onChanged: (v) => setState(() => _mainConsent = v ?? false),
            title: Text(context.l10n.cbMainConsent,
                style: const TextStyle(fontSize: 13.5)),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _canSubmit ? _submit : null,
            child: Text(_submitting
                ? context.l10n.cbPublishing
                : context.l10n.cbPublish),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.cbWithdrawNote,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: KJColors.inkSoft),
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
            Icon(Icons.check, size: 15, color: KJColors.forest),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: const TextStyle(fontSize: 13.5)),
            ),
          ],
        ),
      );
}

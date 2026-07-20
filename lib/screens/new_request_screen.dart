/// New research request — structured criteria (filter chips), not
/// free-form text (brief §2.7). Goes to the moderation queue.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../mahakosh/models.dart';
import '../state/providers.dart';
import '../ui/common.dart';
import '../l10n/astro_l10n.dart';
import 'research_board_screen.dart';

class NewRequestScreen extends ConsumerStatefulWidget {
  const NewRequestScreen({super.key});

  @override
  ConsumerState<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends ConsumerState<NewRequestScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final List<AtomicFilter> _criteria = [];
  bool _submitting = false;

  Future<void> _submit() async {
    final repo = ref.read(researchRepoProvider);
    if (repo == null || _criteria.isEmpty) return;
    // Captured before the first await — context must not be used across
    // suspension points.
    final l10n = context.l10n;
    setState(() => _submitting = true);
    try {
      await repo.submit(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        criteria: _criteria.length == 1
            ? _criteria.first
            : GroupFilter('AND', _criteria.cast<FilterNode>()),
      );
      ref.invalidate(researchBoardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.nrSubmitted)));
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.nrTitle)),
      body: ListView(
        padding: formPadding(context),
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
                labelText: context.l10n.nrTitleLabel,
                hintText: context.l10n.nrTitleHint),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: InputDecoration(
                labelText: context.l10n.nrPurpose,
                hintText: context.l10n.nrPurposeHint),
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.nrPrivacyHint,
            style: TextStyle(fontSize: 11.5, color: KJColors.inkSoft),
          ),
          const SizedBox(height: 20),
          Text(context.l10n.nrCriteriaSection,
              style: TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 1.1,
                  color: KJColors.inkSoft,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in _criteria)
                InputChip(
                  label: Text(mahakoshFilterLabel(context.l10n, f),
                      style: const TextStyle(fontSize: 12.5)),
                  onDeleted: () => setState(() => _criteria.remove(f)),
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: Text(context.l10n.nrAddCriterion),
                onPressed: _addCriterion,
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _criteria.isEmpty ||
                    _titleController.text.trim().isEmpty ||
                    _submitting
                ? null
                : _submit,
            child: Text(_submitting
                ? context.l10n.nrSubmitting
                : context.l10n.nrSubmit),
          ),
          const SizedBox(height: 10),
          Text(
            context.l10n.nrModerationNote,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: KJColors.inkSoft),
          ),
        ],
      ),
    );
  }

  Future<void> _addCriterion() async {
    // Minimal inline builder: planet-in-house and yoga/life-event tags.
    final planetController = ValueNotifier<Planet>(Planet.mars);
    final houseController = ValueNotifier<int>(7);
    await showModalBottomSheet(
      context: context,
      backgroundColor: KJColors.paper,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.nrAddCriterion, style: KJTheme.serif(size: 18)),
            const SizedBox(height: 12),
            ValueListenableBuilder(
              valueListenable: planetController,
              builder: (_, planet, __) => DropdownButtonFormField<Planet>(
                value: planet,
                decoration: InputDecoration(labelText: context.l10n.nrPlanet),
                items: [
                  for (final p in Planet.values)
                    DropdownMenuItem(
                        value: p,
                        child: Text(p.label(context.l10n),
                            style: TextStyle(color: planetInk(p)))),
                ],
                onChanged: (p) => planetController.value = p!,
              ),
            ),
            const SizedBox(height: 10),
            ValueListenableBuilder(
              valueListenable: houseController,
              builder: (_, house, __) => DropdownButtonFormField<int>(
                value: house,
                decoration:
                    InputDecoration(labelText: context.l10n.nrHouseFromLagna),
                items: [
                  for (var h = 1; h <= 12; h++)
                    DropdownMenuItem(
                        value: h, child: Text(context.l10n.nrHouseN('$h'))),
                ],
                onChanged: (v) => houseController.value = v!,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                setState(() => _criteria.add(AtomicFilter(
                      type: 'planet_in_house',
                      planet: planetController.value.name,
                      house: houseController.value,
                    )));
                Navigator.pop(ctx);
              },
              child: Text(context.l10n.nrAdd),
            ),
          ],
        ),
      ),
    );
  }
}

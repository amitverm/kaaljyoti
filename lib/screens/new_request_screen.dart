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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Request submitted — it goes live after a quick review.')));
        context.pop();
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Research Request')),
      body: ListView(
        padding: formPadding(context),
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Mars in 7H + Rahu dasha at marriage'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: const InputDecoration(
                labelText: 'Purpose',
                hintText:
                    'What pattern are you researching, and why?'),
          ),
          const SizedBox(height: 6),
          Text(
            'Title and purpose are shown publicly — don\'t include names, '
            'contact details, or anything that could identify a real '
            'person.',
            style: TextStyle(fontSize: 11.5, color: TEColors.inkSoft),
          ),
          const SizedBox(height: 20),
          Text('CRITERIA (structured — runs as a real query)',
              style: TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 1.1,
                  color: TEColors.inkSoft,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in _criteria)
                InputChip(
                  label: Text(f.label,
                      style: const TextStyle(fontSize: 12.5)),
                  onDeleted: () => setState(() => _criteria.remove(f)),
                ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: const Text('Add criterion'),
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
            child: Text(_submitting ? 'Submitting…' : 'Submit for review'),
          ),
          const SizedBox(height: 10),
          Text(
            'Requests are reviewed before going live — primarily to catch '
            'attempts to identify a specific known individual rather than '
            'genuine pattern research.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: TEColors.inkSoft),
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
      backgroundColor: TEColors.paper,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Add criterion', style: TETheme.serif(size: 18)),
            const SizedBox(height: 12),
            ValueListenableBuilder(
              valueListenable: planetController,
              builder: (_, planet, __) =>
                  DropdownButtonFormField<Planet>(
                value: planet,
                decoration: const InputDecoration(labelText: 'Planet'),
                items: [
                  for (final p in Planet.values)
                    DropdownMenuItem(
                        value: p,
                        child: Text(p.displayName,
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
                    const InputDecoration(labelText: 'House (from lagna)'),
                items: [
                  for (var h = 1; h <= 12; h++)
                    DropdownMenuItem(value: h, child: Text('${h}H')),
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
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

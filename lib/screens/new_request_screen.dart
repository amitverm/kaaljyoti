/// New research request — structured criteria (filter chips), not
/// free-form text (brief §2.7). Goes to the moderation queue.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/theme.dart';
import '../mahakosh/filter_builder_sheet.dart';
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
    if (repo == null) return;
    // Captured before the first await — context must not be used across
    // suspension points.
    final l10n = context.l10n;
    setState(() => _submitting = true);
    try {
      // Criteria is optional (the pattern may be exactly what's being
      // researched): without it the request relies on manual responses
      // instead of auto-matching.
      await repo.submit(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        criteria: switch (_criteria.length) {
          0 => null,
          1 => _criteria.first,
          _ => GroupFilter('AND', _criteria.cast<FilterNode>()),
        },
      );
      ref.invalidate(researchBoardProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.nrSubmitted)));
        context.pop();
      }
    } catch (e) {
      // Without this the failure is invisible: the async error is
      // unhandled and the button just flips back to "Submit".
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.nrSubmitFailed('$e'))));
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
            // Rebuild so the submit button enables as soon as a title
            // exists — criteria no longer gates it (and its setState no
            // longer serves as the accidental rebuild trigger).
            onChanged: (_) => setState(() {}),
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
          const SizedBox(height: 6),
          Text(
            context.l10n.nrCriteriaOptionalHint,
            style: TextStyle(fontSize: 11.5, color: KJColors.inkSoft),
          ),
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
            onPressed: _titleController.text.trim().isEmpty || _submitting
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
    // Same builder as Mahakosh search — the full filter vocabulary
    // (house/sign/nakshatra, yoga, life event, birth range), not just
    // planet-in-house.
    final filter = await showFilterBuilderSheet(context);
    if (filter != null) {
      setState(() => _criteria.add(filter));
    }
  }
}

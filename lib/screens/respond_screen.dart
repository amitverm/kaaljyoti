/// Screen 12 — Respond to Request. Tag one of the user's contributed
/// (or newly shared) charts against an open research request.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/theme.dart';
import '../state/providers.dart';
import '../ui/common.dart';
import '../l10n/astro_l10n.dart';
import 'request_detail_screen.dart';

class RespondScreen extends ConsumerStatefulWidget {
  const RespondScreen({super.key, required this.requestId});
  final String requestId;

  @override
  ConsumerState<RespondScreen> createState() => _RespondScreenState();
}

class _RespondScreenState extends ConsumerState<RespondScreen> {
  String? _selectedMkCode;
  bool _submitting = false;

  Future<void> _submit() async {
    final repo = ref.read(researchRepoProvider);
    if (repo == null || _selectedMkCode == null) return;
    setState(() => _submitting = true);
    try {
      await repo.respondWithChart(
        requestId: widget.requestId,
        mkCode: _selectedMkCode!,
      );
      ref.invalidate(requestMatchesProvider(widget.requestId));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.rsTagged)));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.l10n.rsError('$e'))));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kundlis = ref.watch(kundlisProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.rsTitle)),
      body: kundlis.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(message: context.l10n.uiGenericError('$e')),
        data: (list) {
          final shared = list.where((k) => k.isSharedToMahakosh).toList();
          final unshared = list.where((k) => !k.isSharedToMahakosh).toList();
          return ListView(
            padding: formPadding(context),
            children: [
              Text(
                context.l10n.rsPickChart,
                style: TextStyle(fontSize: 13.5, color: KJColors.inkSoft),
              ),
              const SizedBox(height: 14),
              if (shared.isEmpty)
                Text(context.l10n.rsNoSharedCharts,
                    style: TextStyle(fontSize: 13)),
              for (final k in shared)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: RadioListTile<String>(
                    value: k.mahakoshCode!,
                    groupValue: _selectedMkCode,
                    activeColor: KJColors.maroon,
                    title: Text('${k.name} · ${k.mahakoshCode}'),
                    subtitle: Text(context.l10n.rsSharedToMahakosh,
                        style: TextStyle(fontSize: 11.5)),
                    onChanged: (v) => setState(() => _selectedMkCode = v),
                  ),
                ),
              if (unshared.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  context.l10n.rsNotShared,
                  style: TextStyle(fontSize: 12.5, color: KJColors.inkSoft),
                ),
                for (final k in unshared)
                  Card(
                    margin: const EdgeInsets.only(top: 8),
                    child: ListTile(
                      title: Text(k.name),
                      trailing: TextButton(
                        onPressed: () =>
                            context.push('/kundli/${k.id}/contribute'),
                        child: Text(context.l10n.share),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed:
                    _selectedMkCode == null || _submitting ? null : _submit,
                child: Text(_submitting
                    ? context.l10n.rsTagging
                    : context.l10n.rsTagChart),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Screen 12 — Respond to Request. Tag one of the user's contributed
/// (or newly shared) charts against an open research request.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/theme.dart';
import '../state/providers.dart';
import '../ui/common.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Chart tagged against this request.')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Could not respond: $e')));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kundlis = ref.watch(kundlisProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Respond with a Chart')),
      body: kundlis.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(message: 'Error: $e'),
        data: (list) {
          final shared =
              list.where((k) => k.isSharedToMahakosh).toList();
          final unshared =
              list.where((k) => !k.isSharedToMahakosh).toList();
          return ListView(
            padding: formPadding(context),
            children: [
              Text(
                'Pick one of your Mahakosh-shared charts to tag against '
                'this research request. The requester sees it anonymized.',
                style: TextStyle(fontSize: 13.5, color: TEColors.inkSoft),
              ),
              const SizedBox(height: 14),
              if (shared.isEmpty)
                const Text('You have no shared charts yet.',
                    style: TextStyle(fontSize: 13)),
              for (final k in shared)
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: RadioListTile<String>(
                    value: k.mahakoshCode!,
                    groupValue: _selectedMkCode,
                    activeColor: TEColors.maroon,
                    title: Text('${k.name} · ${k.mahakoshCode}'),
                    subtitle: const Text('Shared to Mahakosh',
                        style: TextStyle(fontSize: 11.5)),
                    onChanged: (v) =>
                        setState(() => _selectedMkCode = v),
                  ),
                ),
              if (unshared.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Not shared yet — share a kundli first, then respond:',
                  style:
                      TextStyle(fontSize: 12.5, color: TEColors.inkSoft),
                ),
                for (final k in unshared)
                  Card(
                    margin: const EdgeInsets.only(top: 8),
                    child: ListTile(
                      title: Text(k.name),
                      trailing: TextButton(
                        onPressed: () =>
                            context.push('/kundli/${k.id}/contribute'),
                        child: const Text('Share…'),
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed:
                    _selectedMkCode == null || _submitting ? null : _submit,
                child: Text(_submitting ? 'Tagging…' : 'Tag chart'),
              ),
            ],
          );
        },
      ),
    );
  }
}

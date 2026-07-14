/// Shared "report this chart" bottom sheet + submit flow (§2.7b — App
/// Store Guideline 1.2 content reporting). Reachable from every place a
/// Mahakosh chart summary is shown: search/browse, the chart detail
/// screen, and research-request matches.
///
/// Reporting always also hides the chart from the reporter's own view
/// (via [MahakoshRepository.reportChart], reusing the §2.7a mechanism) —
/// a report shouldn't leave the reported content sitting in the
/// reporter's own feed while it's under review.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/theme.dart';
import '../state/providers.dart';

/// reason code -> user-facing label. Kept in sync with the
/// chart_reports.reason check constraint (0007_report_mahakosh_chart.sql).
const kReportReasons = {
  'deanonymization': 'Could identify a real, named person',
  'health_privacy': 'Sensitive health information shouldn’t be public',
  'harassment': 'Harassing, hateful, or abusive content',
  'spam': 'Spam or fake/test data',
  'other': 'Something else',
};

/// Opens the report sheet, submits the report (+ auto-hide) on confirm,
/// and shows a confirmation snackbar. [onReported] lets the caller
/// refresh/remove the row from its own list or pop back, mirroring how
/// the "Hide from my view" action is wired at each call site.
Future<void> showReportChartSheet(
  BuildContext context,
  WidgetRef ref,
  String mkCode, {
  VoidCallback? onReported,
}) async {
  final result = await showModalBottomSheet<(String, String)>(
    context: context,
    backgroundColor: TEColors.paper,
    isScrollControlled: true,
    builder: (ctx) => _ReportSheet(mkCode: mkCode),
  );
  if (result == null || !context.mounted) return;
  final (reason, details) = result;

  final repo = ref.read(mahakoshRepoProvider);
  if (repo == null) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await repo.reportChart(mkCode, reason: reason, details: details);
    onReported?.call();
    messenger.showSnackBar(SnackBar(content: Text(
        'Chart $mkCode reported and hidden from your view — our team '
        'will review it.')));
  } catch (e) {
    messenger
        .showSnackBar(SnackBar(content: Text('Could not report chart: $e')));
  }
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.mkCode});
  final String mkCode;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  String _reason = kReportReasons.keys.first;
  final _detailsController = TextEditingController();

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Report Chart ${widget.mkCode}',
              style: TETheme.serif(size: 18)),
          const SizedBox(height: 6),
          Text(
            'Sends the chart for review by our team and hides it from '
            'your own view right away. The contributor is never told who '
            'reported it.',
            style: TextStyle(fontSize: 12.5, color: TEColors.inkSoft),
          ),
          const SizedBox(height: 10),
          for (final e in kReportReasons.entries)
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: e.key,
              groupValue: _reason,
              activeColor: TEColors.maroon,
              title: Text(e.value, style: const TextStyle(fontSize: 13.5)),
              onChanged: (v) => setState(() => _reason = v!),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _detailsController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Additional details (optional)',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              (_reason, _detailsController.text.trim()),
            ),
            child: const Text('Submit report'),
          ),
        ],
      ),
    );
  }
}

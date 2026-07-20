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
import '../l10n/astro_l10n.dart';
import '../state/providers.dart';

/// reason code -> English fallback label. The reason CODES are the
/// persisted contract, kept in sync with the chart_reports.reason check
/// constraint (0007_report_mahakosh_chart.sql); the display strings come
/// from [reportReasonLabel]. Only the keys are load-bearing here.
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
    backgroundColor: KJColors.paper,
    isScrollControlled: true,
    builder: (ctx) => _ReportSheet(mkCode: mkCode),
  );
  if (result == null || !context.mounted) return;
  final (reason, details) = result;

  final repo = ref.read(mahakoshRepoProvider);
  if (repo == null) return;
  // Captured before the await — context must not be used across
  // suspension points.
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await repo.reportChart(mkCode, reason: reason, details: details);
    onReported?.call();
    messenger.showSnackBar(SnackBar(content: Text(l10n.rcReported(mkCode))));
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.rcReportError('$e'))));
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
          Text(context.l10n.rcTitle(widget.mkCode),
              style: KJTheme.serif(size: 18)),
          const SizedBox(height: 6),
          Text(
            context.l10n.rcBlurb,
            style: TextStyle(fontSize: 12.5, color: KJColors.inkSoft),
          ),
          const SizedBox(height: 10),
          for (final e in kReportReasons.entries)
            RadioListTile<String>(
              contentPadding: EdgeInsets.zero,
              dense: true,
              value: e.key,
              groupValue: _reason,
              activeColor: KJColors.maroon,
              title: Text(reportReasonLabel(context.l10n, e.key),
                  style: const TextStyle(fontSize: 13.5)),
              onChanged: (v) => setState(() => _reason = v!),
            ),
          const SizedBox(height: 8),
          TextField(
            controller: _detailsController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: context.l10n.rcDetails,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              (_reason, _detailsController.text.trim()),
            ),
            child: Text(context.l10n.rcSubmit),
          ),
        ],
      ),
    );
  }
}

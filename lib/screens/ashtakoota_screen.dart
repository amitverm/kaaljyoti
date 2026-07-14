/// Ashtakoota Guna Milan — a standalone two-kundli compare (menu
/// entry, not an AstroModule card, since it needs bride AND groom
/// kundlis rather than a single ModuleContext). Score dial, koota
/// table, Mangal Dosha check for both charts, PDF export.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/astro/guna_milan.dart';
import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../data/models.dart' show Kundli;
import '../modules/common.dart' show pdfInk, pdfInkSoft, pdfMaroon,
    pdfHairline, pdfBody, pdfSectionHeader, kjPdfCredit;
import '../state/providers.dart';
import '../ui/common.dart';

class AshtakootaScreen extends ConsumerStatefulWidget {
  const AshtakootaScreen({super.key});

  @override
  ConsumerState<AshtakootaScreen> createState() => _AshtakootaScreenState();
}

class _AshtakootaScreenState extends ConsumerState<AshtakootaScreen> {
  String? _brideId;
  String? _groomId;

  @override
  Widget build(BuildContext context) {
    final kundlis = ref.watch(kundlisProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Ashtakoota Guna Milan')),
      body: kundlis.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load kundlis: $e')),
        data: (list) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: _KundliPicker(
                    label: 'Bride',
                    kundlis: list,
                    value: _brideId,
                    onChanged: (id) => setState(() => _brideId = id),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KundliPicker(
                    label: 'Groom',
                    kundlis: list,
                    value: _groomId,
                    onChanged: (id) => setState(() => _groomId = id),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_brideId != null && _groomId != null)
              _MatchBody(brideId: _brideId!, groomId: _groomId!)
            else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'Choose both a bride and a groom kundli to see the match.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: TEColors.inkSoft),
                  ),
                ),
              ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _KundliPicker extends StatelessWidget {
  const _KundliPicker({
    required this.label,
    required this.kundlis,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<Kundli> kundlis;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TESectionLabel(label),
        const SizedBox(height: 4),
        DropdownButton<String?>(
          isExpanded: true,
          value: value,
          hint: const Text('Choose…'),
          items: [
            for (final k in kundlis)
              DropdownMenuItem<String?>(value: k.id, child: Text(k.name)),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _MatchBody extends ConsumerWidget {
  const _MatchBody({required this.brideId, required this.groomId});
  final String brideId;
  final String groomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bride = ref.watch(snapshotProvider(brideId));
    final groom = ref.watch(snapshotProvider(groomId));
    if (bride.isLoading || groom.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (bride.hasError) {
      return Text('Could not compute bride chart: ${bride.error}');
    }
    if (groom.hasError) {
      return Text('Could not compute groom chart: ${groom.error}');
    }
    final b = bride.value!;
    final g = groom.value!;
    final result = computeGunaMilan(b, g);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ModuleCard(
          title: 'Score',
          child: _ScoreDial(result: result),
        ),
        const SizedBox(height: 12),
        ModuleCard(
          title: 'Koota breakdown',
          child: _KootaTable(result: result),
        ),
        const SizedBox(height: 12),
        ModuleCard(
          title: 'Mangal Dosha',
          child: _MangalDoshaSection(result: result),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            onPressed: () => _exportPdf(context, b, g, result),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Export PDF'),
          ),
        ),
      ],
    );
  }

  Future<void> _exportPdf(BuildContext context, AstroSnapshot bride,
      AstroSnapshot groom, GunaMilanResult result) async {
    final doc = pw.Document(
      title: 'Ashtakoota Guna Milan',
      producer: 'Kaal Jyoti',
    );
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        footer: (context) => context.pageNumber == context.pagesCount
            ? pw.Container(
                margin: const pw.EdgeInsets.only(top: 8),
                child: kjPdfCredit(),
              )
            : pw.SizedBox(),
        build: (_) => [
          pw.Text('KAAL JYOTI',
              style: pw.TextStyle(
                  fontSize: 11, letterSpacing: 4, color: pdfInkSoft)),
          pw.SizedBox(height: 6),
          pw.Text('Ashtakoota Guna Milan',
              style: pw.TextStyle(
                  fontSize: 22,
                  color: pdfInk,
                  fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(
            '${result.total.toStringAsFixed(1)} / ${GunaMilanResult.maxTotal.toStringAsFixed(0)}'
            ' — ${result.verdict}',
            style: pw.TextStyle(fontSize: 14, color: pdfMaroon),
          ),
          pdfSectionHeader('Koota breakdown'),
          pw.TableHelper.fromTextArray(
            headers: const ['Koota', 'Points', 'Max', 'Notes'],
            data: [
              for (final k in result.kootas)
                [
                  k.name,
                  k.points % 1 == 0
                      ? k.points.toStringAsFixed(0)
                      : k.points.toStringAsFixed(1),
                  k.maxPoints.toStringAsFixed(0),
                  k.note ?? '',
                ],
            ],
            headerStyle: pw.TextStyle(
                fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: pdfInkSoft),
            cellStyle: pdfBody(size: 9.5),
            border: null,
            headerDecoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: pdfInk, width: 0.8)),
            ),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: pdfHairline, width: 0.5)),
            ),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
          ),
          pdfSectionHeader('Mangal Dosha (Kuja Dosha)'),
          pw.Text(
            'Bride: ${result.brideMangalDosha ? 'Present' : 'Not present'}   '
            'Groom: ${result.groomMangalDosha ? 'Present' : 'Not present'}',
            style: pdfBody(size: 10.5),
          ),
          if (result.mangalDoshaMismatch)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                'Mismatch — one chart has Mangal Dosha and the other '
                'does not; classically this is checked further before '
                'ruling the match in or out (mutual cancellation rules, '
                'mitigating dignity, etc.).',
                style: pw.TextStyle(fontSize: 9, color: pdfInkSoft),
              ),
            ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Checks Mars in 1/2/4/7/8/12 from both Lagna and Moon. '
            'Ashtakoota tables per guna_milan.dart doc comments — not '
            'validated against a printed reference; cross-check before '
            'relying on this for consultations.',
            style: pw.TextStyle(fontSize: 7.5, color: pdfInkSoft),
          ),
        ],
      ),
    );
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'ashtakoota_guna_milan.pdf',
    );
  }
}

class _ScoreDial extends StatelessWidget {
  const _ScoreDial({required this.result});
  final GunaMilanResult result;

  @override
  Widget build(BuildContext context) {
    final frac = (result.total / GunaMilanResult.maxTotal).clamp(0.0, 1.0);
    final color = switch (result.verdict) {
      'Excellent' => TEColors.forest,
      'Good' => TEColors.forest,
      'Average' => TEColors.maroon,
      _ => TEColors.maroon,
    };
    return Row(
      children: [
        SizedBox(
          width: 84,
          height: 84,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: CircularProgressIndicator(
                  value: frac,
                  strokeWidth: 8,
                  backgroundColor: TEColors.paperAlt,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Text(
                '${result.total.toStringAsFixed(1)}',
                style: TETheme.serif(size: 20, color: color),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${result.total.toStringAsFixed(1)} / '
                '${GunaMilanResult.maxTotal.toStringAsFixed(0)}',
                style: TETheme.serif(size: 18),
              ),
              const SizedBox(height: 4),
              TETag(result.verdict, maroon: color == TEColors.maroon),
            ],
          ),
        ),
      ],
    );
  }
}

class _KootaTable extends StatelessWidget {
  const _KootaTable({required this.result});
  final GunaMilanResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final k in result.kootas)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(k.name,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600)),
                ),
                SizedBox(
                  width: 64,
                  child: Text(
                    '${k.points % 1 == 0 ? k.points.toStringAsFixed(0) : k.points.toStringAsFixed(1)} / ${k.maxPoints.toStringAsFixed(0)}',
                    style: TETheme.mono(
                      size: 12,
                      color: k.points >= k.maxPoints
                          ? TEColors.forest
                          : (k.points == 0 ? TEColors.maroon : TEColors.inkSoft),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    k.note ?? '',
                    style: TextStyle(fontSize: 12, color: TEColors.inkSoft),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _MangalDoshaSection extends StatelessWidget {
  const _MangalDoshaSection({required this.result});
  final GunaMilanResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 80,
              child: Text('Bride',
                  style: TETheme.mono(size: 11.5, color: TEColors.inkSoft)),
            ),
            TETag(result.brideMangalDosha ? 'Present' : 'Not present',
                maroon: result.brideMangalDosha),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 80,
              child: Text('Groom',
                  style: TETheme.mono(size: 11.5, color: TEColors.inkSoft)),
            ),
            TETag(result.groomMangalDosha ? 'Present' : 'Not present',
                maroon: result.groomMangalDosha),
          ],
        ),
        if (result.mangalDoshaMismatch) ...[
          const SizedBox(height: 10),
          Text(
            'Mismatch — classically checked further (mutual cancellation, '
            'mitigating dignity) before ruling the match in or out.',
            style: TextStyle(fontSize: 12, color: TEColors.maroon),
          ),
        ],
      ],
    );
  }
}

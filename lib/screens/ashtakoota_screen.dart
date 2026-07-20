/// Ashtakoota Guna Milan — a standalone two-kundli compare (menu
/// entry, not an AstroModule card, since it needs bride AND groom
/// kundlis rather than a single ModuleContext). Score dial, koota
/// table, Mangal Dosha check for both charts, PDF export.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import '../pdf/pw.dart' as pw;
import 'package:printing/printing.dart';

import '../core/astro/guna_milan.dart';
import '../core/astro/models.dart';
import '../core/theme/theme.dart';
import '../data/models.dart' show Kundli;
import '../modules/common.dart'
    show
        pdfInk,
        pdfInkSoft,
        pdfMaroon,
        pdfHairline,
        pdfBody,
        pdfSectionHeader,
        pdfTheme,
        kjPdfCredit;
import '../state/providers.dart';
import '../ui/common.dart';
import '../l10n/astro_l10n.dart';

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
      appBar: AppBar(title: Text(context.l10n.akTitle)),
      body: kundlis.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(context.l10n.klLoadError('$e'))),
        data: (list) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(
                  child: _KundliPicker(
                    label: context.l10n.akBride,
                    kundlis: list,
                    value: _brideId,
                    onChanged: (id) => setState(() => _brideId = id),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KundliPicker(
                    label: context.l10n.akGroom,
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
                    context.l10n.akChooseBoth,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: KJColors.inkSoft),
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
        KJSectionLabel(label),
        const SizedBox(height: 4),
        DropdownButton<String?>(
          isExpanded: true,
          value: value,
          hint: Text(context.l10n.akChoose),
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
      return Text(context.l10n.akBrideError('${bride.error}'));
    }
    if (groom.hasError) {
      return Text(context.l10n.akGroomError('${groom.error}'));
    }
    final b = bride.value!;
    final g = groom.value!;
    final result = computeGunaMilan(b, g);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ModuleCard(
          title: context.l10n.akScore,
          child: _ScoreDial(result: result),
        ),
        const SizedBox(height: 12),
        ModuleCard(
          title: context.l10n.akKootaBreakdown,
          child: _KootaTable(result: result),
        ),
        const SizedBox(height: 12),
        ModuleCard(
          title: context.l10n.akMangalDosha,
          child: _MangalDoshaSection(result: result),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            onPressed: () => _exportPdf(context, b, g, result),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: Text(context.l10n.akExportPdf),
          ),
        ),
      ],
    );
  }

  Future<void> _exportPdf(BuildContext context, AstroSnapshot bride,
      AstroSnapshot groom, GunaMilanResult result) async {
    final l10n = context.l10n;
    final doc = pw.Document(
      title: l10n.akTitle,
      producer: 'Kaal Jyoti',
      // Same theme as the main exporter — without it this document
      // renders in the built-in non-Unicode Helvetica, which warns on
      // "—"/"·" and covers nothing past Latin-1. This PDF prints no
      // names, so the UI language's own script is the whole sample.
      theme: await pdfTheme(scriptSample: l10n.languageEndonym),
    );
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        footer: (context) => context.pageNumber == context.pagesCount
            ? pw.Container(
                margin: const pw.EdgeInsets.only(top: 8),
                child: kjPdfCredit(l10n),
              )
            : pw.SizedBox(),
        build: (_) => [
          pw.Text('KAAL JYOTI',
              style: pw.TextStyle(
                  fontSize: 11, letterSpacing: 4, color: pdfInkSoft)),
          pw.SizedBox(height: 6),
          pw.Text(l10n.akTitle,
              style: pw.TextStyle(
                  fontSize: 22, color: pdfInk, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(
            l10n.akPdfScore(
              result.total.toStringAsFixed(1),
              GunaMilanResult.maxTotal.toStringAsFixed(0),
              result.verdict.label(l10n),
            ),
            style: pw.TextStyle(fontSize: 14, color: pdfMaroon),
          ),
          pdfSectionHeader(l10n.akKootaBreakdown),
          pw.TableHelper.fromTextArray(
            headers: [
              l10n.akColKoota,
              l10n.akColPoints,
              l10n.akColMax,
              l10n.akColNotes,
            ],
            data: [
              for (final k in result.kootas)
                [
                  k.koota.label(l10n),
                  k.points % 1 == 0
                      ? k.points.toStringAsFixed(0)
                      : k.points.toStringAsFixed(1),
                  k.maxPoints.toStringAsFixed(0),
                  k.note ?? '',
                ],
            ],
            headerStyle: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: pdfInkSoft),
            cellStyle: pdfBody(size: 9.5),
            border: null,
            headerDecoration: const pw.BoxDecoration(
              border:
                  pw.Border(bottom: pw.BorderSide(color: pdfInk, width: 0.8)),
            ),
            rowDecoration: const pw.BoxDecoration(
              border: pw.Border(
                  bottom: pw.BorderSide(color: pdfHairline, width: 0.5)),
            ),
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
          ),
          pdfSectionHeader(l10n.akMangalDoshaFull),
          pw.Text(
            l10n.akMangalLine(
              result.brideMangalDosha ? l10n.akPresent : l10n.akNotPresent,
              result.groomMangalDosha ? l10n.akPresent : l10n.akNotPresent,
            ),
            style: pdfBody(size: 10.5),
          ),
          if (result.mangalDoshaMismatch)
            pw.Padding(
              padding: const pw.EdgeInsets.only(top: 4),
              child: pw.Text(
                l10n.akMangalMismatch,
                style: pw.TextStyle(fontSize: 9, color: pdfInkSoft),
              ),
            ),
          pw.SizedBox(height: 8),
          pw.Text(
            l10n.akPdfDisclaimer,
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
      GunaVerdict.excellent || GunaVerdict.good => KJColors.forest,
      GunaVerdict.average || GunaVerdict.notRecommended => KJColors.maroon,
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
                  backgroundColor: KJColors.paperAlt,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              Text(
                '${result.total.toStringAsFixed(1)}',
                style: KJTheme.serif(size: 20, color: color),
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
                style: KJTheme.serif(size: 18),
              ),
              const SizedBox(height: 4),
              KJTag(result.verdict.label(context.l10n),
                  maroon: color == KJColors.maroon),
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
                  child: Text(k.koota.label(context.l10n),
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600)),
                ),
                SizedBox(
                  width: 64,
                  child: Text(
                    '${k.points % 1 == 0 ? k.points.toStringAsFixed(0) : k.points.toStringAsFixed(1)} / ${k.maxPoints.toStringAsFixed(0)}',
                    style: KJTheme.mono(
                      size: 12,
                      color: k.points >= k.maxPoints
                          ? KJColors.forest
                          : (k.points == 0
                              ? KJColors.maroon
                              : KJColors.inkSoft),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    k.note ?? '',
                    style: TextStyle(fontSize: 12, color: KJColors.inkSoft),
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
              child: Text(context.l10n.akBride,
                  style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft)),
            ),
            KJTag(
                result.brideMangalDosha
                    ? context.l10n.akPresent
                    : context.l10n.akNotPresent,
                maroon: result.brideMangalDosha),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              width: 80,
              child: Text(context.l10n.akGroom,
                  style: KJTheme.mono(size: 11.5, color: KJColors.inkSoft)),
            ),
            KJTag(
                result.groomMangalDosha
                    ? context.l10n.akPresent
                    : context.l10n.akNotPresent,
                maroon: result.groomMangalDosha),
          ],
        ),
        if (result.mangalDoshaMismatch) ...[
          const SizedBox(height: 10),
          Text(
            context.l10n.akMangalMismatchScreen,
            style: TextStyle(fontSize: 12, color: KJColors.maroon),
          ),
        ],
      ],
    );
  }
}

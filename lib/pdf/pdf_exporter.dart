/// PDF export (brief §2.9): loops over the registry of enabled
/// modules and renders each module's pdfView — the exporter knows
/// nothing about module internals. Free on every plan.
library;

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/astro/ayanamsa.dart';
import '../core/date_format.dart';
import '../modules/common.dart';
import '../widgetsystem/astro_module.dart';
import '../widgetsystem/registry.dart';

enum PdfPaper { a4, letter }

/// One exported block: a module type + its instance config (so three
/// divisional-chart instances export as D3, D7, D9 — not one D9).
typedef PdfBlock = ({String widgetId, Map<String, dynamic> config});

class PdfExportOptions {
  const PdfExportOptions({
    required this.blocks, // ordered, pre-checked from dashboard config
    this.paper = PdfPaper.a4,
    this.coverPage = true,
    this.brandingFooter, // Pro/practitioner branding line (optional)
  });

  final List<PdfBlock> blocks;
  final PdfPaper paper;
  final bool coverPage;
  final String? brandingFooter;
}

class PdfExporter {
  Future<void> exportAndShare(
    ModuleContext ctx,
    PdfExportOptions options,
  ) async {
    final doc = await _build(ctx, options);
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename:
          '${ctx.kundli.name.replaceAll(RegExp(r'\s+'), '_')}_kundli.pdf',
    );
  }

  Future<void> printDialog(
    ModuleContext ctx,
    PdfExportOptions options,
  ) async {
    await Printing.layoutPdf(
      onLayout: (_) async => (await _build(ctx, options)).save(),
    );
  }

  Future<pw.Document> _build(
      ModuleContext ctx, PdfExportOptions options) async {
    // Embed real fonts: the built-in Helvetica is a non-Unicode Type1
    // font (console warnings for — · etc.), and embedding IBM Plex +
    // Marcellus makes the report match the app's brand. Fonts are
    // cached by `printing` after the first fetch; if unavailable
    // (offline first run), fall back to the defaults.
    pw.ThemeData? theme;
    pw.Font? display;
    try {
      final base = await PdfGoogleFonts.iBMPlexSansRegular();
      final bold = await PdfGoogleFonts.iBMPlexSansBold();
      final italic = await PdfGoogleFonts.iBMPlexSansItalic();
      display = await PdfGoogleFonts.marcellusRegular();
      theme = pw.ThemeData.withFont(
          base: base, bold: bold, italic: italic);
    } catch (_) {
      // Offline without cached fonts — export still works.
    }

    final doc = pw.Document(
      title: '${ctx.kundli.name} — Kundli',
      producer: 'Kaal Jyoti',
      theme: theme,
    );
    final format = options.paper == PdfPaper.a4
        ? PdfPageFormat.a4
        : PdfPageFormat.letter;
    final birthFmt = DateFormat('${TEDate.pref.datePattern} · HH:mm');

    if (options.coverPage) {
      doc.addPage(
        pw.Page(
          pageFormat: format,
          build: (_) => pw.Container(
            color: const PdfColor.fromInt(0xFFFCFAF4),
            child: pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Text('KAAL JYOTI',
                      style: pw.TextStyle(
                          fontSize: 11,
                          letterSpacing: 4,
                          color: pdfInkSoft)),
                  pw.SizedBox(height: 24),
                  pw.Text(ctx.kundli.name,
                      style: pw.TextStyle(
                          font: display, fontSize: 32, color: pdfInk)),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    birthFmt
                        .format(ctx.kundli.toBirthData().localDateTime),
                    style: pw.TextStyle(fontSize: 12, color: pdfInkSoft),
                  ),
                  pw.Text(ctx.kundli.placeName,
                      style:
                          pw.TextStyle(fontSize: 12, color: pdfInkSoft)),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    '${Ayanamsa.byId(ctx.snapshot.ayanamsaId).name} ayanamsa',
                    style: pw.TextStyle(fontSize: 9, color: pdfInkSoft),
                  ),
                  if (options.brandingFooter != null) ...[
                    pw.SizedBox(height: 48),
                    pw.Text(options.brandingFooter!,
                        style: pw.TextStyle(
                            fontSize: 10, color: pdfMaroon)),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    }

    // The exporter loops over enabled module instances — same contract
    // as the dashboard and customizer, config-aware per instance. Each
    // module hands back a LIST of top-level widgets so MultiPage can
    // paginate between them and split long tables.
    final blocks = <pw.Widget>[
      for (final block in options.blocks)
        if (moduleRegistry.containsKey(block.widgetId))
          ...moduleRegistry[block.widgetId]!
              .pdfView(ctx.withConfig(block.config)),
    ];

    doc.addPage(
      pw.MultiPage(
        pageFormat: format,
        maxPages: 80,
        margin: const pw.EdgeInsets.all(36),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    options.brandingFooter ?? 'Kaal Jyoti',
                    style: pw.TextStyle(fontSize: 8, color: pdfInkSoft),
                  ),
                  pw.Text('${context.pageNumber} / ${context.pagesCount}',
                      style: pw.TextStyle(fontSize: 8, color: pdfInkSoft)),
                ],
              ),
              if (context.pageNumber == context.pagesCount)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 3),
                  child: kjPdfCredit(),
                ),
            ],
          ),
        ),
        build: (_) => blocks,
      ),
    );

    return doc;
  }
}

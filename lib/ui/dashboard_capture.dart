/// The dashboard board as a single shareable image.
///
/// A deliberately plain re-render of the active view: the same packed
/// rows and the same module cards the user is looking at, minus every
/// affordance that means nothing in a PNG (drag handles, the per-widget
/// menu, detail arrows, the add-widgets button), plus a header giving
/// the chart's birth details and a footer naming the app.
///
/// It takes plain data rather than watching providers — the capture
/// happens in a throwaway overlay subtree (see [captureLongWidget]),
/// and a pure widget is also what lets a test build the board directly.
library;

import 'package:flutter/material.dart';

import '../core/date_format.dart';
import '../core/theme/theme.dart';
import '../data/models.dart';
import '../l10n/astro_l10n.dart';
import '../widgetsystem/astro_module.dart';
import '../widgetsystem/registry.dart';
import 'common.dart';
import 'dashboard_layout.dart';

class DashboardCaptureView extends StatelessWidget {
  const DashboardCaptureView({
    super.key,
    required this.kundli,
    required this.moduleCtx,
    required this.placed,
    required this.width,
  });

  final Kundli kundli;
  final ModuleContext moduleCtx;

  /// The active view's widgets, in board order.
  final List<PlacedWidget> placed;

  /// Logical width the image is rendered at — also what decides the
  /// three-column breakpoint, so a tablet screenshot looks like the
  /// tablet board and a phone one like the phone board.
  final double width;

  @override
  Widget build(BuildContext context) {
    final isWide = width >= 720;
    // An id left behind by an uninstalled/renamed module has no card to
    // draw; drop it before packing so it doesn't reserve empty space.
    final known = placed
        .where((p) => moduleById(p.widgetId) != null)
        .toList(growable: false);
    final rows = packDashboardRows(known, isWide: isWide);

    return Container(
      width: width,
      color: KJColors.paper,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(context),
          const SizedBox(height: 14),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < row.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(
                      flex: spanUnits(row[i].span, isWide: isWide),
                      child: _card(context, row[i]),
                    ),
                  ],
                  // Blank remainder of an incomplete row — without it the
                  // last card would stretch and stop matching the board.
                  if (rowUnits(row, isWide: isWide) < 6) ...[
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 6 - rowUnits(row, isWide: isWide),
                      child: const SizedBox(),
                    ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 2),
          _footer(context),
        ],
      ),
    );
  }

  /// Birth details only — deliberately no name.
  ///
  /// This image is made to be sent to someone else, and once it leaves
  /// there is no redacting it: no crop step, no edit, no recall. Whoever
  /// the chart is for can say whose it is; the file shouldn't say it for
  /// them.
  Widget _header(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          KJDate.dateDotTime(kundli.toBirthData().localDateTime),
          style: KJTheme.mono(size: 11, color: KJColors.inkSoft),
        ),
        if (kundli.placeName.trim().isNotEmpty)
          Text(
            kundli.placeName,
            style: TextStyle(fontSize: 11.5, color: KJColors.inkSoft),
          ),
      ],
    );
  }

  Widget _footer(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(context.l10n.appTitle, style: KJTheme.serif(size: 13)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'kaaljyoti.com',
            style: KJTheme.mono(size: 9.5, color: KJColors.inkSoft),
          ),
        ),
      ],
    );
  }

  Widget _card(BuildContext context, PlacedWidget pwd) {
    final module = moduleById(pwd.widgetId)!;
    return ModuleCard(
      title: moduleInstanceTitle(module, pwd.config, context.l10n),
      child: module.cardView(context, moduleCtx.withConfig(pwd.config)),
    );
  }
}

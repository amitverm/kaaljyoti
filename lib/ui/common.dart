/// Shared UI: the floating text-first pill nav (deliberately not a
/// generic icon tab bar), the KUNDLIS/MAHAKOSH/RESEARCH switcher, the
/// dashboard card chrome, and small shared pieces.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/theme.dart';
import '../core/theme/tokens.dart';
import '../core/theme/type_scale.dart';
import '../l10n/astro_l10n.dart';

/// The one uppercase section eyebrow used across the app — Mono / Kicker
/// per the type handout (Plex Mono 500, 10px, +0.18em tracking, muted
/// ink). Replaces the eight hand-rolled copies that had drifted on size
/// and letter-spacing. The label is uppercased for you.
class KJSectionLabel extends StatelessWidget {
  const KJSectionLabel(this.label,
      {super.key, this.color, this.padded = false});

  final String label;
  final Color? color;

  /// Adds a small bottom gap — for use directly above a form field,
  /// list, or control group.
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final text = Text(label.toUpperCase(), style: KJType.kicker(color: color));
    if (!padded) return text;
    return Padding(
      padding: const EdgeInsets.only(bottom: KJSpace.sm),
      child: text,
    );
  }
}

enum KJSection { today, kundlis, mahakosh, research, menu }

/// Padding for form-style screens: 16pt on phones, but on wide
/// displays (tablet / landscape) the content is centered at a
/// comfortable reading width instead of stretching edge to edge.
EdgeInsets formPadding(BuildContext context, {double maxWidth = 520}) {
  final w = MediaQuery.of(context).size.width;
  final horizontal = w > maxWidth + 32 ? (w - maxWidth) / 2 : 16.0;
  return EdgeInsets.symmetric(horizontal: horizontal, vertical: 16);
}

/// Floating text-first pill navigation (design §3.1).
class KJNavPill extends StatelessWidget {
  const KJNavPill({super.key, required this.current});
  final KJSection current;

  // Nav labels say WHERE you are; screen headers say WHAT you see
  // (the Home screen's header remains "Kundlis"). Text-first by
  // design; the single trailing icon is the Menu page (profile,
  // subscription, settings…), which reads fine as the conventional ☰.
  /// Labels are resolved per build (they're localized); the icon-only
  /// Menu entry keeps a null label.
  static List<(KJSection, String?, IconData?, String)> _itemsFor(
          AppLocalizations l10n) =>
      [
        (KJSection.today, l10n.navToday, null, '/today'),
        (KJSection.kundlis, l10n.navHome, null, '/'),
        (KJSection.mahakosh, l10n.navMahakosh, null, '/mahakosh'),
        (KJSection.research, l10n.navResearch, null, '/research'),
        (KJSection.menu, null, Icons.menu, '/menu'),
      ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.only(bottom: 12),
      // heightFactor: 1 keeps the bar at its intrinsic height — a bare
      // Center would expand to fill the screen and crush the body.
      child: Center(
        heightFactor: 1,
        child: Container(
          padding: const EdgeInsets.all(KJSpace.xs),
          decoration: BoxDecoration(
            color: KJColors.ink,
            borderRadius: KJRadius.all(KJRadius.pill),
            boxShadow: [
              BoxShadow(
                color: KJColors.ink.withValues(alpha: KJTint.medium),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (section, label, icon, path)
                  in _itemsFor(context.l10n))
                GestureDetector(
                  onTap: () => context.go(path),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: icon != null ? KJSpace.md + 1 : KJSpace.lg,
                        vertical: KJSpace.sm + 1),
                    decoration: BoxDecoration(
                      color: section == current
                          ? KJColors.maroon
                          : Colors.transparent,
                      borderRadius: KJRadius.all(KJRadius.pill),
                    ),
                    child: icon != null
                        ? Icon(
                            icon,
                            size: KJIcon.md,
                            color: section == current
                                ? KJColors.paper
                                : KJColors.paper
                                    .withValues(alpha: KJTint.inactive),
                          )
                        : Text(
                            label!,
                            style: KJType.chip(
                              size: 12.5,
                              color: section == current
                                  ? KJColors.paper
                                  : KJColors.paper
                                      .withValues(alpha: KJTint.inactive),
                            ).copyWith(
                              fontWeight: section == current
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                          ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Scaffold wrapper for top-level sections.
class KJScaffold extends StatelessWidget {
  const KJScaffold({
    super.key,
    required this.section,
    required this.body,
    this.appBar,
    this.floatingAction,
  });

  final KJSection section;
  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? floatingAction;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingAction,
      bottomNavigationBar: KJNavPill(current: section),
    );
  }
}

/// Dashboard card chrome — hosts don't know module internals; they
/// wrap whatever the module hands back (brief §2.8).
class ModuleCard extends StatelessWidget {
  const ModuleCard({
    super.key,
    required this.title,
    required this.child,
    this.onDetail,
    this.onSettings,
    this.wrapHeader,
  });

  final String title;
  final Widget child;
  final VoidCallback? onDetail;
  final VoidCallback? onSettings;

  /// When set, the header row is passed through this wrapper — the
  /// dashboard uses it to make ONLY the header the long-press drag
  /// handle, leaving the card body free for chart gestures. A drag
  /// indicator icon is shown beside the title as the affordance.
  final Widget Function(Widget header)? wrapHeader;

  @override
  Widget build(BuildContext context) {
    // A compact IconButton is ~40px tall, so cards with a settings/detail
    // action get a taller header than plain ones. Reserve that height on
    // every card (via minHeight) so the title always centers with the
    // same breathing room whether or not action icons are present.
    Widget header = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Row(
        children: [
          if (wrapHeader != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.drag_indicator,
                  size: 14, color: KJColors.inkSoft.withValues(alpha: 0.55)),
            ),
          Expanded(child: KJSectionLabel(title)),
          if (onSettings != null)
            IconButton(
              icon: Icon(Icons.more_horiz, size: 18, color: KJColors.inkSoft),
              onPressed: onSettings,
              visualDensity: VisualDensity.compact,
            ),
          if (onDetail != null)
            IconButton(
              icon: Icon(Icons.arrow_forward, size: 18, color: KJColors.maroon),
              onPressed: onDetail,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
    if (wrapHeader != null) header = wrapHeader!(header);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            header,
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.message,
    this.leading,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String message;

  /// Optional widget above the message — e.g. the brand emblem on the
  /// first-run screen.
  final Widget? leading;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(height: 20),
            ],
            Text(message,
                textAlign: TextAlign.center,
                style: KJType.body(size: 14, color: KJColors.inkSoft)),
            if (actionLabel != null) ...[
              const SizedBox(height: 16),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
            if (secondaryLabel != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Small tag chip (lagna/moon-sign quick reads, sync status, …).
class KJTag extends StatelessWidget {
  const KJTag(this.label, {super.key, this.maroon = false});
  final String label;
  final bool maroon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: KJSpace.sm + 2, vertical: KJSpace.xs),
      decoration: BoxDecoration(
        color: maroon
            ? KJColors.maroon.withValues(alpha: KJTint.faint)
            : KJColors.paperAlt,
        borderRadius: KJRadius.all(KJRadius.md),
        border: Border.all(
            color: maroon
                ? KJColors.maroon.withValues(alpha: KJTint.muted)
                : KJColors.hairline),
      ),
      child: Text(
        label,
        style: KJType.chip(
            size: 11.5, color: maroon ? KJColors.maroon : KJColors.inkSoft),
      ),
    );
  }
}

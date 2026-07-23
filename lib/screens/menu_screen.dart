import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show FunctionException, SignOutScope;

import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../core/theme/theme.dart';
import '../state/providers.dart';
import '../ui/common.dart';
import '../l10n/astro_l10n.dart';

/// The Menu landing page (last pill item) — home for everything that
/// isn't a daily-use section. The account lives inline at the top (no
/// separate Profile screen); app preferences moved to Settings.
class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authUserProvider).value;
    // .value defaults to false while loading/on error — the Admin tile
    // simply doesn't appear until the check resolves true. This hides the
    // entry point for non-admins; it is not what actually keeps them out
    // (see admin_repository.dart's doc comment).
    final isAdmin = ref.watch(isAdminProvider).value ?? false;

    return KJScaffold(
      section: KJSection.menu,
      appBar: AppBar(title: Text(context.l10n.mnTitle)),
      body: ListView(
        padding: formPadding(context),
        children: [
          _label(context.l10n.mnSectionTools),
          _tile(
            context,
            icon: Icons.brightness_5_outlined,
            title: context.l10n.mhTitle,
            subtitle: context.l10n.mnMuhurtaSubtitle,
            onTap: () => context.push('/muhurta'),
          ),
          _tile(
            context,
            icon: Icons.favorite_border,
            title: context.l10n.mnAshtakoota,
            subtitle: context.l10n.mnAshtakootaSubtitle,
            onTap: () => context.push('/ashtakoota'),
          ),
          const SizedBox(height: 18),
          _label(context.l10n.mnSectionAccount),
          _accountCard(context, ref, user),
          const SizedBox(height: 8),
          _tile(
            context,
            icon: Icons.settings_outlined,
            title: context.l10n.mnSettings,
            subtitle: context.l10n.mnSettingsSubtitle,
            onTap: () => context.push('/settings'),
          ),
          _tile(
            context,
            icon: Icons.notifications_none,
            title: context.l10n.notificationsTitle,
            subtitle: context.l10n.mnNotificationsSubtitle,
            onTap: () => context.push('/notifications'),
          ),
          const SizedBox(height: 18),
          _label(context.l10n.mnSectionMahakosh),
          _tile(
            context,
            icon: Icons.visibility_off_outlined,
            title: context.l10n.mnHiddenCharts,
            subtitle: context.l10n.mnHiddenChartsSubtitle,
            onTap: () => context.push('/mahakosh/hidden'),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 18),
            _label(context.l10n.mnSectionAdmin),
            _tile(
              context,
              icon: Icons.shield_outlined,
              title: context.l10n.mnModerationQueue,
              subtitle: context.l10n.mnModerationSubtitle,
              onTap: () => context.push('/admin'),
            ),
          ],
          const SizedBox(height: 18),
          _label(context.l10n.mnSectionAbout),
          _tile(
            context,
            icon: Icons.description_outlined,
            title: context.l10n.mnLicenses,
            subtitle: context.l10n.mnLicensesSubtitle,
            onTap: () => showLicensePage(
              context: context,
              applicationName: kAppName,
              applicationLegalese: kCopyrightLine,
            ),
          ),
          const SizedBox(height: 28),
          // AGPL §13 source offer + §0 Appropriate Legal Notices: users
          // interacting with the app are prominently offered the license
          // and the Corresponding Source.
          _licenseFooter(context),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _accountCard(BuildContext context, WidgetRef ref, dynamic user) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: user == null
            ? Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.mnSignedOut,
                      style: const TextStyle(fontSize: 13.5),
                    ),
                  ),
                  FilledButton(
                    onPressed: () => context.push('/signin'),
                    child: Text(context.l10n.signIn),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.email ?? context.l10n.mnAccountFallback,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(context.l10n.mnSyncEnabled,
                      style:
                          TextStyle(fontSize: 12.5, color: KJColors.inkSoft)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () async {
                          // Captured before the awaits — context must not be
                          // used across suspension points.
                          final l10n = context.l10n;
                          final messenger = ScaffoldMessenger.of(context);
                          try {
                            await ref.read(syncServiceProvider)?.pushAll();
                            final pulled =
                                await ref.read(syncServiceProvider)?.pullAll();
                            ref.invalidate(kundlisProvider);
                            messenger.showSnackBar(SnackBar(
                                content: Text(l10n.mnSynced('${pulled ?? 0}'))));
                          } catch (_) {
                            // Offline is the common cause — a user-initiated
                            // sync must say it failed, not crash or go silent.
                            messenger.showSnackBar(
                                SnackBar(content: Text(l10n.mnSyncFailed)));
                          }
                        },
                        child: Text(context.l10n.mnSyncNow),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () async {
                          await ref
                              .read(supabaseClientProvider)
                              ?.auth
                              .signOut();
                        },
                        child: Text(context.l10n.signOut),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => _confirmDeleteAccount(context, ref),
                      child: Text(context.l10n.mnDeleteAccount,
                          style: TextStyle(color: KJColors.maroon)),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  /// Account deletion must be initiable in-app (App Store Guideline
  /// 5.1.1(v), Play account-deletion policy). Server side: the
  /// delete-account edge function. Public description of exactly what is
  /// and isn't removed: kaaljyoti.com/delete-account.html — keep the
  /// dialog text consistent with that page.
  Future<void> _confirmDeleteAccount(
      BuildContext context, WidgetRef ref) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.mnDeleteAccountTitle),
        content: Text(ctx.l10n.mnDeleteAccountBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(ctx.l10n.cancel)),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(ctx.l10n.mnDeleteForever,
                  style: TextStyle(color: KJColors.maroon))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await client.functions
          .invoke('delete-account', body: {'confirm': 'DELETE'});
      // The server-side session is already gone with the user; clear the
      // local one (a global sign-out would call the dead session's
      // endpoint and fail).
      await client.auth.signOut(scope: SignOutScope.local);
      messenger.showSnackBar(SnackBar(content: Text(l10n.mnAccountDeleted)));
    } catch (e) {
      final detail = e is FunctionException
          ? ((e.details is Map ? (e.details as Map)['error'] : null) ??
              'status ${e.status}')
          : e;
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.mnDeleteAccountError('$detail'))));
    }
  }

  /// App version + build number, e.g. "v0.0.1 (7)" — resolved once per
  /// process; PackageInfo reads the bundle, no network involved.
  static final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  Widget _licenseFooter(BuildContext context) {
    Widget line(String text, {String? url}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 1.5),
          child: url == null
              ? Text(text,
                  textAlign: TextAlign.center,
                  style: KJTheme.mono(size: 11, color: KJColors.inkSoft))
              : InkWell(
                  onTap: () => launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication),
                  child: Text(text,
                      textAlign: TextAlign.center,
                      style: KJTheme.mono(size: 11, color: KJColors.maroon)
                          .copyWith(decoration: TextDecoration.underline)),
                ),
        );
    return Column(
      children: [
        FutureBuilder<PackageInfo>(
          future: _packageInfo,
          builder: (_, snap) => line(snap.hasData
              ? context.l10n
                  .mnVersion(snap.data!.version, snap.data!.buildNumber)
              : kAppName),
        ),
        line(kCopyrightLine),
        line(context.l10n.mnAuthorCredit, url: kAuthorLinkedInUrl),
        line(kWebsite, url: kWebsiteUrl),
        line(context.l10n.mnFoss),
        line(context.l10n.mnLicenseLine, url: kLicenseUrl),
        line(context.l10n.mnSourceCode, url: kSourceRepoUrl),
        line(context.l10n.mnEphemerisCredit),
        line(context.l10n.mnNoWarranty),
      ],
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 10.5,
            letterSpacing: 1.1,
            color: KJColors.inkSoft,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _tile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        enabled: enabled,
        leading: Icon(icon,
            color: enabled
                ? KJColors.maroon
                : KJColors.inkSoft.withValues(alpha: 0.5)),
        title: Text(title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: enabled
                  ? KJColors.ink
                  : KJColors.inkSoft.withValues(alpha: 0.7),
            )),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 12, color: KJColors.inkSoft)),
        trailing: enabled
            ? const Icon(Icons.chevron_right, size: 20)
            : Text(context.l10n.mnSoon,
                style: KJTheme.mono(size: 10, color: KJColors.inkSoft)),
        onTap: onTap,
      ),
    );
  }
}

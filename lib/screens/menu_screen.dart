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

    return TEScaffold(
      section: TESection.menu,
      appBar: AppBar(title: const Text('Menu')),
      body: ListView(
        padding: formPadding(context),
        children: [
          _label('TOOLS'),
          _tile(
            context,
            icon: Icons.brightness_5_outlined,
            title: 'Muhurta',
            subtitle: 'Choghadiya, Hora, Rahu Kaal & auspicious timings',
            onTap: () => context.push('/muhurta'),
          ),
          _tile(
            context,
            icon: Icons.favorite_border,
            title: 'Ashtakoota Guna Milan',
            subtitle: 'Marriage compatibility — 36-point koota match',
            onTap: () => context.push('/ashtakoota'),
          ),
          const SizedBox(height: 18),
          _label('ACCOUNT'),
          _accountCard(context, ref, user),
          const SizedBox(height: 8),
          _tile(
            context,
            icon: Icons.settings_outlined,
            title: 'Settings',
            subtitle: 'Date format, default ayanamsa & chart style, appearance',
            onTap: () => context.push('/settings'),
          ),
          _tile(
            context,
            icon: Icons.notifications_none,
            title: 'Notifications',
            subtitle: 'Research replies & updates',
            onTap: () => context.push('/notifications'),
          ),
          const SizedBox(height: 18),
          _label('MAHAKOSH'),
          _tile(
            context,
            icon: Icons.visibility_off_outlined,
            title: 'Hidden charts',
            subtitle: "Charts you've hidden from your own Mahakosh view",
            onTap: () => context.push('/mahakosh/hidden'),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 18),
            _label('ADMIN'),
            _tile(
              context,
              icon: Icons.shield_outlined,
              title: 'Moderation queue',
              subtitle: 'Pending research requests & chart reports',
              onTap: () => context.push('/admin'),
            ),
          ],
          const SizedBox(height: 18),
          _label('ABOUT'),
          _tile(
            context,
            icon: Icons.description_outlined,
            title: 'Open-source licenses',
            subtitle: 'Licenses of the libraries this app is built on',
            onTap: () => showLicensePage(
              context: context,
              applicationName: kAppName,
              applicationLegalese: '© 2026 Amit Verma',
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
                  const Expanded(
                    child: Text(
                      'Signed out — kundlis stay on this device.',
                      style: TextStyle(fontSize: 13.5),
                    ),
                  ),
                  FilledButton(
                    onPressed: () => context.push('/signin'),
                    child: const Text('Sign in'),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.email ?? 'Account',
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Sync + Mahakosh enabled',
                      style: TextStyle(
                          fontSize: 12.5, color: TEColors.inkSoft)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () async {
                          await ref.read(syncServiceProvider)?.pushAll();
                          final pulled =
                              await ref.read(syncServiceProvider)?.pullAll();
                          ref.invalidate(kundlisProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content:
                                    Text('Synced (${pulled ?? 0} pulled).')));
                          }
                        },
                        child: const Text('Sync now'),
                      ),
                      const SizedBox(width: 10),
                      TextButton(
                        onPressed: () async {
                          await ref
                              .read(supabaseClientProvider)
                              ?.auth
                              .signOut();
                        },
                        child: const Text('Sign out'),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => _confirmDeleteAccount(context, ref),
                      child: Text('Delete account…',
                          style: TextStyle(color: TEColors.maroon)),
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
  Future<void> _confirmDeleteAccount(BuildContext context, WidgetRef ref) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
            'This permanently deletes your account: synced kundli copies, '
            'notifications and your sign-in identity. Kundlis stored on '
            'this device are not affected.\n\n'
            'Your comments in discussions remain, shown as from a deleted '
            'account. Delete any comments you don\'t want to keep before '
            'deleting your account.\n\n'
            'Charts you shared with Mahakosh stay in the research pool, '
            'anonymized. To remove one from the pool, withdraw it on its '
            'kundli\'s edit screen BEFORE deleting your account — '
            'afterwards it can no longer be traced back to you.\n\n'
            'This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Delete forever',
                  style: TextStyle(color: TEColors.maroon))),
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
      messenger.showSnackBar(
          const SnackBar(content: Text('Your account has been deleted.')));
    } catch (e) {
      final detail = e is FunctionException
          ? ((e.details is Map ? (e.details as Map)['error'] : null) ??
              'status ${e.status}')
          : e;
      messenger.showSnackBar(
          SnackBar(content: Text('Could not delete account: $detail')));
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
                  style: TETheme.mono(size: 11, color: TEColors.inkSoft))
              : InkWell(
                  onTap: () => launchUrl(Uri.parse(url),
                      mode: LaunchMode.externalApplication),
                  child: Text(text,
                      textAlign: TextAlign.center,
                      style: TETheme.mono(size: 11, color: TEColors.maroon)
                          .copyWith(decoration: TextDecoration.underline)),
                ),
        );
    return Column(
      children: [
        FutureBuilder<PackageInfo>(
          future: _packageInfo,
          builder: (_, snap) => line(snap.hasData
              ? 'Kaal Jyoti v${snap.data!.version} (${snap.data!.buildNumber})'
              : 'Kaal Jyoti'),
        ),
        line('Free & open source software'),
        line('Released under the GNU AGPL v3', url: kLicenseUrl),
        line('Source code', url: kSourceRepoUrl),
        line('Planetary calculations powered by the Swiss Ephemeris'),
        line('No warranty — see license for details'),
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
            color: TEColors.inkSoft,
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
                ? TEColors.maroon
                : TEColors.inkSoft.withValues(alpha: 0.5)),
        title: Text(title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: enabled
                  ? TEColors.ink
                  : TEColors.inkSoft.withValues(alpha: 0.7),
            )),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 12, color: TEColors.inkSoft)),
        trailing: enabled
            ? const Icon(Icons.chevron_right, size: 20)
            : Text('soon',
                style: TETheme.mono(size: 10, color: TEColors.inkSoft)),
        onTap: onTap,
      ),
    );
  }
}

/// Screen 14 — Sign In. Email + one-time code via Supabase Auth: no
/// passwords, and no separate signup — the account is created on
/// first successful code verification. Value-driven, never forced.
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/constants.dart';
import '../core/theme/theme.dart';
import '../services/social_auth.dart';
import '../state/providers.dart';
import '../ui/common.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  String get _email => _emailController.text.trim();

  bool get _showApple => !kIsWeb && Platform.isIOS;

  Future<void> _afterSignIn() async {
    await ref.read(syncServiceProvider)?.pullAll();
    ref.invalidate(kundlisProvider);
    if (mounted) context.pop();
  }

  Future<void> _social(Future<void> Function(SocialAuth) run) async {
    final client = ref.read(supabaseClientProvider);
    if (client == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await run(SocialAuth(client));
      await _afterSignIn();
    } on SocialAuthCancelled {
      // User backed out — not an error.
    } catch (e) {
      // The underlying cause (e.g. Supabase AuthException) matters for
      // diagnosing provider misconfiguration - log it, show the calm
      // message.
      debugPrint('social sign-in failed: $e');
      setState(() => _error = e is StateError
          ? e.message
          : 'Sign-in failed. Please try again or use the email code.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() async {
    final client = ref.read(supabaseClientProvider);
    if (client == null || _email.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Creates the account on first use — signup and login are the
      // same flow.
      await client.auth.signInWithOtp(email: _email);
      setState(() => _codeSent = true);
    } catch (e) {
      setState(() => _error = _friendly(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    final client = ref.read(supabaseClientProvider);
    final code = _codeController.text.trim();
    if (client == null || code.isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await client.auth.verifyOTP(
        type: OtpType.email,
        email: _email,
        token: code,
      );
      await _afterSignIn();
    } catch (e) {
      setState(() => _error = _friendly(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _friendly(Object e) {
    final msg = e.toString();
    if (msg.contains('rate limit') || msg.contains('429')) {
      return 'Too many attempts — please wait a minute and try again.';
    }
    if (msg.contains('expired') || msg.contains('invalid')) {
      return 'That code didn\'t match or has expired. Request a new one.';
    }
    return 'Something went wrong. Check the email address and try again.';
  }

  @override
  Widget build(BuildContext context) {
    final client = ref.watch(supabaseClientProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sign In')),
      body: client == null
          ? const EmptyState(
              message:
                  'Accounts need the backend configured (SUPABASE_URL / '
                  'SUPABASE_ANON_KEY). The app works fully offline without '
                  'one — sync and Mahakosh are the only features gated.')
          : ListView(
              padding: formPadding(context),
              children: [
                const SizedBox(height: 16),
                // Brand mark — the OTP email says "Kaal Jyoti"; the
                // screen asking for that code should visibly match.
                Center(
                  child: Column(
                    children: [
                      Image.asset('assets/emblem.png',
                          width: 72, height: 72),
                      const SizedBox(height: 12),
                      Text('KAAL JYOTI',
                          style: TextStyle(
                              fontSize: 13,
                              letterSpacing: 4,
                              color: TEColors.ink)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'An account unlocks cross-device sync and Mahakosh — '
                  'chart casting never requires one.',
                  style:
                      TextStyle(fontSize: 13.5, color: TEColors.inkSoft),
                ),
                const SizedBox(height: 20),
                if (kGoogleSignInConfigured) ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.g_mobiledata, size: 26),
                    label: const Text('Continue with Google'),
                    onPressed: _busy
                        ? null
                        : () => _social((s) => s.signInWithGoogle()),
                  ),
                  const SizedBox(height: 10),
                ],
                if (_showApple) ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.apple, size: 22),
                    label: const Text('Continue with Apple'),
                    onPressed: _busy
                        ? null
                        : () => _social((s) => s.signInWithApple()),
                  ),
                  const SizedBox(height: 10),
                ],
                if (kGoogleSignInConfigured || _showApple)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          child: Text('or use an email code',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: TEColors.inkSoft)),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),
                  ),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  enabled: !_codeSent,
                  decoration: const InputDecoration(labelText: 'Email'),
                  onSubmitted: (_) => _codeSent ? null : _sendCode(),
                ),
                if (_codeSent) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    // Supabase OTP length is a project setting (6–10
                    // digits) — don't assume a fixed length.
                    maxLength: 10,
                    style: TETheme.mono(size: 20),
                    decoration: InputDecoration(
                      labelText: 'One-time code',
                      helperText: 'Sent to $_email — check spam too',
                      counterText: '',
                    ),
                    onSubmitted: (_) => _verify(),
                  ),
                ],
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(_error!,
                        style: TextStyle(
                            fontSize: 12.5, color: TEColors.maroon)),
                  ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy
                      ? null
                      : (_codeSent ? _verify : _sendCode),
                  child: Text(_busy
                      ? 'Working…'
                      : (_codeSent ? 'Verify & sign in' : 'Send code')),
                ),
                if (_codeSent)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () {
                            setState(() {
                              _codeSent = false;
                              _codeController.clear();
                              _error = null;
                            });
                          },
                    child:
                        const Text('Different email / resend code'),
                  ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'No password needed — first sign-in creates your '
                    'account automatically.',
                    textAlign: TextAlign.center,
                    style: TETheme.mono(
                        size: 10.5, color: TEColors.inkSoft),
                  ),
                ),
                const SizedBox(height: 14),
                // Terms presented before registering — sign-up and
                // sign-in are the same flow here, so this is the one
                // place the agreement can appear (Guideline 1.2).
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('By continuing you agree to the ',
                          style: TextStyle(
                              fontSize: 11.5, color: TEColors.inkSoft)),
                      _legalLink('Terms of Use', kTermsUrl),
                      Text(' and ',
                          style: TextStyle(
                              fontSize: 11.5, color: TEColors.inkSoft)),
                      _legalLink('Privacy Policy', kPrivacyUrl),
                      Text('.',
                          style: TextStyle(
                              fontSize: 11.5, color: TEColors.inkSoft)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _legalLink(String label, String url) => InkWell(
        onTap: () => launchUrl(Uri.parse(url),
            mode: LaunchMode.externalApplication),
        child: Text(label,
            style: TextStyle(
                fontSize: 11.5,
                color: TEColors.maroon,
                decoration: TextDecoration.underline)),
      );
}

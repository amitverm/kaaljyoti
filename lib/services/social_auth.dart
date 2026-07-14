/// Native Google / Apple sign-in, exchanged for a Supabase session via
/// signInWithIdToken (the Supabase-recommended mobile flow — no
/// browser redirect). Email OTP remains the universal fallback.
library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants.dart';

class SocialAuthCancelled implements Exception {}

class SocialAuth {
  const SocialAuth(this._client);
  final SupabaseClient _client;

  /// Google: native account picker -> idToken -> Supabase session.
  Future<void> signInWithGoogle() async {
    if (!kGoogleSignInConfigured) {
      throw StateError('Google sign-in is not configured '
          '(GOOGLE_WEB_CLIENT_ID missing).');
    }
    final google = GoogleSignIn(
      // On iOS the app's own client id; serverClientId (the WEB
      // client) is what ends up in the idToken audience that
      // Supabase validates.
      clientId: kGoogleIosClientId.isEmpty ? null : kGoogleIosClientId,
      serverClientId: kGoogleWebClientId,
    );
    final account = await google.signIn();
    if (account == null) throw SocialAuthCancelled();
    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw StateError('Google returned no ID token — check that the '
          'web client ID is set as serverClientId.');
    }
    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: auth.accessToken,
    );
  }

  /// Apple: native sheet -> identityToken (+ nonce) -> Supabase
  /// session. iOS only in this app.
  Future<void> signInWithApple() async {
    final rawNonce = _randomNonce();
    final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final AuthorizationCredentialAppleID credential;
    try {
      credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw SocialAuthCancelled();
      }
      rethrow;
    }

    final idToken = credential.identityToken;
    if (idToken == null) {
      throw StateError('Apple returned no identity token.');
    }
    await _client.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: idToken,
      nonce: rawNonce,
    );
  }

  static String _randomNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
        length, (_) => charset[random.nextInt(charset.length)]).join();
  }
}

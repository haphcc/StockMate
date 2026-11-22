import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../config/app_config.dart';

/// Google OAuth credentials returned after interactive sign-in.
class GoogleAuthCredentials {
  final String? idToken;
  final String? accessToken;

  const GoogleAuthCredentials({this.idToken, this.accessToken});

  bool get isValid =>
      (idToken != null && idToken!.isNotEmpty) ||
      (accessToken != null && accessToken!.isNotEmpty);
}

/// Singleton service to handle Google OAuth 2.0 Sign-In in Flutter.
class GoogleSignInService {
  static final GoogleSignInService _instance = GoogleSignInService._internal();
  factory GoogleSignInService() => _instance;
  GoogleSignInService._internal();

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const <String>[
      'email',
      'profile',
    ],
    // serverClientId is required on Android/iOS to receive an ID token,
    // while Flutter Web reads the client ID from <meta name="google-signin-client_id">.
    serverClientId: (!kIsWeb && AppConfig.googleServerClientId.isNotEmpty)
        ? AppConfig.googleServerClientId
        : null,
  );

  /// Initiates interactive Google Sign-In and retrieves Google OAuth tokens.
  /// Throws an exception if user cancels or if neither idToken nor accessToken is returned.
  Future<GoogleAuthCredentials> signIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        throw Exception('Đã hủy đăng nhập Google.');
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final credentials = GoogleAuthCredentials(
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      );

      if (!credentials.isValid) {
        throw Exception(
          'Không nhận được token xác thực từ Google. Vui lòng kiểm tra cấu hình OAuth.',
        );
      }

      return credentials;
    } catch (e) {
      developer.log('Google Sign-In Error: $e', name: 'GoogleSignInService');
      rethrow;
    }
  }

  /// Sign out current Google session so users can pick another account on next login.
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      developer.log('Google Sign-Out Error: $e', name: 'GoogleSignInService');
    }
  }
}

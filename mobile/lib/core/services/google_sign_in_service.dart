import 'dart:developer' as developer;
import 'package:google_sign_in/google_sign_in.dart';

/// Singleton service to handle Google OAuth 2.0 Sign-In in Flutter.
class GoogleSignInService {
  static final GoogleSignInService _instance = GoogleSignInService._internal();
  factory GoogleSignInService() => _instance;
  GoogleSignInService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: <String>[
      'email',
      'profile',
    ],
  );

  /// Initiates interactive Google Sign-In and retrieves the Google ID Token.
  /// Throws an exception if user cancels or if idToken is not returned.
  Future<String> signIn() async {
    try {
      // Prompt user to select Google account
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        throw Exception('Đã hủy đăng nhập Google.');
      }

      // Obtain authentication tokens
      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception('Không nhận được ID Token từ Google. Vui lòng kiểm tra cấu hình OAuth.');
      }

      return idToken;
    } catch (e) {
      developer.log('Google Sign-In Error: $e', name: 'GoogleSignInService');
      rethrow;
    }
  }

  /// Sign out current Google session
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      developer.log('Google Sign-Out Error: $e', name: 'GoogleSignInService');
    }
  }
}

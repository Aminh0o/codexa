import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GoogleAuthResult {
  final bool isSuccess;
  final bool isCancelled;
  final String? errorMessage;
  final String? accessToken;
  final String? userEmail;
  final String? userName;
  final String? userPhoto;

  GoogleAuthResult.success({
    required this.accessToken,
    required this.userEmail,
    this.userName,
    this.userPhoto,
  })  : isSuccess = true,
        isCancelled = false,
        errorMessage = null;

  GoogleAuthResult.cancelled()
      : isSuccess = false,
        isCancelled = true,
        errorMessage = null,
        accessToken = null,
        userEmail = null,
        userName = null,
        userPhoto = null;

  GoogleAuthResult.error(this.errorMessage)
      : isSuccess = false,
        isCancelled = false,
        accessToken = null,
        userEmail = null,
        userName = null,
        userPhoto = null;
}

class GoogleAuthService {
  static const String _webClientId = '958439411078-g799g3et53qlahbdj266oqu2s5cm2ob9.apps.googleusercontent.com';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/drive',
    ],
    serverClientId: _webClientId,
  );

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _keyAccessToken = 'g_access_token';
  static const _keyUserEmail = 'g_user_email';
  static const _keyUserName = 'g_user_name';
  static const _keyUserPhoto = 'g_user_photo';
  static const _keyIsSignedIn = 'g_is_signed_in';
  static const _keyTokenExpiry = 'g_token_expiry';

  static Future<GoogleAuthResult> signIn() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return GoogleAuthResult.cancelled();

      final auth = await account.authentication;
      if (auth.accessToken == null) {
        return GoogleAuthResult.error('Failed to get access token. Please try again.');
      }

      await _secureStorage.write(key: _keyAccessToken, value: auth.accessToken);
      await _secureStorage.write(key: _keyUserEmail, value: account.email);
      await _secureStorage.write(key: _keyUserName, value: account.displayName);
      await _secureStorage.write(key: _keyUserPhoto, value: account.photoUrl);
      await _secureStorage.write(key: _keyIsSignedIn, value: 'true');
      await _secureStorage.write(key: _keyTokenExpiry, value: DateTime.now().add(const Duration(minutes: 55)).toIso8601String());

      return GoogleAuthResult.success(
        accessToken: auth.accessToken,
        userEmail: account.email,
        userName: account.displayName,
        userPhoto: account.photoUrl,
      );
    } catch (e) {
      final message = _mapSignInError(e);
      return GoogleAuthResult.error(message);
    }
  }

  static String _mapSignInError(Object e) {
    final text = e.toString();
    if (text.contains('10') || text.contains('DEVELOPER_ERROR')) {
      return 'Sign-in is not configured. Please check app settings.';
    }
    if (text.contains('12500') || text.contains('LOGIN_REQUIRES_RECENT_LOGIN')) {
      return 'Session expired. Please sign in again.';
    }
    if (text.contains('12501') || text.contains('SIGN_IN_CANCELLED')) {
      return 'Sign-in was cancelled.';
    }
    if (text.contains('7') || text.contains('NETWORK_ERROR')) {
      return 'Network error. Please check your connection.';
    }
    if (text.contains('16') || text.contains('BEARER_TOKEN_EXCHANGE')) {
      return 'Authentication error. Please try again.';
    }
    return 'Sign-in failed. Please try again.';
  }

  static Future<void> signOut() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      try { await _googleSignIn.signOut(); } catch (_) {}
    }
    // Delete only Codexa auth keys (not all secure storage)
    for (final key in [_keyAccessToken, _keyUserEmail, _keyUserName,
      _keyUserPhoto, _keyIsSignedIn, _keyTokenExpiry]) {
      try { await _secureStorage.delete(key: key); } catch (_) {}
    }
  }

  static Future<String?> getAccessToken() async {
    try {
      return await _secureStorage.read(key: _keyAccessToken);
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isSignedIn() async {
    try {
      final val = await _secureStorage.read(key: _keyIsSignedIn);
      return val == 'true';
    } catch (_) {
      return false;
    }
  }

  static Future<String?> getUserEmail() async {
    try {
      return await _secureStorage.read(key: _keyUserEmail);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getUserName() async {
    try {
      return await _secureStorage.read(key: _keyUserName);
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getUserPhoto() async {
    try {
      return await _secureStorage.read(key: _keyUserPhoto);
    } catch (_) {
      return null;
    }
  }

  static Future<GoogleSignInAccount?> trySilentSignIn() async {
    try {
      return await _googleSignIn.signInSilently();
    } catch (_) {
      return null;
    }
  }

  /// Try to refresh the access token silently.
  /// Returns a new access token if successful, null otherwise.
  /// Does NOT clear stored credentials on failure (offline-safe).
  static Future<String?> tryRefreshToken() async {
    try {
      final account = await _googleSignIn.signInSilently();
      if (account == null) {
        // Refresh failed (likely offline) — don't clear credentials
        return null;
      }

      final auth = await account.authentication;
      if (auth.accessToken == null) {
        return null;
      }

      // Only update stored token if it's actually different
      final currentToken = await _secureStorage.read(key: _keyAccessToken);
      if (currentToken != auth.accessToken) {
        await _secureStorage.write(key: _keyAccessToken, value: auth.accessToken);
      }
      // Always reset expiry when a valid token is returned
      await _secureStorage.write(key: _keyTokenExpiry,
          value: DateTime.now().add(const Duration(minutes: 55)).toIso8601String());
      return auth.accessToken;
    } catch (_) {
      return null;
    }
  }

  /// Get a valid access token, refreshing if needed.
  /// Returns null if not signed in. Does NOT clear stored tokens on failure.
  static Future<String?> getValidAccessToken() async {
    // Check if token has expired
    final expiryStr = await _secureStorage.read(key: _keyTokenExpiry);
    if (expiryStr != null) {
      final expiry = DateTime.tryParse(expiryStr);
      if (expiry != null && DateTime.now().isAfter(expiry)) {
        // Token expired — try to refresh (may fail offline)
        final newToken = await tryRefreshToken();
        if (newToken != null) return newToken;
        // Refresh failed (offline) — return expired token as fallback
        // The caller should handle this gracefully
        final expiredToken = await _secureStorage.read(key: _keyAccessToken);
        return expiredToken;
      }
    }

    // Token exists and hasn't expired — return it
    final token = await _secureStorage.read(key: _keyAccessToken);
    if (token != null) return token;

    // No token, try silent refresh
    final newToken = await tryRefreshToken();
    return newToken;
  }
}

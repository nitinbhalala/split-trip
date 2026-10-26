import 'dart:async';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:split_trip/core/common/widgets/app_logger.dart';
import 'package:split_trip/core/const/app_string.dart';
import 'package:split_trip/data/database/database_provider.dart';
import 'package:split_trip/data/service/pref_keys.dart';

class GoogleAuthService {
  GoogleAuthService._();

  static const List<String> _scopes = <String>[
    'email',
    'https://www.googleapis.com/auth/drive.file',
  ];

  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  static GoogleSignInAccount? _currentUser;
  static bool _isInitialized = false;

  /// Call this ONCE at app startup.
  static Future<void> initialize({
    String? clientId,
    String? serverClientId = AppString.serverClientId,
  }) async {
    if (_isInitialized) return;

    await _googleSignIn.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );

    _googleSignIn.authenticationEvents
        .listen((event) {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            _currentUser = event.user;
            _saveUserEmailToPrefs(event.user.email);
          } else if (event is GoogleSignInAuthenticationEventSignOut) {
            _currentUser = null;
            _saveUserEmailToPrefs(null);
          }
        })
        .onError((Object error) {
          // Handle or log auth events streams errors
        });

    // Intentionally NOT calling attemptLightweightAuthentication() here.
    // Google sign-in must only ever be triggered by an explicit user action
    // (tapping "Backup to Google Drive" / "Restore from Google Drive"),
    // never automatically on app start.
    final storedEmail = await _getStoredUserEmail();
    if (storedEmail != null && storedEmail.isNotEmpty) {
      await DatabaseProvider.switchUserDatabase(storedEmail);
    }

    _isInitialized = true;
  }

  static Future<void> _saveUserEmailToPrefs(String? email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (email != null && email.isNotEmpty) {
        await prefs.setString(PrefKeys.userEmail, email);
      } else {
        await prefs.remove(PrefKeys.userEmail);
      }
    } catch (_) {}
  }

  static Future<String?> _getStoredUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(PrefKeys.userEmail);
    } catch (_) {
      return null;
    }
  }

  static String lastAuthError = "";

  /// Triggers the Google Sign-In interactive flow.
  /// Returns [GoogleSignInAccount?] — use this for sign-in.
  static Future<GoogleSignInAccount?> signIn() async {
    lastAuthError = "";
    if (!_isInitialized) await initialize();

    return _attemptSignIn(isRetry: false);
  }

  static Future<GoogleSignInAccount?> _attemptSignIn({
    required bool isRetry,
  }) async {
    try {
      _currentUser = await _googleSignIn.authenticate();
      if (_currentUser == null) {
        lastAuthError = "Google account selection returned null";
        return null;
      }

      await _saveUserEmailToPrefs(_currentUser!.email);
      await DatabaseProvider.switchUserDatabase(_currentUser!.email);
      return _currentUser;
    } catch (e, stackTrace) {
      if (!isRetry &&
          e is GoogleSignInException &&
          (e.description?.contains('reauth') == true ||
              e.description?.contains('16') == true)) {
        // ignore: avoid_print
        print(
          '⚠️ [GoogleAuthService]: Stale credential detected, clearing and retrying...',
        );
        AppLogger.error(
          'GoogleAuthService: Stale credential, retrying after signOut',
        );
        try {
          await _googleSignIn.signOut();
          _currentUser = null;
          await _saveUserEmailToPrefs(null);
        } catch (_) {}
        return _attemptSignIn(isRetry: true);
      }

      if (e is GoogleSignInException) {
        final desc = e.description ?? '';
        final codeStr = e.code.toString().replaceAll(
          'GoogleSignInExceptionCode.',
          '',
        );
        lastAuthError =
            'GoogleSDK Error [$codeStr]: ${desc.isEmpty ? "No description returned" : desc}';
      } else {
        lastAuthError = 'Error: $e';
      }
      // ignore: avoid_print
      print('❌ [GoogleAuthService.signIn Error]: $lastAuthError');
      AppLogger.error('GoogleAuthService.signIn Error: $lastAuthError');
      // ignore: avoid_print
      print('❌ [Stack trace]: $stackTrace');
      AppLogger.error('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Signs in with Google and returns the [GoogleSignInAccount].
  /// Restores an existing session silently, but a user who has never signed
  /// in through this app before always gets the explicit account picker —
  /// never a silent auto pick of whatever account is on the device.
  static Future<GoogleSignInAccount?> signInForDrive() async {
    if (!_isInitialized) await initialize();

    if (_currentUser != null) {
      await _saveUserEmailToPrefs(_currentUser!.email);
      await DatabaseProvider.switchUserDatabase(_currentUser!.email);
      return _currentUser;
    }

    final storedEmail = await _getStoredUserEmail();
    if (storedEmail != null && storedEmail.isNotEmpty) {
      try {
        _currentUser = await _googleSignIn.attemptLightweightAuthentication();
        if (_currentUser != null) {
          await _saveUserEmailToPrefs(_currentUser!.email);
          await DatabaseProvider.switchUserDatabase(_currentUser!.email);
          return _currentUser;
        }
      } catch (_) {
        // Fall through to interactive prompt
      }
    }

    return _attemptAuthenticateForDrive(isRetry: false);
  }

  static Future<GoogleSignInAccount?> _attemptAuthenticateForDrive({
    required bool isRetry,
  }) async {
    try {
      _currentUser = await _googleSignIn.authenticate();
      if (_currentUser == null) return null;

      await _saveUserEmailToPrefs(_currentUser!.email);
      await DatabaseProvider.switchUserDatabase(_currentUser!.email);
      return _currentUser;
    } catch (e, stackTrace) {
      if (!isRetry &&
          e is GoogleSignInException &&
          (e.description?.contains('reauth') == true ||
              e.description?.contains('16') == true)) {
        // ignore: avoid_print
        print(
          '⚠️ [GoogleAuthService]: Stale credential detected (drive), clearing and retrying...',
        );
        AppLogger.error(
          'GoogleAuthService: Stale credential (drive), retrying after signOut',
        );
        try {
          await _googleSignIn.signOut();
          _currentUser = null;
          await _saveUserEmailToPrefs(null);
        } catch (_) {}
        return _attemptAuthenticateForDrive(isRetry: true);
      }

      if (e is GoogleSignInException &&
          e.code == GoogleSignInExceptionCode.canceled) {
        // ignore: avoid_print
        print('ℹ️ [GoogleAuthService]: Sign in for drive cancelled by user.');
        return null;
      }
      // ignore: avoid_print
      print('❌ [GoogleAuthService.signInForDrive Error]: $e');
      // ignore: avoid_print
      print('❌ [Stack trace]: $stackTrace');
      AppLogger.error('GoogleAuthService.signInForDrive Error: $e');
      AppLogger.error('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Attempts silent (lightweight) sign-in.
  static Future<GoogleSignInAccount?> signInSilently() async {
    try {
      if (!_isInitialized) await initialize();
      _currentUser = await _googleSignIn.attemptLightweightAuthentication();
      if (_currentUser != null) {
        await _saveUserEmailToPrefs(_currentUser!.email);
        await DatabaseProvider.switchUserDatabase(_currentUser!.email);
      }
      return _currentUser;
    } catch (e, stackTrace) {
      if (e is GoogleSignInException &&
          e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      // ignore: avoid_print
      print('❌ [GoogleAuthService.signInSilently Error]: $e');
      // ignore: avoid_print
      print('❌ [Stack trace]: $stackTrace');
      AppLogger.error('GoogleAuthService.signInSilently Error: $e');
      rethrow;
    }
  }

  /// Signs out from Google.
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    await _saveUserEmailToPrefs(null);
    await DatabaseProvider.switchUserDatabase(null);
  }

  /// Permanently disconnects the Google account and signs out.
  static Future<void> deleteUserAccount() async {
    try {
      await _googleSignIn.disconnect();
    } catch (_) {
      await _googleSignIn.signOut();
    }
    _currentUser = null;
    await _saveUserEmailToPrefs(null);
    await DatabaseProvider.switchUserDatabase(null);
  }

  /// Attempts silent lightweight authentication and returns [GoogleSignInAccount?] without prompting user UI.
  static Future<GoogleSignInAccount?> signInSilentlyAccount() async {
    if (_currentUser != null) return _currentUser;
    try {
      if (!_isInitialized) await initialize();
      _currentUser = await _googleSignIn.attemptLightweightAuthentication();
      if (_currentUser != null) {
        await _saveUserEmailToPrefs(_currentUser!.email);
        await DatabaseProvider.switchUserDatabase(_currentUser!.email);
      }
      return _currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Returns true if user is currently signed in to Google.
  static bool get isSignedIn => _currentUser != null;

  /// Returns the cached signed-in account, if any, without ever triggering
  /// a sign-in attempt (no network/UI). Safe to call on app startup.
  static GoogleSignInAccount? get currentUser => _currentUser;

  /// Generates a Google APIs client authenticated with the user's Google Sign-In credentials.
  static Future<auth.AuthClient?> getAuthenticatedClient({
    bool allowInteractive = true,
  }) async {
    if (!_isInitialized) await initialize();
    if (_currentUser == null) return null;

    final authorization = await _currentUser!.authorizationClient
        .authorizationForScopes(_scopes);

    if (authorization == null) {
      if (!allowInteractive) return null;

      final finalAuthorization = await _currentUser!.authorizationClient
          .authorizeScopes(_scopes);
      return finalAuthorization.authClient(scopes: _scopes);
    }

    return authorization.authClient(scopes: _scopes);
  }
}

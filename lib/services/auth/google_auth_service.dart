import 'dart:async';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:split_trip/core/const/app_string.dart';

class GoogleAuthService {
  GoogleAuthService._();

  static const List<String> _scopes = <String>[
    'email',
    'https://www.googleapis.com/auth/drive.file',
  ];

  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  static GoogleSignInAccount? _currentUser;
  static bool _isInitialized = false;

  /// Returns the currently signed-in Firebase user (if any).
  static User? get firebaseUser => _firebaseAuth.currentUser;

  /// Stream of Firebase auth state changes.
  static Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Call this ONCE at app startup.
  static Future<void> initialize({
    String? clientId,
    // Web Client ID from google-services.json (oauth_client with client_type: 3)
    String? serverClientId =
       AppString.serverClientId,
  }) async {
    if (_isInitialized) return;

    await _googleSignIn.initialize(
      clientId: clientId,
      serverClientId: serverClientId,
    );

    // Listen for authentication events to track user session
    _googleSignIn.authenticationEvents
        .listen((event) {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            _currentUser = event.user;
          } else if (event is GoogleSignInAuthenticationEventSignOut) {
            _currentUser = null;
          }
        })
        .onError((Object error) {
          // Handle or log auth events streams errors
        });

    _isInitialized = true;
  }

  /// Triggers the Google Sign-In interactive flow and signs into Firebase.
  /// Returns [UserCredential?] — use this for login screen.
  static Future<UserCredential?> signIn() async {
    if (!_isInitialized) await initialize();

    // Check if already signed in to Firebase
    if (_firebaseAuth.currentUser != null) {
      return null; // already signed in
    }

    try {
      _currentUser = await _googleSignIn.authenticate();
      if (_currentUser == null) return null;

      return await _signInToFirebase(_currentUser!);
    } catch (e) {
      if (e is GoogleSignInException &&
          e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }
  }

  /// Signs in with Google and returns the [GoogleSignInAccount].
  /// Tries existing or lightweight silent session first; shows UI picker only if necessary.
  static Future<GoogleSignInAccount?> signInForDrive() async {
    if (!_isInitialized) await initialize();

    // 1. If already authenticated in memory, return immediately
    if (_currentUser != null) {
      if (_firebaseAuth.currentUser == null) {
        await _signInToFirebase(_currentUser!);
      }
      return _currentUser;
    }

    // 2. Try silent lightweight auth first
    try {
      _currentUser = await _googleSignIn.attemptLightweightAuthentication();
      if (_currentUser != null) {
        if (_firebaseAuth.currentUser == null) {
          await _signInToFirebase(_currentUser!);
        }
        return _currentUser;
      }
    } catch (_) {  
      // Fall through to interactive prompt if silent auth is unavailable
    }

    // 3. Trigger interactive prompt if not signed in
    try {
      _currentUser = await _googleSignIn.authenticate();
      if (_currentUser == null) return null;

      if (_firebaseAuth.currentUser == null) {
        await _signInToFirebase(_currentUser!);
      }

      return _currentUser;
    } catch (e) {
      if (e is GoogleSignInException &&
          e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }
  }

  /// Attempts silent (lightweight) sign-in and syncs with Firebase.
  static Future<User?> signInSilently() async {
    try {
      if (!_isInitialized) await initialize();
      _currentUser = await _googleSignIn.attemptLightweightAuthentication();
      if (_currentUser == null) return null;

      // Sync with Firebase if not already signed in
      if (_firebaseAuth.currentUser == null) {
        await _signInToFirebase(_currentUser!);
      }
      return _firebaseAuth.currentUser;
    } catch (e) {
      if (e is GoogleSignInException &&
          e.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }
  }

  /// Internal: use Google credentials to sign into Firebase Auth.
  static Future<UserCredential> _signInToFirebase(
    GoogleSignInAccount googleUser,
  ) async {
    final googleAuth = await googleUser.authentication;

    // idToken should always be present — if null, likely SHA-1 fingerprint
    // is missing in Firebase Console or a network/config issue.
    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw Exception(
        'Google idToken is null.\n'
        'Fix: Add your debug SHA-1 fingerprint to Firebase Console.\n'
        'Run: cd android && ./gradlew signingReport',
      );
    }

    // google_sign_in v7+ removed accessToken from GoogleSignInAuthentication.
    // idToken alone is sufficient for Firebase Google sign-in.
    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return await _firebaseAuth.signInWithCredential(credential);
  }

  /// Signs out from both Google and Firebase.
  static Future<void> signOut() async {
    await Future.wait([_googleSignIn.signOut(), _firebaseAuth.signOut()]);
    _currentUser = null;
  }

  /// Permanently deletes the current Firebase user account and signs out from Google.
  static Future<void> deleteUserAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          final googleUser = await _googleSignIn.authenticate();
          if (googleUser != null) {
            final googleAuth = await googleUser.authentication;
            final credential =
                GoogleAuthProvider.credential(idToken: googleAuth.idToken);
            await user.reauthenticateWithCredential(credential);
            await user.delete();
          }
        } else {
          rethrow;
        }
      }
    }
    await signOut();
  }

  /// Returns the current signed-in Google account (checks Firebase first).
  static Future<GoogleSignInAccount?> getCurrentGoogleUser() async {
    if (_currentUser != null) return _currentUser;
    return null;
  }

  /// Attempts silent lightweight authentication and returns [GoogleSignInAccount?] without prompting user UI.
  static Future<GoogleSignInAccount?> signInSilentlyAccount() async {
    if (_currentUser != null) return _currentUser;
    try {
      if (!_isInitialized) await initialize();
      _currentUser = await _googleSignIn.attemptLightweightAuthentication();
      return _currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Returns true if user is currently signed in to Firebase.
  static bool get isSignedIn => _firebaseAuth.currentUser != null;

  /// Generates a Google APIs client authenticated with the user's Google Sign-In credentials.
  /// Set [allowInteractive] to false during background/auto-backup operations to prevent UI popups on app launch.
  static Future<auth.AuthClient?> getAuthenticatedClient({
    bool allowInteractive = true,
  }) async {
    if (!_isInitialized) await initialize();
    if (_currentUser == null) return null;

    final authorization = await _currentUser!.authorizationClient
        .authorizationForScopes(_scopes);

    if (authorization == null) {
      if (!allowInteractive) return null;

      final finalAuthorization =
          await _currentUser!.authorizationClient.authorizeScopes(_scopes);
      return finalAuthorization.authClient(scopes: _scopes);
    }

    return authorization.authClient(scopes: _scopes);
  }
}

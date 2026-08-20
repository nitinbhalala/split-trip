import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:split_trip/core/common/widgets/app_logger.dart';

class AppleAuthService {
  AppleAuthService._();

  static final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Returns the currently signed-in Firebase user (if any).
  static User? get firebaseUser => _firebaseAuth.currentUser;

  /// Stream of Firebase auth state changes.
  static Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Returns true if user is currently signed in to Firebase.
  static bool get isSignedIn => _firebaseAuth.currentUser != null;

  /// Generates a cryptographically secure random nonce.
  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Generates SHA256 string from input.
  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Triggers the Apple Sign-In interactive flow and signs into Firebase.
  static Future<UserCredential?> signIn() async {
    try {
      // 1. Generate nonce for security
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      // 2. Request Apple ID Credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // 3. Create Firebase OAuth Credential
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
        rawNonce: rawNonce,
      );

      // 4. Sign in to Firebase with credential
      final userCredential =
          await _firebaseAuth.signInWithCredential(oauthCredential);

      // Save user display name if returned on first Apple Sign-In
      final user = userCredential.user;
      if (user != null) {
        final givenName = appleCredential.givenName;
        final familyName = appleCredential.familyName;
        if (givenName != null && givenName.isNotEmpty) {
          final fullName = familyName != null && familyName.isNotEmpty
              ? '$givenName $familyName'
              : givenName;
          if (user.displayName == null || user.displayName!.isEmpty) {
            await user.updateDisplayName(fullName);
          }
        }
      }

      return userCredential;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        // ignore: avoid_print
        print('ℹ️ [AppleAuthService]: Sign in cancelled by user.');
        AppLogger.log('Apple Sign in cancelled by user.');
        return null;
      }
      // ignore: avoid_print
      print('❌ [AppleAuthService.signIn Error]: $e');
      AppLogger.error('AppleAuthService.signIn Error: $e');
      rethrow;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'canceled' ||
          e.code == 'web-context-cancelled' ||
          e.code == 'user-cancelled' ||
          e.code == 'ERROR_ABORTED_BY_USER') {
        // ignore: avoid_print
        print('ℹ️ [AppleAuthService]: Firebase sign in cancelled by user.');
        return null;
      }
      // ignore: avoid_print
      print('❌ [AppleAuthService.signIn FirebaseAuthException]: $e');
      AppLogger.error('AppleAuthService.signIn FirebaseAuthException: $e');
      rethrow;
    } catch (e, stackTrace) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('cancel') || errStr.contains('1001')) {
        // ignore: avoid_print
        print('ℹ️ [AppleAuthService]: Sign in cancelled by user (1001).');
        return null;
      }
      // ignore: avoid_print
      print('❌ [AppleAuthService.signIn Error]: $e');
      // ignore: avoid_print
      print('❌ [Stack trace]: $stackTrace');
      AppLogger.error('AppleAuthService.signIn Error: $e');
      AppLogger.error('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Signs out from Firebase.
  static Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Permanently deletes the current Firebase user account.
  static Future<void> deleteUserAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      try {
        await user.delete();
      } on FirebaseAuthException catch (e) {
        if (e.code == 'requires-recent-login') {
          final rawNonce = _generateNonce();
          final nonce = _sha256ofString(rawNonce);
          final appleCredential = await SignInWithApple.getAppleIDCredential(
            scopes: [
              AppleIDAuthorizationScopes.email,
              AppleIDAuthorizationScopes.fullName,
            ],
            nonce: nonce,
          );
          final oauthCredential = OAuthProvider('apple.com').credential(
            idToken: appleCredential.identityToken,
            accessToken: appleCredential.authorizationCode,
            rawNonce: rawNonce,
          );
          await user.reauthenticateWithCredential(oauthCredential);
          await user.delete();
        } else {
          rethrow;
        }
      }
    }
    await signOut();
  }
}

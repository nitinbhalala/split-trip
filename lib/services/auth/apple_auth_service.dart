// import 'dart:async';
// import 'package:sign_in_with_apple/sign_in_with_apple.dart';
// import 'package:split_trip/core/common/widgets/app_logger.dart';

// class AppleAuthService {
//   AppleAuthService._();

//   static AuthorizationCredentialAppleID? _appleIDCredential;

//   /// Returns true if user signed in via Apple.
//   static bool get isSignedIn => _appleIDCredential != null;

//   /// Triggers the Apple Sign-In interactive flow.
//   static Future<AuthorizationCredentialAppleID?> signIn() async {
//     try {
//       _appleIDCredential = await SignInWithApple.getAppleIDCredential(
//         scopes: [
//           AppleIDAuthorizationScopes.email,
//           AppleIDAuthorizationScopes.fullName,
//         ],
//       );

//       return _appleIDCredential;
//     } on SignInWithAppleAuthorizationException catch (e) {
//       if (e.code == AuthorizationErrorCode.canceled) {
//         // ignore: avoid_print
//         print('ℹ️ [AppleAuthService]: Sign in cancelled by user.');
//         AppLogger.log('Apple Sign in cancelled by user.');
//         return null;
//       }
//       // ignore: avoid_print
//       print('❌ [AppleAuthService.signIn Error]: $e');
//       AppLogger.error('AppleAuthService.signIn Error: $e');
//       rethrow;
//     } catch (e, stackTrace) {
//       final errStr = e.toString().toLowerCase();
//       if (errStr.contains('cancel') || errStr.contains('1001')) {
//         // ignore: avoid_print
//         print('ℹ️ [AppleAuthService]: Sign in cancelled by user (1001).');
//         return null;
//       }
//       // ignore: avoid_print
//       print('❌ [AppleAuthService.signIn Error]: $e');
//       // ignore: avoid_print
//       print('❌ [Stack trace]: $stackTrace');
//       AppLogger.error('AppleAuthService.signIn Error: $e');
//       AppLogger.error('Stack trace: $stackTrace');
//       rethrow;
//     }
//   }

//   /// Signs out.
//   static Future<void> signOut() async {
//     _appleIDCredential = null;
//   }

//   /// Deletes account session.
//   static Future<void> deleteUserAccount() async {
//     await signOut();
//   }
// }

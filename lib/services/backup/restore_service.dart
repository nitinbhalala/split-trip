import 'dart:convert';
import 'package:split_trip/modules/Settings/controller/profile_controller.dart';
import 'package:split_trip/services/auth/google_auth_service.dart';
import 'package:split_trip/services/google_drive/google_drive_service.dart';
import 'package:split_trip/services/gzip/gzip_service.dart';
import 'package:split_trip/services/sqlite/database_import_service.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

class RestoreResult {
  final bool success;
  final String? error;
  final bool noBackupFound;
  final bool emailMismatch;

  RestoreResult({
    required this.success,
    this.error,
    this.noBackupFound = false,
    this.emailMismatch = false,
  });
}

class RestoreService {
  RestoreService._();

  /// Executes the restore process: verification, file download, decompression, parsing, SQLite transaction import, and controller reload.
  static Future<RestoreResult> performRestore(GoogleSignInAccount account) async {
    try {
      final profileController = Get.find<ProfileController>();
      final googleEmail = account.email.trim();
      var profileEmail = profileController.email.value.trim();

      // 1. If local Profile email is empty, auto-sync with Google account email
      if (profileEmail.isEmpty) {
        profileEmail = googleEmail;
        await profileController.saveProfile(
          fName: profileController.firstName.value,
          lName: profileController.lastName.value,
          emailVal: googleEmail,
          profilePicPath: profileController.profilePicture.value,
        );
      }

      // 2. Verify Google account email matches Profile email (case-insensitive)
      if (googleEmail.toLowerCase() != profileEmail.toLowerCase()) {
        return RestoreResult(
          success: false,
          emailMismatch: true,
          error: "Google account email does not match your Profile email.\n\n"
              "Google: $googleEmail\n"
              "Profile: $profileEmail",
        );
      }

      // Get authenticated client
      final client = await GoogleAuthService.getAuthenticatedClient();
      if (client == null) {
        return RestoreResult(
          success: false,
          error: "Failed to get Google API authenticated client.",
        );
      }

      // 2. Download backup
      final gzipBytes = await GoogleDriveService.downloadFile(
        client: client,
        fileName: 'expense_backup.gz',
        folderName: 'Expense Tracker',
      );

      if (gzipBytes == null || gzipBytes.isEmpty) {
        return RestoreResult(
          success: false,
          noBackupFound: true,
          error: "No backup file found in Google Drive.",
        );
      }

      // 3. Decompress GZip
      final decompressedBytes = GZipService.decompress(gzipBytes);
      final jsonStr = utf8.decode(decompressedBytes);

      // 4. Parse JSON
      final Map<String, dynamic> dbData = jsonDecode(jsonStr) as Map<String, dynamic>;

      // 5. Restore all SQLite tables inside transaction
      await DatabaseImportService.importDatabase(dbData);

      // 6. Refresh controllers so local UI list values update immediately
      await profileController.loadProfile();

      // if (Get.isRegistered<AccountController>()) {
      //   await Get.find<AccountController>().loadAccounts();
      // }

      // if (Get.isRegistered<TransactionController>()) {
      //   await Get.find<TransactionController>().loadTransactions();
      // }

      // if (Get.isRegistered<PaymentModeController>()) {
      //   await Get.find<PaymentModeController>().loadPaymentModes();
      // }

      return RestoreResult(success: true);
    } catch (e) {
      return RestoreResult(
        success: false,
        error: "Restore failed: $e",
      );
    }
  }
}

import 'dart:convert';
import 'package:split_trip/core/common/widgets/app_logger.dart';
import 'package:split_trip/data/database/db_constants.dart';
import 'package:split_trip/modules/Settings/controller/profile_controller.dart';
import 'package:split_trip/services/auth/google_auth_service.dart';
import 'package:split_trip/services/google_drive/google_drive_service.dart';
import 'package:split_trip/services/gzip/gzip_service.dart';
import 'package:split_trip/services/sqlite/database_export_service.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BackupResult {
  final bool success;
  final String? error;
  final bool profileIncomplete;
  final bool emailMismatch;

  BackupResult({
    required this.success,
    this.error,
    this.profileIncomplete = false,
    this.emailMismatch = false,
  });
}

class BackupService {
  BackupService._();

  /// Executes the backup process: profile check, email verification, database export, compression, and drive upload.
  static Future<BackupResult> performBackup(
    GoogleSignInAccount account, {
    bool isAutoBackup = false,
  }) async {
    try {
      final profileController = Get.find<ProfileController>();

      final googleEmail = account.email.trim();
      var profileEmail = profileController.email.value.trim();

      // 1. If Profile email is empty, auto-sync with Google account email
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
        return BackupResult(
          success: false,
          emailMismatch: true,
          error:
              "Google account email does not match your Profile email.\n\n"
              "Google: $googleEmail\n"
              "Profile: $profileEmail",
        );
      }

      // Get authenticated client (disable interactive UI popups for auto backup)
      final client = await GoogleAuthService.getAuthenticatedClient(
        allowInteractive: !isAutoBackup,
      );
      if (client == null) {
        return BackupResult(
          success: false,
          error: "Failed to get Google API authenticated client.",
        );
      }

      // 3. Export database
      final dbData = await DatabaseExportService.exportDatabase();
      final jsonStr = jsonEncode(dbData);
      final bytes = utf8.encode(jsonStr);

      // 4. Compress using GZip
      final gzipBytes = GZipService.compress(bytes);

      // Metadata
      final now = DateTime.now();
      final backupDate = DateFormat('yyyy-MM-dd').format(now);
      final backupTime = DateFormat('HH:mm:ss').format(now);

      final metadata = {
        'backupDate': backupDate,
        'backupTime': backupTime,
        'appVersion': '1.0.0', // Fallback standard app version constant
        'dbVersion': DBConstants.databaseVersion.toString(),
        'googleEmail': account.email,
      };

      // 5. Upload file to Google Drive
      await GoogleDriveService.uploadOrReplaceFile(
        client: client,
        bytes: gzipBytes,
        fileName: 'Split_trip.gz',
        folderName: 'Split_trip',
        appProperties: metadata,
      );

      // Reset change tracking flag and update last backup date
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_auto_backup_date', backupDate);
      await prefs.setBool('has_unbacked_up_changes', false);

      return BackupResult(success: true);
    } catch (e) {
      AppLogger.error(useDebug: true, "Backup failed: $e");
      return BackupResult(success: false, error: "Backup failed: $e");
    }
  }

  /// Call this whenever any transaction, account, category, or profile data is modified.
  static Future<void> markDataChanged() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_unbacked_up_changes', true);
    } catch (e) {
      AppLogger.error(useDebug: true, "Failed to mark data changed: $e");
    }
  }

  /// Performs a daily auto-backup ONLY IF data has changed since the last backup.
  static Future<void> performAutoBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final lastBackupDate = prefs.getString('last_auto_backup_date');
      final hasChanges = prefs.getBool('has_unbacked_up_changes') ?? true;

      // Skip backup if already backed up today OR if no data changes occurred
      if (lastBackupDate == today || !hasChanges) {
        return;
      }

      // Check if user is signed in to Google
      final account = await GoogleAuthService.signInSilentlyAccount();
      if (account == null) return;

      await performBackup(account, isAutoBackup: true);
    } catch (e) {
      AppLogger.error(useDebug: true, "Silent daily auto backup skipped/failed: $e");
    }
  }
}



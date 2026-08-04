import 'package:split_trip/core/common/widgets/app_logger.dart';
import 'package:split_trip/core/common/widgets/app_snackbar.dart';
import 'package:split_trip/core/router/app_pages.dart';
import 'package:split_trip/services/auth/google_auth_service.dart';
import 'package:split_trip/services/backup/backup_service.dart';
import 'package:split_trip/services/backup/restore_service.dart';
import 'package:split_trip/modules/Settings/controller/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:split_trip/services/analytics/analytics_service.dart';

class BackupController extends GetxController {
  final RxBool isBackupLoading = false.obs;
  final RxBool isRestoreLoading = false.obs;

  /// Starts the Backup to Google Drive flow.
  Future<void> backupToGoogleDrive() async {
    if (isBackupLoading.value ||
        isRestoreLoading.value ||
        Get.isDialogOpen == true) {
      return;
    }
    isBackupLoading.value = true;

    // 1. Verify Profile Completeness (No loader shown)
    final profileController = Get.find<ProfileController>();
    var email = profileController.email.value.trim();

    if (email.isEmpty) {
      final fbUser = GoogleAuthService.firebaseUser;
      if (fbUser?.email != null && fbUser!.email!.isNotEmpty) {
        email = fbUser.email!.trim();
        await profileController.saveProfile(
          fName: profileController.firstName.value,
          lName: profileController.lastName.value,
          emailVal: email,
          profilePicPath: profileController.profilePicture.value,
        );
      }
    }

    if (email.isEmpty) {
      _showIncompleteProfileDialog();
      isBackupLoading.value = false;
      return;
    }

    // 2. Perform Google Sign-In first (No loader shown, Google selector sheet opens cleanly)
    GoogleSignInAccount? account;
    try {
      account = await GoogleAuthService.signInForDrive();
    } catch (e) {
      AppLogger.error("Google Sign-In failed: $e");
      AppSnackbar.error(message: "Google Sign-In failed: $e");
      isBackupLoading.value = false;
      return;
    }

    if (account == null) {
      AppSnackbar.error(message: "Google Sign-In cancelled.");
      isBackupLoading.value = false;
      return;
    }

    // 3. NOW show the loader dialog while we perform background export and upload operations
    _showLoaderDialog("Backing up data...");

    try {
      final result = await BackupService.performBackup(account);
      await _hideLoaderDialog();

      // Log success or fail event
      await AnalyticsService.logBackup(
        success: result.success,
        error: result.success ? null : (result.error ?? "Failed to perform backup."),
      );

      if (result.success) {
        AppSnackbar.success(message: "Backup completed successfully.");
      } else {
        if (result.profileIncomplete) {
          _showIncompleteProfileDialog();
        } else if (result.emailMismatch) {
          _showEmailMismatchDialog(result.error ?? "", isBackup: true);
        } else {
          AppSnackbar.error(
            message: result.error ?? "Failed to perform backup.",
          );
        }
      }
    } catch (e) {
      await _hideLoaderDialog();
      await AnalyticsService.logBackup(success: false, error: e.toString());
      AppLogger.error("Backup failed: $e");
      AppSnackbar.error(message: "Backup failed: $e");
    } finally {
      isBackupLoading.value = false;
    }
  }

  /// Starts the Restore from Google Drive flow, asking for confirmation first.
  void restoreFromGoogleDrive() {
    if (isBackupLoading.value ||
        isRestoreLoading.value ||
        Get.isDialogOpen == true) {
      return;
    }

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Restore Database"),
        content: const Text(
          "Are you sure you want to restore from Google Drive?\n\n"
          "This will overwrite and permanently delete your current local accounts, categories, and transactions.",
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Get.back();
              _executeRestore();
            },
            child: const Text("Overwrite & Restore"),
          ),
        ],
      ),
    );
  }

  Future<void> _executeRestore() async {
    if (isBackupLoading.value || isRestoreLoading.value) return;
    isRestoreLoading.value = true;

    // 1. Perform Google Sign-In first (No loader shown)
    GoogleSignInAccount? account;
    try {
      account = await GoogleAuthService.signInForDrive();
    } catch (e) {
      AppSnackbar.error(message: "Google Sign-In failed: $e");
      isRestoreLoading.value = false;
      return;
    }

    if (account == null) {
      AppSnackbar.error(message: "Google Sign-In cancelled.");
      isRestoreLoading.value = false;
      return;
    }

    // 2. NOW show the loader dialog while we perform background download and import operations
    _showLoaderDialog("Restoring data...");

    try {
      final result = await RestoreService.performRestore(account);
      await _hideLoaderDialog();

      // Log success or fail event
      await AnalyticsService.logRestore(
        success: result.success,
        error: result.success ? null : (result.error ?? "Failed to restore database."),
      );

      if (result.success) {
        AppSnackbar.success(message: "Database restored successfully.");
      } else {
        if (result.emailMismatch) {
          _showEmailMismatchDialog(result.error ?? "", isBackup: false);
        } else if (result.noBackupFound) {
          _showErrorDialog("No Backup Found", result.error ?? "");
        } else {
          AppSnackbar.error(
            message: result.error ?? "Failed to restore database.",
          );
        }
      }
    } catch (e) {
      await _hideLoaderDialog();
      await AnalyticsService.logRestore(success: false, error: e.toString());
      AppSnackbar.error(message: "Restore failed: $e");
    } finally {
      isRestoreLoading.value = false;
    }
  }

  // ── Helper Overlays ────────────────────────────────────────────────────────

  void _showLoaderDialog(String message) {
    Get.dialog(
      PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 280,
            color: Theme.of(Get.context!).colorScheme.surface,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.8),
    );
  }

  Future<void> _hideLoaderDialog() async {
    // Add a tiny delay to ensure Get.dialog transition has fully started
    await Future.delayed(const Duration(milliseconds: 200));
    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  void _showIncompleteProfileDialog() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Incomplete Profile"),
        content: const Text(
          "An email address is required inside your Profile details to perform backups. Please update it first.",
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Get.back();
              Get.toNamed(AppRoutes.profile);
            },
            child: const Text("Go to Profile"),
          ),
        ],
      ),
    );
  }

  void _showEmailMismatchDialog(String message, {required bool isBackup}) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Email Mismatch"),
        content: Text(
          "$message\n\n"
          "Would you like to sign out of the current Google account and switch to another account?",
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              Get.back(); // close dialog

              // Sign out from the current mismatch account
              _showLoaderDialog("Signing out...");
              await GoogleAuthService.signOut();
              await _hideLoaderDialog();

              // Re-trigger the flow with interactive sign-in
              if (isBackup) {
                backupToGoogleDrive();
              } else {
                _executeRestore();
              }
            },
            child: const Text("Switch Account"),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String title, String message) {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(onPressed: () => Get.back(), child: const Text("OK")),
        ],
      ),
    );
  }
}

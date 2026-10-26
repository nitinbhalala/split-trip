import 'package:split_trip/core/common/dailog/common_general_dialog.dart';
import 'package:split_trip/core/common/widgets/app_alert_dialog.dart';
import 'package:split_trip/core/common/widgets/app_logger.dart';
import 'package:split_trip/core/common/widgets/app_snackbar.dart';
import 'package:split_trip/core/router/app_pages.dart';
import 'package:split_trip/services/auth/google_auth_service.dart';
import 'package:split_trip/services/backup/backup_service.dart';
import 'package:split_trip/services/backup/restore_service.dart';
import 'package:split_trip/services/google_drive/google_drive_service.dart';
import 'package:split_trip/data/database/database_helper.dart';
import 'package:split_trip/data/database/db_constants.dart';
import 'package:split_trip/modules/Group/controller/group_controller.dart';
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

    // 1. Perform Google Sign-In first (Prompts sign-in sheet if guest user)
    GoogleSignInAccount? account;
    try {
      account = await GoogleAuthService.signInForDrive();
    } catch (e) {
      AppLogger.error("Google Sign-In failed: $e");
      AppSnackbar.error(message: "Google Sign-In failed: $e");
      isBackupLoading.value = false;
      return;
    }

    if (account == null || !GoogleAuthService.isSignedIn) {
      AppSnackbar.warning(
        message: "Google Sign-In is required to backup data to Google Drive.",
      );
      isBackupLoading.value = false;
      return;
    }

    // 2. Guard against silently overwriting an existing Drive backup:
    // if this device's local data is empty but a backup already exists for
    // this account (e.g. fresh install / cleared app data), let the user
    // choose to restore it instead of pushing an empty backup over it.
    final isLocalEmpty = await RestoreService.isLocalDatabaseEmpty();
    if (isLocalEmpty) {
      final hasExistingBackup = await RestoreService.hasBackup(account);
      if (hasExistingBackup) {
        final wantsRestore = await AppAlertDialog.show<bool>(
          titleText: "Restore Backup Found",
          contentText:
              "We found an existing data backup associated with ${account.email} on Google Drive.\n\n"
              "Would you like to restore your previous expenses and groups instead of creating a new empty backup?",
          barrierDismissible: false,
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text("Continue Backup"),
            ),
            ElevatedButton(
              onPressed: () => Get.back(result: true),
              child: const Text("Restore Data"),
            ),
          ],
        );

        // Back press / system dismissal returns null — treat that as an
        // explicit cancel of the whole backup flow, not as "Continue Backup".
        if (wantsRestore == null) {
          isBackupLoading.value = false;
          return;
        }

        if (wantsRestore == true) {
          isBackupLoading.value = false;
          await _executeRestoreForAccount(account);
          return;
        }
      }
    }

    // 3. Sync Profile details with Google account if local email is empty
    final profileController = Get.find<ProfileController>();
    var email = profileController.email.value.trim();

    if (email.isEmpty) {
      email = account.email.trim();
      final displayName = account.displayName ?? "";
      String fName = profileController.firstName.value.trim();
      String lName = profileController.lastName.value.trim();

      if (fName.isEmpty && displayName.isNotEmpty) {
        final parts = displayName.split(" ");
        fName = parts.first;
        if (parts.length > 1) {
          lName = parts.sublist(1).join(" ");
        }
      }

      await profileController.saveProfile(
        fName: fName.isNotEmpty ? fName : "User",
        lName: lName,
        emailVal: email,
        profilePicPath: profileController.profilePicture.value,
      );
    }

    // 4. NOW show the loader dialog while we perform background export and upload operations
    _showLoaderDialog("Backing up data...");

    try {
      final result = await BackupService.performBackup(account);
      await _hideLoaderDialog();

      // Log success or fail event
      await AnalyticsService.logBackup(
        success: result.success,
        error: result.success
            ? null
            : (result.error ?? "Failed to perform backup."),
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

    AppAlertDialog.show(
      titleText: "Restore Database",
      contentText:
          "Are you sure you want to restore from Google Drive?\n\n"
          "This will overwrite and permanently delete your current local accounts, categories, and transactions.",
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

    if (account == null || !GoogleAuthService.isSignedIn) {
      AppSnackbar.warning(
        message: "Google Sign-In is required to restore data from Google Drive.",
      );
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
        error: result.success
            ? null
            : (result.error ?? "Failed to restore database."),
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
    AppAlertDialog.show(
      titleText: "Incomplete Profile",
      contentText:
          "An email address is required inside your Profile details to perform backups. Please update it first.",
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
    );
  }

  void _showEmailMismatchDialog(
    String message, {
    required bool isBackup,
    VoidCallback? onSwitchAccount,
  }) {
    AppAlertDialog.show(
      titleText: "Email Mismatch",
      contentText:
          "$message\n\n"
          "Would you like to sign out of the current Google account and switch to another account?",
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
            if (onSwitchAccount != null) {
              onSwitchAccount();
            } else if (isBackup) {
              backupToGoogleDrive();
            } else {
              _executeRestore();
            }
          },
          child: const Text("Switch Account"),
        ),
      ],
    );
  }

  void _showErrorDialog(String title, String message) {
    AppAlertDialog.show(
      titleText: title,
      contentText: message,
      actions: [
        ElevatedButton(onPressed: () => Get.back(), child: const Text("OK")),
      ],
    );
  }

  Future<void> _executeRestoreForAccount(GoogleSignInAccount account) async {
    if (isRestoreLoading.value) return;
    isRestoreLoading.value = true;

    _showLoaderDialog("Restoring your data from Google Drive...");

    try {
      final result = await RestoreService.performRestore(account);
      await _hideLoaderDialog();

      await AnalyticsService.logRestore(
        success: result.success,
        error: result.success
            ? null
            : (result.error ?? "Failed to restore database."),
      );

      if (result.success) {
        if (Get.isRegistered<GroupController>()) {
          await Get.find<GroupController>().loadGroups();
        }
        AppSnackbar.success(message: "Data restored successfully.");
      } else {
        AppSnackbar.error(
          message: result.error ?? "Failed to restore data.",
        );
      }
    } catch (e) {
      await _hideLoaderDialog();
      await AnalyticsService.logRestore(success: false, error: e.toString());
      AppSnackbar.error(message: "Restore failed: $e");
    } finally {
      isRestoreLoading.value = false;
    }
  }

  /// Deletes the backup file from Google Drive after confirmation.
  Future<void> deleteBackupFromGoogleDrive(BuildContext context) async {
    if (isBackupLoading.value ||
        isRestoreLoading.value ||
        Get.isDialogOpen == true) {
      return;
    }

    // 1. Sign in first so we know exactly which account's backup is about
    // to be deleted, instead of asking a generic confirmation up front.
    GoogleSignInAccount? account;
    try {
      account = await GoogleAuthService.signInForDrive();
    } catch (e) {
      AppSnackbar.error(message: "Google Sign-In failed: $e");
      return;
    }

    if (account == null || !GoogleAuthService.isSignedIn) {
      AppSnackbar.warning(
        message:
            "Google Sign-In is required to delete backup data from Google Drive.",
      );
      return;
    }

    // 2. If a Profile email was already set (i.e. a backup was taken
    // before), it must match the signed-in Google account so we never
    // delete a different account's backup by mistake.
    final profileController = Get.find<ProfileController>();
    final profileEmail = profileController.email.value.trim();
    final googleEmail = account.email.trim();

    if (profileEmail.isNotEmpty &&
        profileEmail.toLowerCase() != googleEmail.toLowerCase()) {
      _showEmailMismatchDialog(
        "Google account email does not match your Profile email.\n\n"
        "Google: $googleEmail\n"
        "Profile: $profileEmail",
        isBackup: false,
        onSwitchAccount: () => deleteBackupFromGoogleDrive(context),
      );
      return;
    }

    // 3. Confirm with the exact account email whose backup will be removed
    // (defaults to the already-set Profile email whenever one exists).
    if (!context.mounted) return;
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: "Delete Backup Data",
      message:
          "Are you sure you want to delete the backup data for $googleEmail from Google Drive?\n\n"
          "This will permanently delete your backup file ('Split_trip.gz') from Google Drive AND clear your expenses/groups stored locally on this device. This action cannot be undone.",
      confirmText: "Delete Backup",
      cancelText: "Cancel",
      isDeleteAction: true,
      icon: Icons.delete_forever_rounded,
    );

    if (confirmed != true) return;

    _showLoaderDialog("Deleting backup from Google Drive...");

    try {
      final client = await GoogleAuthService.getAuthenticatedClient();
      if (client == null) {
        await _hideLoaderDialog();
        AppSnackbar.error(
          message: "Failed to get Google API authenticated client.",
        );
        return;
      }

      final deleted = await GoogleDriveService.deleteBackupFile(
        client: client,
        fileName: 'Split_trip.gz',
        folderName: 'Split_trip',
      );

      // Also clear the expenses/groups stored locally on this device, so
      // "Delete Backup Data" removes both the cloud copy and the local copy.
      final db = DatabaseHelper.instance;
      await db.clearTable(DBConstants.groupMessagesTable);
      await db.clearTable(DBConstants.groupMembersTable);
      await db.clearTable(DBConstants.groupsTable);

      if (Get.isRegistered<GroupController>()) {
        await Get.find<GroupController>().loadGroups();
      }

      await _hideLoaderDialog();

      if (deleted) {
        AppSnackbar.success(
          message:
              "Backup data deleted from Google Drive and cleared from this device.",
        );
      } else {
        AppSnackbar.warning(
          message:
              "No backup file found on Google Drive. Local data on this device has been cleared.",
        );
      }
    } catch (e) {
      await _hideLoaderDialog();
      AppLogger.error(useDebug: true, "Failed to delete backup: $e");
      AppSnackbar.error(message: "Failed to delete backup: $e");
    }
  }
}



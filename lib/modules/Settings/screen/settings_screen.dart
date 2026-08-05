import 'dart:io';
import 'package:split_trip/core/common/divider/app_divider.dart';
import 'package:split_trip/core/common/widgets/app_card.dart';
import 'package:split_trip/core/common/widgets/common_app_bar.dart';
import 'package:split_trip/core/const/app_string.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';
import 'package:split_trip/core/theme/theme_controller.dart';
import 'package:split_trip/data/service/share_service.dart';
import 'package:split_trip/data/service/url_helper.dart';
import 'package:split_trip/modules/Settings/controller/backup_controller.dart';
import 'package:split_trip/modules/Settings/controller/currency_controller.dart';
import 'package:split_trip/modules/Settings/controller/profile_controller.dart';
import 'package:split_trip/core/router/app_pages.dart';
import 'package:split_trip/data/database/database_helper.dart';
import 'package:split_trip/data/database/db_constants.dart';
import 'package:split_trip/core/common/dailog/common_general_dialog.dart';
import 'package:split_trip/core/common/widgets/app_snackbar.dart';
import 'package:split_trip/data/service/shared_preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/services/auth/google_auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyController = Get.find<CurrencyController>();
    final themeController = Get.find<ThemeController>();
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: const CommonAppBar(title: "Settings", showBackButton: false),
      body: SingleChildScrollView(
        padding: AppSize.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Profile Section
            Align(alignment: Alignment.center, child: const _ProfileHeader()),
            AppSize.gapH(20),

            // Section Title: Preferences
            Text(
              "Preferences",
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: AppSize.sp(11.5),
              ),
            ),
            AppSize.gapH(8),

            // 2. Preferences Card Group
            Column(
              children: [
                // Currency Selection Card
                Obx(
                  () => _SettingsTile(
                    icon: Icons.currency_exchange_rounded,
                    iconColor: AppColors.income,
                    title: "Currency",
                    subtitle: "Change app-wide currency symbol",
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "${currencyController.selectedCurrency.value.code} (${currencyController.selectedCurrency.value.symbol})",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: AppSize.sp(11.5),
                          ),
                        ),
                        AppSize.gapW(4),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: AppSize.sp(20),
                        ),
                      ],
                    ),
                    onTap: () {
                      Get.toNamed(AppRoutes.selectCurrency);
                    },
                  ),
                ),

                AppDivider(color: theme.colorScheme.outlineVariant),

                // Theme Selection Card
                Obx(
                  () => _SettingsTile(
                    icon: Icons.palette_outlined,
                    iconColor: Colors.purple,
                    title: "App Theme",
                    subtitle: "Choose light, dark, or system look",
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          themeController.themeMode == ThemeMode.light
                              ? "Light"
                              : themeController.themeMode == ThemeMode.dark
                              ? "Dark"
                              : "System",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: AppSize.sp(11),
                          ),
                        ),
                        AppSize.gapW(4),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: AppSize.sp(20),
                        ),
                      ],
                    ),
                    onTap: () {
                      Get.toNamed(AppRoutes.selectTheme);
                    },
                  ),
                ),
              ],
            ),
            // Section Title: Backup & Restore
            Text(
              "Backup & Restore",
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: AppSize.sp(11.5),
              ),
            ),
            AppSize.gapH(8),

            // Backup & Restore Card Group
            Column(
              children: [
                _SettingsTile(
                  icon: Icons.cloud_upload_outlined,
                  iconColor: Colors.blue,
                  title: "Backup to Google Drive",
                  subtitle: "Save accounts and transactions online",

                  onTap: () {
                    final backupController = Get.find<BackupController>();
                    backupController.backupToGoogleDrive();
                  },
                ),
                AppDivider(color: theme.colorScheme.outlineVariant),
                _SettingsTile(
                  icon: Icons.cloud_download_outlined,
                  iconColor: Colors.green,
                  title: "Restore from Google Drive",
                  subtitle: "Restore accounts and transactions backup",

                  onTap: () {
                    final backupController = Get.find<BackupController>();
                    backupController.restoreFromGoogleDrive();
                  },
                ),
              ],
            ),
            AppSize.gapH(20),

            AppSize.gapH(20),

            // Section Title: Support & About
            Text(
              "About & Support",
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                fontSize: AppSize.sp(11.5),
              ),
            ),
            AppSize.gapH(8),

            // 3. Support & About Card Group
            Column(
              children: [
                _SettingsTile(
                  iconColor: AppColors.income,
                  icon: Icons.privacy_tip,
                  title: "Privacy Policy",
                  subtitle:
                      "Learn about our privacy practices and data handling",
                  onTap: () =>
                      UrlHelper.launchAnyUrl(AppString.privacyPolicyURl),
                ),
                AppDivider(color: theme.colorScheme.outlineVariant),
                _SettingsTile(
                  iconColor: Colors.blue,
                  icon: Icons.share_sharp,
                  title: "Share App",
                  subtitle: "Invite friends and family to use Expense Tacker",
                  onTap: () async {
                    await ShareService.shareText(
                      "Download ${AppString.appname}\n\n${AppString.shareAppLink}",
                    );
                  },
                ),
                AppDivider(color: theme.colorScheme.outlineVariant),

                _SettingsTile(
                  iconColor: AppColors.warning,
                  icon: Icons.star_border_outlined,
                  title: "Rate Us App",
                  subtitle: "Share your feeback and rate our app",
                  onTap: () async {
                    await UrlHelper.launchAnyUrl(AppString.rateUsLink);
                  },
                ),
                AppDivider(color: theme.colorScheme.outlineVariant),
                // _SettingsTile(
                //   icon: Icons.logout_rounded,
                //   iconColor: Colors.red,
                //   title: "Logout",
                //   subtitle: "Sign out of your account",
                //   onTap: () {
                //     _showLogoutConfirmationDialog(context);
                //   },
                // ),
                AppDivider(color: theme.colorScheme.outlineVariant),
                _SettingsTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: Colors.blue,
                  title: "Version",
                  subtitle: "App version and details",
                  trailing: Text(
                    "1.0.0+1",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: AppSize.sp(11),
                    ),
                  ),
                  onTap: () {},
                ),
                AppDivider(color: theme.colorScheme.outlineVariant),
                _SettingsTile(
                  icon: Icons.delete_forever_rounded,
                  iconColor: AppColors.error,
                  delete: true,
                  title: "Account Delete",
                  subtitle: "Delete your account permanently",
                  onTap: () {
                    _showDeleteAccountConfirmationDialog(context);
                  },
                ),
                AppSize.gapH(15),

                AppCard(
                  boxShadow: true,
                  borderColor: isDark
                      ? AppColors.error.withValues(alpha: 0.5)
                      : AppColors.error.withValues(alpha: 0.3),
                  padding: AppSize.symmetric(horizontal: 6, vertical: 6),
                  height: AppSize.h(45),
                  width: AppSize.w(250),
                  color: theme.scaffoldBackgroundColor,
                  onTap: () => _showLogoutConfirmationDialog(context),
                  child: Row(
                    mainAxisAlignment: .center,
                    children: [
                      Icon(
                        Icons.logout_rounded,
                        color: AppColors.error,
                        size: AppSize.sp(18),
                      ),
                      AppSize.gapW(10),
                      Text(
                        "Logout",
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.error,
                          fontSize: AppSize.sp(15),
                          letterSpacing: AppSize.sp(1),
                        ),
                      ),
                    ],
                  ),
                ),
                AppSize.gapH(5),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      messageAlign: TextAlign.center,
      title: "Logout",
      message: "Are you sure you want to sign out of your account?",
      confirmText: "Logout",
      messageColor: Theme.of(context).colorScheme.onSurface,
      cancelText: "Cancel",
      isDeleteAction: true,
      icon: Icons.logout_rounded,
    );

    if (confirmed == true) {
      // Sign out from both Google and Firebase
      await GoogleAuthService.signOut();

      // Clear all SQLite DB tables for complete local data cleanup
      final db = DatabaseHelper.instance;
      await db.clearTable(DBConstants.profileTable);
      await db.clearTable(DBConstants.categoriesTable);

      // Reset profile controller observables
      final profileController = Get.find<ProfileController>();
      profileController.firstName.value = "";
      profileController.lastName.value = "";
      profileController.email.value = "";
      profileController.profilePicture.value = "";

      // Navigate back to login screen
      Get.offAllNamed(AppRoutes.login);
    }
  }

  void _showDeleteAccountConfirmationDialog(BuildContext context) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      messageAlign: TextAlign.center,
      title: "Delete Account",
      message:
          "Are you sure you want to delete your account permanently?\n\nThis action cannot be undone. All your profile information, accounts, categories, and transaction history will be permanently deleted from this device and Firebase.",
      confirmText: "Delete Account",
      cancelText: "Cancel",
      isDeleteAction: true,
      icon: Icons.delete_forever_rounded,
    );

    if (confirmed == true) {
      // 1. Show loader overlay dialog
      Get.dialog(
        const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        ),
        barrierDismissible: false,
      );

      try {
        // 2. Permanently delete Firebase user account & sign out
        await GoogleAuthService.deleteUserAccount();

        // 3. Clear all local SQLite database tables
        final db = DatabaseHelper.instance;
        await db.clearTable(DBConstants.profileTable);
        await db.clearTable(DBConstants.categoriesTable);

        // 4. Clear SharedPreferences
        if (Get.isRegistered<SharedPreferencesService>()) {
          await Get.find<SharedPreferencesService>().clear();
        }

        // 5. Reset ProfileController state
        if (Get.isRegistered<ProfileController>()) {
          final profileController = Get.find<ProfileController>();
          profileController.firstName.value = "";
          profileController.lastName.value = "";
          profileController.email.value = "";
          profileController.profilePicture.value = "";
        }

        // 6. Dismiss loader dialog
        if (Get.isDialogOpen == true) {
          Get.back();
        }

        AppSnackbar.success(message: "Account deleted successfully.");

        // 7. Navigate back to login screen
        Get.offAllNamed(AppRoutes.login);
      } catch (e) {
        if (Get.isDialogOpen == true) {
          Get.back();
        }
        AppSnackbar.error(message: "Failed to delete account: $e");
      }
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileController = Get.find<ProfileController>();

    return Obx(() {
      final hasImage = profileController.profilePicture.value.isNotEmpty;

      return GestureDetector(
        onTap: () => Get.toNamed(AppRoutes.profile),
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: AppSize.w(72),
                  height: AppSize.w(72),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    image: hasImage
                        ? DecorationImage(
                            image: FileImage(
                              File(profileController.profilePicture.value),
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: !hasImage
                      ? Icon(
                          Icons.person_rounded,
                          color: AppColors.primary,
                          size: AppSize.sp(40),
                        )
                      : null,
                ),

                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: AppSize.w(24),
                    height: AppSize.w(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.edit,
                      color: AppColors.white,
                      size: AppSize.sp(14),
                    ),
                  ),
                ),
              ],
            ),
            AppSize.gapH(4),

            Text(
              (profileController.firstName.value.trim().isEmpty &&
                      profileController.lastName.value.trim().isEmpty)
                  ? "Guest"
                  : "${profileController.firstName.value} ${profileController.lastName.value}"
                        .trim(),
              style: theme.textTheme.labelLarge,
            ),
            AppSize.gapH(4),
            Text(
              profileController.email.value.trim().isEmpty
                  ? "Tap to complete profile "
                  : profileController.email.value,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      );
    });
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool delete;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
    this.delete = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,

      contentPadding: AppSize.symmetric(horizontal: 8, vertical: 2),
      leading: Container(
        padding: AppSize.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: AppSize.sp(18)),
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: AppSize.sp(13),
          color: delete ? AppColors.error : null,
        ),
      ),
      // subtitle: subtitle != null
      //     ? Text(
      //         subtitle!,
      //         style: theme.textTheme.labelMedium?.copyWith(
      //           color: delete
      //               ? AppColors.error.withValues(alpha: .9)
      //               : AppColors.subtitle,
      //           fontSize: AppSize.sp(9.5),
      //         ),
      //       )
      //     : null,
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right_rounded,
            color: delete
                ? AppColors.error.withValues(alpha: .9)
                : theme.colorScheme.onSurfaceVariant,
            size: AppSize.sp(20),
          ),
      onTap: onTap,
    );
  }
}

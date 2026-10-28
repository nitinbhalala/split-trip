import 'dart:io';
import 'package:split_trip/core/common/divider/app_divider.dart';
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
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:split_trip/services/auth/google_auth_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currencyController = Get.find<CurrencyController>();
    final themeController = Get.find<ThemeController>();

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
                Obx(() {
                  // Same "account linked" check as the Delete Backup tile;
                  // profile email is Rx, so the tag appears right after the
                  // first sign-in.
                  final profileController = Get.find<ProfileController>();
                  // final isLoggedIn =
                  //     GoogleAuthService.isSignedIn ||
                  //     profileController.email.value.trim().isNotEmpty;
                  // isGoogleSignedIn is Rx — updates the tag the moment
                  // sign-in finishes, without a reload.
                  final isLoggedIn =
                      Get.find<BackupController>().isGoogleSignedIn.value ||
                      profileController.email.value.trim().isNotEmpty;

                  return _SettingsTile(
                    icon: Icons.cloud_upload_outlined,
                    iconColor: Colors.blue,
                    title: "Backup to Google Drive",
                    subtitle: "Save accounts and transactions online",
                    // Tap goes straight to the interstitial + backup (no
                    // confirm popup to carry the tag) — so tag the tile.
                    // showAdsTag: true,
                    // No tag while sign-in is still pending.
                    showAdsTag: isLoggedIn,

                    onTap: () {
                      final backupController = Get.find<BackupController>();
                      backupController.backupToGoogleDrive();
                    },
                  );
                }),
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
                Obx(() {
                  final profileController = Get.find<ProfileController>();
                  final profileEmail = profileController.email.value.trim();
                  final hasBackupEmail =
                      GoogleAuthService.isSignedIn || profileEmail.isNotEmpty;
                  if (!hasBackupEmail) return const SizedBox.shrink();

                  return Column(
                    children: [
                      AppDivider(color: theme.colorScheme.outlineVariant),
                      _SettingsTile(
                        icon: Icons.delete_sweep_outlined,
                        iconColor: AppColors.error,
                        delete: true,
                        title: "Delete Backup Data",
                        subtitle: "Delete backup file from Google Drive",
                        onTap: () {
                          final backupController = Get.find<BackupController>();
                          backupController.deleteBackupFromGoogleDrive(context);
                        },
                      ),
                    ],
                  );
                }),
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
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final versionStr = snapshot.hasData
                        ? "${snapshot.data!.version}+${snapshot.data!.buildNumber}"
                        : "1.0.0+1";
                    return _SettingsTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: Colors.blue,
                      title: "Version",
                      subtitle: "App version and details",
                      trailing: Text(
                        versionStr,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: AppSize.sp(11),
                        ),
                      ),
                      onTap: () {},
                    );
                  },
                ),
                AppSize.gapH(5),
              ],
            ),
          ],
        ),
      ),
    );
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
                  ? (GoogleAuthService.isSignedIn ? "User" : "Guest User")
                  : "${profileController.firstName.value} ${profileController.lastName.value}"
                        .trim(),
              style: theme.textTheme.labelLarge,
            ),
            AppSize.gapH(4),
            Text(
              profileController.email.value.trim().isEmpty
                  ? (GoogleAuthService.isSignedIn
                        ? "Tap to edit profile"
                        : "Guest Account • Tap to edit or sign in")
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

  /// Small "Ads" tag after the title — the tap shows an interstitial first.
  final bool showAdsTag;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.onTap,
    this.delete = false,
    this.showAdsTag = false,
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
      // title: Text(
      //   title,
      //   style: theme.textTheme.bodyLarge?.copyWith(
      //     fontWeight: FontWeight.w600,
      //     fontSize: AppSize.sp(13),
      //     color: delete ? AppColors.error : null,
      //   ),
      // ),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: AppSize.sp(13),
                color: delete ? AppColors.error : null,
              ),
            ),
          ),
          if (showAdsTag) ...[
            AppSize.gapW(3),
            Text(
              "Ads",
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: AppSize.sp(7),
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ],
        ],
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

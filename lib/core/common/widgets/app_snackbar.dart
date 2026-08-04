import 'package:split_trip/core/sizer/app_size.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/theme/app_color.dart';

enum SnackbarType { success, error, warning, info }

class AppSnackbar {
  AppSnackbar._();

  static void show({
    required String message,
    required SnackbarType type,
    Duration? duration,
  }) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
    final context = Get.context!;
    final theme = Theme.of(context);

    // // 🎨 Decide gradient / color
    // final bool useGradient =
    //     type == SnackbarType.info || type == SnackbarType.warning;

    final Color solidColor = switch (type) {
      SnackbarType.success => AppColors.success,
      SnackbarType.error => AppColors.error,
      SnackbarType.warning => AppColors.warning,
      SnackbarType.info => AppColors.primary,
      // _ => Colors.transparent,
    };

    Get.snackbar(
      '',
      '',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.transparent,
      margin: AppSize.all(16),
      barBlur: 0,
      padding: EdgeInsets.zero,
      duration: duration ?? const Duration(milliseconds: 2500),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      shouldIconPulse: false,

      messageText: Container(
        padding: AppSize.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: solidColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          message,
          style: theme.textTheme.bodyMedium!.copyWith(color: AppColors.white),
        ),
      ),
    );
  }

  // ✅ Helpers (NO title anywhere)

  static void success({required String message, Duration? duration}) {
    show(message: message, type: SnackbarType.success, duration: duration);
  }

  static void error({required String message, Duration? duration}) {
    show(message: message, type: SnackbarType.error, duration: duration);
  }

  static void warning({required String message, Duration? duration}) {
    show(message: message, type: SnackbarType.warning, duration: duration);
  }

  static void info({required String message, Duration? duration}) {
    show(message: message, type: SnackbarType.info, duration: duration);
  }

  static void hide() {
    Get.closeCurrentSnackbar();
  }

  static void showNoInternet(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text(
            "Couldn't refresh. Please check your internet connection.",
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
  }
}

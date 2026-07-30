import 'package:split_trip/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FullScreenLoadingPage extends StatelessWidget {
  const FullScreenLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String statusMessage = Get.arguments as String? ?? "Processing...";

    return PopScope(
      canPop:
          false, // Disables back gesture navigation during critical database operations
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(strokeWidth: 4.5),
                ),
                const SizedBox(height: 32),
                Text(
                  statusMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Please do not close the app or go back.",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.subtitle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

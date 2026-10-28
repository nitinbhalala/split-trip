
import 'package:calendar_date_picker2/calendar_date_picker2.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/common/button/app_ads_button.dart';
import 'package:split_trip/core/common/button/app_elevated_button.dart';
import 'package:split_trip/core/common/button/app_outlined_button.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';

Future<T?> commonGeneralDialog<T>({
  required BuildContext context,
  required WidgetBuilder pageBuilder,
  bool barrierDismissible = true,
  Color? barrierColor,
  Duration duration = const Duration(milliseconds: 280),
}) {
  return showGeneralDialog(
    barrierLabel: '',
    context: context,
    transitionDuration: duration,
    barrierDismissible: barrierDismissible,
    transitionBuilder: (context, anim1, anim2, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: anim1, child: child),
      );
    },
    pageBuilder: (_, _, _) => pageBuilder(context),
  );
}

/// A premium, reusable confirmation dialog using [commonGeneralDialog]
Future<bool?> showAppConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  Color? messageColor,
  TextAlign messageAlign = TextAlign.start,
  String confirmText = "Confirm",
  String cancelText = "Cancel",
  bool isDeleteAction = false,
  IconData? icon,
  // Confirm runs an interstitial first (caller's flow) — show the "Ads" tag.
  bool showAdsTag = false,
}) {
  return commonGeneralDialog<bool>(
    context: context,
    pageBuilder: (context) {
      final theme = Theme.of(context);
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSize.r(10)),
        ),
        backgroundColor: theme.colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        child: Container(
          width: AppSize.w(320),
          padding: AppSize.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Container(
                  padding: AppSize.all(12),
                  decoration: BoxDecoration(
                    color: isDeleteAction
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: AppSize.sp(24),
                    color: isDeleteAction ? AppColors.error : AppColors.primary,
                  ),
                ),
                AppSize.gapH(16),
              ],
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: AppSize.sp(18),
                ),
                textAlign: TextAlign.center,
              ),
              AppSize.gapH(8),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: messageColor ?? theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                  fontSize: AppSize.sp(13),
                ),
                textAlign: messageAlign,
              ),
              AppSize.gapH(20),
              Row(
                children: [
                  Expanded(
                    child: AppOutlinedButton(
                      title: cancelText,
                      onPressed: () => Get.back(result: false),
                      height: AppSize.h(40),
                    ),
                  ),
                  AppSize.gapW(12),
                  Expanded(
                    child: showAdsTag
                        // Only the "Ads" tag here (showAds: false) — the
                        // caller shows the ad after the dialog closes.
                        ? AppAdsButton(
                            showAds: false,
                            borderRadius: BorderRadius.circular(AppSize.r(9)),
                            title: confirmText,
                            onPressed: () => Get.back(result: true),
                            color: isDeleteAction
                                ? AppColors.error
                                : AppColors.primary,
                            textColor: AppColors.white,
                            height: AppSize.h(40),
                          )
                        : AppElevatedButton(
                            borderRadius:AppSize.r(9),
                            title: confirmText,
                            onPressed: () => Get.back(result: true),
                            color: isDeleteAction
                                ? AppColors.error
                                : AppColors.primary,
                            textColor: AppColors.white,
                            height: AppSize.h(40),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// A reusable premium date range picker dialog using [calendar_date_picker2]
Future<DateTimeRange?> showAppDateRangePicker({
  required BuildContext context,
  DateTimeRange? initialRange,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  final theme = Theme.of(context);
  final startVal = initialRange?.start;
  final endVal = initialRange?.end;

  final List<DateTime?>? results = await showCalendarDatePicker2Dialog(
    context: context,
    config: CalendarDatePicker2WithActionButtonsConfig(
      calendarType: CalendarDatePicker2Type.range,
      firstDate: firstDate ?? DateTime(2015),
      lastDate: lastDate ?? DateTime.now(), // Max date set to today by default
      selectedDayHighlightColor: AppColors.primary,
      selectedRangeHighlightColor: AppColors.primary.withValues(alpha: .15),
      weekdayLabelTextStyle: theme.textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.subtitle,
      ),
      controlsTextStyle: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
      ),
      okButtonTextStyle: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
      cancelButtonTextStyle: theme.textTheme.bodyMedium?.copyWith(
        color: AppColors.subtitle,
      ),
    ),
    dialogSize: const Size(325, 400),
    borderRadius: BorderRadius.circular(8),
    value: [startVal, endVal],
  );

  if (results != null &&
      results.length == 2 &&
      results[0] != null &&
      results[1] != null) {
    return DateTimeRange(start: results[0]!, end: results[1]!);
  }
  return null;
}

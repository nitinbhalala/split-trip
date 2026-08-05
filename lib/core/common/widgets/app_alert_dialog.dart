import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/sizer/app_size.dart';

/// ── Common Alert Dialog Widget ──────────────────────────────────────────────
class AppAlertDialog extends StatelessWidget {
  final String? titleText;
  final Widget? title;
  final String? contentText;
  final Widget? content;
  final List<Widget>? actions;
  final MainAxisAlignment? actionsAlignment;
  final double borderRadius;
  final EdgeInsetsGeometry? contentPadding;

  const AppAlertDialog({
    super.key,
    this.titleText,
    this.title,
    this.contentText,
    this.content,
    this.actions,
    this.actionsAlignment,
    this.borderRadius = 16.0,
    this.contentPadding,
  });

  /// Static helper to display the common alert dialog using Get.dialog
  static Future<T?> show<T>({
    String? titleText,
    Widget? title,
    String? contentText,
    Widget? content,
    List<Widget>? actions,
    MainAxisAlignment? actionsAlignment,
    double borderRadius = 10.0,
    bool barrierDismissible = true,
  }) {
    return Get.dialog<T>(
      AppAlertDialog(
        titleText: titleText,
        title: title,
        contentText: contentText,
        content: content,
        actions: actions,
        actionsAlignment: actionsAlignment,
        borderRadius: borderRadius,
      ),
      barrierDismissible: barrierDismissible,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      title:
          title ??
          (titleText != null
              ? Text(
                  titleText!,
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium!.copyWith(fontWeight: .w600),
                )
              : null),
      content: content ?? (contentText != null ? Text(contentText!) : null),
      contentPadding:
          contentPadding ?? AppSize.symmetric(horizontal: 20, vertical: 20),
      actions: actions,
      actionsAlignment: actionsAlignment,
    );
  }
}

import 'package:split_trip/core/sizer/app_size.dart';
import 'package:flutter/material.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool? showBackButton;
  final bool centerTitle;
  final List<Widget>? actions;
  final VoidCallback? onBack;
  final IconData? leadingIcon;

  const CommonAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = false,
    this.centerTitle = true,
    this.actions,
    this.onBack,
    this.leadingIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.canPop(context);

    final shouldShowBack = showBackButton ?? canPop;

    return AppBar(
      automaticallyImplyLeading: true,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: centerTitle,
      // toolbarHeight: AppSize.h(45),
      shape: Border(bottom: BorderSide(color: theme.dividerColor, width: 1)),

      leading: shouldShowBack
          ? IconButton(
              onPressed:
                  onBack ??
                  () {
                    FocusManager.instance.primaryFocus?.unfocus();

                    Navigator.maybePop(context);
                  },

              icon: Icon(
                leadingIcon ?? Icons.arrow_back_ios_new_rounded,
                size: AppSize.sp(20),
              ),
            )
          : null,

      title: subtitle == null
          ? Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: AppSize.sp(18),
                fontWeight: FontWeight.w500,
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: .start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: AppSize.sp(18),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: AppSize.h(2)),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: AppSize.sp(12),
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

import 'package:flutter/material.dart';
import 'package:split_trip/core/common/loader/app_loader.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';

class CommonSocialButton extends StatelessWidget {
  const CommonSocialButton({
    super.key,
    required this.text,
    required this.onTap,
    this.imagePath,
    this.icon,
    this.isLoading = false,
    this.height = 54,
  });

  final String text;
  final String? imagePath;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isLoading;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: height,
        decoration: BoxDecoration(
          color: isLoading
              ? theme.cardColor.withValues(alpha: 0.6)
              : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isLoading
            ? const Center(
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (imagePath != null)
                    Image.asset(
                      imagePath!,
                      height: AppSize.sp(20),
                      width: AppSize.sp(20),
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.account_circle_outlined,
                        color: AppColors.primary,
                        size: AppSize.sp(20),
                      ),
                    )
                  else if (icon != null)
                    Icon(icon, size: AppSize.sp(20), color: AppColors.primary),
                  AppSize.gapW(16),
                  Text(
                    text,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: .2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

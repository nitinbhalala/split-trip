import 'package:flutter/material.dart';
import 'package:split_trip/core/common/widgets/app_auto_size_text.dart';
import 'package:split_trip/core/common/widgets/app_card.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';

class TripCard extends StatelessWidget {
  const TripCard({
    super.key,
    required this.title,
    required this.members,
    required this.amount,
    required this.statusText,
    required this.icon,
    required this.gradient,
    required this.isOwe,
    this.onTap,
  });

  final String title;
  final String members;
  final String amount;
  final String statusText;
  final IconData icon;
  final List<Color> gradient;
  final bool isOwe;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      borderRadius: 10,
      borderColor: theme.colorScheme.outline,
      child: ListTile(
        contentPadding: AppSize.symmetric(horizontal: 10, vertical: 0),
        dense: true,
        leading: Container(
          width: AppSize.w(44),
          height: AppSize.w(44),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.white, size: AppSize.sp(22)),
        ),

        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        subtitle: Text(
          members,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodySmall,
        ),

        trailing: RichText(
          textAlign: TextAlign.end,
          text: TextSpan(
            children: [
              TextSpan(
                text: statusText,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isOwe ? AppColors.error : AppColors.income,
                ),
              ),
               TextSpan(text: '\n'),

              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 80),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      amount,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: isOwe ? AppColors.error : AppColors.income,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:split_trip/core/sizer/app_size.dart';

class GroupEmptyState extends StatelessWidget {
  final String searchQuery;

  const GroupEmptyState({
    super.key,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_off_rounded,
            size: AppSize.sp(50),
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.5),
          ),
          AppSize.gapH(12),
          Text(
            searchQuery.isNotEmpty
                ? "No matching groups found"
                : "No groups yet. Tap '+' to create one!",
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

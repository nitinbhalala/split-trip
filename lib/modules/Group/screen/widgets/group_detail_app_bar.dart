import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';
import 'package:split_trip/data/model/group_model.dart';
import 'package:split_trip/modules/Group/controller/group_detail_controller.dart';
import 'package:split_trip/modules/Group/screen/group_info_screen.dart';

class GroupDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final GroupModel group;
  final GroupDetailController controller;
  final TabController tabController;
  final List<Color>? gradient;
  final IconData? icon;

  const GroupDetailAppBar({
    super.key,
    required this.group,
    required this.controller,
    required this.tabController,
    this.gradient,
    this.icon,
  });

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight + AppSize.h(48));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final String groupInitial = group.name.isNotEmpty
        ? group.name[0].toUpperCase()
        : 'G';

    final Color primaryColor = gradient?.first ?? AppColors.primary;

    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: AppSize.sp(20)),
        onPressed: () => Get.back(),
      ),
      titleSpacing: 0,
      title: InkWell(
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        focusColor: Colors.transparent,
        splashColor: Colors.transparent,
        onTap: () {
          Get.to(
            () => GroupInfoScreen(
              group: group,
              controller: controller,
              gradient: gradient,
              icon: icon,
            ),
          );
        },
        child: Row(
          children: [
            Hero(
              tag: 'group_avatar_${group.id}',
              child: CircleAvatar(
                radius: AppSize.r(16),
                backgroundColor: primaryColor.withValues(alpha: 0.15),
                child: icon != null
                    ? Icon(
                        icon,
                        color: primaryColor,
                        size: AppSize.sp(18),
                      )
                    : Text(
                        groupInitial,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            AppSize.gapW(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.name.capitalizeFirst!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Obx(() {
                    final count = controller.members.length;
                    return Text(
                      "$count ${count == 1 ? 'member' : 'members'}",
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: AppSize.sp(10),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          padding: AppSize.only(right: 20),
          icon: Icon(
            Icons.group_add_outlined,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () {
            Get.to(
              () => GroupInfoScreen(
                group: group,
                controller: controller,
                gradient: gradient,
                icon: icon,
              ),
            );
          },
        ),
        AppSize.gapW(5),
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(AppSize.h(48)),
        child: Column(
          children: [
            TabBar(
              controller: tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              labelStyle: theme.textTheme.titleMedium,
              dividerColor: Colors.transparent,
              labelPadding: AppSize.symmetric(horizontal: 24),
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(width: 3, color: AppColors.primary),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              tabs: [
                Tab(height: AppSize.h(30), text: "Chat"),
                Tab(height: AppSize.h(30), text: "Expenses"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

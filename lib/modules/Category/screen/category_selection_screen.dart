import 'package:split_trip/core/common/divider/app_divider.dart';
import 'package:split_trip/core/common/icons/app_icons.dart';
import 'package:split_trip/core/common/dailog/common_general_dialog.dart';
import 'package:split_trip/core/common/loader/app_loader.dart';
import 'package:split_trip/core/common/widgets/app_card.dart';
import 'package:split_trip/core/common/widgets/app_circle_icon_button.dart';
import 'package:split_trip/core/common/widgets/app_snackbar.dart';
import 'package:split_trip/core/common/widgets/common_app_bar.dart';
import 'package:split_trip/core/router/app_pages.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';
import 'package:split_trip/data/model/category_model.dart';
import 'package:split_trip/modules/Category/controller/category_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CategorySelectionScreen extends StatelessWidget {
  const CategorySelectionScreen({super.key});

  void _showDeleteCategoryConfirmationDialog(
    BuildContext context,
    CategoryController categoryController,
    DBCategory category,
  ) async {
    final confirmed = await showAppConfirmationDialog(
      context: context,
      title: "Delete Category",
      message:
          "Are you sure you want to delete the category '${category.name}'?",
      isDeleteAction: true,
      icon: Icons.delete_outline_rounded,
    );

    if (confirmed == true) {
      await categoryController.deleteCategory(category.id!);
      AppSnackbar.success(
        message: "Category '${category.name}' deleted successfully!",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final CategoryController categoryController =
        Get.isRegistered<CategoryController>()
        ? Get.find<CategoryController>()
        : Get.put(CategoryController());

    // Parse parameters
    final args = Get.arguments as Map? ?? {};
    final String selectedCategoryIconName =
        args["selectedCategoryIconName"] as String? ?? "";

    return Scaffold(
      appBar: const CommonAppBar(
        title: "Select Category",
        showBackButton: true,
        centerTitle: false,
      ),
      floatingActionButton: AppCard(
        showBorder: false,
        height: AppSize.h(40),
        onTap: () {
          Get.toNamed(AppRoutes.addCategory);
        },
        padding: AppSize.symmetric(horizontal: 10),

        color: AppColors.primary,
        borderRadius: 8,

        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: AppColors.white, size: AppSize.sp(20)),
            AppSize.gapW(2),
            Text(
              "Add Category",
              style: Theme.of(
                context,
              ).textTheme.labelLarge!.copyWith(color: AppColors.white),
            ),
          ],
        ),
      ),
      body: Obx(() {
        if (categoryController.isLoading.value) {
          return const Center(child: AppLoader());
        }

        final allCategories = categoryController.categories;

        if (allCategories.isEmpty) {
          return Center(
            child: Text(
              "No categories found. Tap '+' to add.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.subtitle,
              ),
            ),
          );
        }

        return SafeArea(
          bottom: true,
          top: false,
          child: ReorderableListView.builder(
            padding: AppSize.symmetric(horizontal: 12, vertical: 1),
            shrinkWrap: true,
            buildDefaultDragHandles: false,
            itemCount: allCategories.length,
            onReorderItem: (oldIndex, newIndex) {
              categoryController.reorderCategory(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final category = allCategories[index];
              final categoryColor = Color(category.colorValue);
              final isSelected = category.iconName == selectedCategoryIconName;

              return Container(
                key: ValueKey(category.id),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      dense: true,
                      contentPadding: AppSize.symmetric(
                        horizontal: 0,
                        vertical: 0,
                      ),
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ReorderableDragStartListener(
                            index: index,
                            child: Padding(
                              padding: AppSize.only(right: 8.0),
                              child: Icon(
                                Icons.drag_handle_rounded,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.6),
                                size: AppSize.sp(20),
                              ),
                            ),
                          ),
                          AppCircleIconButton(
                            backgroundColor: categoryColor.withValues(
                              alpha: 0.15,
                            ),
                            icon: AppIcons.getIcon(category.iconName),
                            iconColor: categoryColor,
                            iconSize: AppSize.sp(14),
                            size: AppSize.sp(25),
                            showBackground: true,
                          ),
                        ],
                      ),
                      title: Text(
                        category.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isSelected ? AppColors.primary : null,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected)
                            Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.primary,
                              size: AppSize.sp(20),
                            ),
                          AppSize.gapW(4),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: AppColors.subtitle,
                            ),
                            iconSize: AppSize.sp(20),
                            padding: EdgeInsets.zero,
                            onSelected: (value) {
                              if (value == 'edit') {
                                Get.toNamed(
                                  AppRoutes.addCategory,
                                  arguments: {
                                    "category": category,
                                  },
                                );
                              } else if (value == 'delete') {
                                _showDeleteCategoryConfirmationDialog(
                                  context,
                                  categoryController,
                                  category,
                                );
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem<String>(
                                value: 'edit',
                                child: ListTile(
                                  leading: Icon(Icons.edit_rounded, size: 20),
                                  title: Text('Edit'),
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'delete',
                                child: ListTile(
                                  leading: Icon(
                                    Icons.delete_outline_rounded,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  title: Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        // Return the selected category icon name to the entry screen
                        Get.back(result: category.iconName);
                      },
                    ),
                    if (index < allCategories.length - 1)
                      const AppDivider(thickness: 1.2),
                  ],
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

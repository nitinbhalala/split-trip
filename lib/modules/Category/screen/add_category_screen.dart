
import 'package:split_trip/core/common/icons/app_icons.dart';
import 'package:split_trip/core/common/widgets/app_icon_picker.dart';
import 'package:split_trip/core/common/widgets/app_snackbar.dart';
import 'package:split_trip/core/common/widgets/common_app_bar.dart';
import 'package:split_trip/core/common/widgets/custom_text_field.dart';
import 'package:split_trip/core/const/app_data.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:split_trip/data/model/category_model.dart';
import 'package:split_trip/modules/Category/controller/category_controller.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final CategoryController _categoryController = Get.find<CategoryController>();
  DBCategory? editingCategory;

  final TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (Get.arguments is Map) {
      final args = Get.arguments as Map;
      editingCategory = args["category"] as DBCategory?;
      if (editingCategory != null) {
        nameController.text = editingCategory!.name;
        AppData.selectedIconName = editingCategory!.iconName;
        AppData.selectedColor = Color(editingCategory!.colorValue);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: editingCategory != null ? "Edit category" : "Add category",
        showBackButton: true,
        leadingIcon: Icons.close,
        actions: [
          IconButton(
            icon: Icon(Icons.check, size: AppSize.sp(22)),
            onPressed: () async {
              final categoryName = nameController.text.trim();
              if (categoryName.isEmpty) {
                AppSnackbar.error(message: "Please enter a category name");
                return;
              }

              if (editingCategory != null) {
                final updated = DBCategory(
                  id: editingCategory!.id,
                  name: categoryName,
                  iconName: AppData.selectedIconName,
                  colorValue: AppData.selectedColor.toARGB32(),
                );
                await _categoryController.updateCategory(updated);
                Get.back();
                AppSnackbar.success(
                  message: "Category '$categoryName' updated successfully!",
                );
              } else {
                await _categoryController.addCategory(
                  name: categoryName,
                  iconName: AppData.selectedIconName,
                  color: AppData.selectedColor,
                );
                Get.back();
                AppSnackbar.success(
                  message: "Category '$categoryName' added successfully!",
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: AppSize.symmetric(horizontal: 12.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSize.gapH(4),

              // 1. Selected Icon Container + Category Name Text Field
              _buildTopInputSection(),

              AppSize.gapH(24),

              // 3. Color Grid Selection
              _buildColorSelectorSection(),

              AppSize.gapH(24),

              // 4. Categorized Icon Grid
              AppIconPicker(
                selectedIconName: AppData.selectedIconName,
                selectedColor: AppData.selectedColor,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                onIconSelected: (iconName) {
                  setState(() {
                    AppData.selectedIconName = iconName;
                  });
                },
              ),

              AppSize.gapH(32),
            ],
          ),
        ),
      ),
    );
  }



  Widget _buildTopInputSection() {
    return Row(
      children: [
        // Top Left Selected Icon Container with Radial Gradient & Opacity
        Container(
          width: AppSize.w(40),
          height: AppSize.w(40),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppData.selectedColor.withValues(alpha: .35),
                AppData.selectedColor.withValues(alpha: .12),
              ],
            ),
          ),
          child: Center(
            child: Icon(
              AppIcons.getIcon(AppData.selectedIconName),
              color: Colors.black.withValues(alpha: .8),
              size: AppSize.sp(20),
            ),
          ),
        ),

        AppSize.gapW(10),

        // Text Field for Category Name
        Expanded(
          child: CustomTextField(
            title: "",
            hint: "Please enter the category name",
            controller: nameController,
            focusBorderColor: AppColors.darkBackground,
            fill: true,
            isDense: true,
            borderRadius: 8,
          ),
        ),
      ],
    );
  }

  Widget _buildColorSelectorSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: AppData.row1Colors
              .map((color) => _buildColorWrapper(color))
              .toList(),
        ),
        AppSize.gapH(12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: AppData.row2Colors
              .map((color) => _buildColorWrapper(color))
              .toList(),
        ),
        AppSize.gapH(12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: AppData.row3Colors
              .map((color) => _buildColorWrapper(color))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildColorWrapper(Color color) {
    return Padding(
      padding: AppSize.symmetric(horizontal: 8.0),
      child: _buildColorCircle(color),
    );
  }

  Widget _buildColorCircle(Color color) {
    final isSelected = AppData.selectedColor.toARGB32() == color.toARGB32();
    return GestureDetector(
      onTap: () {
        setState(() {
          AppData.selectedColor = color;
        });
      },
      child: Container(
        width: AppSize.w(38),
        height: AppSize.w(38),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: isSelected
            ? Icon(Icons.check, color: Colors.white, size: AppSize.sp(18))
            : null,
      ),
    );
  }
}

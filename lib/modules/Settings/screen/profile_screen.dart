import 'dart:io';
import 'package:split_trip/core/common/button/app_elevated_button.dart';
import 'package:split_trip/core/common/button/app_outlined_button.dart';
import 'package:split_trip/core/common/widgets/custom_text_field.dart';
import 'package:split_trip/core/common/widgets/common_app_bar.dart';
import 'package:split_trip/core/common/widgets/app_circle_icon_button.dart';
import 'package:split_trip/core/common/widgets/app_snackbar.dart';
import 'package:split_trip/core/common/helper/app_validation_helper.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/data/service/image_picker_service.dart';
import 'package:split_trip/modules/Settings/controller/profile_controller.dart';
import 'package:split_trip/services/ads/ad_unit_ids.dart';
import 'package:split_trip/services/ads/banner_or_native_ad_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileController _controller;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;

  String _profilePicPath = "";

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController());

    _firstNameController = TextEditingController(
      text: _controller.firstName.value,
    );
    _lastNameController = TextEditingController(
      text: _controller.lastName.value,
    );
    _emailController = TextEditingController(text: _controller.email.value);
    _profilePicPath = _controller.profilePicture.value;

    // Trigger loadProfile if observables are empty or need loading
    _controller.loadProfile();

    // Listen to changes in ProfileController when loadProfile() completes
    ever<String>(_controller.firstName, (val) {
      if (mounted && _firstNameController.text != val) {
        _firstNameController.text = val;
      }
    });

    ever<String>(_controller.lastName, (val) {
      if (mounted && _lastNameController.text != val) {
        _lastNameController.text = val;
      }
    });

    ever<String>(_controller.email, (val) {
      if (mounted && _emailController.text != val) {
        _emailController.text = val;
      }
    });

    ever<String>(_controller.profilePicture, (val) {
      if (mounted) {
        setState(() {
          _profilePicPath = val;
        });
      }
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showImagePickerOptions() async {
    final result = await ImagePickerService.showPickerSheet(
      context,
      showRemoveOption: _profilePicPath.isNotEmpty,
    );

    if (result != null) {
      if (result.isRemoved) {
        setState(() {
          _profilePicPath = "";
        });
      } else if (result.success) {
        setState(() {
          _profilePicPath = result.file!.path;
        });
      } else if (result.error != null) {
        AppSnackbar.error(message: result.error!);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = _profilePicPath.isNotEmpty;

    return Scaffold(
      appBar: CommonAppBar(title: "Edit Profile", showBackButton: true),
      // Banner (native if the banner fails) at the bottom of the screen.
      bottomNavigationBar: BannerOrNativeAdWidget(
        bannerAdUnitId: AdUnitIds.profileBanner,
        nativeAdUnitId: AdUnitIds.profileNative,
        bannerPlacementId: 'profile_banner',
        nativePlacementId: 'profile_banner_fallback_native',
      ),
      body: SafeArea(
        bottom: true,
        top: false,
        child: SingleChildScrollView(
          padding: AppSize.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppSize.gapH(16),
                // Editable Profile Picture Circle
                Center(
                  child: Stack(
                    children: [
                      GestureDetector(
                        onTap: _showImagePickerOptions,
                        child: Container(
                          width: AppSize.w(100),
                          height: AppSize.w(100),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 2,
                            ),
                            image: hasImage
                                ? DecorationImage(
                                    image: FileImage(File(_profilePicPath)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: !hasImage
                              ? Icon(
                                  Icons.person_rounded,
                                  color: AppColors.primary,
                                  size: AppSize.sp(48),
                                )
                              : null,
                        ),
                      ),
                      Positioned(
                        top: 2,
                        right: 4,
                        child: AppCircleIconButton(
                          padding: EdgeInsets.zero,
                          icon: Icons.edit_rounded,
                          iconColor: Colors.white,
                          showBackground: true,
                          backgroundColor: AppColors.primary,
                          size: AppSize.w(24),
                          iconSize: AppSize.sp(14),
                          onTap: _showImagePickerOptions,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSize.gapH(32),

                // Form Fields
                CustomTextField(
                  title: "First Name",
                  controller: _firstNameController,
                  hint: "Enter your first name",
                  validator: (value) =>
                      AppValidationHelper.name(value, "First Name"),
                ),
                AppSize.gapH(16),
                CustomTextField(
                  title: "Last Name",
                  controller: _lastNameController,
                  hint: "Enter your last name",
                  validator: (value) =>
                      AppValidationHelper.name(value, "Last Name"),
                ),
                AppSize.gapH(16),
                Obx(
                  () => CustomTextField(
                    title: "Email Address",
                    controller: _emailController,
                    hint: "Enter your email address",
                    readOnly: !_controller.isEmailEditable,
                    keyBoardType: TextInputType.emailAddress,
                    validator: (value) => AppValidationHelper.email(value),
                  ),
                ),
                AppSize.gapH(40),

                // Buttons row
                Obx(() {
                  final isLoading = _controller.isLoading.value;
                  return Row(
                    children: [
                      Expanded(
                        child: AppOutlinedButton(
                          title: "Cancel",
                          onPressed: () => Get.back(),
                        ),
                      ),
                      AppSize.gapW(16),
                      Expanded(
                        child: AppElevatedButton(
                          title: "Save",
                          isLoading: isLoading,
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              final emailToSave =
                                  _emailController.text.trim().isNotEmpty
                                  ? _emailController.text.trim()
                                  : _controller.email.value.trim();

                              final success = await _controller.saveProfile(
                                fName: _firstNameController.text,
                                lName: _lastNameController.text,
                                emailVal: emailToSave,
                                profilePicPath: _profilePicPath,
                              );

                              if (success) {
                                Get.back();
                                AppSnackbar.success(
                                  message: "Profile updated successfully!",
                                );
                              } else {
                                AppSnackbar.error(
                                  message: "Failed to update profile",
                                );
                              }
                            }
                          },
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

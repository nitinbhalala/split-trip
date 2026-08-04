import 'package:flutter_svg/svg.dart';
import 'package:split_trip/core/common/widgets/common_social_button.dart';
import 'package:split_trip/core/const/app_assets.dart';
import 'package:split_trip/core/router/app_pages.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';
// import 'package:split_trip/data/service/notification_service.dart';
import 'package:split_trip/services/analytics/analytics_service.dart';
import 'package:split_trip/services/auth/apple_auth_service.dart';
import 'package:split_trip/services/auth/google_auth_service.dart';
import 'package:split_trip/modules/Settings/controller/profile_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isGoogleLoading = false;
  bool _isAppleLoading = false;

  Future<void> _saveProfileDetails() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (!Get.isRegistered<ProfileController>()) {
        Get.put(ProfileController());
      }
      final profileController = Get.find<ProfileController>();

      final emailVal = user.email ?? "";
      final displayName = user.displayName ?? "";
      String fName = "";
      String lName = "";
      if (displayName.isNotEmpty) {
        final parts = displayName.split(" ");
        fName = parts.first;
        if (parts.length > 1) {
          lName = parts.sublist(1).join(" ");
        }
      }

      await profileController.saveProfile(
        fName: profileController.firstName.value.isNotEmpty
            ? profileController.firstName.value
            : fName,
        lName: profileController.lastName.value.isNotEmpty
            ? profileController.lastName.value
            : lName,
        emailVal: emailVal,
        profilePicPath: profileController.profilePicture.value,
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isGoogleLoading || _isAppleLoading) return;
    setState(() => _isGoogleLoading = true);
    try {
      final credential = await GoogleAuthService.signIn();

      if (!mounted) return;

      // Navigate if Firebase says we're signed in
      if (GoogleAuthService.isSignedIn) {
        await _saveProfileDetails();
        AnalyticsService.logLogin();
        Get.offAllNamed(AppRoutes.main);
        return;
      }

      // signIn() returns null when: user cancelled OR silent sign-in already done
      if (credential == null) {
        // Already signed in silently on splash? check again
        await GoogleAuthService.signInSilently();
        if (GoogleAuthService.isSignedIn) {
          await _saveProfileDetails();
          AnalyticsService.logLogin();
          Get.offAllNamed(AppRoutes.main);
        }
        // else: user cancelled — do nothing, just hide loader
      }
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'Sign-in Failed',
        e.toString(), // actual error dikhao for debugging
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 5),
      );
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    if (_isGoogleLoading || _isAppleLoading) return;
    setState(() => _isAppleLoading = true);
    try {
      final credential = await AppleAuthService.signIn();

      if (!mounted) return;

      if (credential != null || AppleAuthService.isSignedIn) {
        await _saveProfileDetails();
        AnalyticsService.logLogin();
        Get.offAllNamed(AppRoutes.main);
        return;
      }
    } catch (e) {
      if (!mounted) return;
      Get.snackbar(
        'Sign-in Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withValues(alpha: 0.9),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        duration: const Duration(seconds: 5),
      );
    } finally {
      if (mounted) setState(() => _isAppleLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutBack,
          ),
        );
    _animationController.forward();

    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   NotificationService.requestPermission();
    // });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSize.symmetric(horizontal: 22),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Welcome Back!",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      letterSpacing: .3,
                      fontWeight: .w800,
                    ),
                  ),
                  AppSize.gapH(10),
                  Text(
                    "Login to continue your jounrney",
                    style: theme.textTheme.bodyMedium,
                  ),
                  AppSize.gapH(50),
                  SvgPicture.asset(AppAssets.loginPageImage),
                  AppSize.gapH(20),

                  // ── Google Login Button ────────────────────────────────────
                  CommonSocialButton(
                    text: "Continue with Google",
                    imagePath: AppAssets.googleIcon,
                    isLoading: _isGoogleLoading,
                    onTap: (_isGoogleLoading || _isAppleLoading)
                        ? () {}
                        : _handleGoogleSignIn,
                  ),

                  AppSize.gapH(10),

                  // ── Apple Login Button ─────────────────────────────────────
                  CommonSocialButton(
                    text: "Continue with Apple",
                    imagePath: AppAssets.appleIcon,
                    isLoading: _isAppleLoading,
                    onTap: (_isGoogleLoading || _isAppleLoading)
                        ? () {}
                        : _handleAppleSignIn,
                  ),
                  AppSize.gapH(20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter_svg/svg.dart';
import 'package:split_trip/core/const/app_assets.dart';
import 'package:split_trip/core/router/app_pages.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/modules/Settings/controller/profile_controller.dart';
import 'package:split_trip/services/auth/google_auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _titleSlideAnimation;
  late Animation<Offset> _subtitleSlideAnimation;

  @override
  void initState() {
    super.initState();

    // 1. FIRST create controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // 2. Then create animations
    _scaleAnimation = Tween<double>(
      begin: 0.35,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _titleSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.35, 0.8, curve: Curves.easeOut),
          ),
        );

    _subtitleSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
          ),
        );

    _controller.forward();

    // 3. After animation — check Firebase auth state and navigate
    Future.delayed(const Duration(seconds: 2), () {
      _navigateBasedOnAuth();
    });
  }

  /// Check if user is signed in via Firebase and navigate accordingly.
  Future<void> _navigateBasedOnAuth() async {
    if (!mounted) return;

    if (GoogleAuthService.isSignedIn) {
      // Sync profile details in local database
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

      // User already logged in → go to main screen
      Get.offAllNamed(AppRoutes.main);
    } else {
      // Not logged in → go to onboarding screen
      Get.offAllNamed(AppRoutes.onboarding);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: AppSize.sp(120),
                  height: AppSize.sp(120),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D314B),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(10), // Increase/Decrease as needed
                    child: Image.asset(AppAssets.applogo, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),

            AppSize.gapH(10),
            SlideTransition(
              position: _titleSlideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  "Split Trip",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    letterSpacing: .5,
                  ),
                ),
              ),
            ),
            AppSize.gapH(4),

            SlideTransition(
              position: _subtitleSlideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  "Track • Save • Grow",
                  style: TextStyle(color: AppColors.subtitle, fontSize: 16),
                ),
              ),
            ),

            AppSize.gapH(8),
          ],
        ),
      ),
    );
  }
}

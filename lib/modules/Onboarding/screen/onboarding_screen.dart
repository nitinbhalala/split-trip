import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/common/button/app_elevated_button.dart';
import 'package:split_trip/core/const/app_assets.dart';
import 'package:split_trip/core/router/app_pages.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_color.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _items = const [
    OnboardingItem(
      image: AppAssets.onBoardingPageImage1,
      title: "Create or join trips",
      description: "Create a trip for your group\nor join with a trip code.",
    ),
    OnboardingItem(
      image: AppAssets.onBoardingPageImage2,
      title: "Add & split expenses",
      description:
          "Add expenses on the go and\nsplit easily with your friends.",
    ),
    OnboardingItem(
      image: AppAssets.onBoardingPageImage3,
      title: "Track & settle balances",
      description: "Track who owes what and\nsettle up in a few taps.",
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onSkip() {
    Get.offAllNamed(AppRoutes.login);
  }

  void _onNext() {
    if (_currentPage < _items.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppSize.init(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: true,
        top: true,
        child: Column(
          children: [
            // Top Bar with Skip Button
            Padding(
              padding: AppSize.only(right: 20, top: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _onSkip,
                  child: Text(
                    "Skip",
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: .w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),

            // PageView content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _items.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Padding(
                    padding: AppSize.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // SVG Image Illustration
                        Expanded(
                          flex: 5,
                          child: Container(
                            alignment: Alignment.center,
                            child: SvgPicture.asset(
                              item.image,
                              fit: BoxFit.contain,
                              width: AppSize.w(280),
                            ),
                          ),
                        ),
                        AppSize.gapH(20),

                        // Title
                        Text(
                          item.title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineMedium,
                        ),
                        AppSize.gapH(12),

                        // Description
                        Text(
                          item.description,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: AppSize.sp(14),
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        AppSize.gapH(20),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Page Indicator Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _items.length,
                (index) => _buildIndicator(index == _currentPage),
              ),
            ),
            AppSize.gapH(30),

            // Bottom Action Button
            Padding(
              padding: AppSize.symmetric(horizontal: 24),
              child: AppElevatedButton(
                textStyle: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.white,
                  letterSpacing: 1.5,
                ),
                title: _currentPage == _items.length - 1
                    ? "Get Started"
                    : "Next",
                onPressed: _onNext,
              ),
            ),
            AppSize.gapH(24),
          ],
        ),
      ),
    );
  }

  Widget _buildIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: EdgeInsets.symmetric(horizontal: AppSize.w(4)),
      height: AppSize.h(8),
      width: isActive ? AppSize.w(24) : AppSize.w(8),
      decoration: BoxDecoration(
        color: isActive
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(AppSize.r(4)),
      ),
    );
  }
}

class OnboardingItem {
  final String image;
  final String title;
  final String description;

  const OnboardingItem({
    required this.image,
    required this.title,
    required this.description,
  });
}

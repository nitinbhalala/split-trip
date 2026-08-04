
import 'package:get/get.dart';
import 'package:split_trip/core/Binding/app_initial_binding.dart';
import 'package:split_trip/core/router/app_pages.dart';
import 'package:split_trip/mainScreen/main_screen.dart';
import 'package:split_trip/modules/Category/screen/add_category_screen.dart';
import 'package:split_trip/modules/Category/screen/category_selection_screen.dart';
import 'package:split_trip/modules/Settings/screen/currency_selection_screen.dart';
import 'package:split_trip/modules/Settings/screen/profile_screen.dart';
import 'package:split_trip/modules/Settings/screen/theme_selection_screen.dart';
import 'package:split_trip/modules/Onboarding/screen/onboarding_screen.dart';
import 'package:split_trip/modules/Splash/splash_screen.dart';
import 'package:split_trip/modules/auth/login_screen.dart';

class AppPages {
  AppPages._();
  static const intialRoute = AppRoutes.splash;
  // static const intialRoute = AppRoutes.main;

  static final pages = <GetPage>[
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.onboarding, page: () => const OnboardingScreen()),
    GetPage(name: AppRoutes.login, page: () => const LoginScreen()),
    GetPage(
      name: AppRoutes.main,
      binding: MainBinding(),
      page: () => const MainScreen(),
    ),
    GetPage(
      name: AppRoutes.selectCurrency,
      page: () => const CurrencySelectionScreen(),
    ),
    GetPage(name: AppRoutes.addCategory, page: () => const AddCategoryScreen()),

    GetPage(
      name: AppRoutes.selectTheme,
      page: () => const ThemeSelectionScreen(),
    ),
    GetPage(name: AppRoutes.profile, page: () => const ProfileScreen()),

   
    GetPage(
      name: AppRoutes.selectCategory,
      page: () => const CategorySelectionScreen(),
    ),
  
  ];
}

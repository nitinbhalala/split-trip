import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/Binding/app_initial_binding.dart';
import 'package:split_trip/core/const/app_string.dart';
import 'package:split_trip/core/router/app_routes.dart';
import 'package:split_trip/core/sizer/app_size.dart';
import 'package:split_trip/core/theme/app_theme.dart';
import 'package:split_trip/services/analytics/analytics_service.dart';
import 'package:split_trip/services/app_initializer_service.dart';

import 'core/theme/theme_controller.dart';

void main() async {
    await AppInitializerService.initialize();

  // WidgetsFlutterBinding.ensureInitialized();
  // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // SystemChrome.setSystemUIOverlayStyle(
  //   const SystemUiOverlayStyle(
  //     systemNavigationBarColor: Colors.transparent,
  //     systemNavigationBarDividerColor: Colors.transparent,
  //     systemNavigationBarContrastEnforced: false, // <-- ye critical hai
  //     statusBarColor: Colors.transparent,
  //   ),
  // );

  // await SystemChrome.setPreferredOrientations([
  //   DeviceOrientation.portraitUp,
  //   DeviceOrientation.portraitDown,
  // ]);
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // await AnalyticsService.init();
  // await NotificationService.init();
  // await GoogleAuthService.initialize();
  // await Get.putAsync(() => SharedPreferencesService().init());

  // Get.put(ThemeController(), permanent: true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
        AppSize.init(context);
    final themeController = Get.find<ThemeController>();
    return GetMaterialApp(
      title: AppString.appname,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.0)),
          child: child!,
        );
      },
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeController.themeMode,
      initialRoute: AppPages.intialRoute,
      initialBinding: InitialBinding(),
      getPages: AppPages.pages,
      navigatorObservers: [AnalyticsService.observer],
      // home: SplashScreen(),
    );
  }
}

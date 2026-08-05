import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:split_trip/core/common/widgets/app_logger.dart';
import 'package:split_trip/core/theme/theme_controller.dart';
import 'package:split_trip/modules/Settings/controller/currency_controller.dart';
// import 'package:split_trip/data/service/notification_service.dart';
import 'package:split_trip/data/service/shared_preferences_service.dart';
import 'package:split_trip/firebase_options.dart';
import 'package:split_trip/services/analytics/analytics_service.dart';

class AppInitializerService {
  AppInitializerService._();

  static Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    AppLogger.log(
      "========== APP INITIALIZATION START ==========",
      tag: "INIT",
    );
    await _initializeStep(
      name: "Initializing System UI..",
      action: () async {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
            statusBarColor: Colors.transparent,
          ),
        );

        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      },
    );
    await _initializeStep(
      name: "Firebase",
      action: () async {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      },
    );
    await _initializeStep(
      name: "Firebase",
      action: () async {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      },
    );

    await _initializeStep(
      name: "Analytics",
      action: () async {
        await AnalyticsService.init();
      },
    );

    // await _initializeStep(
    //   name: "Notification",
    //   action: () async {
    //     await NotificationService.init();
    //   },
    // );

    await _initializeStep(
      name: "Shared Preferences",
      action: () async {
        await Get.putAsync(() => SharedPreferencesService().init());
      },
    );

    await _initializeStep(
      name: "Theme Controller",
      action: () async {
        Get.put(ThemeController(), permanent: true);
      },
    );

    await _initializeStep(
      name: "Currency Controller",
      action: () async {
        Get.put(CurrencyController(), permanent: true);
      },
    );

    AppLogger.success("========== APP INITIALIZATION COMPLETED ==========");
  }

  static Future<void> _initializeStep({
    required String name,
    required Future<void> Function() action,
  }) async {
    try {
      AppLogger.log("Initializing $name...", tag: "INIT");

      final stopwatch = Stopwatch()..start();

      await action();

      stopwatch.stop();

      AppLogger.success(
        "$name initialized (${stopwatch.elapsedMilliseconds} ms)",
      );
    } catch (e, s) {
      AppLogger.error("$name initialization failed");
      AppLogger.error(e);
      AppLogger.error(s);
    }
  }
}

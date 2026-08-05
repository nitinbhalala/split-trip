
import 'package:get/get.dart';
import 'package:split_trip/core/theme/theme_controller.dart';
import 'package:split_trip/mainScreen/main_controller.dart';
import 'package:split_trip/modules/Category/controller/category_controller.dart';
import 'package:split_trip/modules/Group/controller/group_controller.dart';
import 'package:split_trip/modules/Settings/controller/backup_controller.dart';
import 'package:split_trip/modules/Settings/controller/currency_controller.dart';
import 'package:split_trip/modules/Settings/controller/profile_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Only core startup controllers required at Splash screen / app launch
    Get.put(ThemeController(), permanent: true);
    Get.put(CurrencyController(), permanent: true);
  }
}

class MainBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => MainController());

    // Feature modules initialized lazily when entering the main application context
    Get.lazyPut(() => CategoryController(), fenix: true);
    Get.lazyPut(() => ProfileController(), fenix: true);
    Get.lazyPut(() => BackupController(), fenix: true);
    Get.lazyPut(() => GroupController(), fenix: true);
  }
}

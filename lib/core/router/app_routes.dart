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

import 'package:split_trip/data/model/group_model.dart';
import 'package:split_trip/data/model/group_message_model.dart';
import 'package:split_trip/data/model/expense_metadata_model.dart';
import 'package:split_trip/modules/Group/controller/group_detail_controller.dart';
import 'package:split_trip/modules/Group/screen/group_detail_screen.dart';
import 'package:split_trip/modules/Group/screen/group_info_screen.dart';
import 'package:split_trip/modules/Group/screen/add_split_expense_screen.dart';
import 'package:split_trip/modules/Group/screen/expense_detail_screen.dart';

class AppPages {
  AppPages._();
  static const intialRoute = AppRoutes.splash;
  // static const intialRoute = AppRoutes.main;

  static final pages = <GetPage>[
    GetPage(name: AppRoutes.splash, page: () => const SplashScreen()),
    GetPage(name: AppRoutes.onboarding, page: () => const OnboardingScreen()),
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
    GetPage(
      name: AppRoutes.groupDetail,
      page: () {
        final group = Get.arguments as GroupModel;
        return GroupDetailScreen(group: group);
      },
    ),
    GetPage(
      name: AppRoutes.groupInfo,
      page: () {
        final args = Get.arguments;
        if (args is Map<String, dynamic>) {
          return GroupInfoScreen(
            group: args['group'] as GroupModel,
            controller: args['controller'] as GroupDetailController,
          );
        }
        final group = args as GroupModel;
        final tag = "group_${group.id}";
        final controller = Get.isRegistered<GroupDetailController>(tag: tag)
            ? Get.find<GroupDetailController>(tag: tag)
            : (Get.isRegistered<GroupDetailController>()
                ? Get.find<GroupDetailController>()
                : Get.put(GroupDetailController(groupId: group.id ?? 0), tag: tag));
        return GroupInfoScreen(group: group, controller: controller);
      },
    ),
    GetPage(
      name: AppRoutes.addSplitExpense,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return AddSplitExpenseScreen(
          controller: args['controller'] as GroupDetailController,
          groupName: args['groupName'] as String,
          editingMessage: args['editingMessage'] as GroupMessageModel?,
          initialMeta: args['initialMeta'] as ExpenseMetadataModel?,
        );
      },
    ),
    GetPage(
      name: AppRoutes.expenseDetail,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return ExpenseDetailScreen(
          controller: args['controller'] as GroupDetailController,
          msg: args['msg'] as GroupMessageModel,
          initialMeta:
              (args['initialMeta'] ?? args['meta']) as ExpenseMetadataModel,
        );
      },
    ),
  ];
}

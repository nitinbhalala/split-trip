import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/data/service/pref_keys.dart';
import 'package:split_trip/data/service/shared_preferences_service.dart';


class ThemeController extends GetxController {
  static ThemeController get to => Get.find();
  final SharedPreferencesService _prefs = Get.find<SharedPreferencesService>();
  final Rx<ThemeMode> _themeMode = ThemeMode.system.obs;
  ThemeMode get themeMode => _themeMode.value;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  void _loadTheme() {
    final savedTheme = _prefs.getString(
      PrefKeys.themeMode,
      defaultValue: 'system',
    );

    switch (savedTheme) {
      case 'light':
        _themeMode.value = ThemeMode.light;
        break;
      case 'dark':
        _themeMode.value = ThemeMode.dark;
        break;
      default:
        _themeMode.value = ThemeMode.system;
    }

    Get.changeThemeMode(_themeMode.value);
  }

  void changeTheme(ThemeMode mode) {
    _themeMode.value = mode;
    Get.changeThemeMode(mode);

    _prefs.setString(
      PrefKeys.themeMode,
      mode == ThemeMode.light
          ? 'light'
          : mode == ThemeMode.dark
          ? 'dark'
          : 'system',
    );
  }
}

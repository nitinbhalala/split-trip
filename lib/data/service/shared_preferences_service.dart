import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:split_trip/data/service/pref_keys.dart';

class SharedPreferencesService extends GetxService {
  late SharedPreferences _prefs;

  Future<SharedPreferencesService> init() async {
    _prefs = await SharedPreferences.getInstance();
    return this;
  }

  // ==========================
  // Bool
  // ==========================

  Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  bool getBool(String key, {bool defaultValue = false}) {
    return _prefs.getBool(key) ?? defaultValue;
  }

  // ==========================
  // String
  // ==========================

  Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  String getString(String key, {String defaultValue = ''}) {
    return _prefs.getString(key) ?? defaultValue;
  }

  // ==========================
  // Int
  // ==========================

  Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  int getInt(String key, {int defaultValue = 0}) {
    return _prefs.getInt(key) ?? defaultValue;
  }

  // ==========================
  // Double
  // ==========================

  Future<bool> setDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }

  double getDouble(String key, {double defaultValue = 0.0}) {
    return _prefs.getDouble(key) ?? defaultValue;
  }

  // ==========================
  // List<String>
  // ==========================

  Future<bool> setStringList(String key, List<String> value) async {
    return await _prefs.setStringList(key, value);
  }

  List<String> getStringList(String key) {
    return _prefs.getStringList(key) ?? [];
  }

  // ==========================
  // Remove
  // ==========================

  Future<void> remove(String key) async {
    await _prefs.remove(key);
  }

  Future<void> clear() async {
    await _prefs.clear();
  }

  // ==========================
  // Profile Getters & Setters
  // ==========================

  String get userFirstName => getString(PrefKeys.userFirstName);
  Future<bool> setUserFirstName(String value) => setString(PrefKeys.userFirstName, value);

  String get userLastName => getString(PrefKeys.userLastName);
  Future<bool> setUserLastName(String value) => setString(PrefKeys.userLastName, value);

  String get userEmail => getString(PrefKeys.userEmail);
  Future<bool> setUserEmail(String value) => setString(PrefKeys.userEmail, value);

  String get userPhone => getString(PrefKeys.userPhone);
  Future<bool> setUserPhone(String value) => setString(PrefKeys.userPhone, value);

  String get userProfileImagePath => getString(PrefKeys.userProfileImagePath);
  Future<bool> setUserProfileImagePath(String value) => setString(PrefKeys.userProfileImagePath, value);

  bool get useDummyData => getBool(PrefKeys.useDummyData, defaultValue: false);
  Future<bool> setUseDummyData(bool value) => setBool(PrefKeys.useDummyData, value);
}

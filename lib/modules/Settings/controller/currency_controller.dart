import 'package:get/get.dart';
import 'package:split_trip/core/common/widgets/app_logger.dart';
import 'package:split_trip/data/database/database_helper.dart';
import 'package:split_trip/data/database/db_constants.dart';
import 'package:split_trip/data/model/currecy_icons_model.dart';
import 'package:split_trip/data/service/pref_keys.dart';
import 'package:split_trip/data/service/shared_preferences_service.dart';

class CurrencyController extends GetxController {
  final SharedPreferencesService _prefs = Get.find<SharedPreferencesService>();

  // Selected currency
  final Rx<CurrencyIconModel> selectedCurrency = Rx<CurrencyIconModel>(currencyList.first);

  @override
  void onInit() {
    super.onInit();
    _loadSelectedCurrency();
  }

  void _loadSelectedCurrency() {
    final savedCode = _prefs.getString(PrefKeys.currencyCode, defaultValue: 'INR');
    final match = currencyList.firstWhere(
      (element) => element.code == savedCode,
      orElse: () => currencyList.first,
    );
    selectedCurrency.value = match;
  }

  Future<void> updateCurrency(CurrencyIconModel currency, {bool saveToDb = true}) async {
    selectedCurrency.value = currency;
    await _prefs.setString(PrefKeys.currencyCode, currency.code);

    if (saveToDb) {
      try {
        final db = DatabaseHelper.instance;
        final result = await db.getWhere(
          table: DBConstants.profileTable,
          where: "id = ?",
          args: [1],
        );

        if (result.isNotEmpty) {
          // Update the currency column on row 1
          await db.insert(
            table: DBConstants.profileTable,
            values: {
              ...result.first,
              'selected_currency': currency.code,
            },
          );
        } else {
          // If no row exists yet (unlikely), insert a default one
          await db.insert(
            table: DBConstants.profileTable,
            values: {
              'id': 1,
              'first_name': "",
              'last_name': "",
              'email': "",
              'profile_picture': "",
              'selected_currency': currency.code,
            },
          );
        }
      } catch (e) {
        AppLogger.error("Error saving selected currency to DB: $e");
      }
    }
  }
}

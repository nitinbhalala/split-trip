import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/data/database/database_helper.dart';
import 'package:split_trip/data/database/db_constants.dart';
import 'package:split_trip/data/model/currecy_icons_model.dart';
import 'package:split_trip/modules/Settings/controller/currency_controller.dart';
import 'package:split_trip/services/auth/google_auth_service.dart';

class ProfileController extends GetxController {
  static ProfileController get to => Get.find();

  final RxString firstName = "".obs;
  final RxString lastName = "".obs;
  final RxString email = "".obs;
  final RxString profilePicture = "".obs; // Holds picked image file path

  final RxBool isLoading = false.obs;

  /// Returns true if email should be editable in profile screen.
  bool get isEmailEditable {
    final currentEmail = email.value;
    if (!GoogleAuthService.isSignedIn) return true;
    return currentEmail.trim().isEmpty;
  }

  @override
  void onInit() {
    super.onInit();
    loadProfile();
  }

  Future<void> loadProfile() async {
    isLoading.value = true;
    try {
      final db = DatabaseHelper.instance;
      final result = await db.getWhere(
        table: DBConstants.profileTable,
        where: "id = ?",
        args: [1],
      );

      if (result.isNotEmpty) {
        final data = result.first;
        firstName.value = (data['first_name'] as String?) ?? "";
        lastName.value = (data['last_name'] as String?) ?? "";
        email.value = (data['email'] as String?) ?? "";
        profilePicture.value = (data['profile_picture'] as String?) ?? "";

        // Auto-sync Google user details if database email is empty.
        // Uses the cached account only — must never trigger a sign-in
        // attempt (and its UI) automatically on app startup.
        final googleUser = GoogleAuthService.currentUser;
        if (email.value.isEmpty && googleUser != null) {
          email.value = googleUser.email;
          final displayName = googleUser.displayName ?? "";
          if (firstName.value.isEmpty && displayName.isNotEmpty) {
            final parts = displayName.split(" ");
            firstName.value = parts.first;
            if (parts.length > 1) {
              lastName.value = parts.sublist(1).join(" ");
            }
          }

          // Save to database
          final savedCurrency = (data['selected_currency'] as String?) ?? "";
          await db.insert(
            table: DBConstants.profileTable,
            values: {
              'id': 1,
              'first_name': firstName.value,
              'last_name': lastName.value,
              'email': email.value,
              'profile_picture': profilePicture.value,
              'selected_currency': savedCurrency,
            },
          );
        }

        // Load and sync currency from DB
        final savedCurrency = (data['selected_currency'] as String?) ?? "";
        if (savedCurrency.isNotEmpty) {
          final currencyController = Get.find<CurrencyController>();
          final match = currencyList.firstWhere(
            (e) => e.code == savedCurrency,
            orElse: () => currencyList.first,
          );
          await currencyController.updateCurrency(match, saveToDb: false);
        }
      } else {
        // Create initial default empty profile in DB
        final currencyController = Get.find<CurrencyController>();
        final currentCurrencyCode =
            currencyController.selectedCurrency.value.code;

        final googleUser = GoogleAuthService.currentUser;
        String initialEmail = "";
        String initialFName = "";
        String initialLName = "";

        if (googleUser != null) {
          initialEmail = googleUser.email;
          final displayName = googleUser.displayName ?? "";
          if (displayName.isNotEmpty) {
            final parts = displayName.split(" ");
            initialFName = parts.first;
            if (parts.length > 1) {
              initialLName = parts.sublist(1).join(" ");
            }
          }
        }

        await db.insert(
          table: DBConstants.profileTable,
          values: {
            'id': 1,
            'first_name': initialFName,
            'last_name': initialLName,
            'email': initialEmail,
            'profile_picture': "",
            'selected_currency': currentCurrencyCode,
          },
        );
        firstName.value = initialFName;
        lastName.value = initialLName;
        email.value = initialEmail;
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> saveProfile({
    required String fName,
    required String lName,
    required String emailVal,
    required String profilePicPath,
  }) async {
    isLoading.value = true;
    try {
      final db = DatabaseHelper.instance;
      final currencyController = Get.find<CurrencyController>();
      final currentCurrencyCode =
          currencyController.selectedCurrency.value.code;

      String finalEmail = emailVal.trim();
      if (finalEmail.isEmpty) {
        final googleUser = GoogleAuthService.currentUser;
        if (googleUser?.email != null && googleUser!.email.isNotEmpty) {
          finalEmail = googleUser.email.trim();
        } else if (email.value.isNotEmpty) {
          finalEmail = email.value.trim();
        }
      }

      await db.insert(
        table: DBConstants.profileTable,
        values: {
          'id': 1,
          'first_name': fName.trim(),
          'last_name': lName.trim(),
          'email': finalEmail,
          'profile_picture': profilePicPath,
          'selected_currency': currentCurrencyCode,
        },
      );

      firstName.value = fName.trim();
      lastName.value = lName.trim();
      email.value = finalEmail;
      profilePicture.value = profilePicPath;

      return true;
    } catch (e) {
      debugPrint("Error saving profile: $e");
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}

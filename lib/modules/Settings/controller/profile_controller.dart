import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:split_trip/data/database/database_helper.dart';
import 'package:split_trip/data/database/db_constants.dart';
import 'package:split_trip/data/model/currecy_icons_model.dart';
import 'package:split_trip/modules/Settings/controller/currency_controller.dart';

class ProfileController extends GetxController {
  static ProfileController get to => Get.find();

  final RxString firstName = "".obs;
  final RxString lastName = "".obs;
  final RxString email = "".obs;
  final RxString profilePicture = "".obs; // Holds picked image file path

  final RxBool isLoading = false.obs;

  /// Returns true if current logged-in Firebase user signed in with Apple.
  bool get isAppleLogin {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return user.providerData.any((p) => p.providerId == 'apple.com');
    }
    return false;
  }

  /// Returns true if email should be editable in profile screen (e.g. Apple sign-in or empty email).
  bool get isEmailEditable {
    final currentEmail = email
        .value; // Always touch Rx variable for GetX Obx listener registration
    if (isAppleLogin) return true;
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

        // Auto-sync Firebase user details if database email is empty
        final firebaseUser = FirebaseAuth.instance.currentUser;
        if (email.value.isEmpty &&
            firebaseUser != null &&
            firebaseUser.email != null) {
          email.value = firebaseUser.email!;
          final displayName = firebaseUser.displayName ?? "";
          if (firstName.value.isEmpty) {
            String fName = "";
            if (displayName.isNotEmpty) {
              fName = displayName.split(" ").first;
            } else {
              fName = firebaseUser.email!
                  .split('@')
                  .first
                  .replaceAll(RegExp(r'[_.-]'), ' ')
                  .split(RegExp(r'\s+'))
                  .first;
            }
            if (fName.isNotEmpty) {
              firstName.value = fName[0].toUpperCase() + fName.substring(1);
            }
          }
          if (lastName.value.isEmpty) {
            String lName = "";
            if (displayName.isNotEmpty) {
              final parts = displayName.split(" ");
              if (parts.length > 1) {
                lName = parts.sublist(1).join(" ");
              }
            } else {
              final parts = firebaseUser.email!
                  .split('@')
                  .first
                  .replaceAll(RegExp(r'[_.-]'), ' ')
                  .split(RegExp(r'\s+'));
              if (parts.length > 1) {
                lName = parts.sublist(1).join(" ");
              }
            }
            if (lName.isNotEmpty) {
              lastName.value = lName
                  .split(' ')
                  .map(
                    (str) => str.isNotEmpty
                        ? str[0].toUpperCase() + str.substring(1)
                        : '',
                  )
                  .join(' ');
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

        // Auto-sync Firebase user details if we are signing in for the first time
        final firebaseUser = FirebaseAuth.instance.currentUser;
        String initialEmail = "";
        String initialFName = "";
        String initialLName = "";

        if (firebaseUser != null && firebaseUser.email != null) {
          initialEmail = firebaseUser.email!;
          final displayName = firebaseUser.displayName ?? "";
          if (displayName.isNotEmpty) {
            initialFName = displayName.split(" ").first;
            if (displayName.split(" ").length > 1) {
              initialLName = displayName.split(" ").sublist(1).join(" ");
            }
          } else {
            final parts = firebaseUser.email!
                .split('@')
                .first
                .replaceAll(RegExp(r'[_.-]'), ' ')
                .split(RegExp(r'\s+'));
            initialFName = parts.first;
            if (parts.length > 1) {
              initialLName = parts.sublist(1).join(" ");
            }
          }
          if (initialFName.isNotEmpty) {
            initialFName =
                initialFName[0].toUpperCase() + initialFName.substring(1);
          }
          if (initialLName.isNotEmpty) {
            initialLName = initialLName
                .split(' ')
                .map(
                  (str) => str.isNotEmpty
                      ? str[0].toUpperCase() + str.substring(1)
                      : '',
                )
                .join(' ');
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

      // Ensure email is never accidentally cleared if a valid email is available from Firebase/State
      String finalEmail = emailVal.trim();
      if (finalEmail.isEmpty) {
        final fbEmail = FirebaseAuth.instance.currentUser?.email;
        if (fbEmail != null && fbEmail.isNotEmpty) {
          finalEmail = fbEmail.trim();
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

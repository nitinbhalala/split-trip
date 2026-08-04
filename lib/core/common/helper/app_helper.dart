import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:split_trip/modules/Settings/controller/currency_controller.dart';

class AppHelper {
  static String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return "";
    try {
      // String ko DateTime mein convert karein
      final date = DateTime.parse(dateStr);
      // Din aur Mahine ko 2 digits mein lane ke liye padLeft use karein
      String day = date.day.toString().padLeft(2, '0');
      String month = date.month.toString().padLeft(2, '0');
      String year = date.year.toString();

      return "$day/$month/$year";
    } catch (e) {
      return dateStr; // Agar parsing fail ho toh purana format hi dikhayein
    }
  }

  static String getGreeting() {
    final hour = DateTime.now().hour;

    if (hour >= 5 && hour < 12) {
      return "Good Morning";
    } else if (hour >= 12 && hour < 17) {
      return "Good Afternoon";
    } else if (hour >= 17 && hour < 21) {
      return "Good Evening";
    } else {
      return "Good Night";
    }
  }

  static String getCurrentDate() {
    return DateFormat('dd MMM yyyy, EEEE').format(DateTime.now());
  }

  static String formatCurrency(num amount, {String? symbol}) {
    final formatter = NumberFormat('#,##0.00');

    String value = formatter.format(amount);

    value = value.replaceFirst(RegExp(r'\.00$'), '');

    final activeSymbol =
        symbol ??
        (Get.isRegistered<CurrencyController>()
            ? Get.find<CurrencyController>().selectedCurrency.value.symbol
            : '₹');

    return '$activeSymbol $value';
  }

  /// Returns a [Text] widget with the formatted currency, pre-configured with the premium 'Inter' font family.
  static Widget buildCurrencyText(num amount, {TextStyle? style}) {
    return Text(
      formatCurrency(amount),
      style: (style ?? const TextStyle()).copyWith(fontFamily: 'Inter'),
    );
  }

  static String formatAmountWithoutSymbol(double amount) {
    final formatter = NumberFormat('#,##0.##');
    return formatter.format(amount);
  }

  static String formatCompactAmount(double amount) {
    if (amount.abs() >= 1000000000) {
      double value = amount / 1000000000;
      return "${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}B";
    } else if (amount.abs() >= 1000000) {
      double value = amount / 1000000;
      return "${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}M";
    } else if (amount.abs() >= 1000) {
      double value = amount / 1000;
      return "${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}K";
    } else {
      return amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 1);
    }
  }
}

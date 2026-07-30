import 'package:flutter/material.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:split_trip/core/common/widgets/custom_drop_down.dart';

class AppData {
  AppData._();

  static const List<DropdownItem<String>> paymentModes = [
    DropdownItem(
      value: "Cash",
      label: "Cash",
      icon: Icons.account_balance_wallet,
    ),
    DropdownItem(
      value: "Bank Transfer",
      label: "Bank Transfer",
      icon: Icons.account_balance,
    ),
    DropdownItem(value: "UPI", label: "UPI", icon: Icons.credit_card),
  ];

  static const List<Map<String, dynamic>> defaultExpenses = [
    {"name": "Food", "iconName": "restaurant", "color": 0xFFEF5350},
    {"name": "Shopping", "iconName": "shopping_cart", "color": 0xFFBA68C8},
    {"name": "Transport", "iconName": "directions_car", "color": 0xFF2979FF},
    {"name": "Gas", "iconName": "local_gas_station", "color": 0xFFFF9100},
    {"name": "Grocery", "iconName": "shopping_bag", "color": 0xFF26A69A},
    {"name": "Home", "iconName": "home", "color": 0xFF7986CB},
    {"name": "Other", "iconName": "calculate", "color": 0xFF7CB342},
    {"name": "Electricity", "iconName": "electric_bolt", "color": 0xFFFFD54F},
    {"name": "Wifi", "iconName": "wifi", "color": 0xFF4DD0E1},
    {"name": "Health", "iconName": "medical_services", "color": 0xFFEF5350},
    {"name": "Movie", "iconName": "movie", "color": 0xFFF06292},
    {"name": "Education", "iconName": "school", "color": 0xFFC0CA33},
    {"name": "Travel", "iconName": "flight", "color": 0xFF29B6F6},
    {"name": "Bills", "iconName": "payments", "color": 0xFFBA68C8},
    {"name": "Gift", "iconName": "favorite", "color": 0xFFF06292},
    {"name": "Tax", "iconName": "receipt", "color": 0xFFC5A096},
  ];

  static const List<Map<String, dynamic>> defaultIncomes = [
    {"name": "Salary", "iconName": "payments", "color": 0xFF4CAF50},
    {
      "name": "Wallet",
      "iconName": "account_balance_wallet",
      "color": 0xFF26A69A,
    },
    {"name": "Bank", "iconName": "account_balance", "color": 0xFF2979FF},
    {"name": "Coins", "iconName": "monetization_on", "color": 0xFFFF9100},
    {"name": "Savings", "iconName": "savings", "color": 0xFFBA68C8},
    {"name": "Other", "iconName": "calculate", "color": 0xFF7CB342},
    {"name": "Card", "iconName": "credit_card", "color": 0xFF7986CB},
    {"name": "Investment", "iconName": "trending_up", "color": 0xFF4CAF50},
    {"name": "Stocks", "iconName": "pie_chart", "color": 0xFF29B6F6},
    {"name": "Work", "iconName": "work", "color": 0xFFC0CA33},
    {"name": "Business", "iconName": "business_center", "color": 0xFFC5A096},
    {"name": "Promo", "iconName": "campaign", "color": 0xFFFFCC80},
  ];

  // icon data
  static String selectedIconName = "restaurant";
  static Color selectedColor = const Color(0xFFBA68C8); //
  static List<Color> row1Colors = const [
    Color(0xFFEF5350), // Red
    Color(0xFFE57373), // Orange-Red / Light Red
    Color(0xFFC5A096), // Brownish Pink
    Color(0xFFFF9100), // Orange
    Color(0xFFFFCC80), // Peach
  ];

  static List<Color> row2Colors = const [
    Color(0xFFFFD54F), // Yellow/Gold
    Color(0xFFC0CA33), // Olive
    Color(0xFF7CB342), // Light Green
    Color(0xFF4CAF50), // Green
    Color(0xFF26A69A), // Teal/Mint
    Color(0xFF4DD0E1), // Cyan
  ];

  static List<Color> row3Colors = const [
    Color(0xFF29B6F6), // Blue-Teal
    Color(0xFF2979FF), // Blue
    Color(0xFF7986CB), // Indigo/Purple-Blue
    Color(0xFFBA68C8), // Lilac
    Color(0xFFF06292), // Pink
  ];

  //account
  static RxString accountSelectedIconName = "payments".obs;
  static Rx<Color> accountSelectedColor = const Color(0xFF4CAF50).obs;

  static List<Color> accountColors = const [
    Color(0xFFEF5350), // Red
    Color(0xFFFF9100), // Orange
    Color(0xFFFFD54F), // Gold
    Color(0xFF4CAF50), // Green
    Color(0xFF26A69A), // Teal
    Color(0xFF7986CB), // Indigo
    Color(0xFFBA68C8), // Purple
    Color(0xFF4DD0E1), // Cyan
    Color(0xFFF06292), // Pink
  ];
  static const List<String> accountIcons = [
    "payments",
    "account_balance_wallet",
    "account_balance",
    "credit_card",
    "savings",
    "monetization_on",
  ];

  static const List<Map<String, dynamic>> defaultPaymentModes = [
    {
      'name': 'Cash',
      'icon_name': 'wallet',
      'color_value': 0xFF009688, // Colors.teal
    },
    {
      'name': 'Card',
      'icon_name': 'credit_card',
      'color_value': 0xFF2196F3, // Colors.blue
    },
    {
      'name': 'UPI',
      'icon_name': 'qr_code',
      'color_value': 0xFF9C27B0, // Colors.purple
    },
  ];

  static const List<String> paymentIcons = [
    "wallet",
    "credit_card",
    "qr_code",
    "account_balance",
    "payments",
    "savings",
    "local_atm",
    "smartphone",
    "trending_up",
    "star",
  ];

  static const List<Color> paymentColors = [
    Colors.teal,
    Colors.blue,
    Colors.purple,
    Colors.orange,
    Colors.red,
    Colors.indigo,
    Colors.green,
    Colors.amber,
    Colors.pink,
    Colors.brown,
  ];
}

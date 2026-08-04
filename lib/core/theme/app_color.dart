import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // =========================
  // Primary & Accent Colors
  // =========================
  static const Color primary = Color(0xFF10B981); // Emerald Green
  static const Color primaryDark = Color(0xFF059669);
  static const Color secondary = Color(0xFF38BDF8); // Sky Blue
  static const Color accent = Color(0xFFFF6B6B);

  // =========================
  // Background & Surface
  // =========================
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);

  // =========================
  // Status & Finance Colors
  // =========================
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color income = Color(0xFF22C55E);
  static const Color expense = Color(0xFFEF4444);
  static const Color savings = Color(0xFF6366F1);
  // static const Color darkincomeCard = Color(0xFFE8F7F0);

  // =========================
  // Text Colors
  // =========================
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Colors.black54;

  // =========================
  // Border & Divider
  // =========================
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFCBD5E1);

  // =========================
  // Extra UI Colors
  // =========================
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Colors.transparent;

  // =========================
  // Dark Theme
  // =========================
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF334155);

  static const Color darkTextPrimary = Colors.white;

  static const Color darkTextSecondary = Color(0xFFCBD5E1);

  static const Color darkBorder = Color(0xFF334155);
  static const Color darkDivider = Color(0xFF475569);

  // =========================
  // Aliases for Backwards Compatibility
  // =========================
  static const Color lightBackground = background;
  static const Color lightSurface = surface;
  static const Color card = surface;
  static const Color lightDivider = divider;

  static const Color lightText = textPrimary;
  static const Color subtitle = textSecondary;
  static const Color lightHint = Color(0xFF9CA3AF);

  static const Color darkText = darkTextPrimary;
  static const Color darkHint = Color(0xFF94A3B8);

  static const Color primaryLight = Color(0xFFECFDF5);
  static const Color successLight = Color(0xFFEFFAF3);
  static const Color errorLight = Color(0xFFFFF1F2);
  static const Color warningLight = Color(0xFFFFF8E8);
  static const Color infoLight = Color(0xFFEFF6FF);

  static const Color successdark = Color(0xFF1B2A22);
  static const Color errordark = Color(0xFF2C1B1B);
  static const Color infodark = Color(0xFF1D2238);

  static const Color shadow = Color(0x14000000);
}

import 'package:flutter/foundation.dart';

class AppLogger {
  static const bool _isPrintEnabled = kDebugMode;

  static void log(
    dynamic message, {
    String tag = "APP",
    bool useDebug = false,
  }) {
    if (!_isPrintEnabled) return;
    final text = "🔵 [$tag] $message";
    useDebug ? debugPrint(text) : print(text); // ignore: avoid_print
  }

  static void success(dynamic message, {bool useDebug = false}) {
    if (!_isPrintEnabled) return;
    final text = "✅ [SUCCESS] $message";
    useDebug ? debugPrint(text) : print(text); // ignore: avoid_print
  }

  static void error(dynamic message, {bool useDebug = false}) {
    if (!_isPrintEnabled) return;
    final text = "❌ [ERROR] $message";
    useDebug ? debugPrint(text) : print(text); // ignore: avoid_print
  }

  static void warning(dynamic message, {bool useDebug = false}) {
    if (!_isPrintEnabled) return;
    final text = "⚠️ [WARNING] $message";
    // ignore: avoid_print
    useDebug ? debugPrint(text) : print(text);
  }

  static void api(dynamic message, {bool useDebug = true}) {
    if (!_isPrintEnabled) return;
    final text = "🌐 [API] $message";
    useDebug ? debugPrint(text) : print(text); // ignore: avoid_print
  }
}

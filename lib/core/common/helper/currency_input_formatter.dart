import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter = NumberFormat('#,###');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final String text = newValue.text;

    // Allow only digits, commas, and at most one decimal point.
    final dotCount = '.'.allMatches(text).length;
    if (dotCount > 1) {
      return oldValue;
    }

    // Clean text to keep only digits and '.'
    final cleaned = text.replaceAll(',', '');

    // Allow digits optionally followed by a single dot and up to 2 decimal digits
    if (!RegExp(r'^\d*\.?\d{0,2}$').hasMatch(cleaned)) {
      return oldValue;
    }

    // If it's just a dot, format it as "0."
    if (cleaned == '.') {
      const formatted = '0.';
      return const TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }

    String formatted;
    if (cleaned.contains('.')) {
      final parts = cleaned.split('.');
      final intPartStr = parts[0];
      final decPartStr = parts[1];

      final intPart = intPartStr.isEmpty ? 0 : int.parse(intPartStr);
      final formattedInt = _formatter.format(intPart);
      formatted = '$formattedInt.$decPartStr';
    } else {
      final value = int.parse(cleaned);
      formatted = _formatter.format(value);
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: formatted.length,
      ),
    );
  }
}
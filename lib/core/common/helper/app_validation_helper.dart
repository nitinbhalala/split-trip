import 'package:get/get_utils/src/get_utils/get_utils.dart';

class AppValidationHelper {
    static String? name(
    String? value,
    String fieldName,
  ) {
    if (value == null || value.trim().isEmpty) {
      return "Enter $fieldName";
    }

    final text = value.trim();

    if (text.length < 3) {
      return "Minimum 3 characters required";
    }

    // Only letters and spaces allowed
    if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(text)) {
      return "$fieldName can contain only letters";
    }

    return null;
  }
  
static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return "Enter your email";
    }

    final email = value.trim();

    if (email.length > 40) {
      return "Email length should not exceed 40 characters";
    }

    if (!GetUtils.isEmail(email)) {
      return "Enter a valid email";
    }

    final parts = email.split('.');
    if (parts.length > 1) {
      final extension = parts.last;
      if (extension.length > 4) {
        return "Enter a valid email";
      }
    }

    return null;
  }

}
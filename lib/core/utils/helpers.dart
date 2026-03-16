import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Small UI helpers used across screens.
class Helpers {
  /// Shows a GetX snackbar with standard success/error coloring.
  static void showSnackbar(String title, String message, {bool isError = false}) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: isError ? Colors.red : Colors.green,
      colorText: Colors.white,
      margin: const EdgeInsets.all(10),
    );
  }

  /// Removes focus from the current text field to hide the keyboard.
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
}

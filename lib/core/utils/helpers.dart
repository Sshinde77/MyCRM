import 'package:flutter/material.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';

/// Small UI helpers used across screens.
class Helpers {
  /// Shows a GetX snackbar with standard success/error coloring.
  static void showSnackbar(
    String title,
    String message, {
    bool isError = false,
  }) {
    AppSnackbar.show(
      title,
      message,
      isError: isError,
    );
  }

  /// Removes focus from the current text field to hide the keyboard.
  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }
}


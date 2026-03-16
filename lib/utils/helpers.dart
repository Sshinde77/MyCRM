import 'package:flutter/material.dart';

/// Simple ScaffoldMessenger-based helper methods.
class Helpers {
  /// Shows a short snackbar inside the current BuildContext.
  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

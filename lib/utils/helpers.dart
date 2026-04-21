import 'package:flutter/material.dart';
import 'package:mycrm/core/utils/app_snackbar.dart';

/// Simple ScaffoldMessenger-based helper methods.
class Helpers {
  /// Shows a short snackbar inside the current BuildContext.
  static void showSnackBar(BuildContext context, String message) {
    AppSnackbar.show('Notice', message);
  }
}

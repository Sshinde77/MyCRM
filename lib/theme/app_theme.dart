import 'package:flutter/material.dart';
import 'package:mycrm/core/constants/app_text_styles.dart';
import '../core/constants/app_colors.dart';

/// App-wide Material theme configuration.
class AppTheme {
  /// Light theme used by the current CRM starter app.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: AppColors.primaryBlue,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryBlue,
        secondary: AppColors.darkNavy,
        surface: AppColors.cardBackground,
        error: AppColors.dangerRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.primaryText,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.borderColor),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: AppTextStyles.subtitle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        hintStyle: AppTextStyles.body(color: AppColors.secondaryText),
      ),
      textTheme: TextTheme(
        displayLarge: AppTextStyles.title(
          color: AppColors.primaryText,
          fontSize: 32,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: AppTextStyles.title(
          color: AppColors.primaryText,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: AppTextStyles.subtitle(
          color: AppColors.primaryText,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: AppTextStyles.body(
          color: AppColors.primaryText,
          fontSize: 16,
        ),
        bodyMedium: AppTextStyles.body(
          color: AppColors.secondaryText,
          fontSize: 14,
        ),
      ),
    );
  }
}

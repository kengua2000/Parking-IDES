import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Configuración del tema de la aplicación
class AppTheme {
  AppTheme._();

  /// Tema oscuro de la aplicación
  static ThemeData get darkTheme {
    return ThemeData(
      primarySwatch: Colors.green,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      fontFamily: 'Noto Sans',

      // Configuración del TimePicker
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.surfaceDark,
        dialHandColor: AppColors.primary,
        dialBackgroundColor: AppColors.backgroundDark,
        dialTextColor: Colors.white,
        hourMinuteColor: AppColors.inputBg,
        hourMinuteTextColor: Colors.white,
        dayPeriodColor: AppColors.inputBg,
        dayPeriodTextColor: Colors.white,
        entryModeIconColor: AppColors.primary,
        helpTextStyle: const TextStyle(color: Colors.white),
        confirmButtonStyle: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AppColors.primary),
        ),
        cancelButtonStyle: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(Colors.white),
        ),
      ),
    );
  }
}
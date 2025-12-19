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

        // Cuando una hora/minuto está seleccionado (números grandes)
        hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.backgroundDark; // Texto oscuro en selección
          }
          return Colors.white; // Texto blanco sin selección
        }),
        hourMinuteColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary; // Fondo verde neón
          }
          return AppColors.inputBg; // Fondo gris/verde oscuro
        }),

        // AM/PM Selector
        // Aquí usamos un color MUY diferente para la selección para que resalte
        dayPeriodColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          // Color para la opción NO seleccionada
          return Colors.transparent; 
        }),
        
        dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.black; // Texto negro para máximo contraste
          }
          return Colors.white70; // Texto un poco apagado para lo no seleccionado
        }),

        // Borde del selector AM/PM
        dayPeriodBorderSide: const BorderSide(
            color: AppColors.surfaceBorder, 
            width: 1
        ),

        dayPeriodShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        
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
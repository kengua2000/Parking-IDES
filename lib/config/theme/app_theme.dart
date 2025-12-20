import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Configuración del tema de la aplicación
class AppTheme {
  AppTheme._();

  /// Tema oscuro de la aplicación
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark, // Define explícitamente que es un tema oscuro
      
      // Definimos el esquema de colores para asegurar contrastes correctos
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.backgroundDark,
        surface: AppColors.surfaceDark,
        onSurface: Colors.white,
        error: AppColors.redExit,
      ),

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
        dayPeriodColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent; 
        }),
        
        dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.backgroundDark; // Texto oscuro para máximo contraste con verde
          }
          return Colors.white70; // Texto blanco apagado
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
        
        // Estilo de los inputs (Etiquetas "Hour" y "Minute")
        inputDecorationTheme: const InputDecorationTheme(
          labelStyle: TextStyle(color: Colors.white),
          helperStyle: TextStyle(color: Colors.white),
          hintStyle: TextStyle(color: Colors.white54),

          // Padding equilibrado
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          
          filled: true,
          fillColor: AppColors.inputBg,
          border: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.surfaceBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.surfaceBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

/// Paleta de colores de la aplicación
/// Diseño basado en tema oscuro con acentos en verde neón
class AppColors {
  AppColors._(); // Constructor privado para prevenir instanciación

  // Colores primarios
  static const Color primary = Color(0xFF36E27B);      // Verde Neón

  // Fondos
  static const Color backgroundDark = Color(0xFF112117); // Fondo Principal
  static const Color surfaceDark = Color(0xFF1A2C22);    // Fondo Tarjetas
  static const Color surfaceLight = Color(0xFF233A2E);   // Fondo Tarjetas más claras
  static const Color inputBg = Color(0xFF254632);        // Fondo Input

  // Bordes y decoraciones
  static const Color surfaceBorder = Color(0xFF366348);

  // Textos
  static const Color textGray = Color(0xFF95C6A9);       // Texto secundario

  // Estados y acciones
  static const Color redExit = Color(0xFFFF5252);        // Rojo Salida
}
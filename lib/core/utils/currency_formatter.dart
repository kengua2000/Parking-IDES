import 'package:intl/intl.dart';

/// Utilidades para formatear moneda
class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '', // Quitamos el símbolo de la configuración automática
    decimalDigits: 0,
  );

  /// Formatea un número como moneda colombiana
  /// Ejemplo: 10000 -> "$ 10.000"
  static String format(int amount) {
    // Formateamos el número y agregamos el símbolo al principio con espacio
    return '\$ ${_currencyFormat.format(amount)}';
  }

  /// Formatea valor abreviado (ej: 5000 -> "$ 5k")
  static String formatShort(int amount) {
    if (amount >= 1000) {
      return '\$ ${amount ~/ 1000}k';
    }
    return '\$ $amount';
  }
}
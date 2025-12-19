import 'package:intl/intl.dart';

/// Utilidades para formatear fechas y horas
class DateFormatter {
  DateFormatter._();

  static final DateFormat _timeFormat = DateFormat('HH:mm');
  static final DateFormat _dayFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _displayTimeFormat = DateFormat('hh:mm a');

  /// Formatea hora en formato 24h (HH:mm)
  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  /// Formatea fecha como string (yyyy-MM-dd)
  static String formatDay(DateTime date) {
    return _dayFormat.format(date);
  }

  /// Formatea hora en formato 12h con AM/PM
  static String formatDisplayTime(DateTime date) {
    return _displayTimeFormat.format(date);
  }

  /// Parsea string de hora en formato HH:mm a DateTime
  static DateTime parseTime(String timeString, DateTime referenceDate) {
    final parsed = _timeFormat.parse(timeString);
    return DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
      parsed.hour,
      parsed.minute,
    );
  }

  /// Calcula tiempo relativo (ej: "Hace 5 min", "Hace 2 h")
  static String getRelativeTime(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 60) {
      return 'Hace ${diff.inMinutes} min';
    }

    return 'Hace ${diff.inHours} h';
  }

  /// Formatea duración en formato legible (ej: "2h 30m")
  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return '${hours}h ${minutes}m';
  }
}
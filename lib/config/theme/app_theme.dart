import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // Importante para el estilo iOS
import 'app_colors.dart';

/// Configuración del tema de la aplicación
class AppTheme {
  AppTheme._();

  /// Muestra el selector de hora como un diálogo flotante
  static Future<TimeOfDay?> showCupertinoTimePicker({
    required BuildContext context,
    required TimeOfDay initialTime,
  }) async {
    final now = DateTime.now();
    DateTime tempDate = DateTime(now.year, now.month, now.day, initialTime.hour, initialTime.minute);
    TimeOfDay? selectedTime = initialTime;

    return await showDialog<TimeOfDay>(
      context: context,
      builder: (BuildContext context) {
        // Envolvemos con Center y ConstrainedBox para controlar el tamaño
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440), // Ancho máximo para web y tablet
            child: Dialog(
              backgroundColor: AppColors.surfaceDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SizedBox(
                height: 380, // Altura aumentada para incluir el título
                child: Column(
                  children: [
                    // Título del diálogo
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Text(
                        'Hora Manual',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // El Selector tipo Rueda
                    Expanded(
                      child: CupertinoTheme(
                        data: const CupertinoThemeData(
                          brightness: Brightness.dark,
                          textTheme: CupertinoTextThemeData(
                            dateTimePickerTextStyle: TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                            ),
                          ),
                        ),
                        child: CupertinoDatePicker(
                          mode: CupertinoDatePickerMode.time,
                          initialDateTime: tempDate,
                          use24hFormat: false, // Usar formato AM/PM
                          backgroundColor: AppColors.surfaceDark,
                          onDateTimeChanged: (DateTime newDate) {
                            selectedTime = TimeOfDay.fromDateTime(newDate);
                          },
                        ),
                      ),
                    ),
                    
                    // Barra de acciones inferior
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      decoration: const BoxDecoration(
                         border: Border(
                          top: BorderSide(color: Colors.white10, width: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            child: const Text('Cancelar', style: TextStyle(color: Colors.white70)),
                            onPressed: () => Navigator.of(context).pop(null),
                          ),
                          const SizedBox(width: 18),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.backgroundDark,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Aceptar', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () => Navigator.of(context).pop(selectedTime),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Tema oscuro de la aplicación
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        onPrimary: AppColors.backgroundDark,
        surface: AppColors.surfaceDark,
        onSurface: Colors.white,
        error: AppColors.redExit,
      ),

      scaffoldBackgroundColor: AppColors.backgroundDark,
      fontFamily: 'Noto Sans',
      

    );
  }
}
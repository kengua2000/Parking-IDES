import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';

/// Sección de input para número de ticket con selector de hora
class TicketInputSection extends StatelessWidget {
  final TextEditingController ticketController;
  final TextEditingController manualTimeController;
  final bool hasManualTime;
  final VoidCallback onSelectTime;
  final VoidCallback onClearManualTime;

  const TicketInputSection({
    super.key,
    required this.ticketController,
    required this.manualTimeController,
    required this.hasManualTime,
    required this.onSelectTime,
    required this.onClearManualTime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Número de Ticket',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        // Input grande
        Container(
          height: 96,
          decoration: BoxDecoration(
            color: AppColors.inputBg,
            borderRadius: BorderRadius.circular(20),
            border: hasManualTime
                ? Border.all(color: AppColors.primary, width: 1)
                : null,
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: ticketController,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: '0000',
              hintStyle: const TextStyle(color: Colors.white24),
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.access_time,
                  color: hasManualTime
                      ? AppColors.primary
                      : AppColors.textGray,
                  size: 30,
                ),
                onPressed: onSelectTime,
              ),
            ),
          ),
        ),

        // Indicador de hora manual
        if (hasManualTime)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 5),
                Text(
                  'Hora manual: ${manualTimeController.text}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: onClearManualTime,
                  child: const Icon(
                    Icons.close,
                    color: AppColors.textGray,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

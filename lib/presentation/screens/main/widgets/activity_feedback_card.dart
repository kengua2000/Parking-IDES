import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';

/// Card que muestra feedback de la última acción (éxito o error)
class ActivityFeedbackCard extends StatelessWidget {
  final String message;
  final bool isError;

  const ActivityFeedbackCard({
    super.key,
    required this.message,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    // Colores e iconos dinámicos
    final color = isError ? AppColors.redExit : AppColors.primary;
    final icon = isError ? Icons.error_outline : Icons.check_circle;
    final title = isError ? 'Atención' : 'Última acción exitosa';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border.all(
          color: color.withValues(alpha:0.3),
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: TextStyle(
                    color: isError ? AppColors.redExit : AppColors.textGray,
                    fontSize: 12,
                    fontWeight: isError ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

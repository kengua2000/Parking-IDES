import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';

/// Item de vehículo activo (EN CURSO) en la lista
class ActiveVehicleItem extends StatelessWidget {
  final QueryDocumentSnapshot doc;

  const ActiveVehicleItem({
    super.key,
    required this.doc,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final ticket = data['ticket'] ?? '---';
    final entrada = (data['fecha_entrada'] as Timestamp).toDate();
    final diff = DateTime.now().difference(entrada);
    final tiempo = '${diff.inHours}h ${diff.inMinutes % 60}m transcurridos';
    final isMoto = data['tipo'] == 'Moto';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha:0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono con indicador de estado activo
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBorder.withValues(alpha:0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  isMoto ? Icons.two_wheeler : Icons.directions_car,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.surfaceDark,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),

          // Información del vehículo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Ticket #$ticket',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha:0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'ADENTRO',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.login,
                      size: 16,
                      color: Colors.white60,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormatter.formatDisplayTime(entrada),
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.schedule,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      tiempo,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Placeholder para costo (aún no cobrado)
          const Text(
            '---',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';

/// Item de actividad reciente en la pantalla principal
class RecentActivityItem extends StatelessWidget {
  final QueryDocumentSnapshot doc;

  const RecentActivityItem({
    super.key,
    required this.doc,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final isActive = data['estado'] == 'ADENTRO';
    final ticket = data['ticket'] ?? '---';
    final tipo = data['tipo'] ?? 'Carro';

    // Calcular tiempo relativo
    final Timestamp timestamp = isActive
        ? (data['fecha_entrada'] ?? data['entrada'])
        : (data['fecha_salida'] ?? Timestamp.now());
    final fecha = timestamp.toDate();
    final tiempoRelativo = DateFormatter.getRelativeTime(fecha);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha:0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icono y datos del vehículo
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withValues(alpha:0.2)
                      : AppColors.redExit.withValues(alpha:0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isActive ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isActive ? AppColors.primary : AppColors.redExit,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActive ? 'Entrada $tipo' : 'Salida $tipo',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Ticket #$ticket',
                    style: const TextStyle(
                      color: AppColors.textGray,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Tiempo y costo
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tiempoRelativo,
                style: const TextStyle(
                  color: AppColors.textGray,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (!isActive)
                Text(
                  '\$${data['costo']}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
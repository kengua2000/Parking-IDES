import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../config/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/currency_formatter.dart';

/// Item de vehículo completado (FINALIZADO) en la lista
class CompletedVehicleItem extends StatelessWidget {
  final QueryDocumentSnapshot doc;

  const CompletedVehicleItem({
    super.key,
    required this.doc,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final ticket = data['ticket'] ?? '---';
    final entrada = (data['fecha_entrada'] as Timestamp).toDate();
    final salida = (data['fecha_salida'] as Timestamp).toDate();
    final diff = salida.difference(entrada);
    final costo = (data['costo'] as num).toInt();
    final isMoto = data['tipo'] == 'Moto';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha:0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono del vehículo
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isMoto ? Icons.two_wheeler : Icons.directions_car,
              color: Colors.white38,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // Información del vehículo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ticket #$ticket',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(
                      Icons.login,
                      size: 14,
                      color: Colors.white38,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      DateFormatter.formatDisplayTime(entrada),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.logout,
                      size: 14,
                      color: Colors.white38,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      DateFormatter.formatDisplayTime(salida),
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tiempo: ${diff.inHours}h ${diff.inMinutes % 60}m',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Costo y estado
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.format(costo),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Text(
                  'Pagado',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/currency_formatter.dart';

/// Diálogo de resumen del día
class SummaryDialog extends StatelessWidget {
  const SummaryDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateFormatter.formatDay(DateTime.now());

    return Dialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Resumen del Día',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // StreamBuilder para obtener datos en tiempo real
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('vehiculos')
                    .where('dia', isEqualTo: today)
                    .where('estado', isEqualTo: 'SALIDO')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  // Agrupar por costo
                  final Map<int, int> counts = {};
                  int totalIncome = 0;
                  int totalVehicles = 0;

                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;
                    final costo = data['costo'] as int;
                    
                    counts[costo] = (counts[costo] ?? 0) + 1;
                    totalIncome += costo;
                    totalVehicles += 1;
                  }

                  // Ordenar claves
                  final sortedKeys = counts.keys.toList()..sort();

                  return Column(
                    children: [
                      // Resumen general
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStat('Total', '$totalVehicles'),
                          _buildStat('Ingresos', CurrencyFormatter.format(totalIncome)),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 32),
                      
                      // Detalle por valor
                      if (sortedKeys.isEmpty)
                        const Text(
                          'No hay salidas registradas hoy',
                          style: TextStyle(color: Colors.white54),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.white12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Table(
                            columnWidths: const {
                              0: FlexColumnWidth(2), // Columna de Valor
                              1: FlexColumnWidth(1), // Columna de Cantidad
                            },
                            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                            children: sortedKeys.map((costo) {
                              final cantidad = counts[costo];
                              final isLast = costo == sortedKeys.last;
                              return TableRow(
                                decoration: BoxDecoration(
                                  border: isLast ? null : const Border(
                                    bottom: BorderSide(color: Colors.white12),
                                  ),
                                ),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    child: Text(
                                      CurrencyFormatter.format(costo),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                    child: Text(
                                      '$cantidad',
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.backgroundDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

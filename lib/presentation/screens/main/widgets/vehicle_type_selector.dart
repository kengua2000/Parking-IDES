import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';

/// Selector de tipo de vehículo (Carro/Moto)
class VehicleTypeSelector extends StatelessWidget {
  final String selectedType;
  final Function(String) onTypeChanged;

  const VehicleTypeSelector({
    super.key,
    required this.selectedType,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        children: [
          _buildSegmentButton(
            text: 'Carro',
            icon: Icons.directions_car,
            isActive: selectedType == 'Carro',
          ),
          _buildSegmentButton(
            text: 'Moto',
            icon: Icons.two_wheeler,
            isActive: selectedType == 'Moto',
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton({
    required String text,
    required IconData icon,
    required bool isActive,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTypeChanged(text),
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            boxShadow: isActive
                ? [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.1),
                blurRadius: 4,
              ),
            ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive
                    ? AppColors.backgroundDark
                    : AppColors.textGray,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: isActive
                      ? AppColors.backgroundDark
                      : AppColors.textGray,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

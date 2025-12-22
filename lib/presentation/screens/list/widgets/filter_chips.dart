import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';

/// Chips de filtro para la lista de vehículos
class FilterChips extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final int countInParking;
  final int countExits;
  final Widget? trailing; // Widget opcional al final de los chips

  const FilterChips({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.countInParking = 0,
    this.countExits = 0,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildFilterChip('Todos'),
          const SizedBox(width: 12),
          _buildFilterChip('En Parqueadero', count: countInParking),
          const SizedBox(width: 12),
          _buildFilterChip('Salidas', count: countExits),
          
          if (trailing != null) ...[
            const SizedBox(width: 12),
            trailing!,
          ]
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, {int? count}) {
    final isSelected = selectedFilter == label;
    
    // Construir el texto final: "Etiqueta" o "Etiqueta (N)"
    final displayText = count != null ? '$label ($count)' : label;

    return GestureDetector(
      onTap: () => onFilterChanged(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha:0.2),
              blurRadius: 8,
            ),
          ]
              : [],
        ),
        child: Text(
          displayText,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

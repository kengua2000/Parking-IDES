import 'package:flutter/material.dart';
import '../../../../config/theme/app_colors.dart';

/// Botones de ENTRADA y SALIDA
class ActionButtons extends StatelessWidget {
  final VoidCallback onEntryPressed;
  final VoidCallback onExitPressed;

  const ActionButtons({
    super.key,
    required this.onEntryPressed,
    required this.onExitPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'ENTRADA',
            icon: Icons.arrow_downward,
            backgroundColor: AppColors.primary,
            textColor: AppColors.backgroundDark,
            onPressed: onEntryPressed,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _ActionButton(
            label: 'SALIDA',
            icon: Icons.arrow_upward,
            backgroundColor: AppColors.redExit,
            textColor: AppColors.backgroundDark,
            onPressed: onExitPressed,
          ),
        ),
      ],
    );
  }
}

/// Botón de acción individual (ENTRADA o SALIDA)
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha: 0.3),
              blurRadius: 15,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: label == 'ENTRADA'
                    ? AppColors.backgroundDark.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: textColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
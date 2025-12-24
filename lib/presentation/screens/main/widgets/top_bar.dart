import 'package:flutter/material.dart';
import '../../../widgets/common/circle_icon_button.dart';

/// Barra superior con título y botón de resumen
class TopBar extends StatelessWidget {
  final VoidCallback onSummaryPressed;

  const TopBar({
    super.key,
    required this.onSummaryPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CircleIconButton(
          icon: Icons.insert_chart,
          onPressed: onSummaryPressed,
        ),
        const Text(
          'Parqueadero IDES',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }
}
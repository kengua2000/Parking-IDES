import 'package:flutter/material.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';

/// Diálogo de confirmación de cobro con cálculo de cambio
class CobroDialog extends StatefulWidget {
  final String ticket;
  final String tipo;
  final int totalAPagar;
  final String tiempoTotal;
  final VoidCallback onCobrar;

  const CobroDialog({
    super.key,
    required this.ticket,
    this.tipo = 'Vehículo',
    required this.totalAPagar,
    required this.tiempoTotal,
    required this.onCobrar,
  });

  @override
  State<CobroDialog> createState() => _CobroDialogState();
}

class _CobroDialogState extends State<CobroDialog> {
  int _pagoCon = 0;
  int _devuelta = 0;
  bool _isProcessing = false; // NUEVO: Para evitar múltiples toques

  @override
  void initState() {
    super.initState();
    _pagoCon = 0;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).unfocus();
    });
  }

  void _calcularDevuelta(int valorEntregado) {
    setState(() {
      _pagoCon = valorEntregado;
      _devuelta = _pagoCon - widget.totalAPagar;
    });
  }

  List<int> _getOpcionesPago(int total) {
    switch (total) {
      case 2000:
        return [5000, 10000, 20000, 50000, 100000];
      case 2500:
        return [3000, 4000, 5000, 10000, 20000, 50000, 100000];
      case 3000:
        return [4000, 5000, 10000, 20000, 50000, 100000];
      case 3500:
        return [4000, 5000, 10000, 20000, 50000, 100000];
      case 4000:
        return [5000, 10000, 20000, 50000, 100000];
      case 5000:
        return [6000, 10000, 20000, 50000, 100000];
      case 5500:
        return [5000, 6000, 7000, 10000, 20000, 50000, 100000];
      case 6000:
        return [7000, 10000, 20000, 50000, 100000];
      default:
        final standard = [2000, 5000, 10000, 20000, 50000, 100000];
        return standard.where((b) => b >= total).toList();
    }
  }

  // NUEVO: Método seguro para manejar el cobro
  Future<void> _handleCobrar() async {
    if (_isProcessing) return; // Evitar múltiples toques

    setState(() {
      _isProcessing = true;
    });

    try {
      // Cerrar el diálogo PRIMERO
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Luego ejecutar el callback
      widget.onCobrar();
    } catch (e) {
      debugPrint('Error en cobro: $e');
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pagoSuficiente = _pagoCon >= widget.totalAPagar;
    final billetes = _getOpcionesPago(widget.totalAPagar);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.surfaceBorder,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Título
              const Column(
                children: [
                  Text(
                    'Confirmar Salida',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Divider(color: AppColors.surfaceBorder),
                ],
              ),
              const SizedBox(height: 16),

              // Contenido con Scroll
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tiempo Total
                      const Text(
                        'Tiempo Total:',
                        style: TextStyle(
                          color: AppColors.textGray,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        widget.tiempoTotal,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Total a Pagar
                      const Text(
                        'Total a Pagar:',
                        style: TextStyle(
                          color: AppColors.textGray,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(widget.totalAPagar),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                        ),
                      ),

                      // Ticket Info
                      const SizedBox(height: 4),
                      Text(
                        'Ticket #${widget.ticket} ( ${widget.tipo} )',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      const Divider(color: AppColors.surfaceBorder),
                      const Text(
                        'Selecciona con cuánto paga:',
                        style: TextStyle(
                          color: AppColors.textGray,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Botón Pago Exacto
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isProcessing ? null : () => _calcularDevuelta(widget.totalAPagar),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surfaceLight,
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                              side: BorderSide(
                                color: _pagoCon == widget.totalAPagar
                                    ? AppColors.primary
                                    : Colors.transparent,
                              ),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Pago Exacto',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Botones de billetes
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: billetes
                            .map((valor) => _buildBillButton(valor))
                            .toList(),
                      ),
                      const SizedBox(height: 20),

                      // Devuelta (Cambio)
                      const Text(
                        'Devuelta (Cambio):',
                        style: TextStyle(
                          color: AppColors.textGray,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _pagoCon > 0 ? CurrencyFormatter.format(_devuelta) : '---',
                        style: TextStyle(
                          color: _devuelta >= 0
                              ? AppColors.redExit
                              : AppColors.redExit,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Botones de acción
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isProcessing ? null : () => Navigator.pop(context),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.white38),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    // CAMBIO PRINCIPAL: Usar el nuevo método
                    onPressed: (pagoSuficiente && !_isProcessing) ? _handleCobrar : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.surfaceLight.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.backgroundDark,
                      ),
                    )
                        : Text(
                      'COBRAR Y SALIR',
                      style: TextStyle(
                        color: pagoSuficiente
                            ? AppColors.backgroundDark
                            : Colors.white30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillButton(int valor) {
    final isSelected = _pagoCon == valor;

    return GestureDetector(
      onTap: _isProcessing ? null : () => _calcularDevuelta(valor),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.surfaceBorder,
          ),
        ),
        child: Text(
          CurrencyFormatter.formatShort(valor),
          style: TextStyle(
            color: isSelected
                ? AppColors.backgroundDark
                : Colors.white70,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme/app_theme.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/services/firestore_service.dart';
import '../../widgets/common/circle_icon_button.dart';
import '../../widgets/dialogs/cobro_dialog.dart';
import '../../widgets/dialogs/summary_dialog.dart';
import '../list/list_screen.dart';
import 'widgets/main_header.dart';
import 'widgets/vehicle_type_selector.dart';
import 'widgets/ticket_input_section.dart';
import 'widgets/activity_feedback_card.dart';
import 'widgets/recent_activity_item.dart';

/// Pantalla principal del dashboard
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Controladores
  final TextEditingController _ticketController = TextEditingController();
  final TextEditingController _manualTimeController = TextEditingController();

  // Estado
  String _vehicleType = 'Carro';
  String _lastActionText = '';
  bool _isErrorState = false;

  // Servicios
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void dispose() {
    _ticketController.dispose();
    _manualTimeController.dispose();
    super.dispose();
  }

  /// Muestra selector de hora estilo Cupertino (Wheel)
  Future<void> _selectTime() async {
    final picked = await AppTheme.showCupertinoTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      setState(() => _manualTimeController.text = DateFormatter.formatTime(dt));
    }
  }

  /// Registra entrada de vehículo
  void _registerEntry() async {
    final ticket = _ticketController.text.trim();

    if (ticket.isEmpty) {
      _showErrorInCard('Escribe el ticket');
      return;
    }

    FocusScope.of(context).unfocus();

    // Determinar fecha/hora de entrada
    DateTime entryDate = DateTime.now();
    if (_manualTimeController.text.isNotEmpty) {
      try {
        entryDate = DateFormatter.parseTime(
          _manualTimeController.text,
          DateTime.now(),
        );
      } catch (e) {
        _showErrorInCard('Formato de hora incorrecto');
        return;
      }
    }

    // Verificar si ya está adentro
    final isInside = await _firestoreService.isVehicleInside(ticket);
    if (isInside) {
      _showErrorInCard('El vehículo $ticket ya está ADENTRO');
      return;
    }

    // Registrar entrada
    try {
      await _firestoreService.registerEntry(
        ticket: ticket,
        tipo: _vehicleType,
        fechaEntrada: entryDate,
        dia: DateFormatter.formatDay(entryDate),
      );

      _ticketController.clear();
      _manualTimeController.clear();
      
      setState(() {
        _isErrorState = false;
        _lastActionText = 'Entrada registrada para Ticket #$ticket - '
            '${DateFormatter.formatDisplayTime(entryDate)}';
      });
    } catch (e) {
      _showErrorInCard('Error al registrar entrada: $e');
    }
  }

  /// Procesa salida con modal de cobro
  void _processExit() async {
    final ticket = _ticketController.text.trim();

    if (ticket.isEmpty) {
      _showErrorInCard('Escribe el ticket');
      return;
    }

    FocusScope.of(context).unfocus();

    try {
      // Buscar vehículo
      final doc = await _firestoreService.findActiveVehicle(ticket);

      if (doc == null) {
        _showErrorInCard('Ticket no encontrado o ya salió');
        return;
      }

      // Extraer datos
      final data = doc.data() as Map<String, dynamic>;
      final Timestamp entryTimestamp = data['fecha_entrada'] ?? data['entrada'];
      final DateTime entryDate = entryTimestamp.toDate();

      // Determinar fecha/hora de salida
      DateTime exitDate = DateTime.now();
      if (_manualTimeController.text.isNotEmpty) {
        try {
          exitDate = DateFormatter.parseTime(
            _manualTimeController.text,
            DateTime.now(),
          );
        } catch (e) {
          // Si falla, usar fecha actual
        }
      }

      // Calcular tiempo y costo
      int minutes = exitDate.difference(entryDate).inMinutes;
      if (minutes < 0) minutes = 0;

      final tipo = data['tipo'] ?? _vehicleType;
      final costo = FirestoreService.calculateCost(
        tipo: tipo,
        minutes: minutes,
      );

      // Mostrar diálogo de cobro
      _showChargeDialog(
        docId: doc.id,
        ticket: ticket,
        tipo: tipo,
        entryDate: entryDate,
        exitDate: exitDate,
        total: costo,
        totalMinutes: minutes,
      );
    } catch (e) {
      _showErrorInCard('Error: $e');
    }
  }

  /// Elimina un registro de vehículo (corrección de errores)
  void _deleteRecord() async {
    final ticket = _ticketController.text.trim();

    if (ticket.isEmpty) {
      _showErrorInCard('Escribe el ticket para borrar');
      return;
    }

    FocusScope.of(context).unfocus();

    // Confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Eliminar Registro', style: TextStyle(color: Colors.white)),
        content: Text(
          '¿Estás seguro de eliminar el registro activo del ticket #$ticket? Esta acción no se puede deshacer.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ELIMINAR', style: TextStyle(color: AppColors.redExit)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _firestoreService.deleteActiveVehicle(ticket);
      
      _ticketController.clear();
      _manualTimeController.clear();
      
      setState(() {
        _isErrorState = false;
        _lastActionText = 'Registro eliminado para Ticket #$ticket';
      });
    } catch (e) {
      _showErrorInCard('Error al eliminar: $e');
    }
  }

  /// Muestra diálogo de cobro
  void _showChargeDialog({
    required String docId,
    required String ticket,
    required String tipo,
    required DateTime entryDate,
    required DateTime exitDate,
    required int total,
    required int totalMinutes,
  }) {
    final timeFormat = DateFormatter.formatDuration(
      Duration(minutes: totalMinutes),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return CobroDialog(
          ticket: ticket,
          tipo: tipo,
          totalAPagar: total,
          tiempoTotal: timeFormat,
          onCobrar: () async {
            final navigator = Navigator.of(dialogContext);

            await _firestoreService.registerExit(
              docId: docId,
              fechaSalida: exitDate,
              costo: total,
              minutos: totalMinutes,
            );

            if (!mounted) return;

            navigator.pop();
            _ticketController.clear();
            _manualTimeController.clear();

            setState(() {
              _isErrorState = false;
              _lastActionText = 'Salida Ticket #$ticket - '
                  'Cobrado: ${CurrencyFormatter.format(total)}';
            });
          },
        );
      },
    );
  }

  /// Muestra error directamente en la tarjeta de feedback
  void _showErrorInCard(String message) {
    setState(() {
      _isErrorState = true;
      _lastActionText = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasManualTime = _manualTimeController.text.isNotEmpty;

    return Scaffold(
        backgroundColor: AppColors.backgroundDark,
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ListScreen()),
            );
          },
          backgroundColor: AppColors.primary,
          child: const Icon(
            Icons.visibility,
            color: AppColors.backgroundDark,
            size: 30,
          ),
        ),
        body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480), // Ya estaba ajustado aquí
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Bar
                    _buildTopBar(),
                    const SizedBox(height: 24),

                    // Header
                    const MainHeader(),
                    const SizedBox(height: 24),

                    // Selector de tipo de vehículo
                    VehicleTypeSelector(
                      selectedType: _vehicleType,
                      onTypeChanged: (type) => setState(() => _vehicleType = type),
                    ),
                    const SizedBox(height: 24),

                    // Input de ticket
                    TicketInputSection(
                      ticketController: _ticketController,
                      manualTimeController: _manualTimeController,
                      hasManualTime: hasManualTime,
                      onSelectTime: _selectTime,
                      onClearManualTime: () {
                        setState(() => _manualTimeController.clear());
                      },
                    ),
                    const SizedBox(height: 24),

                    // Botones de acción
                    _buildActionButtons(),
                    const SizedBox(height: 16),
                    
                    // Botón de eliminar (NUEVO)
                    Center(
                      child: TextButton.icon(
                        onPressed: _deleteRecord,
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.white38),
                        label: const Text(
                          'Eliminar registro',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Feedback de última acción (o error)
                    if (_lastActionText.isNotEmpty)
                      ActivityFeedbackCard(
                        message: _lastActionText,
                        isError: _isErrorState,
                      ),

                    if (_lastActionText.isNotEmpty)
                      const SizedBox(height: 24),

                    // Lista de actividad reciente
                    _buildRecentActivitySection(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
              ),
            ),
        ),
      );
  }

  /// Top bar con iconos de menú y configuración
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CircleIconButton(
            icon: Icons.insert_chart, 
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const SummaryDialog(),
              );
            }
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

  /// Botones de entrada y salida
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            label: 'ENTRADA',
            icon: Icons.arrow_downward,
            backgroundColor: AppColors.primary,
            textColor: AppColors.backgroundDark,
            onPressed: _registerEntry,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            label: 'SALIDA',
            icon: Icons.arrow_upward,
            backgroundColor: AppColors.redExit,
            textColor: AppColors.backgroundDark,
            onPressed: _processExit,
          ),
        ),
      ],
    );
  }

  /// Botón de acción vertical
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withValues(alpha:0.3),
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
                    ? AppColors.backgroundDark.withValues(alpha:0.1)
                    : Colors.white.withValues(alpha:0.2),
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

  /// Sección de actividad reciente
  Widget _buildRecentActivitySection() {
    return Column(
      children: [
        const Row( 
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Actividad Reciente',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Stream de vehículos recientes
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('vehiculos')
              .orderBy('ultima_actividad', descending: true)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final docs = snapshot.data!.docs;
            return Column(
              children: docs
                  .map((doc) => RecentActivityItem(doc: doc))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}
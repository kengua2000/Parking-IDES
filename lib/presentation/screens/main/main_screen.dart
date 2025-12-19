import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  // Servicios
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void dispose() {
    _ticketController.dispose();
    _manualTimeController.dispose();
    super.dispose();
  }

  /// Muestra selector de hora
  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: 'SELECCIONA HORA',
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
      _showToast('Escribe el ticket/placa');
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
        _showToast('Formato de hora incorrecto');
        return;
      }
    }

    // Verificar si ya está adentro
    final isInside = await _firestoreService.isVehicleInside(ticket);
    if (isInside) {
      _showToast('El vehículo $ticket ya está ADENTRO');
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
      _showToast('Entrada registrada');

      setState(() {
        _lastActionText = 'Entrada registrada para Ticket #$ticket - '
            '${DateFormatter.formatDisplayTime(entryDate)}';
      });
    } catch (e) {
      _showToast('Error al registrar entrada: $e');
    }
  }

  /// Procesa salida con modal de cobro
  void _processExit() async {
    final ticket = _ticketController.text.trim();

    if (ticket.isEmpty) {
      _showToast('Escribe el ticket');
      return;
    }

    FocusScope.of(context).unfocus();

    try {
      // Buscar vehículo
      final doc = await _firestoreService.findActiveVehicle(ticket);

      if (doc == null) {
        _showToast('Ticket no encontrado o ya salió');
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
      _showToast('Error: $e');
    }
  }

  /// Muestra diálogo de cobro
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
          totalAPagar: total,
          tiempoTotal: timeFormat,
          onCobrar: () async {

            final navigator = Navigator.of(dialogContext);
            final scaffoldMessenger = ScaffoldMessenger.of(context);

            // Registrar salida en Firestore
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

            scaffoldMessenger.showSnackBar(
              const SnackBar(content: Text('Salida registrada y cobrada')),
            );

            setState(() {
              _lastActionText = 'Salida Ticket #$ticket - '
                  'Cobrado: ${CurrencyFormatter.format(total)}';
            });
          },
        );
      },
    );
  }

  /// Muestra mensaje toast
  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasManualTime = _manualTimeController.text.isNotEmpty;

    return Scaffold(
        backgroundColor: AppColors.backgroundDark,
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
                    const SizedBox(height: 24),

                    // Feedback de última acción
                    if (_lastActionText.isNotEmpty)
                      ActivityFeedbackCard(message: _lastActionText),

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
        // Botón de resumen (antes menú)
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
          'ParkingApp',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Botón de ver todo (antes configuración)
        CircleIconButton(
            icon: Icons.visibility,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ListScreen()),
              );
            }
        ),
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
            textColor: Colors.white,
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
        const Row( // CAMBIO: Eliminado el botón "Ver Todo"
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
            // "Ver todo" eliminado de aquí
          ],
        ),
        const SizedBox(height: 12),

        // Stream de vehículos recientes
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('vehiculos')
              .orderBy('fecha_entrada', descending: true)
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
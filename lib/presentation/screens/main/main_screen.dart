import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../config/theme/app_theme.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../widgets/dialogs/cobro_dialog.dart';
import '../../widgets/dialogs/summary_dialog.dart';
import '../list/list_screen.dart';
import 'main_viewmodel.dart';
import 'widgets/main_header.dart';
import 'widgets/vehicle_type_selector.dart';
import 'widgets/ticket_input_section.dart';
import 'widgets/activity_feedback_card.dart';
import 'widgets/recent_activity_item.dart';
import 'widgets/action_buttons.dart';
import 'widgets/top_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _ticketController = TextEditingController();
  final TextEditingController _manualTimeController = TextEditingController();
  late final MainViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MainViewModel();
  }

  @override
  void dispose() {
    _ticketController.dispose();
    _manualTimeController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final picked = await AppTheme.showCupertinoTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null && mounted) {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      setState(() => _manualTimeController.text = DateFormatter.formatTime(dt));
    }
  }

  void _handleEntry() async {
    FocusScope.of(context).unfocus();

    await _viewModel.registerEntry(
      ticket: _ticketController.text.trim(),
      manualTime: _manualTimeController.text.isEmpty ? null : _manualTimeController.text,
    );

    if (!_viewModel.isErrorState) {
      _ticketController.clear();
      _manualTimeController.clear();
    }
  }

  void _handleExit() async {
    FocusScope.of(context).unfocus();

    final exitData = await _viewModel.processExit(
      ticket: _ticketController.text.trim(),
      manualTime: _manualTimeController.text.isEmpty ? null : _manualTimeController.text,
    );

    if (exitData != null && mounted) {
      _showChargeDialog(exitData);
    }
  }

  void _handleDelete() async {
    final ticket = _ticketController.text.trim();

    if (ticket.isEmpty) return;

    FocusScope.of(context).unfocus();

    final confirm = await _showDeleteConfirmation(ticket);
    if (confirm != true || !mounted) return;

    await _viewModel.deleteRecord(ticket);

    if (!_viewModel.isErrorState) {
      _ticketController.clear();
      _manualTimeController.clear();
    }
  }

  Future<bool?> _showDeleteConfirmation(String ticket) {
    return showDialog<bool>(
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
  }

  void _showChargeDialog(ExitData exitData) {
    final timeFormat = DateFormatter.formatDuration(
      Duration(minutes: exitData.totalMinutes),
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return CobroDialog(
          ticket: exitData.ticket,
          tipo: exitData.tipo,
          totalAPagar: exitData.total,
          tiempoTotal: timeFormat,
          onCobrar: () async {
            await _viewModel.confirmExit(exitData);

            if (!_viewModel.isErrorState) {
              _ticketController.clear();
              _manualTimeController.clear();
            }
          },
        );
      },
    );
  }

  void _navigateToList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ListScreen()),
    );
  }

  void _showSummary() {
    showDialog(
      context: context,
      builder: (context) => const SummaryDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: AppColors.backgroundDark,
        floatingActionButton: FloatingActionButton(
          onPressed: _navigateToList,
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
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TopBar(onSummaryPressed: _showSummary),
                    const SizedBox(height: 24),
                    const MainHeader(),
                    const SizedBox(height: 24),
                    _buildVehicleTypeSelector(),
                    const SizedBox(height: 24),
                    _buildTicketInput(),
                    const SizedBox(height: 24),
                    ActionButtons(
                      onEntryPressed: _handleEntry,
                      onExitPressed: _handleExit,
                    ),
                    const SizedBox(height: 16),
                    _buildDeleteButton(),
                    const SizedBox(height: 16),
                    _buildFeedback(),
                    _buildRecentActivity(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleTypeSelector() {
    return Consumer<MainViewModel>(
      builder: (context, viewModel, _) {
        return VehicleTypeSelector(
          selectedType: viewModel.vehicleType,
          onTypeChanged: viewModel.setVehicleType,
        );
      },
    );
  }

  Widget _buildTicketInput() {
    final hasManualTime = _manualTimeController.text.isNotEmpty;

    return TicketInputSection(
      ticketController: _ticketController,
      manualTimeController: _manualTimeController,
      hasManualTime: hasManualTime,
      onSelectTime: _selectTime,
      onClearManualTime: () {
        setState(() => _manualTimeController.clear());
      },
    );
  }

  Widget _buildDeleteButton() {
    return Center(
      child: TextButton.icon(
        onPressed: _handleDelete,
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
    );
  }

  Widget _buildFeedback() {
    return Consumer<MainViewModel>(
      builder: (context, viewModel, _) {
        if (viewModel.lastActionText.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            ActivityFeedbackCard(
              message: viewModel.lastActionText,
              isError: viewModel.isErrorState,
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildRecentActivity() {
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
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('vehiculos')
              .orderBy('ultima_actividad', descending: true)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Error al cargar actividad',
                  style: TextStyle(color: Colors.red[300]),
                ),
              );
            }

            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final docs = snapshot.data!.docs;
            return Column(
              children: docs.map((doc) => RecentActivityItem(doc: doc)).toList(),
            );
          },
        ),
      ],
    );
  }
}
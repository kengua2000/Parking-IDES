import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/services/firestore_service.dart';

class MainViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  String _vehicleType = 'Carro';
  String _lastActionText = '';
  bool _isErrorState = false;
  bool _isLoading = false;

  String get vehicleType => _vehicleType;
  String get lastActionText => _lastActionText;
  bool get isErrorState => _isErrorState;
  bool get isLoading => _isLoading;

  void setVehicleType(String type) {
    _vehicleType = type;
    notifyListeners();
  }

  void clearFeedback() {
    _lastActionText = '';
    _isErrorState = false;
    notifyListeners();
  }

  void _showError(String message) {
    _isErrorState = true;
    _lastActionText = message;
    _isLoading = false;
    notifyListeners();
  }

  void _showSuccess(String message) {
    _isErrorState = false;
    _lastActionText = message;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> registerEntry({
    required String ticket,
    String? manualTime,
  }) async {
    if (ticket.isEmpty) {
      _showError('Escribe el ticket');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      DateTime entryDate = DateTime.now();

      if (manualTime != null && manualTime.isNotEmpty) {
        try {
          entryDate = DateFormatter.parseTime(manualTime, DateTime.now());
        } catch (e) {
          _showError('Formato de hora incorrecto');
          return;
        }
      }

      final isInside = await _firestoreService.isVehicleInside(ticket);
      if (isInside) {
        _showError('El vehículo $ticket ya está ADENTRO');
        return;
      }

      await _firestoreService.registerEntry(
        ticket: ticket,
        tipo: _vehicleType,
        fechaEntrada: entryDate,
        dia: DateFormatter.formatDay(entryDate),
      );

      _showSuccess(
          'Entrada registrada para Ticket #$ticket - ${DateFormatter.formatDisplayTime(entryDate)}'
      );
    } catch (e) {
      debugPrint('Error en registerEntry: $e');
      _showError('Error al registrar entrada: $e');
    }
  }

  Future<ExitData?> processExit({
    required String ticket,
    String? manualTime,
  }) async {
    if (ticket.isEmpty) {
      _showError('Escribe el ticket');
      return null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final doc = await _firestoreService.findActiveVehicle(ticket);

      if (doc == null) {
        _showError('Ticket no encontrado o ya salió');
        return null;
      }

      final data = doc.data() as Map<String, dynamic>;
      final Timestamp entryTimestamp = data['fecha_entrada'] ?? data['entrada'];
      final DateTime entryDate = entryTimestamp.toDate();

      DateTime exitDate = DateTime.now();
      if (manualTime != null && manualTime.isNotEmpty) {
        try {
          exitDate = DateFormatter.parseTime(manualTime, DateTime.now());
        } catch (e) {
          debugPrint('Error parseando hora de salida: $e');
        }
      }

      int minutes = exitDate.difference(entryDate).inMinutes;
      if (minutes < 0) minutes = 0;

      final tipo = data['tipo'] ?? _vehicleType;
      final costo = FirestoreService.calculateCost(
        tipo: tipo,
        minutes: minutes,
      );

      _isLoading = false;
      notifyListeners();

      return ExitData(
        docId: doc.id,
        ticket: ticket,
        tipo: tipo,
        entryDate: entryDate,
        exitDate: exitDate,
        total: costo,
        totalMinutes: minutes,
      );
    } catch (e) {
      debugPrint('Error en processExit: $e');
      _showError('Error: $e');
      return null;
    }
  }

  Future<void> confirmExit(ExitData exitData) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService.registerExit(
        docId: exitData.docId,
        fechaSalida: exitData.exitDate,
        costo: exitData.total,
        minutos: exitData.totalMinutes,
      );

      _showSuccess(
          'Salida Ticket #${exitData.ticket} - Cobrado: ${CurrencyFormatter.format(exitData.total)}'
      );
    } catch (e) {
      debugPrint('Error al confirmar salida: $e');
      _showError('Error al procesar cobro: $e');
    }
  }

  Future<void> deleteRecord(String ticket) async {
    if (ticket.isEmpty) {
      _showError('Escribe el ticket para borrar');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _firestoreService.deleteActiveVehicle(ticket);
      _showSuccess('Registro eliminado para Ticket #$ticket');
    } catch (e) {
      debugPrint('Error en deleteRecord: $e');
      _showError('Error al eliminar: $e');
    }
  }
}

class ExitData {
  final String docId;
  final String ticket;
  final String tipo;
  final DateTime entryDate;
  final DateTime exitDate;
  final int total;
  final int totalMinutes;

  ExitData({
    required this.docId,
    required this.ticket,
    required this.tipo,
    required this.entryDate,
    required this.exitDate,
    required this.total,
    required this.totalMinutes,
  });
}
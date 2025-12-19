import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de datos para un vehículo en el parqueadero
class VehicleModel {
  final String id;
  final String ticket;
  final String tipo;
  final DateTime fechaEntrada;
  final DateTime? fechaSalida;
  final String estado; // "ADENTRO" o "SALIDO"
  final String dia;
  final int costo;
  final int minutos;

  VehicleModel({
    required this.id,
    required this.ticket,
    required this.tipo,
    required this.fechaEntrada,
    this.fechaSalida,
    required this.estado,
    required this.dia,
    required this.costo,
    required this.minutos,
  });

  /// Crear modelo desde un documento de Firestore
  factory VehicleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return VehicleModel(
      id: doc.id,
      ticket: data['ticket'] ?? '',
      tipo: data['tipo'] ?? 'Carro',
      fechaEntrada: (data['fecha_entrada'] ?? data['entrada'] as Timestamp).toDate(),
      fechaSalida: data['fecha_salida'] != null
          ? (data['fecha_salida'] as Timestamp).toDate()
          : null,
      estado: data['estado'] ?? 'ADENTRO',
      dia: data['dia'] ?? '',
      costo: (data['costo'] as num?)?.toInt() ?? 0,
      minutos: (data['minutos'] as num?)?.toInt() ?? 0,
    );
  }

  /// Convertir modelo a Map para Firestore
  Map<String, dynamic> toMap() {
    return {
      'ticket': ticket,
      'tipo': tipo,
      'fecha_entrada': Timestamp.fromDate(fechaEntrada),
      'entrada': Timestamp.fromDate(fechaEntrada),
      'fecha_salida': fechaSalida != null ? Timestamp.fromDate(fechaSalida!) : null,
      'estado': estado,
      'dia': dia,
      'costo': costo,
      'minutos': minutos,
    };
  }

  /// Copiar modelo con valores actualizados
  VehicleModel copyWith({
    String? id,
    String? ticket,
    String? tipo,
    DateTime? fechaEntrada,
    DateTime? fechaSalida,
    String? estado,
    String? dia,
    int? costo,
    int? minutos,
  }) {
    return VehicleModel(
      id: id ?? this.id,
      ticket: ticket ?? this.ticket,
      tipo: tipo ?? this.tipo,
      fechaEntrada: fechaEntrada ?? this.fechaEntrada,
      fechaSalida: fechaSalida ?? this.fechaSalida,
      estado: estado ?? this.estado,
      dia: dia ?? this.dia,
      costo: costo ?? this.costo,
      minutos: minutos ?? this.minutos,
    );
  }

  /// Verifica si el vehículo está actualmente en el parqueadero
  bool get isActive => estado == 'ADENTRO';

  /// Obtiene el tiempo transcurrido desde la entrada
  Duration getElapsedTime() {
    final endTime = fechaSalida ?? DateTime.now();
    return endTime.difference(fechaEntrada);
  }
}
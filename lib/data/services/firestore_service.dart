import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicle_model.dart';

/// Servicio para manejar operaciones de Firestore
class FirestoreService {

  final CollectionReference _vehiclesCollection;

  FirestoreService()
      : _vehiclesCollection = FirebaseFirestore.instance.collection('vehiculos');

  /// Verifica si un vehículo ya está registrado como ADENTRO
  Future<bool> isVehicleInside(String ticket) async {
    final snapshot = await _vehiclesCollection
        .where('ticket', isEqualTo: ticket)
        .where('estado', isEqualTo: 'ADENTRO')
        .get();

    return snapshot.docs.isNotEmpty;
  }

  /// Registra la entrada de un vehículo
  Future<void> registerEntry({
    required String ticket,
    required String tipo,
    required DateTime fechaEntrada,
    required String dia,
  }) async {
    // Usamos 'ultima_actividad' para ordenar unificadamente entradas y salidas
    await _vehiclesCollection.add({
      'ticket': ticket,
      'tipo': tipo,
      'fecha_entrada': Timestamp.fromDate(fechaEntrada),
      'entrada': Timestamp.fromDate(fechaEntrada),
      'estado': 'ADENTRO',
      'dia': dia,
      'costo': 0,
      'minutos': 0,
      'ultima_actividad': Timestamp.fromDate(fechaEntrada), // NUEVO CAMPO
    });
  }

  /// Busca un vehículo por ticket que esté ADENTRO
  Future<QueryDocumentSnapshot?> findActiveVehicle(String ticket) async {
    final snapshot = await _vehiclesCollection
        .where('ticket', isEqualTo: ticket)
        .where('estado', isEqualTo: 'ADENTRO')
        .get();

    return snapshot.docs.isNotEmpty ? snapshot.docs.first : null;
  }

  /// Elimina un vehículo activo por ticket (Corrección de errores)
  Future<void> deleteActiveVehicle(String ticket) async {
    final snapshot = await _vehiclesCollection
        .where('ticket', isEqualTo: ticket)
        .where('estado', isEqualTo: 'ADENTRO')
        .get();

    if (snapshot.docs.isEmpty) {
      throw 'No se encontró ningún vehículo activo con ese ticket para eliminar.';
    }

    // Borramos el documento encontrado
    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  /// Registra la salida de un vehículo
  Future<void> registerExit({
    required String docId,
    required DateTime fechaSalida,
    required int costo,
    required int minutos,
  }) async {
    await _vehiclesCollection.doc(docId).update({
      'fecha_salida': Timestamp.fromDate(fechaSalida),
      'costo': costo,
      'minutos': minutos,
      'estado': 'SALIDO',
      'ultima_actividad': Timestamp.fromDate(fechaSalida), // ACTUALIZAMOS CAMPO
    });
  }

  /// Obtiene stream de vehículos recientes (últimos 3)
  Stream<List<VehicleModel>> getRecentVehicles() {
    return _vehiclesCollection
        .orderBy('ultima_actividad', descending: true)
        .limit(3)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => VehicleModel.fromFirestore(doc))
        .toList());
  }

  /// Obtiene stream de vehículos del día actual
  Stream<List<VehicleModel>> getTodayVehicles(String dia) {
    return _vehiclesCollection
        .where('dia', isEqualTo: dia)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => VehicleModel.fromFirestore(doc))
        .toList());
  }

  /// Calcula el costo del parqueadero según el tiempo
  static int calculateCost({
    required String tipo,
    required int minutes,
  }) {
    final bool esMoto = tipo == 'Moto';
    final tarifa = esMoto ? 2000 : 3000;
    final topeMaximo = esMoto ? 4000 : 6000; // Tope diferenciado

    if (minutes <= 65) {
      return tarifa;
    }

    // Cobrar $500 por cada hora adicional después de la primera
    final horasAdicionales = ((minutes - 60) / 60).ceil();
    final total = tarifa + (horasAdicionales * 500);

    // Tope máximo según tipo de vehículo
    if (total > topeMaximo) {
      return topeMaximo;
    }

    return total;
  }
}
/// Constantes de la aplicación
class AppConstants {
  AppConstants._();

  // Estados de vehículo
  static const String estadoAdentro = 'ADENTRO';
  static const String estadoSalido = 'SALIDO';

  // Tipos de vehículo
  static const String tipoCarro = 'Carro';
  static const String tipoMoto = 'Moto';

  // Tarifas (en pesos colombianos)
  static const int tarifaCarro = 3000;
  static const int tarifaMoto = 2000;
  static const int tarifaHoraAdicional = 500;

  // Tiempo
  static const int minutosGracia = 65; // 1 hora + 5 minutos de gracia

  // Firestore
  static const String collectionVehiculos = 'vehiculos';

  // Límites de UI
  static const int limitRecientes = 3;
}
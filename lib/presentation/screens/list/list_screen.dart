import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../config/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/currency_formatter.dart';
import 'widgets/stat_card.dart';
import 'widgets/filter_chips.dart';
import 'widgets/active_vehicle_item.dart';
import 'widgets/completed_vehicle_item.dart';

/// Pantalla de listado diario de vehículos
class ListScreen extends StatefulWidget {
  const ListScreen({super.key});

  @override
  State<ListScreen> createState() => _ListScreenState();
}

class _ListScreenState extends State<ListScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _filter = 'Todos';
  List<QueryDocumentSnapshot> _fullList = [];
  bool _isLoading = true;
  int _totalVehicles = 0;
  int _totalCars = 0;
  int _totalMotos = 0;
  int _totalIncome = 0;
  int _countInParking = 0; // Contador de vehículos adentro
  int _countExits = 0;     // Contador de salidas
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Carga datos del día actual
  void _loadData() {
    final todayString = DateFormatter.formatDay(DateTime.now());

    _db
        .collection('vehiculos')
        .where('dia', isEqualTo: todayString)
        .snapshots()
        .listen((snapshot) {
      var docs = snapshot.docs;

      // Calcular ingresos totales y conteo por tipo
      int income = 0;
      int cars = 0;
      int motos = 0;
      int inParking = 0;
      int exits = 0;

      for (var doc in docs) {
        final data = doc.data() as Map<String, dynamic>;
        final estado = data['estado'] ?? 'ADENTRO';

        // Contar por tipo
        final tipo = data['tipo'] ?? 'Carro';
        if (tipo == 'Carro') {
          cars++;
        } else if (tipo == 'Moto') {
          motos++;
        }

        // Contar por estado
        if (estado == 'ADENTRO') {
          inParking++;
        } else if (estado == 'SALIDO') {
          exits++;
          income += (data['costo'] as num).toInt();
        }
      }

      if (mounted) {
        setState(() {
          _fullList = docs;
          _totalVehicles = docs.length;
          _totalCars = cars;
          _totalMotos = motos;
          _totalIncome = income;
          _countInParking = inParking;
          _countExits = exits;
          _isLoading = false;
        });
      }
    });
  }

  /// Lista filtrada según selección y ordenamiento
  List<QueryDocumentSnapshot> get _filteredList {
    List<QueryDocumentSnapshot> list = [];
    
    if (_filter == 'En Parqueadero') {
      list = _fullList.where((doc) => doc['estado'] == 'ADENTRO').toList();
    } else if (_filter == 'Salidas') {
      list = _fullList.where((doc) => doc['estado'] == 'SALIDO').toList();
    } else {
      list = List.from(_fullList);
    }

    // Ordenamiento por Ticket (solo cuando no es "Todos")
    if (_filter != 'Todos') {
      list.sort((a, b) {
        // Asumiendo que el ticket es un string que puede contener números
        String ticketA = a['ticket'].toString();
        String ticketB = b['ticket'].toString();
        
        // Intentar ordenar numéricamente si es posible
        int? numA = int.tryParse(ticketA);
        int? numB = int.tryParse(ticketB);
        
        if (numA != null && numB != null) {
          return _sortAscending ? numA.compareTo(numB) : numB.compareTo(numA);
        }
        
        return _sortAscending 
            ? ticketA.compareTo(ticketB) 
            : ticketB.compareTo(ticketA);
      });
    } else {
        // Ordenamiento por defecto por fecha para "Todos"
        list.sort((a, b) {
            Timestamp tsA = a['fecha_entrada'] ?? a['entrada'];
            Timestamp tsB = b['fecha_entrada'] ?? b['entrada'];
            return tsB.compareTo(tsA);
        });
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    // Para la vista "Todos", separamos manualmente después del filtro
    // pero _filteredList ya viene con la lógica de "Todos" que devuelve _fullList sin ordenar por ticket
    // Espera, si es "Todos", _filteredList devuelve _fullList ordenado por fecha.
    // La separación se hace abajo.
    
    // Si estamos en "Todos", usamos las listas separadas
    final activeList = _fullList
        .where((doc) => doc['estado'] == 'ADENTRO')
        .toList(); // Orden por defecto (fecha)
    
    // Ordenar activeList por fecha (mas reciente primero)
    activeList.sort((a, b) {
        Timestamp tsA = a['fecha_entrada'] ?? a['entrada'];
        Timestamp tsB = b['fecha_entrada'] ?? b['entrada'];
        return tsB.compareTo(tsA);
    });

    final completedList = _fullList
        .where((doc) => doc['estado'] == 'SALIDO')
        .toList(); // Orden por defecto (fecha)

     completedList.sort((a, b) {
        Timestamp tsA = a['fecha_entrada'] ?? a['entrada'];
        Timestamp tsB = b['fecha_entrada'] ?? b['entrada'];
        return tsB.compareTo(tsA);
    });


    final showSeparated = _filter == 'Todos';
    final currentList = _filteredList; // Esta lista ya viene ordenada si no es "Todos"

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Decoración de fondo (blur)
          _buildBackgroundDecoration(),

          SafeArea(
            child: Column(
              children: [
                // Header
                _buildHeader(),

                // Contenido
                Expanded(
                  child: _isLoading
                      ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  )
                      : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Cards
                        Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                title: 'Vehículos\nHoy',
                                customValue: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.directions_car_filled,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$_totalCars',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Icon(
                                      Icons.two_wheeler,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$_totalMotos',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                percent: 'Total: $_totalVehicles', 
                                icon: Icons.directions_car,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: StatCard(
                                title: 'Ingresos',
                                value: CurrencyFormatter.format(_totalIncome),
                                percent: '+5%',
                                icon: Icons.payments,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Filtros y botón de ordenar
                        FilterChips(
                          selectedFilter: _filter,
                          onFilterChanged: (filter) {
                            setState(() => _filter = filter);
                          },
                          countInParking: _countInParking,
                          countExits: _countExits,
                          trailing: _filter != 'Todos'
                              ? IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _sortAscending = !_sortAscending;
                                    });
                                  },
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.surfaceLight,
                                    padding: const EdgeInsets.all(8),
                                  ),
                                  icon: Icon(
                                    _sortAscending 
                                        ? Icons.arrow_upward 
                                        : Icons.arrow_downward,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  tooltip: 'Ordenar por Ticket',
                                )
                              : null,
                        ),
                        const SizedBox(height: 24),

                        // Listas
                        if (showSeparated) ...[
                          if (activeList.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 8),
                              child: Text(
                                'EN CURSO',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            ...activeList.map(
                                  (doc) => ActiveVehicleItem(doc: doc),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (completedList.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 8),
                              child: Text(
                                'FINALIZADOS',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            ...completedList.map(
                                  (doc) => CompletedVehicleItem(doc: doc),
                            ),
                          ],
                        ] else ...[
                          // Lista filtrada y ordenada por ticket
                          if (currentList.isEmpty)
                             const Padding(
                               padding: EdgeInsets.only(top: 40),
                               child: Center(
                                 child: Text(
                                   'No hay vehículos en esta sección',
                                   style: TextStyle(color: Colors.white38),
                                 ),
                               ),
                             )
                          else
                            ...currentList.map((doc) {
                              return doc['estado'] == 'ADENTRO'
                                  ? ActiveVehicleItem(doc: doc)
                                  : CompletedVehicleItem(doc: doc);
                            }),
                        ],
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        backgroundColor: AppColors.primary,
        child: const Icon(
          Icons.add,
          color: AppColors.backgroundDark,
          size: 30,
        ),
      ),
    );
  }

  /// Decoración de fondo con blur
  Widget _buildBackgroundDecoration() {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha:0.05),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -100,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A442E).withValues(alpha:0.2),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(color: Colors.transparent),
            ),
          ),
        ),
      ],
    );
  }

  /// Header de la pantalla
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              'Listado Diario',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.calendar_month, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

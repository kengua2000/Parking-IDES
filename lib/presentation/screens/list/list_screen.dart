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
  int _totalIncome = 0;

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

      // Ordenar por fecha de entrada (más recientes primero)
      docs.sort((a, b) {
        Timestamp tsA = a['fecha_entrada'] ?? a['entrada'];
        Timestamp tsB = b['fecha_entrada'] ?? b['entrada'];
        return tsB.compareTo(tsA);
      });

      // Calcular ingresos totales
      int income = 0;
      for (var doc in docs) {
        if (doc['estado'] == 'SALIDO') {
          income += (doc['costo'] as num).toInt();
        }
      }

      if (mounted) {
        setState(() {
          _fullList = docs;
          _totalVehicles = docs.length;
          _totalIncome = income;
          _isLoading = false;
        });
      }
    });
  }

  /// Lista filtrada según selección
  List<QueryDocumentSnapshot> get _filteredList {
    if (_filter == 'En Parqueadero') {
      return _fullList.where((doc) => doc['estado'] == 'ADENTRO').toList();
    }
    if (_filter == 'Salidas') {
      return _fullList.where((doc) => doc['estado'] == 'SALIDO').toList();
    }
    return _fullList;
  }

  @override
  Widget build(BuildContext context) {
    final activeList = _filteredList
        .where((doc) => doc['estado'] == 'ADENTRO')
        .toList();
    final completedList = _filteredList
        .where((doc) => doc['estado'] == 'SALIDO')
        .toList();
    final showSeparated = _filter == 'Todos';

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
                                value: '$_totalVehicles',
                                percent: '+12%',
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

                        // Filtros
                        FilterChips(
                          selectedFilter: _filter,
                          onFilterChanged: (filter) {
                            setState(() => _filter = filter);
                          },
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
                          ..._filteredList.map((doc) {
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
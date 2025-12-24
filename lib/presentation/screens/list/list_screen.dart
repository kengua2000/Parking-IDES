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
  int _countInParking = 0;
  int _countExits = 0;
  bool _sortAscending = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    try {
      final todayString = DateFormatter.formatDay(DateTime.now());
      debugPrint('Cargando datos para el día: $todayString');

      _db
          .collection('vehiculos')
          .where('dia', isEqualTo: todayString)
          .snapshots()
          .listen(
            (snapshot) {
          try {
            var docs = snapshot.docs;
            debugPrint('Documentos encontrados: ${docs.length}');

            int income = 0;
            int cars = 0;
            int motos = 0;
            int inParking = 0;
            int exits = 0;

            for (var doc in docs) {
              try {
                final data = doc.data();
                final estado = data['estado'] ?? 'ADENTRO';

                final tipo = data['tipo'] ?? 'Carro';
                if (tipo == 'Carro') {
                  cars++;
                } else if (tipo == 'Moto') {
                  motos++;
                }

                if (estado == 'ADENTRO') {
                  inParking++;
                } else if (estado == 'SALIDO') {
                  exits++;
                  // Protección contra valores null o tipo incorrecto
                  final costoValue = data['costo'];
                  if (costoValue != null) {
                    income += (costoValue is int) ? costoValue : (costoValue as num).toInt();
                  }
                }
              } catch (e) {
                debugPrint('Error procesando documento ${doc.id}: $e');
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
          } catch (e) {
            debugPrint('Error en listener de snapshot: $e');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          }
        },
        onError: (error) {
          debugPrint('Error en stream de Firestore: $error');
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        },
      );
    } catch (e) {
      debugPrint('Error inicializando stream: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<QueryDocumentSnapshot> get _filteredList {
    List<QueryDocumentSnapshot> list = [];

    try {
      if (_filter == 'En Parqueadero') {
        list = _fullList.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          return data != null && (data['estado'] ?? 'ADENTRO') == 'ADENTRO';
        }).toList();
      } else if (_filter == 'Salidas') {
        list = _fullList.where((doc) {
          final data = doc.data() as Map<String, dynamic>?;
          return data != null && (data['estado'] ?? '') == 'SALIDO';
        }).toList();
      } else {
        list = List.from(_fullList);
      }

      if (_filter != 'Todos') {
        list.sort((a, b) {
          try {
            final dataA = a.data() as Map<String, dynamic>?;
            final dataB = b.data() as Map<String, dynamic>?;

            String ticketA = dataA?['ticket']?.toString() ?? '';
            String ticketB = dataB?['ticket']?.toString() ?? '';

            int? numA = int.tryParse(ticketA);
            int? numB = int.tryParse(ticketB);

            if (numA != null && numB != null) {
              return _sortAscending ? numA.compareTo(numB) : numB.compareTo(numA);
            }

            return _sortAscending
                ? ticketA.compareTo(ticketB)
                : ticketB.compareTo(ticketA);
          } catch (e) {
            debugPrint('Error ordenando: $e');
            return 0;
          }
        });
      } else {
        list.sort((a, b) {
          try {
            final dataA = a.data() as Map<String, dynamic>?;
            final dataB = b.data() as Map<String, dynamic>?;

            Timestamp? tsA = dataA?['fecha_entrada'] ?? dataA?['entrada'];
            Timestamp? tsB = dataB?['fecha_entrada'] ?? dataB?['entrada'];

            if (tsA == null || tsB == null) return 0;
            return tsB.compareTo(tsA);
          } catch (e) {
            debugPrint('Error ordenando por fecha: $e');
            return 0;
          }
        });
      }
    } catch (e) {
      debugPrint('Error filtrando lista: $e');
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final activeList = _fullList.where((doc) {
      try {
        final data = doc.data() as Map<String, dynamic>?;
        return data != null && (data['estado'] ?? 'ADENTRO') == 'ADENTRO';
      } catch (e) {
        debugPrint('Error filtrando activos: $e');
        return false;
      }
    }).toList();

    activeList.sort((a, b) {
      try {
        final dataA = a.data() as Map<String, dynamic>?;
        final dataB = b.data() as Map<String, dynamic>?;

        Timestamp? tsA = dataA?['fecha_entrada'] ?? dataA?['entrada'];
        Timestamp? tsB = dataB?['fecha_entrada'] ?? dataB?['entrada'];

        if (tsA == null || tsB == null) return 0;
        return tsB.compareTo(tsA);
      } catch (e) {
        return 0;
      }
    });

    final completedList = _fullList.where((doc) {
      try {
        final data = doc.data() as Map<String, dynamic>?;
        return data != null && (data['estado'] ?? '') == 'SALIDO';
      } catch (e) {
        return false;
      }
    }).toList();

    completedList.sort((a, b) {
      try {
        final dataA = a.data() as Map<String, dynamic>?;
        final dataB = b.data() as Map<String, dynamic>?;

        Timestamp? tsA = dataA?['fecha_entrada'] ?? dataA?['entrada'];
        Timestamp? tsB = dataB?['fecha_entrada'] ?? dataB?['entrada'];

        if (tsA == null || tsB == null) return 0;
        return tsB.compareTo(tsA);
      } catch (e) {
        return 0;
      }
    });

    final showSeparated = _filter == 'Todos';
    final currentList = _filteredList;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          _buildBackgroundDecoration(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
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
                              try {
                                final data = doc.data() as Map<String, dynamic>?;
                                final estado = data?['estado'] ?? 'ADENTRO';
                                return estado == 'ADENTRO'
                                    ? ActiveVehicleItem(doc: doc)
                                    : CompletedVehicleItem(doc: doc);
                              } catch (e) {
                                debugPrint('Error renderizando item: $e');
                                return const SizedBox.shrink();
                              }
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
              color: AppColors.primary.withValues(alpha: 0.05),
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
              color: const Color(0xFF1A442E).withValues(alpha: 0.2),
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
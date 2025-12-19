import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';
import 'dart:ui'; // Necesario para ImageFilter.blur

// --- COLORES DEL DISEÑO ---
class AppColors {
  static const Color primary = Color(0xFF36E27B);      // Verde Neon
  static const Color backgroundDark = Color(0xFF112117); // Fondo Principal
  static const Color surfaceDark = Color(0xFF1A2C22);    // Fondo Tarjetas
  static const Color surfaceLight = Color(0xFF233A2E);   // Fondo Tarjetas más claras
  static const Color surfaceBorder = Color(0xFF366348);  // Bordes
  static const Color textGray = Color(0xFF95C6A9);       // Texto secundario
  static const Color redExit = Color(0xFFFF5252);        // Rojo Salida
  static const Color inputBg = Color(0xFF254632);        // Fondo Input Gigante
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Parking App',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: AppColors.backgroundDark,
        fontFamily: 'Noto Sans',
        timePickerTheme: TimePickerThemeData(
          backgroundColor: AppColors.surfaceDark,
          dialHandColor: AppColors.primary,
          dialBackgroundColor: AppColors.backgroundDark,
          dialTextColor: Colors.white,
          hourMinuteColor: AppColors.inputBg,
          hourMinuteTextColor: Colors.white,
          dayPeriodColor: AppColors.inputBg,
          dayPeriodTextColor: Colors.white,
          entryModeIconColor: AppColors.primary,
          helpTextStyle: const TextStyle(color: Colors.white),
          confirmButtonStyle: ButtonStyle(foregroundColor: WidgetStateProperty.all(AppColors.primary)),
          cancelButtonStyle: ButtonStyle(foregroundColor: WidgetStateProperty.all(Colors.white)),
        ),
      ),
      home: const MainActivity(),
    );
  }
}

// ==========================================
// PANTALLA PRINCIPAL (DASHBOARD - REPLICA HTML)
// ==========================================
class MainActivity extends StatefulWidget {
  const MainActivity({super.key});

  @override
  State<MainActivity> createState() => _MainActivityState();
}

class _MainActivityState extends State<MainActivity> {
  final TextEditingController _etTicket = TextEditingController();
  final TextEditingController _etHoraManual = TextEditingController(); 
  String _tipoVehiculo = "Carro"; 
  String _resultadoTexto = "";
  String _ultimaAccionTexto = ""; // Para el feedback visual
  final DateFormat _timeFormat = DateFormat('HH:mm');
  final CollectionReference _collectionRef = FirebaseFirestore.instance.collection("vehiculos");

  Future<void> _seleccionarHora() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      helpText: "SELECCIONA HORA",
    );
    if (picked != null) {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month, now.day, picked.hour, picked.minute);
      setState(() => _etHoraManual.text = _timeFormat.format(dt));
    }
  }

  void _registrarEntrada() {
    String ticket = _etTicket.text.trim();
    if (ticket.isEmpty) { _showToast("Escribe el ticket/placa"); return; }
    FocusScope.of(context).unfocus();

    DateTime fecha = DateTime.now();
    if (_etHoraManual.text.isNotEmpty) {
      try {
        DateTime now = DateTime.now();
        DateTime horaParsed = _timeFormat.parse(_etHoraManual.text);
        fecha = DateTime(now.year, now.month, now.day, horaParsed.hour, horaParsed.minute);
      } catch (e) {
        _showToast("Formato de hora incorrecto."); return;
      }
    }
    String diaActual = DateFormat("yyyy-MM-dd").format(fecha);

    _collectionRef.where("ticket", isEqualTo: ticket).where("estado", isEqualTo: "ADENTRO").get().then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        _showToast("El vehículo $ticket ya está ADENTRO");
      } else {
        _collectionRef.add({
          "ticket": ticket, "tipo": _tipoVehiculo, "fecha_entrada": Timestamp.fromDate(fecha), "entrada": Timestamp.fromDate(fecha),
          "estado": "ADENTRO", "dia": diaActual, "costo": 0, "minutos": 0
        }).then((_) {
          _etTicket.clear(); _etHoraManual.clear(); _showToast("Entrada registrada");
          setState(() {
            _resultadoTexto = "Entrada OK: $ticket";
            _ultimaAccionTexto = "Entrada registrada para Ticket #$ticket - ${DateFormat('hh:mm a').format(fecha)}";
          });
        });
      }
    });
  }

  void _procesarSalidaConModal() async {
    String ticket = _etTicket.text.trim();
    if (ticket.isEmpty) { _showToast("Escribe el ticket"); return; }
    FocusScope.of(context).unfocus();

    try {
      QuerySnapshot snapshot = await _collectionRef.where("ticket", isEqualTo: ticket).where("estado", isEqualTo: "ADENTRO").get();
      if (snapshot.docs.isEmpty) { _showToast("Ticket no encontrado o ya salió"); return; }

      var doc = snapshot.docs.first;
      var data = doc.data() as Map<String, dynamic>;
      Timestamp fechaEntrada = data["fecha_entrada"] ?? data["entrada"];
      DateTime entrada = fechaEntrada.toDate();
      DateTime salida = DateTime.now();
      
      if (_etHoraManual.text.isNotEmpty) {
         try {
            DateTime now = DateTime.now();
            DateTime horaParsed = _timeFormat.parse(_etHoraManual.text);
            salida = DateTime(now.year, now.month, now.day, horaParsed.hour, horaParsed.minute);
         } catch(e) {}
      }

      int minutes = salida.difference(entrada).inMinutes;
      String tipo = data["tipo"] ?? _tipoVehiculo;
      int tarifa = (tipo == "Moto") ? 2000 : 3000;
      int costo = (minutes <= 65) ? tarifa : tarifa + (((minutes - 60) / 60).ceil() * 500);
      if(minutes < 0) minutes = 0; 

      _mostrarDialogoCobro(doc.id, ticket, tipo, entrada, salida, costo, minutes);
    } catch (e) { _showToast("Error: $e"); }
  }

  void _mostrarDialogoCobro(String docId, String ticket, String tipo, DateTime entrada, DateTime salida, int total, int minutosTotales) {
    int h = minutosTotales ~/ 60;
    int m = minutosTotales % 60;
    String tiempoFormato = "${h}h ${m}m";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return CobroDialog(
          ticket: ticket,
          totalbPagar: total,
          tiempoTotal: tiempoFormato,
          onCobrar: () {
            // Lógica de guardado en Firebase (se ejecuta al confirmar pago)
            _collectionRef.doc(docId).update({
              "fecha_salida": Timestamp.fromDate(salida),
              "costo": total,
              "minutos": minutosTotales,
              "estado": "SALIDO"
            });
            Navigator.pop(context);
            _etTicket.clear();
            _etHoraManual.clear();
            _showToast("Salida registrada y cobrada");

            final NumberFormat currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
            setState(() {
              _ultimaAccionTexto = "Salida Ticket #$ticket - Cobrado: ${currency.format(total)}";
            });
          },
        );
      },
    );
  }
  
  void _showToast(String msg) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg))); }

  @override
  Widget build(BuildContext context) {
    bool hayHoraManual = _etHoraManual.text.isNotEmpty;
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView( 
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCircleIconBtn(Icons.menu),
                  const Text("ParkingApp", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  _buildCircleIconBtn(Icons.settings),
                ],
              ),
              const SizedBox(height: 24),

              // Header Text
              const Center(
                child: Column(
                  children: [
                    Text("Gestión de Vehículos", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text("Registra entradas y salidas", style: TextStyle(color: AppColors.textGray, fontSize: 14)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Selector (Segmented Button Style)
              Container(
                height: 48,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(50)),
                child: Row(
                  children: [
                    _buildSegmentBtn("Carro", Icons.directions_car, _tipoVehiculo == "Carro"),
                    _buildSegmentBtn("Moto", Icons.two_wheeler, _tipoVehiculo == "Moto"),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Big Input (Con Reloj)
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text("Número de Ticket", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
              ),
              Container(
                height: 96, 
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(20),
                  border: hayHoraManual ? Border.all(color: AppColors.primary, width: 1) : null,
                ),
                alignment: Alignment.center,
                child: TextField(
                  controller: _etTicket,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold, letterSpacing: 2),
                  decoration: InputDecoration(
                    border: InputBorder.none, hintText: "0000", hintStyle: const TextStyle(color: Colors.white24),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.access_time, color: hayHoraManual ? AppColors.primary : AppColors.textGray, size: 30),
                      onPressed: _seleccionarHora,
                    ),
                  ),
                ),
              ),
              if (hayHoraManual)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.primary, size: 16),
                      const SizedBox(width: 5),
                      Text("Hora manual: ${_etHoraManual.text}", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(width: 10),
                      GestureDetector(onTap: () => setState(() => _etHoraManual.clear()), child: const Icon(Icons.close, color: AppColors.textGray, size: 16))
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              
              // Action Buttons (Grid)
              Row(
                children: [
                  Expanded(
                    child: _buildVerticalActionBtn(
                      "ENTRADA", Icons.arrow_downward, AppColors.primary, AppColors.backgroundDark
                    )
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildVerticalActionBtn(
                      "SALIDA", Icons.arrow_upward, AppColors.redExit, Colors.white
                    )
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Feedback Message (Última acción)
              if (_ultimaAccionTexto.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    border: Border.all(color: AppColors.inputBg),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Última acción exitosa", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(_ultimaAccionTexto, style: const TextStyle(color: AppColors.textGray, fontSize: 12)),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              
              const SizedBox(height: 24),

              // Recent Activity List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   const Text("Actividad Reciente", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                   TextButton(
                     onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ListadoActivity())),
                     child: const Text("Ver Todo", style: TextStyle(color: AppColors.primary)),
                   )
                ],
              ),
              const SizedBox(height: 12),

              // Stream List
              StreamBuilder<QuerySnapshot>(
                stream: _collectionRef.orderBy("fecha_entrada", descending: true).limit(3).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  var docs = snapshot.data!.docs;
                  return Column(
                    children: docs.map((doc) => _buildRecentActivityItem(doc)).toList(),
                  );
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCircleIconBtn(IconData icon) {
    return Container(
      width: 40, height: 40,
      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(0.05)),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  Widget _buildSegmentBtn(String text, IconData icon, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tipoVehiculo = text),
        child: Container(
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent, 
            borderRadius: BorderRadius.circular(50),
            boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : null
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, 
            children: [
              Icon(icon, size: 20, color: isActive ? AppColors.backgroundDark : AppColors.textGray),
              const SizedBox(width: 8), 
              Text(text, style: TextStyle(color: isActive ? AppColors.backgroundDark : AppColors.textGray, fontWeight: FontWeight.bold, fontSize: 14))
            ]
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalActionBtn(String label, IconData icon, Color bg, Color textColor) {
    return GestureDetector(
      onTap: label == "ENTRADA" ? _registrarEntrada : _procesarSalidaConModal,
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: bg, 
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: bg.withOpacity(0.3), blurRadius: 15)]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: label == "ENTRADA" ? AppColors.backgroundDark.withOpacity(0.1) : Colors.white.withOpacity(0.2), 
                shape: BoxShape.circle
              ),
              child: Icon(icon, color: textColor, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 0.5))
          ],
        ),
      ),
    );
  }

  // ITEM DE LISTA ESTILO HTML
  Widget _buildRecentActivityItem(QueryDocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool esEnCurso = (data["estado"] == "ADENTRO");
    bool esEntrada = esEnCurso; // Simplificación visual: si está adentro fue una entrada reciente, si salió fue una salida.
    String ticket = data["ticket"] ?? "---";
    String tipo = data["tipo"] ?? "Carro";
    
    // Calculo tiempo relativo
    Timestamp ts = esEnCurso ? (data["fecha_entrada"] ?? data["entrada"]) : (data["fecha_salida"] ?? Timestamp.now());
    DateTime fecha = ts.toDate();
    Duration diff = DateTime.now().difference(fecha);
    String tiempoRelativo = "Hace ${diff.inMinutes} min";
    if(diff.inMinutes > 60) tiempoRelativo = "Hace ${diff.inHours} h";

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: esEnCurso ? AppColors.primary.withOpacity(0.2) : AppColors.redExit.withOpacity(0.2),
                  shape: BoxShape.circle
                ),
                child: Icon(
                  esEnCurso ? Icons.arrow_downward : Icons.arrow_upward,
                  color: esEnCurso ? AppColors.primary : AppColors.redExit,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(esEnCurso ? "Entrada $tipo" : "Salida $tipo", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  Text("Ticket #$ticket", style: const TextStyle(color: AppColors.textGray, fontSize: 12, fontFamily: 'monospace')),
                ],
              )
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(tiempoRelativo, style: const TextStyle(color: AppColors.textGray, fontSize: 12, fontWeight: FontWeight.w500)),
              if(!esEnCurso)
                Text("\$${data["costo"]}", style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold))
            ],
          )
        ],
      ),
    );
  }
}

// ==========================================
// NUEVO WIDGET: VENTANA DE COBRO (TEMA OSCURO)
// ==========================================
class CobroDialog extends StatefulWidget {
  final String ticket;
  final int totalbPagar;
  final String tiempoTotal;
  final VoidCallback onCobrar;

  const CobroDialog({
    super.key,
    required this.ticket,
    required this.totalbPagar,
    required this.tiempoTotal,
    required this.onCobrar,
  });

  @override
  State<CobroDialog> createState() => _CobroDialogState();
}

class _CobroDialogState extends State<CobroDialog> {
  int _pagoCon = 0;
  int _devuelta = 0;
  final NumberFormat _currency = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _pagoCon = 0;
  }

  void _calcularDevuelta(int valorEntregado) {
    setState(() {
      _pagoCon = valorEntregado;
      _devuelta = _pagoCon - widget.totalbPagar;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool pagoSuficiente = _pagoCon >= widget.totalbPagar;

    return AlertDialog(
      backgroundColor: AppColors.surfaceDark, // Fondo oscuro de tarjetas
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.surfaceBorder, width: 1), // Borde sutil
      ),
      title: const Column(
        children: [
          Text("Confirmar Salida", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          SizedBox(height: 8),
          Divider(color: AppColors.surfaceBorder), // Divisor color del tema
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Tiempo Total
              const Text("Tiempo Total:", style: TextStyle(color: AppColors.textGray, fontSize: 12)),
              Text(widget.tiempoTotal, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),

              // 2. Total a Pagar (Rojo Neon)
              const Text("Total a Pagar:", style: TextStyle(color: AppColors.textGray, fontSize: 12)),
              Text(
                  _currency.format(widget.totalbPagar),
                  style: const TextStyle(color: AppColors.redExit, fontSize: 36, fontWeight: FontWeight.w900)
              ),
              const SizedBox(height: 20),

              const Divider(color: AppColors.surfaceBorder),
              const Text("Selecciona con cuánto paga:", style: TextStyle(color: AppColors.textGray, fontSize: 12)),
              const SizedBox(height: 10),

              // 3. Botón Pago Exacto
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _calcularDevuelta(widget.totalbPagar),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surfaceLight, // Fondo un poco más claro
                    foregroundColor: AppColors.primary,      // Texto verde neon
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                        side: BorderSide(color: _pagoCon == widget.totalbPagar ? AppColors.primary : Colors.transparent)
                    ),
                    elevation: 0,
                  ),
                  child: const Text("Pago Exacto", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),

              // 4. Botones de Billetes (Grid)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _btnBillete(2000),
                  _btnBillete(5000),
                  _btnBillete(10000),
                  _btnBillete(20000),
                  _btnBillete(50000),
                  _btnBillete(100000),
                ],
              ),
              const SizedBox(height: 20),

              // 5. Devuelta (Cambio)
              const Text("Devuelta (Cambio):", style: TextStyle(color: AppColors.textGray, fontSize: 14)),
              Text(
                  _pagoCon > 0 ? _currency.format(_devuelta) : "---",
                  style: TextStyle(
                    // Si es negativo (falta dinero) rojo, si es positivo (devuelta) verde neon
                      color: _devuelta >= 0 ? AppColors.primary : AppColors.redExit,
                      fontSize: 28,
                      fontWeight: FontWeight.bold
                  )
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar", style: TextStyle(color: Colors.white38))
        ),
        ElevatedButton(
          onPressed: pagoSuficiente ? widget.onCobrar : null,
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, // Verde Neon
              disabledBackgroundColor: AppColors.surfaceLight.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50))
          ),
          child: Text(
              "COBRAR Y SALIR",
              style: TextStyle(
                  color: pagoSuficiente ? AppColors.backgroundDark : Colors.white30,
                  fontWeight: FontWeight.bold
              )
          ),
        )
      ],
    );
  }

  // Widget auxiliar para los botones de billetes (Estilo Dark)
  Widget _btnBillete(int valor) {
    bool seleccionado = _pagoCon == valor;
    return GestureDetector(
      onTap: () => _calcularDevuelta(valor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          // Si está seleccionado: Verde Neon, si no: Transparente
          color: seleccionado ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          // Borde: Si no está seleccionado, usa el color de borde del tema
          border: Border.all(color: seleccionado ? AppColors.primary : AppColors.surfaceBorder),
        ),
        child: Text(
            "\$${valor ~/ 1000}k",
            style: TextStyle(
              // Texto oscuro si el fondo es verde, blanco si el fondo es oscuro
                color: seleccionado ? AppColors.backgroundDark : Colors.white70,
                fontWeight: FontWeight.bold
            )
        ),
      ),
    );
  }
}

// ==========================================
// PANTALLA LISTADO DIARIO (DISEÑO EXACTO HTML)
// ==========================================
class ListadoActivity extends StatefulWidget {
  const ListadoActivity({super.key});

  @override
  State<ListadoActivity> createState() => _ListadoActivityState();
}

class _ListadoActivityState extends State<ListadoActivity> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DateFormat _dayFormat = DateFormat("yyyy-MM-dd");
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);
  
  String _filtro = "Todos"; 
  List<QueryDocumentSnapshot> _listaCompleta = [];
  bool _isLoading = true;
  int _totalVehiculos = 0;
  int _totalIngresos = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  void _cargarDatos() {
    String hoyString = _dayFormat.format(DateTime.now());
    _db.collection("vehiculos").where("dia", isEqualTo: hoyString).snapshots().listen((snapshot) {
            var docs = snapshot.docs;
            docs.sort((a, b) {
              Timestamp tsA = a['fecha_entrada'] ?? a['entrada'];
              Timestamp tsB = b['fecha_entrada'] ?? b['entrada'];
              return tsB.compareTo(tsA);
            });
            int ingresos = 0;
            for(var doc in docs) {
              if (doc['estado'] == 'SALIDO') ingresos += (doc['costo'] as num).toInt();
            }
            if(mounted) setState(() { _listaCompleta = docs; _totalVehiculos = docs.length; _totalIngresos = ingresos; _isLoading = false; });
        });
  }

  List<QueryDocumentSnapshot> get _listaFiltrada {
    if (_filtro == "En Parqueadero") return _listaCompleta.where((doc) => doc['estado'] == "ADENTRO").toList();
    if (_filtro == "Salidas") return _listaCompleta.where((doc) => doc['estado'] == "SALIDO").toList();
    return _listaCompleta;
  }

  @override
  Widget build(BuildContext context) {
    var enCursoList = _listaFiltrada.where((doc) => doc['estado'] == "ADENTRO").toList();
    var finalizadosList = _listaFiltrada.where((doc) => doc['estado'] == "SALIDO").toList();
    bool mostrarSeparado = (_filtro == "Todos");

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Background Decoration (Blur)
          Positioned(top: -100, right: -100, child: Container(width: 300, height: 300, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withOpacity(0.05)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: Container(color: Colors.transparent)))),
          Positioned(bottom: -100, left: -100, child: Container(width: 250, height: 250, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF1A442E).withOpacity(0.2)), child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80), child: Container(color: Colors.transparent)))),
          
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white)),
                      const Expanded(child: Text("Listado Diario", textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                      IconButton(onPressed: (){}, icon: const Icon(Icons.calendar_month, color: Colors.white)),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading ? const Center(child: CircularProgressIndicator(color: AppColors.primary)) :
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats Cards
                        Row(children: [
                          Expanded(child: _buildStatCard("Vehículos\nHoy", "$_totalVehiculos", "+12%", Icons.directions_car)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildStatCard("Ingresos", _currencyFormat.format(_totalIngresos), "+5%", Icons.payments)),
                        ]),
                        const SizedBox(height: 24),
                        
                        // Filters
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(children: [
                             _buildFilterChip("Todos"), const SizedBox(width: 12),
                             _buildFilterChip("En Parqueadero"), const SizedBox(width: 12),
                             _buildFilterChip("Salidas"),
                          ]),
                        ),
                        const SizedBox(height: 24),

                        // Lists
                        if (mostrarSeparado) ...[
                          if(enCursoList.isNotEmpty) ...[
                             const Padding(padding: EdgeInsets.only(left: 4, bottom: 8), child: Text("EN CURSO", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1))),
                             ...enCursoList.map((doc) => _buildActiveItem(doc)),
                             const SizedBox(height: 16),
                          ],
                          if(finalizadosList.isNotEmpty) ...[
                             const Padding(padding: EdgeInsets.only(left: 4, bottom: 8), child: Text("FINALIZADOS", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1))),
                             ...finalizadosList.map((doc) => _buildCompletedItem(doc)),
                          ]
                        ] else ...[
                           ..._listaFiltrada.map((doc) => (doc['estado']=="ADENTRO") ? _buildActiveItem(doc) : _buildCompletedItem(doc))
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
        child: const Icon(Icons.add, color: AppColors.backgroundDark, size: 30),
      ),
    );
  }

  // --- WIDGETS DE LISTADO (Estilo HTML) ---

  Widget _buildStatCard(String title, String value, String percent, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: AppColors.primary, size: 18)),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.2)),
        ]),
        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(50)), child: Text(percent, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold))),
        ])
      ]),
    );
  }

  Widget _buildFilterChip(String label) {
    bool selected = _filtro == label;
    return GestureDetector(
      onTap: () => setState(() => _filtro = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: selected ? AppColors.primary : AppColors.surfaceBorder),
          boxShadow: selected ? [BoxShadow(color: AppColors.primary.withOpacity(0.2), blurRadius: 8)] : [],
        ),
        child: Text(label, style: TextStyle(color: selected ? Colors.black : Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }

  // ITEM "EN CURSO" (Verde, Pulse)
  Widget _buildActiveItem(QueryDocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String ticket = data["ticket"] ?? "---";
    DateTime entrada = (data["fecha_entrada"] as Timestamp).toDate();
    Duration diff = DateTime.now().difference(entrada);
    String tiempo = "${diff.inHours}h ${diff.inMinutes % 60}m transcurridos";
    bool esMoto = (data["tipo"] == "Moto");

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Icono con Pulse
          Stack(children: [
             Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.surfaceBorder.withOpacity(0.3), borderRadius: BorderRadius.circular(20)), child: Icon(esMoto?Icons.two_wheeler:Icons.directions_car, color: AppColors.primary, size: 28)),
             Positioned(bottom: 0, right: 0, child: Container(width: 14, height: 14, decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, border: Border.all(color: AppColors.surfaceDark, width: 2)))),
          ]),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                  Text("Ticket #$ticket", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(6)), child: const Text("ADENTRO", style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold))),
              ]),
              const SizedBox(height: 6),
              Row(children: [const Icon(Icons.login, size: 16, color: Colors.white60), const SizedBox(width: 4), Text(DateFormat('hh:mm a').format(entrada), style: const TextStyle(color: Colors.white60, fontSize: 13))]),
              const SizedBox(height: 4),
              Row(children: [const Icon(Icons.schedule, size: 16, color: AppColors.primary), const SizedBox(width: 4), Text(tiempo, style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w500))]),
          ])),
          const Text("---", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
      ]),
    );
  }

  // ITEM "FINALIZADO" (Transparente)
  Widget _buildCompletedItem(QueryDocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String ticket = data["ticket"] ?? "---";
    DateTime entrada = (data["fecha_entrada"] as Timestamp).toDate();
    DateTime salida = (data["fecha_salida"] as Timestamp).toDate();
    Duration diff = salida.difference(entrada);
    int costo = (data["costo"] as num).toInt();
    bool esMoto = (data["tipo"] == "Moto");

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.transparent, // Transparente como en el diseño HTML
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 56, height: 56, decoration: BoxDecoration(color: AppColors.surfaceDark, borderRadius: BorderRadius.circular(20)), child: Icon(esMoto?Icons.two_wheeler:Icons.directions_car, color: Colors.white38, size: 28)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("Ticket #$ticket", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(children: [
                 const Icon(Icons.login, size: 14, color: Colors.white38), const SizedBox(width: 2), Text(DateFormat('hh:mm a').format(entrada), style: const TextStyle(color: Colors.white38, fontSize: 12)),
                 const SizedBox(width: 8),
                 const Icon(Icons.logout, size: 14, color: Colors.white38), const SizedBox(width: 2), Text(DateFormat('hh:mm a').format(salida), style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ]),
              const SizedBox(height: 4),
              Text("Tiempo: ${diff.inHours}h ${diff.inMinutes%60}m", style: const TextStyle(color: Colors.white60, fontSize: 13)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
             Text(_currencyFormat.format(costo), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
             const SizedBox(height: 4),
             Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(50)), child: const Text("Pagado", style: TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600))),
          ])
      ]),
    );
  }
}

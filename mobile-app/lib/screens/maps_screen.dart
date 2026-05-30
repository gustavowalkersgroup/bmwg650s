import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ble_service.dart';
import '../widgets/map_table.dart';

// Mapa base VE para F650GS (16 linhas MAP × 16 colunas RPM)
// Eixo RPM: 500, 1000, 1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000, 5500, 6000, 6500, 7000, 7500, 8000
// Eixo MAP: 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 140, 160, 180, 200 kPa
const _defaultVeMap = [
  [20.0, 22.0, 25.0, 28.0, 30.0, 30.0, 30.0, 30.0, 30.0, 30.0, 30.0, 30.0, 30.0, 30.0, 30.0, 30.0],
  [30.0, 35.0, 38.0, 40.0, 42.0, 42.0, 42.0, 40.0, 40.0, 38.0, 38.0, 35.0, 35.0, 33.0, 30.0, 30.0],
  [38.0, 42.0, 46.0, 50.0, 54.0, 55.0, 55.0, 54.0, 52.0, 50.0, 48.0, 46.0, 44.0, 40.0, 38.0, 35.0],
  [45.0, 50.0, 55.0, 60.0, 65.0, 68.0, 70.0, 70.0, 68.0, 65.0, 62.0, 58.0, 55.0, 50.0, 46.0, 42.0],
  [52.0, 58.0, 64.0, 70.0, 75.0, 78.0, 80.0, 82.0, 80.0, 78.0, 75.0, 70.0, 66.0, 60.0, 55.0, 50.0],
  [58.0, 65.0, 72.0, 78.0, 82.0, 86.0, 88.0, 90.0, 90.0, 88.0, 84.0, 80.0, 75.0, 70.0, 64.0, 58.0],
  [63.0, 70.0, 78.0, 84.0, 88.0, 92.0, 95.0, 97.0, 97.0, 95.0, 90.0, 86.0, 80.0, 74.0, 68.0, 62.0],
  [67.0, 74.0, 82.0, 88.0, 93.0, 97.0,100.0,102.0,102.0,100.0, 96.0, 90.0, 84.0, 78.0, 72.0, 65.0],
  [70.0, 78.0, 86.0, 92.0, 97.0,101.0,104.0,106.0,106.0,104.0,100.0, 94.0, 88.0, 82.0, 75.0, 68.0],
  [72.0, 80.0, 88.0, 95.0,100.0,104.0,107.0,109.0,109.0,107.0,103.0, 97.0, 90.0, 84.0, 77.0, 70.0],
  [74.0, 82.0, 90.0, 97.0,102.0,106.0,109.0,111.0,111.0,109.0,105.0, 99.0, 92.0, 86.0, 79.0, 72.0],
  [75.0, 83.0, 91.0, 98.0,103.0,107.0,110.0,112.0,112.0,110.0,106.0,100.0, 93.0, 87.0, 80.0, 73.0],
  [76.0, 84.0, 92.0, 99.0,104.0,108.0,111.0,113.0,113.0,111.0,107.0,101.0, 94.0, 88.0, 81.0, 74.0],
  [77.0, 85.0, 93.0,100.0,105.0,109.0,112.0,114.0,114.0,112.0,108.0,102.0, 95.0, 89.0, 82.0, 75.0],
  [78.0, 86.0, 94.0,101.0,106.0,110.0,113.0,115.0,115.0,113.0,109.0,103.0, 96.0, 90.0, 83.0, 76.0],
  [79.0, 87.0, 95.0,102.0,107.0,111.0,114.0,116.0,116.0,114.0,110.0,104.0, 97.0, 91.0, 84.0, 77.0],
];

const _rpmAxis  = [500.0,1000,1500,2000,2500,3000,3500,4000,4500,5000,5500,6000,6500,7000,7500,8000];
const _loadAxis = [10.0, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 140, 160, 180, 200];

class MapsScreen extends StatefulWidget {
  const MapsScreen({super.key});

  @override
  State<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends State<MapsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late List<List<double>> _veMap;
  bool _modified = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _veMap = _defaultVeMap.map((row) => List<double>.from(row)).toList();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _onVeCellChanged(({int row, int col, double value}) event) {
    setState(() {
      _veMap[event.row][event.col] = event.value;
      _modified = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Editor de Mapas', style: TextStyle(color: Colors.white)),
        actions: [
          if (_modified)
            TextButton.icon(
              icon: const Icon(Icons.upload, color: Colors.orange),
              label: const Text('Enviar', style: TextStyle(color: Colors.orange)),
              onPressed: _sendMap,
            ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.blue,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white38,
          tabs: const [
            Tab(text: 'VE (Combustível)'),
            Tab(text: 'Ignição'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _MapView(
            title: 'Tabela VE — Eficiência Volumétrica (%)',
            rpmAxis: _rpmAxis,
            loadAxis: _loadAxis,
            values: _veMap,
            onChanged: _onVeCellChanged,
          ),
          const _MapView(
            title: 'Tabela Ignição — Avanço (°BTDC)',
            rpmAxis: _rpmAxis,
            loadAxis: _loadAxis,
            values: _defaultVeMap,   // placeholder — futuro: mapa ignição separado
          ),
        ],
      ),
    );
  }

  void _sendMap() {
    final ble = context.read<BleService>();
    if (!ble.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ECU não conectada')),
      );
      return;
    }
    // Expansão futura: serializar mapa e enviar ao Speeduino via ESP32
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Envio de mapa via BLE em desenvolvimento — use TunerStudio para upload completo'),
        duration: Duration(seconds: 4),
      ),
    );
    setState(() => _modified = false);
  }
}

class _MapView extends StatelessWidget {
  final String title;
  final List<double> rpmAxis;
  final List<double> loadAxis;
  final List<List<double>> values;
  final ValueChanged<({int row, int col, double value})>? onChanged;

  const _MapView({
    required this.title,
    required this.rpmAxis,
    required this.loadAxis,
    required this.values,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: MapTable(
        title: title,
        rpmAxis: rpmAxis,
        loadAxis: loadAxis,
        values: values,
        onCellChanged: onChanged,
      ),
    );
  }
}

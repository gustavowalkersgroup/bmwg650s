import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/ecu_data.dart';
import '../services/ble_service.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  static const _maxPoints = 120;  // 120 amostras = 6 segundos a 20Hz

  final List<FlSpot> _rpmSpots  = [];
  final List<FlSpot> _afrSpots  = [];
  final List<FlSpot> _mapSpots  = [];
  double _t = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 100), _sample);
  }

  void _sample(Timer _) {
    if (!mounted) return;
    final ble = context.read<BleService>();
    if (!ble.isConnected) return;

    final d = ble.data;
    setState(() {
      _t += 0.1;
      _rpmSpots.add(FlSpot(_t, d.rpm.toDouble()));
      _afrSpots.add(FlSpot(_t, d.afr));
      _mapSpots.add(FlSpot(_t, d.mapKpa.toDouble()));

      if (_rpmSpots.length > _maxPoints) _rpmSpots.removeAt(0);
      if (_afrSpots.length > _maxPoints) _afrSpots.removeAt(0);
      if (_mapSpots.length > _maxPoints) _mapSpots.removeAt(0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF111111),
        title: const Text('Log em Tempo Real', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.white54),
            onPressed: () => setState(() {
              _rpmSpots.clear();
              _afrSpots.clear();
              _mapSpots.clear();
            }),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Expanded(child: _Chart(
              title: 'RPM',
              spots: _rpmSpots,
              color: Colors.redAccent,
              minY: 0,
              maxY: 8000,
            )),
            const SizedBox(height: 12),
            Expanded(child: _Chart(
              title: 'AFR',
              spots: _afrSpots,
              color: Colors.greenAccent,
              minY: 10,
              maxY: 18,
              refLines: [
                HorizontalLine(y: 14.7, color: Colors.white30,
                    strokeWidth: 1, dashArray: [4, 4]),
              ],
            )),
            const SizedBox(height: 12),
            Expanded(child: _Chart(
              title: 'MAP (kPa)',
              spots: _mapSpots,
              color: Colors.blueAccent,
              minY: 0,
              maxY: 110,
            )),
          ],
        ),
      ),
    );
  }
}

class _Chart extends StatelessWidget {
  final String title;
  final List<FlSpot> spots;
  final Color color;
  final double minY;
  final double maxY;
  final List<HorizontalLine>? refLines;

  const _Chart({
    required this.title,
    required this.spots,
    required this.color,
    required this.minY,
    required this.maxY,
    this.refLines,
  });

  @override
  Widget build(BuildContext context) {
    final minX = spots.isNotEmpty ? spots.first.x : 0.0;
    final maxX = spots.isNotEmpty ? spots.last.x  : 10.0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Expanded(
            child: LineChart(
              LineChartData(
                minX: minX,
                maxX: maxX,
                minY: minY,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  horizontalInterval: (maxY - minY) / 4,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: Color(0xFF2A2A2A), strokeWidth: 1),
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (maxY - minY) / 4,
                      reservedSize: 36,
                      getTitlesWidget: (v, _) => Text(
                        v.toStringAsFixed(0),
                        style: const TextStyle(color: Colors.white30, fontSize: 8),
                      ),
                    ),
                  ),
                  bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                extraLinesData: ExtraLinesData(horizontalLines: refLines ?? []),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots.isEmpty ? [FlSpot(0, minY)] : spots,
                    isCurved: true,
                    curveSmoothness: 0.2,
                    color: color,
                    barWidth: 1.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

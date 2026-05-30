import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ecu_data.dart';
import '../services/ble_service.dart';
import '../widgets/rpm_gauge.dart';
import '../widgets/afr_gauge.dart';
import '../widgets/temp_gauge.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BleService>(
      builder: (context, ble, _) {
        final data = ble.data;
        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF111111),
            title: Row(
              children: [
                const Text('F650GS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                _StatusChip(ble: ble),
              ],
            ),
            actions: [
              if (!ble.isConnected)
                IconButton(
                  icon: const Icon(Icons.bluetooth_searching, color: Colors.blue),
                  onPressed: ble.startScan,
                )
              else
                IconButton(
                  icon: const Icon(Icons.bluetooth_connected, color: Colors.green),
                  onPressed: ble.disconnect,
                ),
            ],
          ),
          body: Column(
            children: [
              if (data.hasAlarm) _AlarmBanner(data: data),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      // Tacômetro principal
                      Expanded(
                        flex: 5,
                        child: RpmGauge(rpm: data.rpm),
                      ),
                      const SizedBox(height: 8),

                      // Linha de gauges secundários
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            // AFR
                            Expanded(
                              flex: 3,
                              child: _Card(
                                child: AfrGauge(afr: data.afr, target: data.afrTarget),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Temperaturas
                            Expanded(
                              flex: 2,
                              child: _Card(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    TempGauge(
                                      tempC: data.cltC,
                                      label: 'ÁGUA',
                                      warningThreshold: 95,
                                      criticalThreshold: 105,
                                    ),
                                    TempGauge(
                                      tempC: data.iatC,
                                      label: 'AR',
                                      warningThreshold: 50,
                                      criticalThreshold: 60,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Linha de dados numéricos
                      _Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _DataCell('TPS', '${data.tps}%'),
                              _DataCell('MAP', '${data.mapKpa} kPa'),
                              _DataCell('ADV', '${data.advDeg}°'),
                              _DataCell('VE', '${data.ve}%'),
                              _DataCell('BATT', '${data.battV.toStringAsFixed(1)}V',
                                  color: data.alarmBatt ? Colors.red : null),
                              _DataCell('SYNC', data.synced ? 'OK' : 'FALHA',
                                  color: data.synced ? Colors.green : Colors.red),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final BleService ble;

  const _StatusChip({required this.ble});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (ble.status) {
      BleStatus.connected   => ('ONLINE', Colors.green),
      BleStatus.connecting  => ('CONECTANDO', Colors.orange),
      BleStatus.scanning    => ('BUSCANDO', Colors.blue),
      BleStatus.error       => ('ERRO', Colors.red),
      _                     => ('OFFLINE', Colors.grey),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _AlarmBanner extends StatelessWidget {
  final EcuData data;

  const _AlarmBanner({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.red.shade900,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.yellow, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              data.alarmDescription,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      padding: const EdgeInsets.all(8),
      child: child,
    );
  }
}

class _DataCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _DataCell(this.label, this.value, {this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.white38, fontSize: 9)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

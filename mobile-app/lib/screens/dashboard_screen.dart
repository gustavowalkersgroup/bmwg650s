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
          floatingActionButton: ble.isConnected && !data.crash && !data.immoKilled &&
                  (data.rpm < 500 || data.starterCranking)
              ? _StartButton(ble: ble, data: data)
              : null,
          body: Column(
            children: [
              if (data.immoKilled || data.immoCountdown)
                _ImmoBanner(data: data, ble: ble),
              if (data.hasAlarm) _AlarmBanner(data: data),
              if (data.engineCold || data.tooColdEthanol || data.heaterOn)
                _ColdStartBanner(data: data),
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

                      // Linha de dados numéricos — linha 1
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
                      const SizedBox(height: 8),
                      // Linha de dados numéricos — linha 2 (novos sensores)
                      _Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _DataCell(
                                'ÓLEO',
                                '${data.oilPressBar.toStringAsFixed(1)} bar',
                                color: data.alarmOil ? Colors.red : (data.oilPressBar < 1.5 && data.rpm > 1500 ? Colors.orange : null),
                              ),
                              _DataCell('VEL', '${data.speedKmh} km/h'),
                              _DataCell(
                                'KNOCK',
                                data.knockRetDeg > 0 ? '-${data.knockRetDeg}°' : 'OK',
                                color: data.alarmKnock ? Colors.red : (data.knockRetDeg > 0 ? Colors.orange : Colors.green),
                              ),
                              _DataCell('FLEX', '${data.flexPct}% E'),
                              _DataCell('LOOP', '${data.loopMs}ms'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Linha 3 — combustível virtual + inclinação (IMU)
                      _Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _DataCell(
                                'COMB',
                                '${data.fuelPct}%',
                                color: data.lowFuel ? Colors.orange : null,
                              ),
                              _DataCell('AUTON', data.rangeKm > 0 ? '${data.rangeKm} km' : '--'),
                              _DataCell('CONS', '${data.econKmpl.toStringAsFixed(1)} km/l'),
                              _DataCell(
                                'INCL',
                                data.imuOk ? '${data.leanDeg.abs()}°' : '--',
                                color: data.leanDeg.abs() > 45 ? Colors.orange : null,
                              ),
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

// Banner de partida a frio — etanol exige motor mais quente para partir
class _ColdStartBanner extends StatelessWidget {
  final EcuData data;

  const _ColdStartBanner({required this.data});

  @override
  Widget build(BuildContext context) {
    // Define cor, ícone e mensagem conforme a situação
    final (Color bg, IconData icon, String msg) = switch (data) {
      _ when data.heaterOn => (
        Colors.orange.shade800,
        Icons.hourglass_bottom,
        data.heaterSecs > 0
            ? 'AQUECENDO ADMISSÃO — aguarde ${data.heaterSecs}s antes de dar a partida'
            : 'AQUECENDO ADMISSÃO — aguarde…',
      ),
      _ when data.tooColdEthanol => (
        Colors.deepOrange.shade900,
        Icons.ac_unit,
        'FRIO PARA ETANOL (${data.flexPct}%) — ideal acima de ${data.coldMinC}°C. '
            '${data.readyToStart ? "Pode tentar a partida." : "Preaqueça antes."}',
      ),
      _ => (
        Colors.blueGrey.shade800,
        Icons.thermostat,
        'MOTOR FRIO (${data.cltC}°C) — aguardando aquecimento',
      ),
    };

    return Container(
      width: double.infinity,
      color: bg,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          if (data.readyToStart && !data.heaterOn)
            const Icon(Icons.check_circle, color: Colors.greenAccent, size: 18),
        ],
      ),
    );
  }
}

// Banner de imobilizador por proximidade BLE
class _ImmoBanner extends StatelessWidget {
  final EcuData data;
  final BleService ble;

  const _ImmoBanner({required this.data, required this.ble});

  @override
  Widget build(BuildContext context) {
    if (data.immoKilled) {
      return Container(
        width: double.infinity,
        color: Colors.red.shade900,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            const Icon(Icons.lock, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'IMOBILIZADOR ATIVO — combustível cortado. Reconecte e desbloqueie.',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
            TextButton(
              onPressed: () => ble.sendCommand(0x08), // CMD_IMMOBILIZER_ACK
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              ),
              child: const Text('Desbloquear', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      );
    }

    // Countdown ativo
    return Container(
      width: double.infinity,
      color: Colors.orange.shade800,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.timer, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'SEGURANÇA: BLE perdido — corte do motor em ${data.immoCountdownS}s. '
              'Reaproxime o celular.',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// Botão de partida via touch — um toque dá a partida (firmware desliga em 5s)
class _StartButton extends StatelessWidget {
  final BleService ble;
  final EcuData data;

  const _StartButton({required this.ble, required this.data});

  @override
  Widget build(BuildContext context) {
    final cranking = data.starterCranking;

    return GestureDetector(
      onTap: cranking ? null : () => ble.sendCommand(0x04), // CMD_STARTER_PULSE
      child: SizedBox(
        width: 72,
        height: 72,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (cranking)
              const SizedBox(
                width: 72,
                height: 72,
                child: CircularProgressIndicator(
                  strokeWidth: 5,
                  color: Colors.orange,
                ),
              ),
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cranking ? Colors.orange.shade700 : Colors.red.shade700,
                boxShadow: [
                  BoxShadow(
                      color: (cranking ? Colors.orange : Colors.red)
                          .withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 2)
                ],
              ),
              child: const Icon(Icons.power_settings_new,
                  color: Colors.white, size: 32),
            ),
          ],
        ),
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

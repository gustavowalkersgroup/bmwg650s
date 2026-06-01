import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ecu_data.dart';
import '../services/ble_service.dart';

// Códigos de comando BLE (devem casar com ble_server.cpp no firmware)
const int _cmdFuelRefill = 0x01;
const int _cmdClearCrash = 0x02;
const int _cmdFuelSetL   = 0x03;

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<BleService>(
      builder: (context, ble, _) {
        final data = ble.data;
        return Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          appBar: AppBar(
            backgroundColor: const Color(0xFF111111),
            title: const Text('Configurações', style: TextStyle(color: Colors.white)),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [

              // ── Alerta de queda (só aparece quando crash ativo) ───────────
              if (data.crash) ...[
                _CrashAlert(onClear: () => ble.sendCommand(_cmdClearCrash)),
                const SizedBox(height: 16),
              ],

              // ── Combustível ───────────────────────────────────────────────
              _Section(
                icon: Icons.local_gas_station,
                title: 'Combustível',
                children: [
                  _FuelGauge(data: data),
                  const SizedBox(height: 16),
                  _InfoRow('Restante estimado',
                      '${data.fuelLiters.toStringAsFixed(1)} L  (${data.fuelPct}%)'),
                  _InfoRow('Autonomia estimada',
                      data.rangeKm > 0 ? '${data.rangeKm} km' : '—'),
                  _InfoRow('Consumo atual',
                      '${data.econKmpl.toStringAsFixed(1)} km/l'),
                  const SizedBox(height: 16),

                  // Botão: tanque cheio
                  _ActionButton(
                    icon: Icons.water_drop,
                    label: 'Tanque cheio',
                    subtitle: 'Zera o consumo e assume ${EcuData.tankLiters}L',
                    color: Colors.blue,
                    enabled: ble.isConnected,
                    onTap: () => _confirmFuelRefill(context, ble),
                  ),
                  const SizedBox(height: 8),

                  // Botão: calibrar litros parcial
                  _ActionButton(
                    icon: Icons.tune,
                    label: 'Calibrar nível',
                    subtitle: 'Informe os litros após abastecimento parcial',
                    color: Colors.blueGrey,
                    enabled: ble.isConnected,
                    onTap: () => _showCalibDialog(context, ble, data),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── IMU / Inclinação ──────────────────────────────────────────
              _Section(
                icon: Icons.screen_rotation,
                title: 'IMU — Inclinação',
                children: [
                  _InfoRow('Sensor IMU', data.imuOk ? '✓ MPU6050 OK' : '✗ Não detectado',
                      valueColor: data.imuOk ? Colors.green : Colors.red),
                  _InfoRow('Inclinação atual',
                      data.imuOk ? '${data.leanDeg.abs()}°' : '—'),
                  const SizedBox(height: 4),
                  _InfoRow('Corte de queda', 'Bomba desliga ao detectar tombamento',
                      subtle: true),
                  _InfoRow('Limiar',
                      '62° por mais de 1,5 s', subtle: true),
                ],
              ),

              const SizedBox(height: 16),

              // ── Motor e injetor ───────────────────────────────────────────
              _Section(
                icon: Icons.settings_applications,
                title: 'Motor',
                children: [
                  _InfoRow('Motor', 'Rotax 654cc — monocilíndrico'),
                  _InfoRow('Injetor', 'Bosch EV1 — 270 cc/min @ 3 bar'),
                  _InfoRow('Combustível', 'Gasolina E27 ou Flex até E100*'),
                  _InfoRow('Tanque', '${EcuData.tankLiters} L total  |  reserva ~4,0 L'),
                  const SizedBox(height: 4),
                  const Text(
                    '* Para E100 puro com frequência, considerar injetor de 350-400 cc/min.',
                    style: TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ── Flex Fuel ─────────────────────────────────────────────────
              _Section(
                icon: Icons.opacity,
                title: 'Flex Fuel',
                children: [
                  _InfoRow('Etanol atual',
                      data.flexPct > 0 ? '${data.flexPct}% etanol' : '—'),
                  _InfoRow('Sensor flex', data.flexPct > 0 ? '✓ Ativo' : '— Não instalado',
                      valueColor: data.flexPct > 0 ? Colors.green : Colors.white54),
                  const SizedBox(height: 4),
                  _InfoRow('Como instalar',
                      'Ver docs/flex-fuel.md no repositório', subtle: true),
                ],
              ),

              const SizedBox(height: 16),

              // ── Partida a frio ────────────────────────────────────────────
              _Section(
                icon: Icons.ac_unit,
                title: 'Partida a Frio (Etanol)',
                children: [
                  _InfoRow('Estado',
                      data.heaterOn
                          ? 'Aquecendo (${data.heaterSecs}s)'
                          : (data.tooColdEthanol
                              ? 'Frio para o etanol'
                              : (data.engineCold ? 'Motor frio' : 'Pronto')),
                      valueColor: data.heaterOn
                          ? Colors.orange
                          : (data.tooColdEthanol
                              ? Colors.deepOrange
                              : (data.readyToStart ? Colors.green : Colors.white))),
                  _InfoRow('Temp do motor', '${data.cltC}°C'),
                  _InfoRow('Mín. p/ etanol atual',
                      data.coldMinC > 0 ? '${data.coldMinC}°C' : '—'),
                  _InfoRow('Aquecedor admissão',
                      data.heaterOn ? '✓ Ligado' : 'Desligado',
                      valueColor: data.heaterOn ? Colors.orange : Colors.white54),
                  const SizedBox(height: 4),
                  _InfoRow('Como funciona',
                      'Etanol não vaporiza a frio. O ESP32 aquece a admissão '
                      'antes da partida — ver docs/ethanol-cold-start.md',
                      subtle: true),
                ],
              ),

              const SizedBox(height: 16),

              // ── Sobre ─────────────────────────────────────────────────────
              _Section(
                icon: Icons.info_outline,
                title: 'Sobre',
                children: [
                  _InfoRow('Projeto', 'BMW F650GS ECU DIY'),
                  _InfoRow('Firmware', 'Speeduino + ESP32 BLE Bridge v1.1'),
                  _InfoRow('App', 'Flutter — open source'),
                  _InfoRow('Repositório',
                      'github.com/gustavowalkersgroup/bmwg650s'),
                ],
              ),

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  void _confirmFuelRefill(BuildContext context, BleService ble) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Tanque cheio?',
            style: TextStyle(color: Colors.white)),
        content: Text(
          'Isso assume que o tanque está com ${EcuData.tankLiters} L e '
          'zera o consumo acumulado. Confirme apenas após abastecer completo.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            onPressed: () {
              ble.sendCommand(_cmdFuelRefill);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tanque zerado — consumo reiniciado'),
                  backgroundColor: Colors.blue,
                ),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _showCalibDialog(BuildContext context, BleService ble, EcuData data) {
    double liters = data.fuelLiters.clamp(0, EcuData.tankLiters);

    showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Calibrar nível',
              style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Quantos litros você colocou no tanque?',
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              Text(
                '${liters.toStringAsFixed(1)} L',
                style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace'),
              ),
              Slider(
                value: liters,
                min: 0,
                max: EcuData.tankLiters,
                divisions: (EcuData.tankLiters * 2).toInt(),
                activeColor: Colors.blue,
                onChanged: (v) => setState(() => liters = v),
              ),
              Text(
                '0 L  ←                           →  ${EcuData.tankLiters.toStringAsFixed(1)} L',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar',
                  style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              onPressed: () {
                // CMD_FUEL_SET_L = 0x03, byte[1] = litros × 10
                final payload = [_cmdFuelSetL, (liters * 10).round()];
                ble.sendCommandBytes(payload);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Nível calibrado: ${liters.toStringAsFixed(1)} L'),
                    backgroundColor: Colors.blue,
                  ),
                );
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Alerta de queda ───────────────────────────────────────────────────────────

class _CrashAlert extends StatelessWidget {
  final VoidCallback onClear;
  const _CrashAlert({required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.red.shade900.withOpacity(0.25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade700, width: 1.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.amber, size: 22),
              const SizedBox(width: 8),
              Text('QUEDA DETECTADA — BOMBA CORTADA',
                  style: TextStyle(
                      color: Colors.red.shade300,
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'A bomba de combustível foi desligada por segurança. '
            'Verifique se a moto está upright e sem vazamentos antes de religar.',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.restart_alt),
              label: const Text('Moto em pé — Religar a bomba'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
              ),
              onPressed: onClear,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _Section({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue, size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFF2A2A2A), height: 1),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool subtle;

  const _InfoRow(this.label, this.value,
      {this.valueColor, this.subtle = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: TextStyle(
                    color: subtle ? Colors.white38 : Colors.white54,
                    fontSize: subtle ? 11 : 12)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    color: valueColor ?? (subtle ? Colors.white38 : Colors.white),
                    fontSize: subtle ? 11 : 12,
                    fontWeight:
                        subtle ? FontWeight.normal : FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.4)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 11)),
                  ],
                ),
              ),
              if (!enabled)
                const Text('BLE off',
                    style: TextStyle(color: Colors.white38, fontSize: 11)),
              if (enabled) Icon(Icons.chevron_right, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _FuelGauge extends StatelessWidget {
  final EcuData data;
  const _FuelGauge({required this.data});

  @override
  Widget build(BuildContext context) {
    final pct = data.fuelPct / 100.0;
    final color = data.lowFuel
        ? Colors.orange
        : (pct > 0.5 ? Colors.green : Colors.yellow.shade700);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Nível do tanque',
                style: const TextStyle(color: Colors.white54, fontSize: 12)),
            Text(
              data.lowFuel ? '⚠ RESERVA' : '${data.fuelPct}%',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            backgroundColor: const Color(0xFF2A2A2A),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('0 L',
                style: TextStyle(color: Colors.white38, fontSize: 10)),
            Text('${EcuData.tankLiters.toStringAsFixed(0)} L',
                style:
                    const TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ],
    );
  }
}

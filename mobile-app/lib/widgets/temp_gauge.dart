import 'package:flutter/material.dart';

class TempGauge extends StatelessWidget {
  final int tempC;
  final String label;
  final int warningThreshold;
  final int criticalThreshold;

  const TempGauge({
    super.key,
    required this.tempC,
    required this.label,
    this.warningThreshold = 90,
    this.criticalThreshold = 105,
  });

  Color get _color {
    if (tempC >= criticalThreshold) return Colors.red;
    if (tempC >= warningThreshold)  return Colors.orange;
    if (tempC < 40)                 return Colors.blueAccent;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final pct = ((tempC + 30) / 160.0).clamp(0.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
        const SizedBox(height: 6),
        SizedBox(
          height: 80,
          width: 28,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: const Color(0xFF2A2A2A),
                ),
              ),
              FractionallySizedBox(
                heightFactor: pct,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: _color,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '$tempC°',
          style: TextStyle(
            color: _color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}

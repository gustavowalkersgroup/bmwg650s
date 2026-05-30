import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class AfrGauge extends StatelessWidget {
  final double afr;
  final double target;

  const AfrGauge({super.key, required this.afr, this.target = 14.7});

  Color get _afrColor {
    final diff = afr - target;
    if (diff.abs() < 0.5) return Colors.green;
    if (diff > 0) return Colors.red;     // pobre
    return Colors.orange;                 // rico
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('AFR', style: TextStyle(color: Colors.white60, fontSize: 11)),
        const SizedBox(height: 4),
        SfLinearGauge(
          minimum: 10.0,
          maximum: 18.0,
          orientation: LinearGaugeOrientation.horizontal,
          axisLabelStyle: const TextStyle(color: Colors.white38, fontSize: 9),
          majorTickStyle: const LinearTickStyle(color: Colors.white38),
          minorTickStyle: const LinearTickStyle(color: Colors.white24),
          axisTrackStyle: const LinearAxisTrackStyle(
            thickness: 8,
            color: Color(0xFF2A2A2A),
          ),
          ranges: [
            const LinearGaugeRange(startValue: 10.0, endValue: 12.5, color: Colors.deepOrangeAccent, startWidth: 8, endWidth: 8),
            const LinearGaugeRange(startValue: 12.5, endValue: 13.5, color: Colors.orange, startWidth: 8, endWidth: 8),
            const LinearGaugeRange(startValue: 13.5, endValue: 15.5, color: Colors.green, startWidth: 8, endWidth: 8),
            const LinearGaugeRange(startValue: 15.5, endValue: 17.0, color: Colors.yellow, startWidth: 8, endWidth: 8),
            const LinearGaugeRange(startValue: 17.0, endValue: 18.0, color: Colors.red, startWidth: 8, endWidth: 8),
          ],
          markerPointers: [
            LinearWidgetPointer(
              value: target.clamp(10.0, 18.0),
              child: Container(width: 2, height: 20, color: Colors.white54),
            ),
            LinearShapePointer(
              value: afr.clamp(10.0, 18.0),
              color: _afrColor,
              shapeType: LinearShapePointerType.triangle,
              position: LinearElementPosition.outside,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          afr.toStringAsFixed(1),
          style: TextStyle(
            color: _afrColor,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          'alvo ${target.toStringAsFixed(1)}',
          style: const TextStyle(color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }
}

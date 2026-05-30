import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';

class RpmGauge extends StatelessWidget {
  final int rpm;
  final int maxRpm;

  const RpmGauge({super.key, required this.rpm, this.maxRpm = 8000});

  @override
  Widget build(BuildContext context) {
    return SfRadialGauge(
      title: const GaugeTitle(
        text: 'RPM',
        textStyle: TextStyle(color: Colors.white70, fontSize: 12),
      ),
      axes: [
        RadialAxis(
          minimum: 0,
          maximum: maxRpm.toDouble(),
          startAngle: 150,
          endAngle: 30,
          interval: 1000,
          minorTicksPerInterval: 4,
          axisLineStyle: const AxisLineStyle(
            thickness: 0.03,
            thicknessUnit: GaugeSizeUnit.factor,
            color: Color(0xFF2A2A2A),
          ),
          majorTickStyle: const MajorTickStyle(
            length: 0.12,
            lengthUnit: GaugeSizeUnit.factor,
            color: Colors.white54,
          ),
          minorTickStyle: const MinorTickStyle(
            length: 0.06,
            lengthUnit: GaugeSizeUnit.factor,
            color: Colors.white30,
          ),
          axisLabelStyle: const GaugeTextStyle(color: Colors.white60, fontSize: 10),
          ranges: [
            GaugeRange(
              startValue: 0,
              endValue: 5500,
              startWidth: 0.03,
              endWidth: 0.03,
              sizeUnit: GaugeSizeUnit.factor,
              color: Colors.green.shade700,
            ),
            GaugeRange(
              startValue: 5500,
              endValue: 6800,
              startWidth: 0.03,
              endWidth: 0.03,
              sizeUnit: GaugeSizeUnit.factor,
              color: Colors.orange,
            ),
            GaugeRange(
              startValue: 6800,
              endValue: maxRpm.toDouble(),
              startWidth: 0.03,
              endWidth: 0.03,
              sizeUnit: GaugeSizeUnit.factor,
              color: Colors.red,
            ),
          ],
          pointers: [
            NeedlePointer(
              value: rpm.toDouble().clamp(0, maxRpm.toDouble()),
              needleColor: Colors.redAccent,
              needleLength: 0.75,
              needleLengthUnit: GaugeSizeUnit.factor,
              needleStartWidth: 1,
              needleEndWidth: 4,
              knobStyle: const KnobStyle(
                color: Colors.white,
                borderColor: Colors.white30,
                knobRadius: 0.06,
                sizeUnit: GaugeSizeUnit.factor,
              ),
              enableAnimation: true,
              animationDuration: 80,
              animationType: AnimationType.easeOutBack,
            ),
          ],
          annotations: [
            GaugeAnnotation(
              angle: 90,
              positionFactor: 0.5,
              widget: Text(
                '$rpm',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

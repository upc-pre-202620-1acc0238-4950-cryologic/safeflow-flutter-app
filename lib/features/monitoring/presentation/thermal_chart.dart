import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/models/safeflow_models.dart';
import '../../../core/theme/safeflow_theme.dart';

class SafeFlowThermalChartPainter extends CustomPainter {
  SafeFlowThermalChartPainter(this.readings, {this.minimum, this.maximum});

  final List<SafeFlowReading> readings;
  final double? minimum;
  final double? maximum;

  @override
  void paint(Canvas canvas, Size size) {
    if (readings.isEmpty || size.isEmpty) return;
    const left = 38.0;
    const right = 8.0;
    const top = 12.0;
    const bottom = 24.0;
    final chart = Rect.fromLTRB(
      left,
      top,
      size.width - right,
      size.height - bottom,
    );
    final values = readings.map((reading) => reading.temperature).toList();
    final lowValue = values.reduce(math.min);
    final highValue = values.reduce(math.max);
    var low = math.min(lowValue, minimum ?? lowValue);
    var high = math.max(highValue, maximum ?? highValue);
    if ((high - low).abs() < 0.5) {
      low -= 1;
      high += 1;
    }
    final gridPaint = Paint()
      ..color = SafeFlowColors.outline
      ..strokeWidth = 1;
    const labelStyle = TextStyle(
      color: SafeFlowColors.textSecondary,
      fontSize: 10,
      fontFamily: 'Inter',
    );
    for (var index = 0; index <= 4; index++) {
      final y = chart.top + chart.height * index / 4;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), gridPaint);
      final label = (high - (high - low) * index / 4).toStringAsFixed(1);
      final text = TextPainter(
        text: TextSpan(text: label, style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(canvas, Offset(0, y - text.height / 2));
    }
    void drawThreshold(double? value) {
      if (value == null || value < low || value > high) return;
      final y = chart.bottom - (value - low) / (high - low) * chart.height;
      final paint = Paint()
        ..color = SafeFlowColors.warning
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(chart.left, y), Offset(chart.right, y), paint);
    }

    drawThreshold(minimum);
    drawThreshold(maximum);
    final points = <Offset>[];
    for (var index = 0; index < readings.length; index++) {
      final x =
          chart.left +
          (readings.length == 1
              ? chart.width / 2
              : chart.width * index / (readings.length - 1));
      final y =
          chart.bottom -
          (readings[index].temperature - low) / (high - low) * chart.height;
      points.add(Offset(x, y));
    }
    final line = Paint()
      ..color = SafeFlowColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, line);
    final dot = Paint()..color = SafeFlowColors.primary;
    for (final point in points) {
      canvas.drawCircle(point, 3.5, dot);
    }
  }

  @override
  bool shouldRepaint(covariant SafeFlowThermalChartPainter oldDelegate) =>
      oldDelegate.readings != readings ||
      oldDelegate.minimum != minimum ||
      oldDelegate.maximum != maximum;
}

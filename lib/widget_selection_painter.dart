import 'package:flutter/material.dart';
import 'package:shadesmaster/drawings.dart';
import 'package:shadesmaster/widget_shade_master.dart';

class SelectionPainter extends CustomPainter {
  final List<Region> teethRegions;
  final List<Region> shadesRegions;
  final Stroke currentStroke;
  final SelectionType activeType;
  final RenderBox renderBox;
  final double resolution;

  SelectionPainter({
    required this.teethRegions,
    required this.shadesRegions,
    required this.currentStroke,
    required this.activeType,
    required this.renderBox,
    required this.resolution,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paintTeeth = Paint()
      ..color = teethColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final strokeTeeth = Paint()
      ..color = teethColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 / resolution;

    final paintShades = Paint()
      ..color = shadesColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final strokeShades = Paint()
      ..color = shadesColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 / resolution;

    // Draw teeth regions with numbers
    for (int i = 0; i < teethRegions.length; i++) {
      final region = teethRegions[i];
      final screenOffsets = region.getScreenOffset(renderBox);

      final path = Path()..addPolygon(screenOffsets, true);
      canvas.drawPath(path, paintTeeth);
      canvas.drawPath(path, strokeTeeth);

      // Calculate centroid
      double centroidX =
          screenOffsets.map((offset) => offset.dx).reduce((a, b) => a + b) /
              screenOffsets.length;
      double centroidY =
          screenOffsets.map((offset) => offset.dy).reduce((a, b) => a + b) /
              screenOffsets.length;

      // Draw the number
      _drawText(canvas, '${i + 1}', Offset(centroidX, centroidY), teethColor);
    }

    // Draw shades regions with letters
    for (int i = 0; i < shadesRegions.length; i++) {
      final region = shadesRegions[i];
      final screenOffsets = region.getScreenOffset(renderBox);
      final path = Path()..addPolygon(screenOffsets, true);
      canvas.drawPath(path, paintShades);
      canvas.drawPath(path, strokeShades);

      // Calculate centroid
      double centroidX =
          screenOffsets.map((offset) => offset.dx).reduce((a, b) => a + b) /
              screenOffsets.length;
      double centroidY =
          screenOffsets.map((offset) => offset.dy).reduce((a, b) => a + b) /
              screenOffsets.length;

      // Draw the letter
      _drawText(canvas, String.fromCharCode(65 + i),
          Offset(centroidX, centroidY), shadesColor);
    }

    // Draw current stroke
    final currentPaint = Paint()
      ..color = (activeType == SelectionType.teeth ? teethColor : shadesColor)
          .withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    for (final point in currentStroke.getScreenOffset(renderBox)) {
      canvas.drawCircle(point, 5 / resolution, currentPaint);
    }
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
          color: Colors.white,
          fontSize: 18 / resolution,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 4,
            ),
          ]),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Draw background circle for label
    final bgPaint = Paint()..color = color.withValues(alpha: 0.8);
    canvas.drawCircle(position, (textPainter.width + 8) / 2, bgPaint);

    textPainter.paint(canvas,
        position - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

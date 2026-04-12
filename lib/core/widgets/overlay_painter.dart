import 'package:flutter/material.dart';
import '../../data/models/detection.dart';

/// Paints detection overlays on top of camera preview or images.
/// Uses normalized coordinates (0.0 - 1.0) for device independence.
class OverlayPainter extends CustomPainter {
  final List<Detection> detections;
  final Color? color;

  OverlayPainter({required this.detections, this.color});

  @override
  void paint(Canvas canvas, Size size) {
    for (final detection in detections) {
      _drawDetection(canvas, size, detection);
    }
  }

  void _drawDetection(Canvas canvas, Size size, Detection detection) {
    // Convert normalized coordinates to pixels
    final left = detection.x * size.width;
    final top = detection.y * size.height;
    final width = detection.width * size.width;
    final height = detection.height * size.height;

    final rect = Rect.fromLTWH(left, top, width, height);

    // Choose color based on severity
    final baseColor = color ?? _severityColor(detection.severity);

    // Draw filled rectangle with opacity
    final fillPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    // Draw border
    final borderPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRect(rect, fillPaint);
    canvas.drawRect(rect, borderPaint);

    // Draw label background
    final label = detection.label.replaceAll('_', ' ').toUpperCase();
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      minWidth: 0,
      maxWidth: double.infinity,
    );
    textPainter.layout();

    final labelBgRect = Rect.fromLTWH(
      left,
      top - textPainter.height - 4,
      textPainter.width + 12,
      textPainter.height + 4,
    );

    final labelBgPaint = Paint()..color = baseColor;
    canvas.drawRect(labelBgRect, labelBgPaint);

    // Draw label text
    textPainter.paint(
      canvas,
      Offset(left + 6, top - textPainter.height - 2),
    );

    // Draw severity indicator for high severity
    if (detection.severity == 'high') {
      _drawWarningIndicator(canvas, rect);
    }
  }

  void _drawWarningIndicator(Canvas canvas, Rect rect) {
    // Draw warning triangles at corners
    final triangleSize = 8.0;
    final positions = [
      Offset(rect.left, rect.top),
      Offset(rect.right, rect.top),
      Offset(rect.left, rect.bottom),
      Offset(rect.right, rect.bottom),
    ];

    final warningPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    for (final pos in positions) {
      final path = Path();
      path.moveTo(pos.dx, pos.dy);
      path.lineTo(pos.dx + triangleSize, pos.dy);
      path.lineTo(pos.dx, pos.dy + triangleSize);
      path.close();
      canvas.drawPath(path, warningPaint);
    }
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
      default:
        return Colors.green;
    }
  }

  @override
  bool shouldRepaint(covariant OverlayPainter oldDelegate) {
    return oldDelegate.detections != detections || oldDelegate.color != color;
  }
}

/// Widget that wraps a child with detection overlays.
class DetectionOverlay extends StatelessWidget {
  final Widget child;
  final List<Detection> detections;
  final Color? color;

  const DetectionOverlay({
    super.key,
    required this.child,
    required this.detections,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (detections.isNotEmpty)
          Positioned.fill(
            child: CustomPaint(
              painter: OverlayPainter(detections: detections, color: color),
            ),
          ),
      ],
    );
  }
}

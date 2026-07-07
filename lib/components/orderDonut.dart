import 'package:flutter/material.dart';
import 'dart:math';

class OrderDonut extends StatelessWidget {
  final double done;
  final double total;
  final Color? mainColor;
  final Color? secondaryColor;
  final double? thickness;

  const OrderDonut({
    super.key,
    required this.done,
    required this.total,
    this.mainColor,
    this.secondaryColor,
    this.thickness,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      height: 190,
      child: CustomPaint(
        painter: _RoundedArcPainter(
          done: done,
          total: total,
          activeColor: mainColor ?? Colors.deepOrange,
          trackColor: secondaryColor ?? Colors.deepOrange.shade100,
          thickness: thickness?? 15.0,
        ),
        child: Center(
          child: Text(
            '${done.toInt()}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: mainColor ?? Colors.deepOrange,
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundedArcPainter extends CustomPainter {
  final double done;
  final double total;
  final Color activeColor;
  final Color trackColor;
  final double? thickness;

  _RoundedArcPainter({
    required this.done,
    required this.total,
    required this.activeColor,
    required this.trackColor,
    this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final strokeWidth = thickness?? 15.0;
    const startAngle = -pi / 2; // start from top

    // ── Track (background arc) ──────────────────────────────
    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      2 * pi, // full circle
      false,
      trackPaint,
    );

    // ── Active arc ──────────────────────────────────────────
    final activePaint = Paint()
      ..color = activeColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (done / total).clamp(0.0, 1.0) * 2 * pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      activePaint,
    );
  }

  @override
  bool shouldRepaint(_RoundedArcPainter old) =>
      old.done != done ||
      old.total != total ||
      old.activeColor != activeColor ||
      old.trackColor != trackColor;
}
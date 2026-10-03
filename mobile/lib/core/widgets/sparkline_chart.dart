import 'package:flutter/material.dart';

class SparklineChart extends StatelessWidget {
  final List<double>? data;
  final Color color;
  final double width;
  final double height;
  final bool isUp;

  const SparklineChart({
    super.key,
    this.data,
    required this.color,
    this.width = 64,
    this.height = 24,
    this.isUp = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(
          points: data ?? (isUp ? const [0.2, 0.4, 0.35, 0.6, 0.55, 0.85, 0.95] : const [0.85, 0.7, 0.75, 0.5, 0.45, 0.3, 0.15]),
          lineColor: color,
        ),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> points;
  final Color lineColor;

  _SparklinePainter({required this.points, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final stepX = size.width / (points.length - 1);

    // Coordinate mapping
    double getY(double val) => size.height - (val.clamp(0.0, 1.0) * (size.height - 4) + 2);

    path.moveTo(0, getY(points[0]));

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = Offset(i * stepX, getY(points[i]));
      final p1 = Offset((i + 1) * stepX, getY(points[i + 1]));
      final controlPoint = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
      path.quadraticBezierTo(p0.dx, p0.dy, controlPoint.dx, controlPoint.dy);
    }
    path.lineTo(size.width, getY(points.last));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.lineColor != lineColor || oldDelegate.points != points;
  }
}

import 'package:flutter/material.dart';
import 'dart:math' as math;

class FaceOverlayPainterWidget extends StatefulWidget {
  const FaceOverlayPainterWidget({super.key});

  @override
  State<FaceOverlayPainterWidget> createState() => _FaceOverlayState();
}

class _FaceOverlayState extends State<FaceOverlayPainterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (_, __) => CustomPaint(
        size: size,
        painter: _FacePainter(_pulseAnim.value),
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  final double pulseScale;
  _FacePainter(this.pulseScale);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.42;
    final rx = size.width * 0.32 * pulseScale;
    final ry = size.height * 0.22 * pulseScale;

    // Dimmed overlay outside oval
    final ovalRect = Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2);
    final overlayPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addOval(ovalRect)
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withOpacity(0.55),
    );

    // Glowing border
    final borderPaint = Paint()
      ..color = const Color(0xFF6C63FF).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 6);
    canvas.drawOval(ovalRect, borderPaint);

    // Corner brackets
    _drawCornerBrackets(canvas, cx, cy, rx, ry);

    // Scan line
    _drawScanLines(canvas, cx, cy, rx, ry);
  }

  void _drawCornerBrackets(Canvas c, double cx, double cy, double rx, double ry) {
    final paint = Paint()
      ..color = const Color(0xFF00D4B4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const len = 20.0;
    final corners = [
      _CornerData(cx - rx, cy - ry, 0, math.pi / 2),
      _CornerData(cx + rx, cy - ry, math.pi / 2, math.pi),
      _CornerData(cx - rx, cy + ry, 1.5 * math.pi, 2 * math.pi),
      _CornerData(cx + rx, cy + ry, math.pi, 1.5 * math.pi),
    ];
    for (final corner in corners) {
      c.drawLine(
        Offset(corner.x, corner.y),
        Offset(corner.x + math.cos(corner.a1) * len, corner.y + math.sin(corner.a1) * len),
        paint,
      );
      c.drawLine(
        Offset(corner.x, corner.y),
        Offset(corner.x + math.cos(corner.a2) * len, corner.y + math.sin(corner.a2) * len),
        paint,
      );
    }
  }

  void _drawScanLines(Canvas c, double cx, double cy, double rx, double ry) {
    final paint = Paint()
      ..color = const Color(0xFF6C63FF).withOpacity(0.15)
      ..strokeWidth = 1;
    final top    = cy - ry;
    final bottom = cy + ry;
    final spacing = ry / 6;
    for (int i = 1; i < 6; i++) {
      final y = top + i * spacing;
      c.drawLine(Offset(cx - rx + 4, y), Offset(cx + rx - 4, y), paint);
    }
  }

  @override
  bool shouldRepaint(_FacePainter old) => old.pulseScale != pulseScale;
}

class _CornerData {
  final double x, y, a1, a2;
  const _CornerData(this.x, this.y, this.a1, this.a2);
}

import 'package:flutter/material.dart';

class ConcentricCirclesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE2E8F0).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(-size.width * 0.15, size.height * 0.4);

    canvas.drawCircle(center, 120, paint);
    canvas.drawCircle(center, 210, paint);
    canvas.drawCircle(center, 300, paint);
    canvas.drawCircle(center, 400, paint);
    canvas.drawCircle(center, 520, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class EmergencyRadiusMapPainter extends CustomPainter {
  void _drawRoadPath(Canvas canvas, Path path, double fillWidth, Color fillCol, Color borderCol) {
    final borderPaint = Paint()
      ..color = borderCol
      ..style = PaintingStyle.stroke
      ..strokeWidth = fillWidth + 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = fillCol
      ..style = PaintingStyle.stroke
      ..strokeWidth = fillWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, borderPaint);
    canvas.drawPath(path, fillPaint);
  }

  void _drawMapLabel(Canvas canvas, String text, Offset position) {
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        color: Color(0xFF3C4043),
        fontSize: 9.5,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(color: Colors.white, offset: Offset(1.5, 1.5), blurRadius: 1.5),
          Shadow(color: Colors.white, offset: Offset(-1.5, -1.5), blurRadius: 1.5),
        ],
      ),
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(position.dx - textPainter.width / 2, position.dy - textPainter.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final landPaint = Paint()..color = const Color(0xFFF4F3F0)..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), landPaint);

    final parkPaint = Paint()..color = const Color(0xFFD1F2D9)..style = PaintingStyle.fill;
    final parkBorder = Paint()..color = const Color(0xFFC4E8CC)..style = PaintingStyle.stroke..strokeWidth = 1.0;
    final Rect parkRect = Rect.fromLTWH(size.width * 0.1, size.height * 0.1, size.width * 0.25, size.height * 0.15);
    canvas.drawRRect(RRect.fromRectAndRadius(parkRect, const Radius.circular(8)), parkPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(parkRect, const Radius.circular(8)), parkBorder);

    const Color highwayFill = Color(0xFFFFF2CC);
    const Color highwayBorder = Color(0xFFE9D0A1);
    const Color streetFill = Color(0xFFFFFFFF);
    const Color streetBorder = Color(0xFFD4D4D8);

    final Path h1 = Path()..moveTo(0, size.height * 0.45)..lineTo(size.width, size.height * 0.45);
    final Path v1 = Path()..moveTo(size.width * 0.4, 0)..lineTo(size.width * 0.4, size.height);
    final Path s1 = Path()..moveTo(0, size.height * 0.78)..lineTo(size.width, size.height * 0.78);

    _drawRoadPath(canvas, s1, 8.5, streetFill, streetBorder);
    _drawRoadPath(canvas, h1, 13.0, highwayFill, highwayBorder);
    _drawRoadPath(canvas, v1, 13.0, highwayFill, highwayBorder);

    final center = Offset(size.width * 0.4, size.height * 0.45);

    final radarPaint = Paint()
      ..color = const Color(0xFF3B82F6).withOpacity(0.12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 120, radarPaint);

    final radarStroke = Paint()
      ..color = const Color(0xFF3B82F6).withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, 120, radarStroke);
    canvas.drawCircle(center, 80, radarStroke);
    canvas.drawCircle(center, 40, radarStroke);

    final glowPaint = Paint()
      ..color = const Color(0xFF1E3A8A).withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 16, glowPaint);

    final corePaint = Paint()
      ..color = const Color(0xFF1E3A8A)
      ..style = PaintingStyle.fill;
    final whiteBorder = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(center, 7, corePaint);
    canvas.drawCircle(center, 7, whiteBorder);

    final p1 = Offset(size.width * 0.28, size.height * 0.38);
    final p2 = Offset(size.width * 0.55, size.height * 0.48);
    final p3 = Offset(size.width * 0.48, size.height * 0.3);

    void drawPolsekPin(Canvas canvas, Offset pos, String name) {
      final pinPaint = Paint()..color = const Color(0xFFEF4444)..style = PaintingStyle.fill;
      canvas.drawCircle(pos, 6, pinPaint);
      canvas.drawCircle(pos, 6, whiteBorder);
      
      _drawMapLabel(canvas, name, Offset(pos.dx, pos.dy - 14));
    }

    drawPolsekPin(canvas, p1, "Polsek Jember");
    drawPolsekPin(canvas, p2, "Polsek Patrang");
    drawPolsekPin(canvas, p3, "Polsek Sumbersari");

    _drawMapLabel(canvas, "Hutan Kota", Offset(size.width * 0.22, size.height * 0.17));
    _drawMapLabel(canvas, "Lokasi Anda", Offset(center.dx, center.dy + 26));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

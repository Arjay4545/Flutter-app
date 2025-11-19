import 'package:flutter/material.dart';

class EggplantIllustration extends StatelessWidget {
  final double size;

  const EggplantIllustration({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: EggplantPainter()),
    );
  }
}

class EggplantPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw pot
    final potPaint = Paint()
      ..color = const Color(0xFFD4A574)
      ..style = PaintingStyle.fill;

    final potPath = Path();
    final potWidth = size.width * 0.6;
    final potHeight = size.height * 0.3;
    final potX = (size.width - potWidth) / 2;
    final potY = size.height * 0.7;

    // Pot body (trapezoid)
    potPath.moveTo(potX + potWidth * 0.15, potY);
    potPath.lineTo(potX + potWidth * 0.85, potY);
    potPath.lineTo(potX + potWidth, potY + potHeight);
    potPath.lineTo(potX, potY + potHeight);
    potPath.close();

    canvas.drawPath(potPath, potPaint);

    // Pot rim
    final rimPaint = Paint()
      ..color = const Color(0xFFB8956A)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(potX - potWidth * 0.05, potY - 8, potWidth * 1.1, 16),
        const Radius.circular(8),
      ),
      rimPaint,
    );

    // Draw soil
    final soilPaint = Paint()
      ..color = const Color(0xFF8B4513)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromLTWH(potX + potWidth * 0.1, potY - 4, potWidth * 0.8, 12),
      soilPaint,
    );

    // Draw eggplant stem
    final stemPaint = Paint()
      ..color = const Color(0xFF4A5D23)
      ..style = PaintingStyle.fill
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width / 2, potY),
      Offset(size.width / 2, size.height * 0.4),
      stemPaint,
    );

    // Draw eggplant body
    final eggplantPaint = Paint()
      ..color = const Color(0xFF4A148C)
      ..style = PaintingStyle.fill;

    final eggplantPath = Path();
    final eggplantWidth = size.width * 0.35;
    final eggplantHeight = size.height * 0.45;
    final eggplantX = (size.width - eggplantWidth) / 2;
    final eggplantY = size.height * 0.25;

    // Create eggplant shape (oval with tapered top)
    eggplantPath.addOval(
      Rect.fromLTWH(eggplantX, eggplantY, eggplantWidth, eggplantHeight),
    );
    canvas.drawPath(eggplantPath, eggplantPaint);

    // Add highlight to eggplant
    final highlightPaint = Paint()
      ..color = const Color(0xFF7B1FA2).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    canvas.drawOval(
      Rect.fromLTWH(
        eggplantX + eggplantWidth * 0.15,
        eggplantY + eggplantHeight * 0.2,
        eggplantWidth * 0.3,
        eggplantHeight * 0.4,
      ),
      highlightPaint,
    );

    // Draw eggplant calyx (green top)
    final calyxPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.fill;

    final calyxPath = Path();
    final calyxCenterX = size.width / 2;
    final calyxY = eggplantY;

    // Create star-like calyx
    for (int i = 0; i < 5; i++) {
      final angle = (i * 2 * 3.14159) / 5 - 3.14159 / 2;
      final x =
          calyxCenterX +
          15 *
              (i % 2 == 0 ? 1 : 0.6) *
              (i == 0 ? 1 : 1) *
              (i == 0 ? 1 : (angle < 0 ? -1 : 1)) *
              0.8;
      final y = calyxY + 10 * (i % 2 == 0 ? 1 : 0.6);

      if (i == 0) {
        calyxPath.moveTo(x, y);
      } else {
        calyxPath.lineTo(x, y);
      }
    }
    calyxPath.close();

    // Simplified calyx as small leaves
    for (int i = 0; i < 4; i++) {
      final leafAngle = (i * 3.14159) / 2;
      final leafX =
          calyxCenterX +
          12 * (leafAngle == 0 ? 1 : (leafAngle == 3.14159 ? -1 : 0));
      final leafY =
          calyxY +
          12 *
              (leafAngle == 3.14159 / 2
                  ? -1
                  : (leafAngle == 3 * 3.14159 / 2 ? 1 : 0));

      canvas.drawOval(
        Rect.fromCenter(center: Offset(leafX, leafY), width: 8, height: 16),
        calyxPaint,
      );
    }

    // Draw leaves on stem
    final leafPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.fill;

    // Left leaf
    final leftLeafPath = Path();
    leftLeafPath.moveTo(size.width / 2 - 5, size.height * 0.5);
    leftLeafPath.quadraticBezierTo(
      size.width / 2 - 25,
      size.height * 0.45,
      size.width / 2 - 20,
      size.height * 0.35,
    );
    leftLeafPath.quadraticBezierTo(
      size.width / 2 - 15,
      size.height * 0.4,
      size.width / 2 - 5,
      size.height * 0.45,
    );
    leftLeafPath.close();
    canvas.drawPath(leftLeafPath, leafPaint);

    // Right leaf
    final rightLeafPath = Path();
    rightLeafPath.moveTo(size.width / 2 + 5, size.height * 0.6);
    rightLeafPath.quadraticBezierTo(
      size.width / 2 + 25,
      size.height * 0.55,
      size.width / 2 + 20,
      size.height * 0.45,
    );
    rightLeafPath.quadraticBezierTo(
      size.width / 2 + 15,
      size.height * 0.5,
      size.width / 2 + 5,
      size.height * 0.55,
    );
    rightLeafPath.close();
    canvas.drawPath(rightLeafPath, leafPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

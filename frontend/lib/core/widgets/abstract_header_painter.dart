import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class AbstractHeaderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    // Large overlapping teal circles
    paint.color = AppColors.lightTeal;
    
    // First large circle (top left)
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.3),
      size.width * 0.4,
      paint,
    );

    // Second large circle (top right)
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.25),
      size.width * 0.35,
      paint,
    );

    // Third circle (center)
    paint.color = AppColors.lightTeal.withValues(alpha: 0.7);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.5),
      size.width * 0.3,
      paint,
    );

    // Large white circle (bottom right)
    paint.color = AppColors.white;
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.7),
      size.width * 0.25,
      paint,
    );

    // Small white dot (top right)
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.2),
      size.width * 0.05,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

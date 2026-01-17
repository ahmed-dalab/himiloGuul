import 'package:flutter/material.dart';
import '../../config/app_colors.dart';

class FeatureIllustration extends StatelessWidget {
  final int type; // 0: Verified Listings, 1: Direct Messaging, 2: Secure Deals

  const FeatureIllustration({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CustomPaint(
        painter: _FeaturePainter(type: type),
      ),
    );
  }
}

class _FeaturePainter extends CustomPainter {
  final int type;

  _FeaturePainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    switch (type) {
      case 0: // Verified Listings
        _drawVerifiedListings(canvas, size, paint);
        break;
      case 1: // Direct Messaging
        _drawDirectMessaging(canvas, size, paint);
        break;
      case 2: // Secure Deals
        _drawSecureDeals(canvas, size, paint);
        break;
    }
  }

  void _drawVerifiedListings(Canvas canvas, Size size, Paint paint) {
    // Left frame
    paint.color = AppColors.illustrationBeige;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.1, size.height * 0.1, size.width * 0.35, size.height * 0.8),
        const Radius.circular(4),
      ),
      paint,
    );

    // Right frame
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.55, size.height * 0.1, size.width * 0.35, size.height * 0.8),
        const Radius.circular(4),
      ),
      paint,
    );

    // Left frame content - overlapping circles
    paint.color = AppColors.illustrationTeal;
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.3), size.width * 0.08, paint);
    canvas.drawCircle(Offset(size.width * 0.3, size.height * 0.4), size.width * 0.08, paint);
    canvas.drawCircle(Offset(size.width * 0.25, size.height * 0.5), size.width * 0.08, paint);

    // Right frame content - half circle
    canvas.drawArc(
      Rect.fromLTWH(size.width * 0.55, size.height * 0.6, size.width * 0.35, size.height * 0.3),
      0,
      3.14,
      false,
      paint,
    );
  }

  void _drawDirectMessaging(Canvas canvas, Size size, Paint paint) {
    // Archway shape
    paint.color = AppColors.illustrationTeal;
    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.3)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.1, size.width * 0.8, size.height * 0.3)
      ..lineTo(size.width * 0.8, size.height * 0.7)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.9, size.width * 0.2, size.height * 0.7)
      ..close();
    canvas.drawPath(path, paint);

    // Vertical rectangle
    paint.color = AppColors.illustrationTeal.withValues(alpha: 0.6);
    canvas.drawRect(
      Rect.fromLTWH(size.width * 0.45, size.height * 0.2, size.width * 0.1, size.height * 0.6),
      paint,
    );

    // Circular outline
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    paint.color = AppColors.illustrationTeal;
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.5), size.width * 0.15, paint);
  }

  void _drawSecureDeals(Canvas canvas, Size size, Paint paint) {
    // Top frame
    paint.color = AppColors.illustrationBeige;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.1, size.height * 0.1, size.width * 0.8, size.height * 0.35),
        const Radius.circular(4),
      ),
      paint,
    );

    // Bottom frame
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.1, size.height * 0.55, size.width * 0.8, size.height * 0.35),
        const Radius.circular(4),
      ),
      paint,
    );

    // Top frame content - blob
    paint.color = AppColors.illustrationTeal;
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.2, size.height * 0.15, size.width * 0.6, size.height * 0.25),
      paint,
    );

    // Bottom frame content - blob
    canvas.drawOval(
      Rect.fromLTWH(size.width * 0.2, size.height * 0.6, size.width * 0.6, size.height * 0.25),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

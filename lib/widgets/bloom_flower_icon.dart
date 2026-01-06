import 'dart:math' as math;
import 'package:flutter/material.dart';

class BloomFlowerIcon extends StatelessWidget {
  final double size;

  const BloomFlowerIcon({
    super.key,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: FlowerIconPainter(),
    );
  }
}

class FlowerIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final petalCount = 6;
    final petalAngle = (2 * math.pi) / petalCount;

    // Create a path for each petal
    for (int i = 0; i < petalCount; i++) {
      final angle = i * petalAngle - (math.pi / 2); // Start from top
      
      // Create petal path - wider at outer edge, tapering to center
      final path = Path();
      
      // Calculate points for a symmetrical petal
      final halfAngle = petalAngle / 2;
      
      // Outer edge points (wider)
      final outerRadius = radius * 0.9;
      final outerPoint1 = Offset(
        center.dx + outerRadius * math.cos(angle - halfAngle * 0.6),
        center.dy + outerRadius * math.sin(angle - halfAngle * 0.6),
      );
      final outerPoint2 = Offset(
        center.dx + outerRadius * math.cos(angle + halfAngle * 0.6),
        center.dy + outerRadius * math.sin(angle + halfAngle * 0.6),
      );
      
      // Inner points (tapered towards center)
      final innerRadius = radius * 0.2;
      final innerPoint1 = Offset(
        center.dx + innerRadius * math.cos(angle - halfAngle),
        center.dy + innerRadius * math.sin(angle - halfAngle),
      );
      final innerPoint2 = Offset(
        center.dx + innerRadius * math.cos(angle + halfAngle),
        center.dy + innerRadius * math.sin(angle + halfAngle),
      );
      
      // Create the petal shape
      path.moveTo(center.dx, center.dy);
      path.lineTo(innerPoint1.dx, innerPoint1.dy);
      path.quadraticBezierTo(
        center.dx + radius * 0.6 * math.cos(angle - halfAngle * 0.5),
        center.dy + radius * 0.6 * math.sin(angle - halfAngle * 0.5),
        outerPoint1.dx,
        outerPoint1.dy,
      );
      path.lineTo(outerPoint2.dx, outerPoint2.dy);
      path.quadraticBezierTo(
        center.dx + radius * 0.6 * math.cos(angle + halfAngle * 0.5),
        center.dy + radius * 0.6 * math.sin(angle + halfAngle * 0.5),
        innerPoint2.dx,
        innerPoint2.dy,
      );
      path.close();
      
      // Create gradient for the petal (from dark purple edges to pinkish center)
      final petalRect = Rect.fromLTWH(0, 0, size.width, size.height);
      final gradient = LinearGradient(
        begin: Alignment(
          math.cos(angle),
          math.sin(angle),
        ),
        end: Alignment(
          -math.cos(angle),
          -math.sin(angle),
        ),
        colors: [
          const Color(0xFF6D28D9), // Dark purple at outer edges
          const Color(0xFF8B5CF6), // Medium purple
          const Color(0xFFA78BFA), // Light purple
          const Color(0xFFC084FC), // Lighter purple
          const Color(0xFFE879F9), // Pinkish-purple at center
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      );
      
      final paint = Paint()
        ..shader = gradient.createShader(petalRect)
        ..style = PaintingStyle.fill;
      
      canvas.drawPath(path, paint);
    }
    
    // Add a glowing center
    final centerGradient = RadialGradient(
      colors: [
        const Color(0xFFE879F9).withOpacity(0.9),
        const Color(0xFFC084FC).withOpacity(0.6),
        const Color(0xFFA78BFA).withOpacity(0.3),
        Colors.transparent,
      ],
    );
    
    final centerPaint = Paint()
      ..shader = centerGradient.createShader(
        Rect.fromCircle(center: center, radius: radius * 0.3),
      )
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius * 0.25, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class NavAssistLogo extends StatelessWidget {
  final double size;
  
  const NavAssistLogo({super.key, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoPainter(),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background Glow
    final Paint glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.primaryBlue.withOpacity(0.4),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, glowPaint);

    // Stylized 'N' & 'A' combined into a continuous pulse line
    final Paint linePaint = Paint()
      ..shader = LinearGradient(
        colors: [AppTheme.primaryBlue, AppTheme.accentPurple],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = size.width * 0.12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final Path logoPath = Path();
    // Start bottom left
    logoPath.moveTo(size.width * 0.2, size.height * 0.8);
    // Up for the N
    logoPath.lineTo(size.width * 0.2, size.height * 0.2);
    // Diagonal down for N
    logoPath.lineTo(size.width * 0.8, size.height * 0.8);
    // Up for the right side of N / A
    logoPath.lineTo(size.width * 0.8, size.height * 0.2);

    canvas.drawPath(logoPath, linePaint);

    // Sonar / Radar arcs radiating outwards
    final Paint arcPaint = Paint()
      ..color = AppTheme.safeGreen.withOpacity(0.8)
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(size.width * 0.8, size.height * 0.2), radius: size.width * 0.3),
      -math.pi / 2,
      math.pi / 2,
      false,
      arcPaint,
    );
    
    // Tactile Braille Dot Representation
    final Paint dotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.2), size.width * 0.08, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

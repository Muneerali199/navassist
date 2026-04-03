import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dart:math' as math;

class SensorRadar extends StatefulWidget {
  const SensorRadar({super.key});

  @override
  State<SensorRadar> createState() => _SensorRadarState();
}

class _SensorRadarState extends State<SensorRadar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: 280,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.surfaceDark.withOpacity(0.5),
        border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.1), spreadRadius: 10, blurRadius: 40),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Rings
          _buildRing(200, AppTheme.primaryBlue.withOpacity(0.1)),
          _buildRing(120, AppTheme.primaryBlue.withOpacity(0.2)),
          
          // Radar Sweep
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _controller.value * 2.0 * math.pi,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [
                        Colors.transparent,
                        AppTheme.primaryBlue.withOpacity(0.0),
                        AppTheme.primaryBlue.withOpacity(0.4),
                        AppTheme.primaryBlue,
                      ],
                      stops: const [0.0, 0.5, 0.9, 1.0],
                      transform: const GradientRotation(-math.pi / 2),
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Center Icon (User)
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryBlue,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(color: AppTheme.primaryBlue, blurRadius: 20),
              ],
            ),
            child: const Icon(Icons.accessibility_new_rounded, color: Colors.white, size: 30),
          ),
          
          // Obstacle Markers (Mock Data for presentation)
          _buildObstacle(top: 40, left: 100, color: AppTheme.dangerRed, size: 16),
          _buildObstacle(bottom: 50, right: 60, color: AppTheme.warningYellow, size: 12),
        ],
      ),
    );
  }

  Widget _buildRing(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
    );
  }

  Widget _buildObstacle({double? top, double? bottom, double? left, double? right, required Color color, required double size}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.6), blurRadius: 10, spreadRadius: 2),
          ],
        ),
      ),
    );
  }
}

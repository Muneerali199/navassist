import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class StatusBadge extends StatefulWidget {
  final bool isActive;
  final String activeText;
  final String inactiveText;
  final Color activeColor;

  const StatusBadge({
    super.key,
    required this.isActive,
    required this.activeText,
    required this.inactiveText,
    required this.activeColor,
  });

  @override
  State<StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<StatusBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color currentColor = widget.isActive ? widget.activeColor : AppTheme.dangerRed;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentColor,
                boxShadow: [
                  BoxShadow(
                    color: currentColor.withOpacity(0.6 * _controller.value),
                    blurRadius: 10 * _controller.value,
                    spreadRadius: 2 * _controller.value,
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        Text(
          widget.isActive ? widget.activeText : widget.inactiveText,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: currentColor,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

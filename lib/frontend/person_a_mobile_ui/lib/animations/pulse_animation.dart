import 'package:flutter/material.dart';

/// Pulse animation for SOS button — radiating rings effect.
class PulseAnimation extends StatefulWidget {
  final Widget child;
  final Color color;
  final bool isActive;

  const PulseAnimation({super.key, required this.child, this.color = const Color(0xFFD32F2F), this.isActive = false});

  @override
  State<PulseAnimation> createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<PulseAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return widget.child;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _PulsePainter(progress: _controller.value, color: widget.color),
          child: widget.child,
        );
      },
    );
  }
}

class _PulsePainter extends CustomPainter {
  final double progress;
  final Color color;

  _PulsePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width * 0.6;
    final paint = Paint()..color = color.withValues(alpha: 1 - progress)..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawCircle(center, maxRadius * progress, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

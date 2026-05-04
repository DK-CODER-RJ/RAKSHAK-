import 'package:flutter/material.dart';

/// Large circular SOS emergency button with pulse animation.
class EmergencyButton extends StatelessWidget {
  final VoidCallback onPressed;
  final VoidCallback onLongPress;
  final bool isActive;
  final double size;

  const EmergencyButton({
    super.key,
    required this.onPressed,
    required this.onLongPress,
    this.isActive = false,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      onLongPress: onLongPress,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? const Color(0xFF388E3C) : const Color(0xFFD32F2F),
          boxShadow: [
            BoxShadow(
              color: (isActive ? const Color(0xFF388E3C) : const Color(0xFFD32F2F)).withValues(alpha: 0.3),
              blurRadius: 24, spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shield_outlined, color: Colors.white, size: size * 0.3),
            const SizedBox(height: 4),
            Text(isActive ? 'ACTIVE' : 'SOS',
                style: TextStyle(color: Colors.white, fontSize: size * 0.15, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

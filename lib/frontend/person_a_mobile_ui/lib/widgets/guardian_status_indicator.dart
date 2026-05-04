import 'package:flutter/material.dart';

/// Guardian service status indicator — shows active/inactive state.
class GuardianStatusIndicator extends StatelessWidget {
  final bool isActive;
  const GuardianStatusIndicator({super.key, this.isActive = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 8, height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle,
            color: isActive ? const Color(0xFF388E3C) : const Color(0xFFFF9800))),
        const SizedBox(width: 8),
        Text(isActive ? 'Guardian Active' : 'Guardian Paused',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: isActive ? const Color(0xFF388E3C) : const Color(0xFFFF9800))),
      ]),
    );
  }
}

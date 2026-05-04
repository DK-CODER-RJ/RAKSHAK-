import 'package:flutter/material.dart';

/// Permission dialog for requesting critical app permissions.
class PermissionDialog extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onGrant;
  final VoidCallback onDeny;

  const PermissionDialog({super.key, required this.title, required this.description,
      required this.icon, this.color = const Color(0xFFD32F2F),
      required this.onGrant, required this.onDeny});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 64, height: 64,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 32)),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Text(description, textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.4)),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 48,
            child: ElevatedButton(onPressed: onGrant,
              style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: const Text('Allow', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)))),
          const SizedBox(height: 8),
          TextButton(onPressed: onDeny,
            child: Text('Not Now', style: TextStyle(color: Colors.grey[600]))),
        ]),
      ),
    );
  }
}

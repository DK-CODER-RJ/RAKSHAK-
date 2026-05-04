import 'package:flutter/material.dart';

/// Reusable contact tile widget for emergency contacts list.
class ContactTile extends StatelessWidget {
  final String name;
  final String phone;
  final bool isPrimary;
  final VoidCallback? onCall;
  final VoidCallback? onAlert;

  const ContactTile({super.key, required this.name, required this.phone,
      this.isPrimary = false, this.onCall, this.onAlert});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(width: 48, height: 48,
          decoration: BoxDecoration(
            color: isPrimary ? const Color(0xFFFFEBEE) : const Color(0xFFE3F2FD),
            shape: BoxShape.circle),
          child: Icon(Icons.person_outline,
              color: isPrimary ? const Color(0xFFD32F2F) : const Color(0xFF1976D2))),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          Text(phone, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ])),
        if (onCall != null) IconButton(onPressed: onCall, icon: const Icon(Icons.phone_outlined, color: Color(0xFF388E3C))),
        if (onAlert != null) IconButton(onPressed: onAlert, icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1976D2))),
      ]),
    );
  }
}

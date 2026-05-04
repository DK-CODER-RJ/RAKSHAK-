import 'package:flutter/material.dart';

/// Geofence card widget for displaying safe zone information.
class GeofenceCard extends StatelessWidget {
  final String name;
  final String address;
  final int radiusMeters;
  final IconData icon;
  final Color color;
  final VoidCallback? onEdit;

  const GeofenceCard({super.key, required this.name, required this.address,
      required this.radiusMeters, this.icon = Icons.location_on_outlined,
      this.color = const Color(0xFF388E3C), this.onEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(width: 48, height: 48,
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24)),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          Text('$address • ${radiusMeters}m', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ])),
        if (onEdit != null) IconButton(onPressed: onEdit, icon: Icon(Icons.edit_outlined, color: Colors.grey[400], size: 20)),
      ]),
    );
  }
}

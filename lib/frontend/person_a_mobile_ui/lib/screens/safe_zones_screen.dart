import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rakshak/frontend/person_b_navigation_state/lib/state/providers/safe_zone_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

/// Safe Zones Screen — Geofencing management.
class SafeZonesScreen extends StatelessWidget {
  const SafeZonesScreen({super.key});

  Future<void> _addNewZone(BuildContext context) async {
    try {
      final position = await Geolocator.getCurrentPosition();
      if (context.mounted) {
        final provider = context.read<SafeZoneProvider>();
        final newZone = SafeZone(
          id: const Uuid().v4(),
          name: 'New Safe Zone ${provider.zones.length + 1}',
          address: '${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}',
          latitude: position.latitude,
          longitude: position.longitude,
        );
        await provider.addZone(newZone);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Safe Zone added at your current location')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final zoneProvider = Provider.of<SafeZoneProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1C1C)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Safe Zones',
            style: TextStyle(color: Color(0xFF1A1C1C), fontWeight: FontWeight.w600)),
      ),
      body: zoneProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Safe Zones',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text('Get notified when entering or leaving safe zones',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                  const SizedBox(height: 20),
                  // Night mode toggle (Static for now)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                    child: Row(children: [
                      const Icon(Icons.nightlight_outlined, color: Color(0xFFFF9800)),
                      const SizedBox(width: 16),
                      const Expanded(child: Text('Night Mode Alerts', style: TextStyle(fontWeight: FontWeight.w600))),
                      Switch(value: true, onChanged: (v) {}, activeThumbColor: const Color(0xFF388E3C)),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  const Text('Your Safe Zones', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  if (zoneProvider.zones.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(child: Text('No safe zones added yet')),
                    ),
                  ...zoneProvider.zones.map((zone) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildZoneCard(context, zone),
                  )),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () => _addNewZone(context),
                      icon: const Icon(Icons.add_location_outlined),
                      label: const Text('Add Current Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1976D2),
                        side: const BorderSide(color: Color(0xFF1976D2), width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildZoneCard(BuildContext context, SafeZone zone) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF388E3C).withValues(alpha: 0.1), 
            borderRadius: BorderRadius.circular(12)
          ),
          child: const Icon(Icons.location_on_outlined, color: Color(0xFF388E3C), size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(zone.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          Text(zone.address, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ])),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
          onPressed: () => context.read<SafeZoneProvider>().removeZone(zone.id),
        ),
      ]),
    );
  }
}


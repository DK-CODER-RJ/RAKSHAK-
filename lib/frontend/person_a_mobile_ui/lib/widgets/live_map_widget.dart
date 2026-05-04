import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rakshak/frontend/person_b_navigation_state/lib/state/providers/sos_state_provider.dart';

/// Live map widget — renders Google Maps Flutter with current location.
class LiveMapWidget extends StatefulWidget {
  final double height;
  final bool liteMode;

  const LiveMapWidget({super.key, this.height = 200, this.liteMode = true});

  @override
  State<LiveMapWidget> createState() => _LiveMapWidgetState();
}

class _LiveMapWidgetState extends State<LiveMapWidget> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return Consumer<SosStateProvider>(
      builder: (context, sosProvider, child) {
        final position = sosProvider.currentPosition;
        
        // Default to New Delhi if no location available yet
        final initialTarget = position != null 
            ? LatLng(position.latitude, position.longitude)
            : const LatLng(28.6139, 77.2090);

        if (position != null && _mapController != null) {
          _mapController!.animateCamera(CameraUpdate.newLatLng(initialTarget));
        }

        return Container(
          width: double.infinity, 
          height: widget.height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white, 
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialTarget,
              zoom: 15,
            ),
            liteModeEnabled: widget.liteMode,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapType: MapType.normal,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: position != null ? {
              Marker(
                markerId: const MarkerId('current_location'),
                position: initialTarget,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                infoWindow: const InfoWindow(title: 'You are here'),
              )
            } : {},
          ),
        );
      },
    );
  }
}


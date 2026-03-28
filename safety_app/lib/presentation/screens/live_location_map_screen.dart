import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safety_app/core/constants/app_colors.dart';

class LiveLocationMapScreen extends StatefulWidget {
  const LiveLocationMapScreen({super.key});

  @override
  State<LiveLocationMapScreen> createState() => _LiveLocationMapScreenState();
}

class _LiveLocationMapScreenState extends State<LiveLocationMapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  StreamSubscription<Position>? _positionStream;
  bool _serviceEnabled = true;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() {
          _serviceEnabled = false;
          _currentPosition = const LatLng(28.6139, 77.2090);
        });
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Location services are disabled. Please turn them on.")));
      }
      return;
    } else {
      setState(() {
        _serviceEnabled = true;
      });
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          setState(() {
            _currentPosition = const LatLng(28.6139, 77.2090);
          });
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Location permissions are denied")));
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _currentPosition = const LatLng(28.6139, 77.2090);
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Location permissions are permanently denied")));
      }
      return;
    }

    // Get current fixed position
    Position pos = await Geolocator.getCurrentPosition();
    if (mounted) {
      _updateMarker(LatLng(pos.latitude, pos.longitude));
    }

    // Start stream
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 2),
    ).listen((Position position) {
      if (mounted) {
        _updateMarker(LatLng(position.latitude, position.longitude));
      }
    });
  }

  void _updateMarker(LatLng position) {
    setState(() {
      _currentPosition = position;
      _markers = {
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: const InfoWindow(title: "You are here"),
        )
      };
    });

    _controller.future.then((controller) {
      controller.animateCamera(CameraUpdate.newLatLng(position));
    });
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Map Tracking"),
      ),
      body: _currentPosition == null
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryGreen))
          : Stack(
              children: [
                GoogleMap(
                  mapType: MapType.normal,
                  myLocationEnabled: _serviceEnabled,
                  myLocationButtonEnabled: _serviceEnabled,
                  zoomControlsEnabled: false,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition!,
                    zoom: 16.5,
                  ),
                  markers: _markers,
                  onMapCreated: (GoogleMapController controller) {
                    _controller.complete(controller);
                  },
                ),
                if (!_serviceEnabled)
                  Positioned(
                    bottom: 30,
                    left: 20,
                    right: 20,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () async {
                        await Geolocator.openLocationSettings();
                        // Re-check after returning from settings
                        _determinePosition();
                      },
                      icon: const Icon(Icons.location_on, color: Colors.white),
                      label: const Text(
                        "Turn On Location Services",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

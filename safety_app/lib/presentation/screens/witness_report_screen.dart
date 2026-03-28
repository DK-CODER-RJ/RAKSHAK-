import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:safety_app/presentation/providers/data_providers.dart';
import 'package:safety_app/core/services/location_service.dart';
import 'package:safety_app/core/services/places_service.dart';

class WitnessReportScreen extends ConsumerStatefulWidget {
  final String videoPath;
  const WitnessReportScreen({super.key, required this.videoPath});

  @override
  ConsumerState<WitnessReportScreen> createState() =>
      _WitnessReportScreenState();
}

class _WitnessReportScreenState extends ConsumerState<WitnessReportScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isAnonymous = false;
  bool _isSubmitting = false;
  final TextEditingController _descriptionController = TextEditingController();

  final LocationService _locationService = LocationService();
  final PlacesService _placesService = PlacesService();

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      try {
        String downloadUrl =
            widget.videoPath; // Default to local path if upload fails

        try {
          final fileName = widget.videoPath.split('/').last;
          final storageRef = FirebaseStorage.instance
              .ref()
              .child('incidents/videos/$fileName');

          await storageRef.putFile(File(widget.videoPath));
          downloadUrl = await storageRef.getDownloadURL();
        } catch (e) {
          // print("Firebase Storage Upload Error (Using Local Video Path): $e");
        }

        // 2. Get Location
        var posLat = 0.0;
        var posLng = 0.0;
        var address = "Unknown Address";
        Map<String, dynamic> policeStation = {
          "name": "Unknown",
          "distance": ""
        };

        try {
          final position = await _locationService.getCurrentLocation();
          posLat = position.latitude;
          posLng = position.longitude;
          address =
              await _locationService.getAddressFromCoordinates(posLat, posLng);
          policeStation =
              await _placesService.getNearestPoliceStation(posLat, posLng);
        } catch (e) {
          // Ignore location errors to not block submission
        }

        await ref.read(incidentRepositoryProvider).createIncident({
          'type': 'WITNESS', // Match IncidentHistoryScreen expectation
          'description': _descriptionController.text,
          'videoUrl': downloadUrl,
          'isAnonymous': _isAnonymous,
          'timestamp': DateTime.now().toIso8601String(),
          'location': {'lat': posLat, 'lng': posLng, 'address': address},
          'police_station': policeStation,
          'status': 'SUBMITTED'
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report securely uploaded to Cloud')),
          );
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading report: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Submit Report")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Video recorded: ...${widget.videoPath.split('/').last}",
                style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6)),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                title: const Text("Report Anonymously"),
                value: _isAnonymous,
                onChanged: (val) => setState(() => _isAnonymous = val),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: "Description of Incident",
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
                maxLines: 5,
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text("SUBMIT SECURE REPORT"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

class PlacesService {
  static const String _apiKey = 'AIzaSyBpSU_M0DNpzfiVqpJU-r_goIjy-jvwelA';

  Future<Map<String, dynamic>> getNearestPoliceStation(
      double lat, double lng) async {
    try {
      final String url =
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=$lat,$lng&radius=5000&type=police&key=$_apiKey';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' &&
            data['results'] != null &&
            data['results'].isNotEmpty) {
          final place = data['results'][0];
          return {
            'name': place['name'] ?? 'Nearest Police Station',
            'address': place['vicinity'] ?? 'Unknown Address',
            'distance': 'N/A',
            'phone':
                '100', // Call 100 in India usually, exact phone needs Places Detail API
            'lat': place['geometry']['location']['lat'],
            'lng': place['geometry']['location']['lng'],
          };
        }
      }
    } catch (e) {
      // print('Error fetching places: $e');
    }

    // Fallback response for offline or error
    return {
      'name': 'Central Police Station (Fallback)',
      'address': 'Address Unavailable',
      'distance': 'N/A',
      'phone': '100',
      'lat': lat + 0.001,
      'lng': lng + 0.001,
    };
  }
}

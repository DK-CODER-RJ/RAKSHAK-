import 'package:dio/dio.dart';

class PoliceLookupService {
  PoliceLookupService(this._dio, this.googleApiKey);

  final Dio _dio;
  final String googleApiKey;

  Future<({String stationName, String contact})> nearestPolice({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.get(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
      queryParameters: {
        'location': '$latitude,$longitude',
        'rankby': 'distance',
        'type': 'police',
        'key': googleApiKey,
      },
    );

    final results = (response.data['results'] as List<dynamic>?) ?? const [];
    if (results.isEmpty) {
      return (stationName: 'Police Station Not Found', contact: 'N/A');
    }

    final first = results.first as Map<String, dynamic>;
    final name = (first['name'] as String?) ?? 'Nearest Police Station';
    final contact = (first['formatted_phone_number'] as String?) ?? 'N/A';
    return (stationName: name, contact: contact);
  }
}

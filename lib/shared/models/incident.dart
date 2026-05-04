class Incident {
  final String id;
  final String type; // 'SOS' or 'WITNESS'
  final DateTime timestamp;
  final String? location;
  final String? mediaUrl;
  final String? mediaPath;
  final String? status; // 'Active', 'Resolved', 'Cancelled'

  Incident({
    required this.id,
    required this.type,
    required this.timestamp,
    this.location,
    this.mediaUrl,
    this.mediaPath,
    this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
      'mediaUrl': mediaUrl,
      'mediaPath': mediaPath,
      'status': status,
    };
  }

  factory Incident.fromMap(Map<String, dynamic> map) {
    return Incident(
      id: map['id'] ?? '',
      type: map['type'] ?? 'SOS',
      timestamp: DateTime.parse(map['timestamp']),
      location: map['location'],
      mediaUrl: map['mediaUrl'],
      mediaPath: map['mediaPath'],
      status: map['status'],
    );
  }
}

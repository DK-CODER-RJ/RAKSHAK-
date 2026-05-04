class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final bool isPrimary;
  final String relationship;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.isPrimary,
    required this.relationship,
  });

  EmergencyContact copyWith({
    String? name,
    String? phone,
    bool? isPrimary,
    String? relationship,
  }) {
    return EmergencyContact(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      isPrimary: isPrimary ?? this.isPrimary,
      relationship: relationship ?? this.relationship,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'isPrimary': isPrimary,
      'relationship': relationship,
    };
  }

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      isPrimary: map['isPrimary'] ?? false,
      relationship: map['relationship'] ?? '',
    );
  }
}

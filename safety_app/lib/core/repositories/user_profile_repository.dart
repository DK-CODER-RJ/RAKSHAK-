import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safety_app/core/security/secure_storage_service.dart';

class UserProfile {
  final String name;
  final String dob;
  final String gender;
  final String address;
  final String aadhaar;

  UserProfile({
    this.name = '',
    this.dob = '',
    this.gender = 'Not Specified',
    this.address = '',
    this.aadhaar = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'dob': dob,
      'gender': gender,
      'address': address,
      'aadhaar': aadhaar,
    };
  }

  factory UserProfile.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return UserProfile();
    return UserProfile(
      name: map['name'] ?? '',
      dob: map['dob'] ?? '',
      gender: map['gender'] ?? 'Not Specified',
      address: map['address'] ?? '',
      aadhaar: map['aadhaar'] ?? '',
    );
  }
}

class UserProfileRepository {
  final SecureStorageService _storage = SecureStorageService();

  Future<void> saveProfile(UserProfile profile) async {
    // Navigates AES-256 natively via HiveAesCipher in SecureStorageService
    await _storage.saveData('user_profile', profile.toMap());
  }

  Future<UserProfile> getProfile() async {
    final data = _storage.getData('user_profile');
    if (data != null && data is Map) {
      return UserProfile.fromMap(data);
    }
    return UserProfile();
  }
}

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository();
});

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  return ref.watch(userProfileRepositoryProvider).getProfile();
});

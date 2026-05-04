import 'package:cloud_firestore/cloud_firestore.dart';

/// User Repository — Data layer for user operations.
class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch user profile from Firestore
  Future<Map<String, dynamic>?> getUser(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    return doc.data();
  }

  /// Update user profile
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(userId).set(data, SetOptions(merge: true));
  }

  /// Delete user account
  Future<void> deleteUser(String userId) async {
    await _firestore.collection('users').doc(userId).delete();
  }
}

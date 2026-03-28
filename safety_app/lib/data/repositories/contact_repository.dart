import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class ContactRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _boxName = 'contacts_box';

  String? get uid => _auth.currentUser?.uid;

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  Future<List<Map<String, dynamic>>> getContacts() async {
    if (uid == null) return [];

    List<Map<String, dynamic>> contacts = [];
    final box = await _getBox();

    try {
      // Try Cloud First
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('contacts')
          .get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        contacts.add(data);
        // Sync to local
        await box.put(doc.id, data);
      }
    } catch (e) {
      // print("Firebase Contact Read Error (Using Local Fallback): $e");
      // Fallback to local Hive box if network/permissions fail
      final localData = box.values.toList();
      for (var item in localData) {
        if (item is Map) {
          contacts.add(Map<String, dynamic>.from(item));
        }
      }
    }

    return contacts;
  }

  Future<void> addContact(String name, String number, String relation) async {
    if (uid == null) throw Exception("User not authenticated");

    final String localId = const Uuid().v4();
    final data = {
      'id': localId,
      'name': name,
      'number': number,
      'relation': relation,
      'createdAt': DateTime.now().toIso8601String(),
    };

    // Always save locally first for immediate UI feedback and fallback
    final box = await _getBox();
    await box.put(localId, data);

    try {
      // Try pushing to cloud
      final docRef = await _firestore
          .collection('users')
          .doc(uid)
          .collection('contacts')
          .add(data);
      // Update local with true firestore ID
      data['id'] = docRef.id;
      await box.delete(localId);
      await box.put(docRef.id, data);
    } catch (e) {
      // print("Firebase Contact Write Error: Saved Locally only. $e");
    }
  }

  Future<void> deleteContact(String docId) async {
    if (uid == null) throw Exception("User not authenticated");

    // Delete locally
    final box = await _getBox();
    if (box.containsKey(docId)) {
      await box.delete(docId);
    }

    try {
      // Try deleting from cloud
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('contacts')
          .doc(docId)
          .delete();
    } catch (e) {
      // print("Firebase Contact Delete Error: Deleted Locally only. $e");
    }
  }
}

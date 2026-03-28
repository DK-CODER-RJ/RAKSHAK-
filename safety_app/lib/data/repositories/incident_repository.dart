import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safety_app/core/services/offline_queue_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class IncidentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final OfflineQueueService _queueService = OfflineQueueService();
  final String _boxName = 'incidents_box';

  String? get uid => _auth.currentUser?.uid;

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  Future<List<Map<String, dynamic>>> getIncidents() async {
    if (uid == null) return [];

    List<Map<String, dynamic>> incidents = [];
    final box = await _getBox();

    try {
      // Try Cloud First
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('incidents')
          .orderBy('timestamp', descending: true)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;
        incidents.add(data);
        // Sync to local
        await box.put(doc.id, data);
      }
    } catch (e) {
      // print("Firebase Incident Read Error (Using Local Fallback): $e");
      // Fallback to local Hive box if network/permissions fail
      final localData = box.values.toList();
      for (var item in localData) {
        if (item is Map) {
          incidents.add(Map<String, dynamic>.from(item));
        }
      }
      // Sort locally
      incidents.sort((a, b) =>
          (b['timestamp'] as num? ?? 0).compareTo(a['timestamp'] as num? ?? 0));
    }

    return incidents;
  }

  Future<void> createIncident(Map<String, dynamic> incidentData) async {
    if (uid == null) throw Exception("User not authenticated");

    final String localId = const Uuid().v4();
    incidentData['id'] = localId; // Assign local ID for UI immediate rendering

    // Always save locally first for immediate UI feedback and fallback
    final box = await _getBox();
    await box.put(localId, incidentData);

    try {
      final docRef = await _firestore
          .collection('users')
          .doc(uid)
          .collection('incidents')
          .add(incidentData);
      incidentData['id'] = docRef.id;
      await box.delete(localId);
      await box.put(docRef.id, incidentData);
    } catch (e) {
      // print("Offline/Permission Error: Queuing incident. $e");
      final queueItem = QueueItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'API',
        payload: jsonEncode(
            {'collection': 'users/$uid/incidents', 'data': incidentData}),
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );
      await _queueService.addToQueue(queueItem);
    }
  }

  Future<void> deleteIncident(String docId) async {
    if (uid == null) return;

    // Delete locally
    final box = await _getBox();
    if (box.containsKey(docId)) {
      await box.delete(docId);
    }

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('incidents')
          .doc(docId)
          .delete();
    } catch (e) {
      // print("Firebase Incident Delete Error: Deleted Locally only. $e");
    }
  }
}

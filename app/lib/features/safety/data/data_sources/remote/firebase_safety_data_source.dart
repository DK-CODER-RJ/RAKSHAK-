import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/safety_event_model.dart';

class FirebaseSafetyDataSource {
  FirebaseSafetyDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  Future<void> uploadEvent(SafetyEventModel event) async {
    await _firestore
        .collection('safety_events')
        .doc(event.id)
        .set(event.toJson());
  }

  Future<void> forwardToAuthority(SafetyEventModel event) async {
    // Replace with Cloud Functions/API integration to law enforcement/NGO endpoint.
    await _firestore
        .collection('authority_forward_queue')
        .doc(event.id)
        .set(event.toJson());
  }
}

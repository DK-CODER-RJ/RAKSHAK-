import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Handles uploading of evidence chunks to Firebase Storage
class UploadService {
  static final UploadService _instance = UploadService._internal();
  factory UploadService() => _instance;
  UploadService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Uploads a single evidence chunk (video/audio) to Firebase
  Future<void> uploadEvidence(String filePath, {String? eventId}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('UploadService: Cannot upload, user not logged in.');
        return;
      }

      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('UploadService: File does not exist at $filePath');
        return;
      }

      final fileName = filePath.split('/').last;
      final eId = eventId ?? 'unknown_event';
      
      // Path: evidence/{userId}/{eventId}/{fileName}
      final storageRef = _storage.ref().child('evidence/${user.uid}/$eId/$fileName');

      debugPrint('UploadService: Starting upload for $fileName');
      
      // Upload task
      final uploadTask = storageRef.putFile(
        file,
        SettableMetadata(contentType: 'video/mp4'),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('UploadService: Upload complete. URL: $downloadUrl');

      // Save metadata to Firestore
      await _firestore.collection('evidence').add({
        'userId': user.uid,
        'eventId': eId,
        'fileName': fileName,
        'downloadUrl': downloadUrl,
        'uploadedAt': FieldValue.serverTimestamp(),
        'fileSize': snapshot.totalBytes,
      });

      // Optionally delete the local file after successful upload to save space
      await file.delete();
      debugPrint('UploadService: Local file deleted after upload.');
    } catch (e) {
      debugPrint('UploadService Error: $e');
    }
  }
}

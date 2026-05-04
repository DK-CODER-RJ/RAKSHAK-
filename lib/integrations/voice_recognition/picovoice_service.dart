import 'package:flutter/material.dart';
import 'package:porcupine_flutter/porcupine_manager.dart';
import 'package:porcupine_flutter/porcupine.dart';
import 'package:porcupine_flutter/porcupine_error.dart';

/// Service to handle offline wake word detection using Picovoice Porcupine.
class PicovoiceService {
  PorcupineManager? _porcupineManager;
  final Function(int) onWakeWordDetected;

  PicovoiceService({required this.onWakeWordDetected});

  Future<void> initialize(String accessKey) async {
    try {
      // For now, we use built-in keywords to ensure it works out of the box.
      // In production, use .fromKeywordPaths with custom .ppn files (e.g., 'help', 'bachao').
      _porcupineManager = await PorcupineManager.fromBuiltInKeywords(
        accessKey,
        [BuiltInKeyword.PORCUPINE, BuiltInKeyword.BUMBLEBEE],
        onWakeWordDetected,
      );
      await _porcupineManager?.start();
      debugPrint('Picovoice Porcupine started successfully.');
    } on PorcupineException {
      debugPrint('PorcupineException: \${e.message}');
    } catch (e) {
      debugPrint('Failed to initialize Picovoice: \$e');
    }
  }

  Future<void> stop() async {
    await _porcupineManager?.stop();
    await _porcupineManager?.delete();
    _porcupineManager = null;
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Native Voice Recognition Service — Uses Android's SpeechRecognizer directly.
/// Continuously listens for SOS keywords and auto-restarts.
/// Works reliably as long as the app is in foreground.
class NativeVoiceService {
  static const _methodChannel = MethodChannel('com.rakshak.rakshak/voice');
  static const _eventChannel = EventChannel('com.rakshak.rakshak/voice_events');

  StreamSubscription? _subscription;
  final Function() onSosTrigger;
  final List<String> keywords;
  bool _isActive = false;
  bool _triggerSent = false;

  int _keywordCount = 0;
  Timer? _countResetTimer;

  NativeVoiceService({
    required this.onSosTrigger,
    this.keywords = const ['help', 'bachao', 'emergency', 'madad'],
  });

  /// Start continuous listening
  Future<void> startListening() async {
    if (_isActive) return;

    try {
      // Listen for events from native side
      _subscription = _eventChannel.receiveBroadcastStream().listen(
        (event) {
          if (event is Map) {
            final type = event['type'];
            if (type == 'keyword_detected') {
              final keyword = event['keyword'] ?? '';
              final fullText = event['fullText'] ?? '';
              
              if (!_triggerSent) {
                _keywordCount++;
                debugPrint('🚨 Native voice: keyword "$keyword" detected (Count: $_keywordCount/3) in "$fullText"');
                
                // Reset count after 15 seconds of inactivity
                _countResetTimer?.cancel();
                _countResetTimer = Timer(const Duration(seconds: 15), () {
                  if (_keywordCount > 0 && !_triggerSent) {
                    debugPrint('🎤 Native voice: count reset to 0');
                    _keywordCount = 0;
                  }
                });

                if (_keywordCount >= 3) {
                  _triggerSent = true;
                  _keywordCount = 0;
                  onSosTrigger();
                  
                  // Reset trigger lock after 30 seconds
                  Timer(const Duration(seconds: 30), () {
                    _triggerSent = false;
                  });
                }
              }
            } else if (type == 'status') {
              debugPrint('🎤 Native voice status: ${event['value']}');
            }
          }
        },
        onError: (error) {
          debugPrint('🎤 Native voice error: $error');
        },
      );

      // Start the native recognizer
      await _methodChannel.invokeMethod('startListening', {
        'keywords': keywords,
      });

      _isActive = true;
      _triggerSent = false;
      debugPrint('🎤 Native voice recognition started with keywords: $keywords');
    } catch (e) {
      debugPrint('🎤 Error starting native voice: $e');
    }
  }

  /// Stop listening
  Future<void> stopListening() async {
    try {
      await _methodChannel.invokeMethod('stopListening');
    } catch (e) {
      debugPrint('🎤 Error stopping native voice: $e');
    }
    _subscription?.cancel();
    _subscription = null;
    _isActive = false;
    debugPrint('🎤 Native voice recognition stopped.');
  }

  bool get isActive => _isActive;
}

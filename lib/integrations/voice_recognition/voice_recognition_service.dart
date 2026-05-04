import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

/// Voice Recognition Service — Continuously listens for SOS keywords.
/// Auto-restarts when recognition session ends.
class VoiceRecognitionService {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _isInitialized = false;
  Timer? _restartTimer;
  Timer? _keepAliveTimer;
  
  final Function() onSosTrigger;
  final List<String> keywords;
  bool _sosTriggerSent = false; // Prevent duplicate triggers

  VoiceRecognitionService({
    required this.onSosTrigger,
    this.keywords = const ['help', 'bachao', 'emergency', 'bachaao', 'bachav', 'madad'],
  });

  Future<bool> initialize() async {
    try {
      _isInitialized = await _speech.initialize(
        onError: (error) {
          debugPrint('🎤 Speech error: ${error.errorMsg} (permanent: ${error.permanent})');
          // Auto-restart listening after an error
          if (_isListening && !error.permanent) {
            _scheduleRestart();
          } else if (error.permanent) {
            // For permanent errors, wait longer before retrying
            _scheduleRestart(delay: const Duration(seconds: 3));
          }
        },
        onStatus: (status) {
          debugPrint('🎤 Speech status: $status');
          // When speech recognition stops, restart it immediately
          if ((status == 'done' || status == 'notListening') && _isListening) {
            _scheduleRestart();
          }
        },
      );
      debugPrint('🎤 Speech to text initialized: $_isInitialized');
      
      if (_isInitialized) {
        final locales = await _speech.locales();
        debugPrint('🎤 Available locales: ${locales.length}');
      }
      
      return _isInitialized;
    } catch (e) {
      debugPrint('🎤 Error initializing speech: $e');
      return false;
    }
  }

  /// Start continuous listening for SOS keywords
  Future<void> startListening() async {
    if (!_isInitialized) {
      final ok = await initialize();
      if (!ok) {
        debugPrint('🎤 Failed to initialize speech. Will retry in 5 seconds.');
        _scheduleRestart(delay: const Duration(seconds: 5));
        return;
      }
    }

    _isListening = true;
    _sosTriggerSent = false;
    _startRecognition();
    
    // Keep-alive timer: check every 15 seconds if still listening, restart if not
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_isListening && !_speech.isListening) {
        debugPrint('🎤 Keep-alive: speech stopped, restarting...');
        _startRecognition();
      }
    });
  }

  void _startRecognition() async {
    if (!_isListening || !_isInitialized) return;

    // Wait a bit if speech is currently active
    if (_speech.isListening) {
      debugPrint('🎤 Already listening, skipping restart.');
      return;
    }

    try {
      await _speech.listen(
        onResult: _onSpeechResult,
        listenFor: const Duration(seconds: 60), // Listen longer
        pauseFor: const Duration(seconds: 10), // Wait longer for speech
        localeId: 'en_IN', // English India for better "bachao" detection
        listenOptions: SpeechListenOptions(
          partialResults: true,
          listenMode: ListenMode.dictation,
        ),
      );
      debugPrint('🎤 Now listening for keywords: ${keywords.join(", ")}');
    } catch (e) {
      debugPrint('🎤 Error starting speech listen: $e');
      _scheduleRestart(delay: const Duration(seconds: 2));
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    final recognized = result.recognizedWords.toLowerCase().trim();
    if (recognized.isEmpty) return;
    
    debugPrint('🎤 Heard: "$recognized" (final: ${result.finalResult})');

    // Check each keyword
    for (final keyword in keywords) {
      if (recognized.contains(keyword.toLowerCase())) {
        debugPrint('🚨🚨🚨 SOS KEYWORD DETECTED: "$keyword" in "$recognized"');
        
        if (!_sosTriggerSent) {
          _sosTriggerSent = true;
          onSosTrigger();
          
          // Reset trigger lock after 30 seconds to allow re-triggering
          Timer(const Duration(seconds: 30), () {
            _sosTriggerSent = false;
          });
        }
        break;
      }
    }
  }

  /// Schedule a restart of listening after a brief delay
  void _scheduleRestart({Duration delay = const Duration(milliseconds: 500)}) {
    _restartTimer?.cancel();
    _restartTimer = Timer(delay, () {
      if (_isListening) {
        _startRecognition();
      }
    });
  }

  /// Stop listening
  Future<void> stopListening() async {
    _isListening = false;
    _restartTimer?.cancel();
    _keepAliveTimer?.cancel();
    try {
      await _speech.stop();
    } catch (e) {
      debugPrint('🎤 Error stopping speech: $e');
    }
    debugPrint('🎤 Voice recognition stopped.');
  }

  bool get isListening => _isListening && _speech.isListening;
}

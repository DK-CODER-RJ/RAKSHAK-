import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart';

class AiKeywordService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  final StreamController<String> _keywordController =
      StreamController<String>.broadcast();

  // Keywords to detect (including Indian languages)
  final List<String> _targetKeywords = [
    'help',
    'emergency',
    'bachao',
    'madad',
    'help me',
    'witness mode'
  ];

  Stream<String> get keywordStream => _keywordController.stream;

  Future<void> init() async {
    try {
      await _speechToText.initialize(
        onError: (error) => _handleError(error),
        onStatus: (status) => _handleStatus(status),
      );
    } catch (e) {
      // print("STT Init Error: $e");
    }
  }

  void startListening() async {
    if (_isListening) return;

    if (!_speechToText.isAvailable) {
      await init();
    }

    _isListening = true;
    _listenLoop();
  }

  void _listenLoop() async {
    if (!_isListening) return;

    if (!_speechToText.isListening) {
      try {
        await _speechToText.listen(
          onResult: (result) {
            final text = result.recognizedWords.toLowerCase();
            for (var keyword in _targetKeywords) {
              if (text.contains(keyword)) {
                _keywordController.add(keyword.toUpperCase());
                // Immediately stop to reset the buffer
                _speechToText.stop();
                break;
              }
            }
          },
          listenFor: const Duration(hours: 24),
          pauseFor: const Duration(seconds: 3),
          listenOptions: SpeechListenOptions(
            listenMode: ListenMode.dictation,
            partialResults: true,
            cancelOnError: false,
          ),
        );
      } catch (e) {
        // print("Listen Error: $e");
      }
    }
  }

  void _handleStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      // Loop restarts listening auto if it was stopped by the system
      if (_isListening) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (_isListening) _listenLoop();
        });
      }
    }
  }

  void _handleError(dynamic error) {
    if (_isListening) {
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (_isListening) _listenLoop();
      });
    }
  }

  void stopListening() {
    _isListening = false;
    _speechToText.stop();
  }
}

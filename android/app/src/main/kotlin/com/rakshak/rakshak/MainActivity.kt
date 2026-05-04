package com.rakshak.rakshak

import android.content.Intent
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.rakshak.rakshak/voice"
    private val EVENT_CHANNEL = "com.rakshak.rakshak/voice_events"
    private var speechRecognizer: SpeechRecognizer? = null
    private var isListening = false
    private var eventSink: EventChannel.EventSink? = null
    private var keywords: List<String> = listOf("help", "bachao", "emergency", "madad")
    private val TAG = "RakshakVoice"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Method channel for start/stop
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startListening" -> {
                        val kwList = call.argument<List<String>>("keywords")
                        if (kwList != null) keywords = kwList
                        startContinuousListening()
                        result.success(true)
                    }
                    "stopListening" -> {
                        stopListening()
                        result.success(true)
                    }
                    "isListening" -> {
                        result.success(isListening)
                    }
                    else -> result.notImplemented()
                }
            }

        // Event channel for keyword detection events
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    eventSink = events
                }
                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    private fun startContinuousListening() {
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            Log.e(TAG, "Speech recognition not available on this device!")
            eventSink?.error("UNAVAILABLE", "Speech recognition not available", null)
            return
        }

        isListening = true
        startRecognition()
        Log.d(TAG, "Started continuous listening for keywords: $keywords")
    }

    private fun startRecognition() {
        if (!isListening) return

        // Destroy old recognizer
        speechRecognizer?.destroy()

        speechRecognizer = SpeechRecognizer.createSpeechRecognizer(this)
        speechRecognizer?.setRecognitionListener(object : RecognitionListener {
            override fun onReadyForSpeech(params: Bundle?) {
                Log.d(TAG, "Ready for speech")
                eventSink?.success(mapOf("type" to "status", "value" to "listening"))
            }

            override fun onBeginningOfSpeech() {
                Log.d(TAG, "Speech started")
            }

            override fun onRmsChanged(rmsdB: Float) {}

            override fun onBufferReceived(buffer: ByteArray?) {}

            override fun onEndOfSpeech() {
                Log.d(TAG, "Speech ended, will restart...")
            }

            override fun onError(error: Int) {
                val errorMsg = when (error) {
                    SpeechRecognizer.ERROR_NO_MATCH -> "No speech detected"
                    SpeechRecognizer.ERROR_SPEECH_TIMEOUT -> "Speech timeout"
                    SpeechRecognizer.ERROR_AUDIO -> "Audio error"
                    SpeechRecognizer.ERROR_CLIENT -> "Client error"
                    SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS -> "No mic permission"
                    SpeechRecognizer.ERROR_NETWORK -> "Network error"
                    SpeechRecognizer.ERROR_NETWORK_TIMEOUT -> "Network timeout"
                    SpeechRecognizer.ERROR_RECOGNIZER_BUSY -> "Recognizer busy"
                    SpeechRecognizer.ERROR_SERVER -> "Server error"
                    else -> "Unknown error: $error"
                }
                Log.d(TAG, "Recognition error: $errorMsg")

                // Auto-restart after common errors (no match, timeout, etc)
                if (isListening && error != SpeechRecognizer.ERROR_INSUFFICIENT_PERMISSIONS) {
                    android.os.Handler(mainLooper).postDelayed({
                        startRecognition()
                    }, 500)
                }
            }

            override fun onResults(results: Bundle?) {
                val matches = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                Log.d(TAG, "Results: $matches")

                if (matches != null) {
                    for (match in matches) {
                        val lower = match.lowercase()
                        for (keyword in keywords) {
                            if (lower.contains(keyword.lowercase())) {
                                Log.d(TAG, "🚨 KEYWORD DETECTED: '$keyword' in '$match'")
                                eventSink?.success(mapOf(
                                    "type" to "keyword_detected",
                                    "keyword" to keyword,
                                    "fullText" to match
                                ))
                                break
                            }
                        }
                    }
                }

                // Restart listening after processing results
                if (isListening) {
                    android.os.Handler(mainLooper).postDelayed({
                        startRecognition()
                    }, 300)
                }
            }

            override fun onPartialResults(partialResults: Bundle?) {
                val matches = partialResults?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                if (matches != null) {
                    for (match in matches) {
                        val lower = match.lowercase()
                        for (keyword in keywords) {
                            if (lower.contains(keyword.lowercase())) {
                                Log.d(TAG, "🚨 PARTIAL KEYWORD DETECTED: '$keyword' in '$match'")
                                eventSink?.success(mapOf(
                                    "type" to "keyword_detected",
                                    "keyword" to keyword,
                                    "fullText" to match
                                ))
                                break
                            }
                        }
                    }
                }
            }

            override fun onEvent(eventType: Int, params: Bundle?) {}
        })

        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            putExtra(RecognizerIntent.EXTRA_LANGUAGE, "en-IN")
            putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
            putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 5)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 5000L)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 3000L)
            putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 3000L)
        }

        try {
            speechRecognizer?.startListening(intent)
        } catch (e: Exception) {
            Log.e(TAG, "Error starting recognition: ${e.message}")
            if (isListening) {
                android.os.Handler(mainLooper).postDelayed({
                    startRecognition()
                }, 1000)
            }
        }
    }

    private fun stopListening() {
        isListening = false
        try {
            speechRecognizer?.stopListening()
            speechRecognizer?.destroy()
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping: ${e.message}")
        }
        speechRecognizer = null
        Log.d(TAG, "Voice recognition stopped")
    }

    override fun onDestroy() {
        stopListening()
        super.onDestroy()
    }
}

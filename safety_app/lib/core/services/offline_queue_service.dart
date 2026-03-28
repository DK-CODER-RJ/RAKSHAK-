import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

// Simple model for queued items
class QueueItem {
  final String id;
  final String type; // 'SMS', 'API', 'MEDIA'
  final String payload; // JSON string
  final int timestamp;
  int retryCount;

  QueueItem({
    required this.id,
    required this.type,
    required this.payload,
    required this.timestamp,
    this.retryCount = 0,
  });

  Map<String, dynamic> outputMap() {
    return {
      'id': id,
      'type': type,
      'payload': payload,
      'timestamp': timestamp,
      'retryCount': retryCount,
    };
  }

  static QueueItem fromMap(Map<dynamic, dynamic> map) {
    return QueueItem(
      id: map['id'],
      type: map['type'],
      payload: map['payload'],
      timestamp: map['timestamp'],
      retryCount: map['retryCount'] ?? 0,
    );
  }
}

class OfflineQueueService {
  static final OfflineQueueService _instance = OfflineQueueService._internal();
  factory OfflineQueueService() => _instance;
  OfflineQueueService._internal();

  late Box _queueBox;
  bool _isProcessing = false;

  Future<void> init() async {
    // Register adapter or just use Map if simple
    // For simplicity, we store Maps
    _queueBox = await Hive.openBox('offline_queue');

    // Listen for connectivity changes
    Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> result) {
      if (!result.contains(ConnectivityResult.none)) {
        processQueue();
      }
    });
  }

  Future<void> addToQueue(QueueItem item) async {
    await _queueBox.put(item.id, item.outputMap());
    // Try to process immediately if online
    processQueue();
  }

  Future<void> processQueue() async {
    if (_isProcessing) return;

    // Check connectivity
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult.contains(ConnectivityResult.none)) return;

    _isProcessing = true;

    final keys = _queueBox.keys.toList();
    for (var key in keys) {
      final data = _queueBox.get(key);
      if (data != null) {
        QueueItem item = QueueItem.fromMap(data);
        bool success = await _dispatchItem(item);

        if (success) {
          await _queueBox.delete(key);
        } else {
          item.retryCount++;
          if (item.retryCount > 5) {
            // Move to dead letter queue or delete
            await _queueBox.delete(key); // Give up for now
          } else {
            await _queueBox.put(key, item.outputMap());
          }
        }
      }
    }

    _isProcessing = false;
  }

  Future<bool> _dispatchItem(QueueItem item) async {
    try {
      // Dispatch logic based on type
      if (item.type == 'SMS') {
        // Send SMS via platform channel (if it failed before?)
        // Actually SMS usually works offline if signal exists.
        // This might be for API syncing of SMS logs.
        return true;
      } else if (item.type == 'API') {
        // Call API
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}

import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:safety_app/core/services/ai_keyword_service.dart';
import 'package:safety_app/core/services/background_emergency_manager.dart';

class BackgroundService {
  static Future<void> initializeService() async {
    final service = FlutterBackgroundService();

    /// OPTIONAL, using custom notification channel id
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'safety_foreground', // id
      'Safety Background Service', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.low, // importance must be at low or higher level
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    try {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    } catch (e) {
      // handle error
    }

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        // this will be executed when app is in foreground or background in separated isolate
        onStart: onStart,
        // auto start service
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'safety_foreground',
        initialNotificationTitle: 'Safety Service Active',
        initialNotificationContent: 'Monitoring for emergency triggers',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }
}

@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  // continuous location tracking
  Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    ),
  ).listen((Position position) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "RAKSHAK is Tracking",
          content:
              "Location updating: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}",
        );
      }
    }
  });

  // heartbeat to keep alive if stationary
  Timer.periodic(const Duration(minutes: 1), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        service.setForegroundNotificationInfo(
          title: "RAKSHAK is Active",
          content: "Securing your background environment",
        );
      }
    }
  });

  // Listen for Shake Events
  accelerometerEventStream().listen((event) {
    double acceleration = event.x.abs() + event.y.abs() + event.z.abs();
    if (acceleration > 40) {
      // print("SHAKE DETECTED");
      BackgroundEmergencyManager().trigger();
    }
  });

  // Initialize Voice Detection
  final aiService = AiKeywordService();
  aiService.startListening();

  aiService.keywordStream.listen((keyword) {
    if (['HELP', 'BACHAO', 'EMERGENCY'].contains(keyword.toUpperCase())) {
      // print("VOICE TRIGGER DETECTED: $keyword");
      BackgroundEmergencyManager().trigger();
    }
  });

  service.on('stopService').listen((event) {
    aiService.stopListening();
    service.stopSelf();
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:rakshak/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:rakshak/frontend/person_b_navigation_state/lib/state/providers/auth_provider.dart';
import 'package:rakshak/frontend/person_b_navigation_state/lib/state/providers/settings_provider.dart';
import 'package:rakshak/frontend/person_b_navigation_state/lib/state/providers/contacts_provider.dart';
import 'package:rakshak/frontend/person_b_navigation_state/lib/state/providers/sos_state_provider.dart';
import 'package:rakshak/frontend/person_b_navigation_state/lib/state/providers/incident_provider.dart';
import 'package:rakshak/frontend/person_b_navigation_state/lib/state/providers/safe_zone_provider.dart';

import 'package:rakshak/frontend/person_b_navigation_state/lib/navigation/app_router.dart';
import 'package:rakshak/integrations/background_service.dart';
import 'package:rakshak/integrations/voice_recognition/native_voice_service.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('Firebase initialized!');

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ContactsProvider()),
        ChangeNotifierProvider(create: (_) => SosStateProvider()),
        ChangeNotifierProvider(create: (_) => IncidentProvider()),
        ChangeNotifierProvider(create: (_) => SafeZoneProvider()),
      ],
      child: const RakshakApp(),
    ),
  );
}

class RakshakApp extends StatefulWidget {
  const RakshakApp({super.key});

  @override
  State<RakshakApp> createState() => _RakshakAppState();
}

class _RakshakAppState extends State<RakshakApp> with WidgetsBindingObserver {
  NativeVoiceService? _voiceService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _voiceService?.stopListening();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('📱 App resumed — restarting voice listener');
      _startVoiceListener();
    } else if (state == AppLifecycleState.paused) {
      debugPrint('📱 App paused');
      // Don't stop — let it keep running as long as possible
    }
  }

  Future<void> _initializeApp() async {
    debugPrint('Requesting permissions...');
    
    final statuses = await [
      Permission.microphone,
      Permission.location,
      Permission.notification,
      Permission.camera,
      Permission.sms,
      Permission.phone,
    ].request();
    
    statuses.forEach((permission, status) {
      debugPrint('  $permission: $status');
    });

    await Permission.ignoreBatteryOptimizations.request();

    debugPrint('Initializing Background Service...');
    await RakshakBackgroundService.initializeService();
    debugPrint('Background Service initialized!');

    _setupBackgroundListener();
    
    // Wait for settings to load, then start voice
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _startVoiceListener();
    });
  }

  void _startVoiceListener() async {
    if (!mounted) return;

    final settings = Provider.of<SettingsProvider>(context, listen: false);
    
    if (!settings.voiceActivation) {
      debugPrint('🎤 Voice activation is DISABLED in settings.');
      await _voiceService?.stopListening();
      return;
    }

    final micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      debugPrint('🎤 Microphone permission not granted: $micStatus');
      return;
    }

    // Stop any existing listener first
    await _voiceService?.stopListening();

    _voiceService = NativeVoiceService(
      onSosTrigger: () {
        debugPrint('🚨 VOICE TRIGGER: SOS keyword detected!');
        if (!mounted) return;
        final sosProvider = Provider.of<SosStateProvider>(context, listen: false);
        if (!sosProvider.isActive) {
          sosProvider.triggerSos();
          debugPrint('🚨 SOS Triggered from voice command!');
        }
      },
      keywords: settings.voiceKeywords,
    );

    await _voiceService!.startListening();
    debugPrint('🎤 Native voice listener started with keywords: ${settings.voiceKeywords}');
  }

  void _setupBackgroundListener() {
    FlutterBackgroundService().on('trigger_sos').listen((event) {
      if (!mounted) return;
      final sosProvider = Provider.of<SosStateProvider>(context, listen: false);
      if (!sosProvider.isActive) {
        sosProvider.triggerSos();
        debugPrint('SOS Triggered from Background Voice Command');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RAKSHAK',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFD32F2F),
          brightness: Brightness.light,
          surface: const Color(0xFFF9F9F9),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      ),
      routerConfig: AppRouter.router,
    );
  }
}

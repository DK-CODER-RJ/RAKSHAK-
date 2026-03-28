import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safety_app/core/constants/app_theme.dart';
import 'package:safety_app/core/security/secure_storage_service.dart';
import 'package:safety_app/presentation/screens/emergency_screen.dart';
import 'package:safety_app/presentation/screens/witness_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:safety_app/core/services/background_service.dart';
import 'package:safety_app/core/services/offline_queue_service.dart';
import 'package:safety_app/presentation/screens/login_screen.dart';
import 'package:safety_app/presentation/providers/theme_provider.dart';
import 'package:flutter/services.dart';
import 'package:safety_app/presentation/providers/emergency_viewmodel.dart';
import 'package:safety_app/presentation/screens/emergency_contacts_screen.dart';
import 'package:safety_app/presentation/screens/incident_history_screen.dart';
import 'package:safety_app/presentation/screens/live_location_map_screen.dart';
import 'package:safety_app/presentation/screens/user_profile_screen.dart';
import 'package:safety_app/core/constants/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Initialize only critical services globally
    await Firebase.initializeApp();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint("STRICT LOG [FlutterError]: ${details.exceptionAsString()}");
    };

    runApp(const ProviderScope(child: SafetyApp()));
  }, (error, stackTrace) {
    debugPrint("STRICT LOG [Uncaught Exception]: $error");
  });
}

// ... other imports ...

class SafetyApp extends ConsumerWidget {
  const SafetyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);

    ThemeData lightTheme = AppTheme.lightTheme;
    ThemeData darkTheme = AppTheme.darkTheme;
    ThemeMode flutterThemeMode = ThemeMode.system;

    switch (themeMode) {
      case AppThemeMode.light:
        flutterThemeMode = ThemeMode.light;
        break;
      case AppThemeMode.dark:
        flutterThemeMode = ThemeMode.dark;
        break;
      case AppThemeMode.system:
        flutterThemeMode = ThemeMode.system;
        break;
      case AppThemeMode.safety:
        flutterThemeMode = ThemeMode.light;
        lightTheme = AppTheme.safetyTheme;
        darkTheme = AppTheme.safetyTheme;
        break;
      case AppThemeMode.premium:
        flutterThemeMode = ThemeMode.dark;
        lightTheme = AppTheme.premiumTheme;
        darkTheme = AppTheme.premiumTheme;
        break;
    }

    return MaterialApp(
      title: 'RAKSHAK',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: flutterThemeMode,
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late Future<void> _initServicesFuture;

  @override
  void initState() {
    super.initState();
    _initServicesFuture = _initServices();
  }

  Future<void> _initServices() async {
    // Run these concurrently if possible, or sequentially
    await Hive.initFlutter();
    await SecureStorageService().init();
    await OfflineQueueService().init();
    await BackgroundService.initializeService();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initServicesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          // Beautiful smooth splash screen while loading
          return const Scaffold(
            backgroundColor: AppColors.primaryGreen,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shield_outlined, color: Colors.white, size: 80),
                  SizedBox(height: 24),
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    "RAKSHAK",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0,
                    ),
                  )
                ],
              ),
            ),
          );
        }

        // Once services are loaded, listen to Auth state
        return StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: AppColors.primaryGreen,
                body: Center(
                    child: CircularProgressIndicator(color: Colors.white)),
              );
            }
            if (authSnapshot.hasData) {
              return const HomeScreen();
            }
            return const LoginScreen();
          },
        );
      },
    );
  }
}

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const platform = MethodChannel('com.safety.app/trigger');
  String _displayName = "User";
  String _email = "";

  // ── Map State ──
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng? _currentLatLng;
  Set<Marker> _markers = {};
  StreamSubscription<Position>? _positionStream;

  // Sleek dark map style
  static const String _darkMapStyle = '''
  [
    {"elementType": "geometry", "stylers": [{"color": "#1d2c4d"}]},
    {"elementType": "labels.text.fill", "stylers": [{"color": "#8ec3b9"}]},
    {"elementType": "labels.text.stroke", "stylers": [{"color": "#1a3646"}]},
    {"featureType": "administrative.country", "elementType": "geometry.stroke", "stylers": [{"color": "#4b6878"}]},
    {"featureType": "administrative.land_parcel", "elementType": "labels.text.fill", "stylers": [{"color": "#64779e"}]},
    {"featureType": "landscape.man_made", "elementType": "geometry.stroke", "stylers": [{"color": "#334e87"}]},
    {"featureType": "landscape.natural", "elementType": "geometry", "stylers": [{"color": "#023e58"}]},
    {"featureType": "poi", "elementType": "geometry", "stylers": [{"color": "#283d6a"}]},
    {"featureType": "poi", "elementType": "labels.text.fill", "stylers": [{"color": "#6f9ba5"}]},
    {"featureType": "poi.park", "elementType": "geometry.fill", "stylers": [{"color": "#023e58"}]},
    {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#304a7d"}]},
    {"featureType": "road", "elementType": "labels.text.fill", "stylers": [{"color": "#98a5be"}]},
    {"featureType": "road.highway", "elementType": "geometry", "stylers": [{"color": "#2c6675"}]},
    {"featureType": "road.highway", "elementType": "geometry.stroke", "stylers": [{"color": "#255763"}]},
    {"featureType": "transit", "elementType": "labels.text.fill", "stylers": [{"color": "#98a5be"}]},
    {"featureType": "water", "elementType": "geometry.fill", "stylers": [{"color": "#0e1626"}]},
    {"featureType": "water", "elementType": "labels.text.fill", "stylers": [{"color": "#4e6d70"}]}
  ]
  ''';

  @override
  void initState() {
    super.initState();
    _loadUser();
    _initMapLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowDisclosure();
    });

    platform.setMethodCallHandler((call) async {
      if (call.method == 'triggerEmergency') {
        if (mounted) {
          Navigator.push(context,
              CupertinoPageRoute(builder: (_) => const EmergencyScreen()));
          ref.read(emergencyViewModelProvider.notifier).triggerEmergency();
        }
      }
    });
  }

  void _loadUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _displayName = user.displayName?.split(' ').first ?? "User";
        _email = user.email ?? "";
      });
    }
  }

  Future<void> _initMapLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      Position pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        _updateMapPosition(LatLng(pos.latitude, pos.longitude));
      }

      _positionStream = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).listen((Position position) {
        if (mounted) {
          _updateMapPosition(LatLng(position.latitude, position.longitude));
        }
      });
    } catch (_) {
      // fail silently – map just won't render until location is available
    }
  }

  void _updateMapPosition(LatLng position) {
    setState(() {
      _currentLatLng = position;
      _markers = {
        Marker(
          markerId: const MarkerId('myLocation'),
          position: position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'You are here'),
        ),
      };
    });
    if (_mapController.isCompleted) {
      _mapController.future.then((controller) {
        controller.animateCamera(CameraUpdate.newLatLng(position));
      });
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }

  Future<void> _checkAndShowDisclosure() async {
    final prefs = await SharedPreferences.getInstance();
    final hasAgreed = prefs.getBool('has_agreed_disclosure') ?? false;

    if (!hasAgreed) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Permissions Required"),
          content: const Text(
              "RAKSHAK collects location data to enable emergency alerts and "
              "track your device even when the app is closed or not in use. "
              "It also requires SMS permission to send alerts to your contacts, "
              "and Microphone/Camera to record evidence."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text("DENY"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await prefs.setBool('has_agreed_disclosure', true);
                _requestPermissions();
              },
              child: const Text("I AGREE"),
            ),
          ],
        ),
      );
    } else {
      _requestPermissions(); // Silently check/request
    }
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.microphone,
      Permission.location,
      Permission.sms,
      Permission.camera,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: _buildDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Custom Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Hamburger Menu
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF161b17),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.menu_rounded, size: 26),
                      onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                    ),
                  ),
                  // Center Logo
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryGreen,
                              AppColors.primaryGreen.withValues(alpha: 0.6),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGreen.withValues(alpha: 0.3),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.shield, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "RAKSHAK",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  // Notification Bell
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF161b17),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.notifications_outlined, size: 24),
                      onPressed: () {},
                    ),
                  ),
                ],
              )
                  .animate(delay: 200.ms)
                  .fade(duration: 400.ms)
                  .slideY(begin: -0.2),
              const SizedBox(height: 16),

              // ── Guardian Status Bar ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Pulsing green dot
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryGreen,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryGreen.withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .fade(begin: 0.4, end: 1.0, duration: 1200.ms),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        "Guardian: ",
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Text(
                      "Active",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryGreen,
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Text(
                        "Hi, $_displayName",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )
                  .animate(delay: 250.ms)
                  .fade(duration: 300.ms)
                  .slideX(begin: -0.1),
              const SizedBox(height: 20),

              // Warning Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: AppColors.warning),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "This app is a safety-support tool designed to improve emergency response time. It does not replace official emergency services.",
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.7),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate(delay: 300.ms).fade().slideX(begin: 0.1),
              const SizedBox(height: 20),

              // Emergency Mode Card
              _buildBigCard(
                title: "Emergency Mode",
                subtitle:
                    "Activate when you need help.\nAuto-records evidence and alerts your contacts.",
                actionText: 'Say "Help" or "Emergency"',
                icon: Icons.shield_outlined,
                color: AppColors.primaryGreen,
                onTap: () => Navigator.push(context,
                    CupertinoPageRoute(builder: (_) => const EmergencyScreen())),
              ).animate(delay: 400.ms).fade().scale(),
              const SizedBox(height: 16),

              // Witness Mode Card
              _buildBigCard(
                title: "Witness Mode",
                subtitle:
                    "Report crimes or incidents you witness.\nHelp others safely.",
                actionText: 'Say "Witness Mode"',
                icon: Icons.remove_red_eye_outlined,
                color: AppColors.primaryGreen,
                onTap: () => Navigator.push(context,
                    CupertinoPageRoute(builder: (_) => const WitnessScreen())),
              ).animate(delay: 500.ms).fade().scale(),
              const SizedBox(height: 16),

              // Bottom Grid Cards
              Row(
                children: [
                  Expanded(
                    child: _buildInteractiveSquareCard(
                      title: "Emergency\nContacts",
                      icon: Icons.people_outline,
                      statusText: "CONTACTS VERIFIED",
                      onTap: () => Navigator.push(
                          context,
                          CupertinoPageRoute(
                              builder: (_) => const EmergencyContactsScreen())),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildInteractiveSquareCard(
                      title: "Incident\nHistory",
                      icon: Icons.history,
                      statusText: "NO RECENT ACTIVITY",
                      onTap: () => Navigator.push(
                          context,
                          CupertinoPageRoute(
                              builder: (_) => const IncidentHistoryScreen())),
                    ),
                  ),
                ],
              ).animate(delay: 600.ms).fade().slideY(begin: 0.2),
              const SizedBox(height: 20),
              // ── "Your Perimeter" Section Header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Your Perimeter",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryGreen,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGreen.withValues(alpha: 0.5),
                              blurRadius: 6,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .fade(begin: 0.3, end: 1.0, duration: 1000.ms),
                      const SizedBox(width: 6),
                      Text(
                        "Live Status",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryGreen.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ],
              ).animate(delay: 650.ms).fade(),
              const SizedBox(height: 12),
              // ── Embedded Live Map Preview ──
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (_) => const LiveLocationMapScreen(),
                  ),
                ),
                child: Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.15),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      // Map or loading placeholder
                      if (_currentLatLng != null)
                        AbsorbPointer(
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _currentLatLng!,
                              zoom: 15.0,
                            ),
                            markers: _markers,
                            style: _darkMapStyle,
                            myLocationEnabled: false,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            compassEnabled: false,
                            mapToolbarEnabled: false,
                            liteModeEnabled: false,
                            onMapCreated: (GoogleMapController controller) {
                              if (!_mapController.isCompleted) {
                                _mapController.complete(controller);
                              }
                            },
                          ),
                        )
                      else
                        Container(
                          color: const Color(0xFF1d2c4d),
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  color: AppColors.primaryGreen,
                                  strokeWidth: 2.5,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Acquiring location...',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Top gradient overlay
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: 50,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.5),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10,
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                color: AppColors.primaryGreen,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Live Location',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Bottom "View Full Map" overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.7),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Tap to open full map',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryGreen,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.open_in_full_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'View Full Map',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(delay: 700.ms).fade().slideY(begin: 0.2),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      // ── Bottom Navigation Bar ──
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0b0f0c),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded, "Home", true, () {}),
                _buildNavItem(Icons.shield_outlined, "Safety", false, () {
                  Navigator.push(context,
                      CupertinoPageRoute(builder: (_) => const EmergencyScreen()));
                }),
                _buildNavItem(Icons.history_rounded, "History", false, () {
                  Navigator.push(context,
                      CupertinoPageRoute(builder: (_) => const IncidentHistoryScreen()));
                }),
                _buildNavItem(Icons.person_outline_rounded, "Profile", false, () {
                  Navigator.push(context,
                      CupertinoPageRoute(builder: (_) => const UserProfileScreen()));
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primaryGreen, Color(0xFF1B5E20)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.shield, color: Colors.white, size: 48),
                const SizedBox(height: 12),
                const Text(
                  "RAKSHAK User",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _email.isNotEmpty ? _email : "Ready to protect.",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading:
                const Icon(Icons.info_outline, color: AppColors.primaryGreen),
            title: const Text('App Features'),
            onTap: () {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("RAKSHAK Features"),
                  content: const SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("🛡️ Emergency Mode:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                            "Tap the red button or say 'Help' / 'Bachao'. The app instantly records audio, gets your location, finds the nearest police station, and texts your contacts.\n"),
                        Text("👁️ Witness Mode:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                            "Record crimes securely. Videos are uploaded silently to the cloud without saving to your local gallery.\n"),
                        Text("🔊 Voice Activation:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                            "RAKSHAK listens in the background for keywords like 'Emergency' or 'Help'.\n"),
                        Text("⚡ Power Button SOS:",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                            "Press the screen on/off 3 times rapidly to trigger silent SOS."),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text("Got it"))
                  ],
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading:
                const Icon(Icons.person_outline, color: AppColors.primaryGreen),
            title: const Text('User Profile'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserProfileScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.warning),
            title: const Text('Logout'),
            onTap: () {
              Navigator.pop(context);
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBigCard({
    required String title,
    required String subtitle,
    required String actionText,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 36),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                actionText,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primaryGreen.withValues(alpha: 0.15)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 24,
              color: isActive
                  ? AppColors.primaryGreen
                  : Colors.grey.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              color: isActive
                  ? AppColors.primaryGreen
                  : Colors.grey.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractiveSquareCard({
    required String title,
    required IconData icon,
    required String statusText,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF161b17),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Icon with glowing background
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen.withValues(alpha: 0.12),
              ),
              child: Icon(icon, color: AppColors.primaryGreen, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              statusText,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen.withValues(alpha: 0.7),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

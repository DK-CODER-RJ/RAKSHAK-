import 'package:go_router/go_router.dart';

// Import screens using package imports after move to lib/
import 'package:rakshak/frontend/person_a_mobile_ui/lib/screens/splash_screen.dart';
import 'package:rakshak/frontend/person_a_mobile_ui/lib/screens/onboarding_screen.dart';
import 'package:rakshak/frontend/person_a_mobile_ui/lib/screens/home_dashboard.dart';
import 'package:rakshak/frontend/person_a_mobile_ui/lib/screens/sos_trigger_screen.dart';
import 'package:rakshak/frontend/person_a_mobile_ui/lib/screens/witness_mode_screen.dart';
import 'package:rakshak/frontend/person_a_mobile_ui/lib/screens/contacts_manager.dart';
import 'package:rakshak/frontend/person_a_mobile_ui/lib/screens/safe_zones_screen.dart';
import 'package:rakshak/frontend/person_a_mobile_ui/lib/screens/settings_screen.dart';
import 'package:rakshak/frontend/person_a_mobile_ui/lib/screens/incident_history_screen.dart';
import 'package:rakshak/frontend/person_a_mobile_ui/lib/screens/login_screen.dart';
import 'package:rakshak/frontend/person_a_mobile_ui/lib/screens/signup_screen.dart';

/// App Router — Centralized navigation using GoRouter.
class AppRouter {
  AppRouter._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String sos = '/sos';
  static const String witness = '/witness';
  static const String contacts = '/contacts';
  static const String safezones = '/safezones';
  static const String settings = '/settings';
  static const String history = '/history';
  static const String login = '/login';
  static const String signup = '/signup';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(
        path: splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: home,
        builder: (context, state) => const HomeDashboard(),
      ),
      GoRoute(
        path: sos,
        builder: (context, state) => const SosTriggerScreen(),
      ),
      GoRoute(
        path: witness,
        builder: (context, state) => const WitnessModeScreen(),
      ),
      GoRoute(
        path: contacts,
        builder: (context, state) => const ContactsManager(),
      ),
      GoRoute(
        path: safezones,
        builder: (context, state) => const SafeZonesScreen(),
      ),
      GoRoute(
        path: settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: history,
        builder: (context, state) => const IncidentHistoryScreen(),
      ),
      GoRoute(
        path: login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: signup,
        builder: (context, state) => const SignUpScreen(),
      ),
    ],
  );
}

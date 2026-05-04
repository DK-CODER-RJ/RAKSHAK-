import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:rakshak/frontend/person_b_navigation_state/lib/navigation/app_router.dart';

/// Deep Link Handler — Handles incoming deep links and dynamic links.
class DeepLinkHandler {
  /// Initialize deep link listener
  static Future<void> initialize() async {
    // Check if the app was opened via a dynamic link
    final PendingDynamicLinkData? initialLink = await FirebaseDynamicLinks.instance.getInitialLink();
    if (initialLink != null) {
      _handleLink(initialLink.link);
    }

    // Listen for incoming dynamic links while the app is in foreground/background
    FirebaseDynamicLinks.instance.onLink.listen((PendingDynamicLinkData dynamicLinkData) {
      _handleLink(dynamicLinkData.link);
    }).onError((error) {
      // Handle error
    });
  }

  static void _handleLink(Uri link) {
    if (link.path.contains('/track/')) {
      final eventId = link.pathSegments.last;
      handleTrackingLink(eventId);
    } else if (link.path.contains('/evidence/')) {
      final witnessId = link.pathSegments.last;
      handleEvidenceLink(witnessId);
    }
  }

  /// Handle SOS tracking link: rakshak://track/{eventId}
  static void handleTrackingLink(String eventId) {
    AppRouter.router.push('${AppRouter.home}?eventId=$eventId');
  }

  /// Handle witness evidence link: rakshak://evidence/{witnessId}
  static void handleEvidenceLink(String witnessId) {
    AppRouter.router.push('${AppRouter.history}?witnessId=$witnessId');
  }
}

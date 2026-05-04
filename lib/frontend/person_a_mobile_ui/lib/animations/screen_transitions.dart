import 'package:flutter/cupertino.dart';

/// Screen transition utilities — smooth CupertinoPageRoute transitions.
class ScreenTransitions {
  ScreenTransitions._();

  /// Standard iOS-style push transition.
  static Route<T> slideRight<T>(Widget page) {
    return CupertinoPageRoute(builder: (_) => page);
  }

  /// Fade transition for modal screens.
  static Route<T> fade<T>(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Slide up transition for emergency screens.
  static Route<T> slideUp<T>(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}

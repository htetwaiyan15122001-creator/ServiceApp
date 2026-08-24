import 'package:flutter/material.dart';

/// A subtle slide-up + fade transition, used in place of the default
/// [MaterialPageRoute] for the app's main navigation flows so screen
/// changes feel intentional instead of an instant cut.
class AppRoute {
  AppRoute._();

  static Route<T> to<T>(Widget page) {
    return PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  /// Same transition, but replaces the current route (used for
  /// login -> dashboard and bottom-nav tab switches).
  static Route<T> replace<T>(Widget page) => to<T>(page);
}

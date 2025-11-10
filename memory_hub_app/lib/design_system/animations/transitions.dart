import 'package:flutter/material.dart';
import '../tokens/duration_tokens.dart';
import 'motion.dart';

/// Fade route transition
Route fadeRoute(Widget page, {RouteSettings? settings}) {
  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: Durations.base,
    reverseTransitionDuration: Durations.base,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}

/// Slide route transition (from right)
Route slideRoute(Widget page, {RouteSettings? settings}) {
  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: Durations.slow,
    reverseTransitionDuration: Durations.slow,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      final tween = Tween(begin: begin, end: end);
      final offsetAnimation = animation.drive(
        tween.chain(CurveTween(curve: Motion.emphasized)),
      );

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );
}

/// Scale route transition
Route scaleRoute(Widget page, {RouteSettings? settings}) {
  return PageRouteBuilder(
    settings: settings,
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: Durations.base,
    reverseTransitionDuration: Durations.base,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return ScaleTransition(
        scale: Tween<double>(begin: 0.9, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Motion.decelerate,
          ),
        ),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      );
    },
  );
}

/// Page transitions theme for MaterialApp
PageTransitionsTheme buildPageTransitionsTheme() {
  return const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: CupertinoPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    },
  );
}

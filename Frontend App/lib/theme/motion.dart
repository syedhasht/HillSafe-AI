import 'package:flutter/material.dart';

class HillSafePageTransitionsBuilder extends PageTransitionsBuilder {
  const HillSafePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.settings.name == Navigator.defaultRouteName) {
      return child;
    }

    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    // Light, hardware-accelerated fade and subtle horizontal slide transition
    return FadeTransition(
      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(curved),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.08, 0.0), // subtle horizontal slide from the right
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

class HillSafeScrollBehavior extends MaterialScrollBehavior {
  const HillSafeScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}

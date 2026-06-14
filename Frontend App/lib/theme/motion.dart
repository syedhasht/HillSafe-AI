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
      reverseCurve: Curves.easeOutCubic,
    );

    return FadeTransition(
      opacity: Tween<double>(begin: 0.96, end: 1).animate(curved),
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.995, end: 1).animate(curved),
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

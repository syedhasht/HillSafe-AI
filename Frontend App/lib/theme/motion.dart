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

    final theme = Theme.of(context);
    final platform = theme.platform;

    // Use CupertinoPageTransitionsBuilder for Apple platforms (native slide-in with swipe-back support)
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return CupertinoPageTransitionsBuilder().buildTransitions(
        route,
        context,
        animation,
        secondaryAnimation,
        child,
      );
    }

    // Use ZoomPageTransitionsBuilder for Android and desktop platforms (native Material zoom-in/fade)
    return ZoomPageTransitionsBuilder().buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
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

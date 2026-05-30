import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:frontend_app/services/api_service.dart';
import 'package:frontend_app/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:frontend_app/theme/theme_provider.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final results = await Future.wait([
      Future.delayed(const Duration(milliseconds: 1800)),
      _getDestinationRoute(),
    ]);
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(results[1] as String);
  }

  Future<String> _getDestinationRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      if (isLoggedIn) {
        final token = await ApiService().getToken();
        if (token != null && token.isNotEmpty) {
          final userType = prefs.getString('userType') ?? '';
          if (userType == 'authority') return '/authority_dashboard';
          if (userType == 'community') return '/community_dashboard';
        }
      }
    } catch (_) {}
    return '/role_selection';
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Scaffold(
        backgroundColor: AppTheme.lightBackground,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo circle
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.lightSurface,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/Logo.jpeg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppTheme.accentTeal,
                      child: const Center(
                        child: Icon(
                          Icons.landscape,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    );
                  },
                ),
              ),
            )
                .animate()
                .scale(
                  duration: 700.ms,
                  curve: Curves.easeOutBack,
                  begin: const Offset(0.7, 0.7),
                )
                .fadeIn(duration: 500.ms),

            const SizedBox(height: 32),

            Text(
              'HillSafe AI',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.lightTextPrimary,
                letterSpacing: -0.5,
              ),
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 500.ms)
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: 6),

            Text(
              'Disaster Early Warning System',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.lightTextSecondary,
                letterSpacing: 0.5,
              ),
            ).animate().fadeIn(delay: 450.ms, duration: 500.ms),

            const SizedBox(height: 56),

            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppTheme.accentTeal),
              ),
            ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
          ],
        ),
      ),
    ),
  );
}
}

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_app/screens/splash_screen.dart';
import 'package:frontend_app/screens/auth/login_screen.dart';
import 'package:frontend_app/screens/auth/authority_signup_screen.dart';
import 'package:frontend_app/screens/auth/authority_dashboard.dart';
import 'package:frontend_app/screens/auth/resident_login_screen.dart';
import 'package:frontend_app/screens/community/community_dashboard.dart';
import 'package:frontend_app/screens/role_selection_screen.dart';
import 'package:frontend_app/theme/app_theme.dart';
import 'package:frontend_app/theme/theme_provider.dart';
import 'package:frontend_app/providers/language_provider.dart';
import 'package:frontend_app/providers/user_provider.dart';
import 'package:frontend_app/providers/safety_controller.dart';

// Maps
import 'package:frontend_app/screens/maps/authority_map_screen.dart';
import 'package:frontend_app/screens/community/risk_map_screen.dart';

// Dashboard Authority
import 'package:frontend_app/screens/dashboard_authority/regional_summary_screen.dart';
import 'package:frontend_app/screens/dashboard_authority/analytics_trends_screen.dart';
import 'package:frontend_app/screens/dashboard_authority/district_detail_screen.dart';
import 'package:frontend_app/screens/dashboard_authority/resident_reports_screen.dart';

// Alerts
import 'package:frontend_app/screens/alerts/alert_management_screen.dart';
import 'package:frontend_app/screens/alerts/alert_feed_screen.dart';
import 'package:frontend_app/screens/alerts/alert_detail_screen.dart';

// Safety
import 'package:frontend_app/screens/safety/safety_guidelines_screen.dart';
import 'package:frontend_app/screens/safety/safety_topic_detail.dart';
import 'package:frontend_app/screens/safety/report_incident_screen.dart';

// Settings
import 'package:frontend_app/screens/settings/settings_screen.dart';
import 'package:frontend_app/screens/settings/language_selection_screen.dart';
import 'package:frontend_app/screens/settings/about_project_screen.dart';
import 'package:frontend_app/screens/settings/privacy_policy_screen.dart';
import 'package:frontend_app/screens/assistant/hillsafe_assistant_screen.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Preload theme preferences to prevent white flash
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;

  // Create and initialize SafetyController
  final safetyController = SafetyController();
  // Don't await here to prevent blocking app startup (especially for permissions)
  safetyController.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(initialIsDark: isDarkMode)),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider.value(value: safetyController),
      ],
      child: const HillSafeApp(),
    ),
  );
}

class HillSafeApp extends StatelessWidget {
  const HillSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = context.select<UserProvider, bool>(
      (provider) => provider.isLoggedIn,
    );

    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, child) {
        return MaterialApp(
          title: 'HillSafe AI',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          themeAnimationDuration: Duration.zero,
          themeAnimationCurve: Curves.linear,
          home: const SplashScreen(),
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            final clampedScaler = mediaQuery.textScaler.clamp(
              minScaleFactor: 0.9,
              maxScaleFactor: 1.15,
            );

            // Dynamically set system status bar and navigation bar styles reactively
            SystemChrome.setSystemUIOverlayStyle(
              SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: themeProvider.isDarkMode ? Brightness.light : Brightness.dark,
                statusBarBrightness: themeProvider.isDarkMode ? Brightness.dark : Brightness.light,
                systemNavigationBarColor: themeProvider.isDarkMode ? const Color(0xFF0F172A) : const Color(0xFFF5F4F0),
                systemNavigationBarIconBrightness: themeProvider.isDarkMode ? Brightness.light : Brightness.dark,
              ),
            );

            return Directionality(
              textDirection: languageProvider.isUrdu && isLoggedIn
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: MediaQuery(
                data: mediaQuery.copyWith(textScaler: clampedScaler),
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
          routes: {
            // Auth & Role
            '/role_selection': (context) => const RoleSelectionScreen(),
            '/resident_login': (context) => const ResidentLoginScreen(),
            '/login': (context) => const LoginScreen(),
            '/authority_signup': (context) => const AuthoritySignupScreen(),
            '/community_dashboard': (context) => const CommunityDashboard(),
            '/authority_dashboard': (context) => const AuthorityDashboard(),

            // Maps
            '/authority_map': (context) => const AuthorityMapScreen(),
            '/community_map': (context) => const RiskMapScreen(),

            // Dashboard Authority
            '/regional_summary': (context) => const RegionalSummaryScreen(),
            '/analytics_trends': (context) => const AnalyticsTrendsScreen(),
            '/district_detail': (context) => const DistrictDetailScreen(),
            '/resident_reports': (context) => const ResidentReportsScreen(),

            // Alerts
            '/alert_management': (context) => const AlertManagementScreen(),
            '/alert_feed': (context) => const AlertFeedScreen(),
            '/alert_detail': (context) => const AlertDetailScreen(),

            // Safety
            '/safety_guidelines': (context) => const SafetyGuidelinesScreen(),
            '/safety_topic': (context) => const SafetyTopicDetail(),
            '/report_incident': (context) => const ReportIncidentScreen(),

            // Settings
            '/settings': (context) => const SettingsScreen(),
            '/language_selection': (context) => const LanguageSelectionScreen(),
            '/about': (context) => const AboutProjectScreen(),
            '/privacy_policy': (context) => const PrivacyPolicyScreen(),
            '/assistant': (context) => const HillSafeAssistantScreen(),
          },
        );
      },
    );
  }
}

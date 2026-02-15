import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_2/screens/splash_screen.dart';
import 'package:flutter_application_2/screens/auth/login_screen.dart';
import 'package:flutter_application_2/screens/auth/authority_dashboard.dart';
import 'package:flutter_application_2/screens/auth/resident_login_screen.dart';
import 'package:flutter_application_2/screens/community/community_dashboard.dart';
import 'package:flutter_application_2/screens/role_selection_screen.dart';
import 'package:flutter_application_2/theme/app_theme.dart';
import 'package:flutter_application_2/theme/theme_provider.dart';
import 'package:flutter_application_2/providers/language_provider.dart';
import 'package:flutter_application_2/providers/user_provider.dart';
import 'package:flutter_application_2/providers/safety_controller.dart';

// Maps
import 'package:flutter_application_2/screens/maps/authority_map_screen.dart';
import 'package:flutter_application_2/screens/community/risk_map_screen.dart';

// Dashboard Authority
import 'package:flutter_application_2/screens/dashboard_authority/regional_summary_screen.dart';
import 'package:flutter_application_2/screens/dashboard_authority/analytics_trends_screen.dart';
import 'package:flutter_application_2/screens/dashboard_authority/district_detail_screen.dart';
import 'package:flutter_application_2/screens/dashboard_authority/resident_reports_screen.dart';

// Alerts
import 'package:flutter_application_2/screens/alerts/alert_management_screen.dart';
import 'package:flutter_application_2/screens/alerts/alert_feed_screen.dart';
import 'package:flutter_application_2/screens/alerts/alert_detail_screen.dart';

// Safety
import 'package:flutter_application_2/screens/safety/safety_guidelines_screen.dart';
import 'package:flutter_application_2/screens/safety/safety_topic_detail.dart';
import 'package:flutter_application_2/screens/safety/report_incident_screen.dart';

// Settings
import 'package:flutter_application_2/screens/settings/settings_screen.dart';
import 'package:flutter_application_2/screens/settings/language_selection_screen.dart';
import 'package:flutter_application_2/screens/settings/about_project_screen.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Create and initialize SafetyController
  final safetyController = SafetyController();
  // Don't await here to prevent blocking app startup (especially for permissions)
  safetyController.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
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
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'HillSafe AI',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
          routes: {
            // Auth & Role
            '/role_selection': (context) => const RoleSelectionScreen(),
            '/resident_login': (context) => const ResidentLoginScreen(),
            '/login': (context) => const LoginScreen(),
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
          },
        );
      },
    );
  }
}

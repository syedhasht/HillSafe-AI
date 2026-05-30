import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend_app/theme/app_theme.dart';

class PrivacyPolicyScreen extends StatefulWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  State<PrivacyPolicyScreen> createState() => _PrivacyPolicyScreenState();
}

class _PrivacyPolicyScreenState extends State<PrivacyPolicyScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 230,
            backgroundColor: AppTheme.primaryDark,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(56, 0, 20, 16),
              centerTitle: false,
              title: const Text(
                'Privacy Policy',
                textAlign: TextAlign.left,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF102033), Color(0xFF2A7D6F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -40,
                      top: 20,
                      child: Icon(
                        LucideIcons.shieldCheck,
                        size: 180,
                        color: Colors.white.withOpacity(0.08),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 70,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 58,
                            height: 58,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.22),
                              ),
                            ),
                            child: const Icon(
                              LucideIcons.lockKeyhole,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'How HillSafe AI protects your data',
                            style: theme.titleMedium?.copyWith(
                              color: Colors.white.withOpacity(0.92),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Effective date: May 30, 2026',
                            style: theme.bodySmall?.copyWith(
                              color: Colors.white.withOpacity(0.72),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: AppTheme.cardShadow,
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppTheme.accentTealLight,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            LucideIcons.badgeInfo,
                            color: AppTheme.accentTeal,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'HillSafe AI supports safety awareness and early warnings. It does not replace official government warnings, emergency services, geological surveys, disaster management authorities, or professional safety advice.',
                            style: theme.bodyMedium?.copyWith(
                              color: AppTheme.textSecondary,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            sliver: SliverList.separated(
              itemCount: _policySections.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final section = _policySections[index];
                return _PolicySectionCard(
                  key: ValueKey(section.title),
                  number: index + 1,
                  section: section,
                ).animate().fadeIn(duration: 350.ms, delay: (index * 25).ms);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicySectionCard extends StatelessWidget {
  const _PolicySectionCard({
    super.key,
    required this.number,
    required this.section,
  });

  final int number;
  final _PolicySection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: section.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(section.icon, color: section.color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$number. ${section.title}',
                      style: theme.titleMedium?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      section.subtitle,
                      style: theme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            section.body,
            style: theme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
              height: 1.52,
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicySection {
  const _PolicySection({
    required this.shortTitle,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.icon,
    required this.color,
  });

  final String shortTitle;
  final String title;
  final String subtitle;
  final String body;
  final IconData icon;
  final Color color;
}

const List<_PolicySection> _policySections = [
  _PolicySection(
    shortTitle: 'Intro',
    title: 'Introduction',
    subtitle: 'Purpose of this policy',
    icon: LucideIcons.shield,
    color: AppTheme.accentTeal,
    body:
        'HillSafe AI is a landslide-risk warning and safety application for mountainous and landslide-prone regions of Pakistan. It provides location-based landslide risk predictions, weather-based alerts, monitored region information, incident reporting, safety status updates, and emergency-related community features. By using HillSafe AI, you agree to the practices described in this policy.',
  ),
  _PolicySection(
    shortTitle: 'Data',
    title: 'Information We Collect',
    subtitle: 'Account, location, weather, reports, and settings data',
    icon: LucideIcons.database,
    color: Color(0xFF2563EB),
    body:
        'We may collect phone number, username or display name, email address if provided, login or session information, and user role. We may also collect GPS latitude and longitude, nearby monitored region, location-based risk score, environmental data linked to your location, Firebase device token, notification preference, incident reports, safety status, selected language, profile settings, API logs, error logs, device type, operating system information, request times, and general usage activity.',
  ),
  _PolicySection(
    shortTitle: 'Use',
    title: 'How We Use Your Information',
    subtitle: 'Risk prediction, alerts, reports, accounts, and security',
    icon: LucideIcons.workflow,
    color: Color(0xFF7C3AED),
    body:
        'HillSafe AI uses collected information to provide landslide risk predictions, show monitored region risk, send safety alerts, support incident reporting, manage user accounts, save user preferences, improve app speed and reliability, monitor backend performance, improve the user experience, and protect the platform from misuse or unauthorized access.',
  ),
  _PolicySection(
    shortTitle: 'Prediction',
    title: 'How Landslide Risk Prediction Works',
    subtitle: 'Machine learning estimate, not a guaranteed warning',
    icon: LucideIcons.brainCircuit,
    color: Color(0xFF0891B2),
    body:
        'The app sends your location to the backend, where weather, elevation, slope, soil, and other environmental information may be combined. A trained machine learning model calculates a landslide-risk score. This score is an estimate and should be treated as a safety-support tool, not a guaranteed prediction. Always follow official alerts and instructions from local authorities and emergency services.',
  ),
  _PolicySection(
    shortTitle: 'Services',
    title: 'External Services Used',
    subtitle: 'Weather, terrain, soil, notifications, hosting, and database',
    icon: LucideIcons.cloudCog,
    color: Color(0xFF0F766E),
    body:
        'HillSafe AI may use OpenWeather for rainfall, temperature, snow, and humidity; OpenTopoData for elevation; SoilGrids for soil texture; Firebase for push notifications and device tokens; Render for backend hosting; and Neon PostgreSQL for database storage. These services may process limited information required for their functionality.',
  ),
  _PolicySection(
    shortTitle: 'Sharing',
    title: 'How We Share Information',
    subtitle: 'Limited sharing for app functionality and safety',
    icon: LucideIcons.share2,
    color: Color(0xFFEA580C),
    body:
        'HillSafe AI does not sell user personal information. Information may be processed by backend and database services, used with environmental data providers to request weather or terrain data, processed by notification services, shown to authorized dashboards for safety features, or disclosed when required by law, regulation, legal process, or emergency safety concerns.',
  ),
  _PolicySection(
    shortTitle: 'Storage',
    title: 'Data Storage',
    subtitle: 'Secure backend database and cached terrain data',
    icon: LucideIcons.server,
    color: Color(0xFF475569),
    body:
        'HillSafe AI may store user account details, region risk scores, terrain samples, safety status, incident reports, device tokens, app preferences, and API-related records in a secure database connected to the backend system. Some terrain and environmental data may be cached to reduce repeated calls to external APIs and improve performance.',
  ),
  _PolicySection(
    shortTitle: 'Retention',
    title: 'Data Retention',
    subtitle: 'Stored only as long as needed',
    icon: LucideIcons.clock3,
    color: Color(0xFF9333EA),
    body:
        'We retain information only as long as necessary to provide app services, maintain safety records, support reports and analytics, meet legal or operational requirements, and improve system reliability. Some records, such as incident reports or safety status logs, may be retained longer if needed for safety, authority review, or disaster-management analysis.',
  ),
  _PolicySection(
    shortTitle: 'Location',
    title: 'Location Data Policy',
    subtitle: 'Used for risk, maps, reports, and regional analysis',
    icon: LucideIcons.mapPin,
    color: Color(0xFFDC2626),
    body:
        'Location data is important for HillSafe AI core functionality. The app may request location access to calculate user-specific risk, find the nearest monitored region, display map-based risk information, support incident reports, and improve regional safety analysis. Users can control location permissions in device settings. If location permission is disabled, some features may not work correctly.',
  ),
  _PolicySection(
    shortTitle: 'Alerts',
    title: 'Push Notifications',
    subtitle: 'Safety alerts and important updates',
    icon: LucideIcons.bellRing,
    color: Color(0xFFF59E0B),
    body:
        'HillSafe AI may send push notifications when risk levels increase, a region becomes unsafe, safety alerts are available, or important app and emergency updates are sent. Users can enable or disable push notifications from app settings or device settings. If notifications are disabled, users may miss important safety alerts.',
  ),
  _PolicySection(
    shortTitle: 'Rights',
    title: 'User Rights and Choices',
    subtitle: 'Access, correction, permissions, and deletion requests',
    icon: LucideIcons.userCheck,
    color: Color(0xFF16A34A),
    body:
        'Depending on applicable laws and app functionality, users may access personal information, correct inaccurate information, update profile or settings information, disable location permissions, disable push notifications, request deletion of personal data, withdraw consent for certain data uses, or stop using the app. Some features may become limited if required permissions are disabled.',
  ),
  _PolicySection(
    shortTitle: 'Security',
    title: 'Security Measures',
    subtitle: 'Reasonable technical and organizational safeguards',
    icon: LucideIcons.lockKeyhole,
    color: Color(0xFF0284C7),
    body:
        'HillSafe AI aims to protect user information through secure backend communication, protected database access, environment-based secret management, avoiding public exposure of API keys and secret files, controlled backend access, secure storage of sensitive configuration values, and monitoring of backend errors and issues. No system is completely secure, so absolute security cannot be guaranteed.',
  ),
  _PolicySection(
    shortTitle: 'Children',
    title: 'Children Privacy',
    subtitle: 'Use by minors should be supervised',
    icon: LucideIcons.usersRound,
    color: Color(0xFFDB2777),
    body:
        'HillSafe AI is intended for general safety and community awareness. If used by minors, it should be used under the guidance of a parent, guardian, school, authority, or responsible adult. We do not knowingly collect unnecessary personal information from children. A parent or guardian may contact HillSafe AI for review or deletion concerns.',
  ),
  _PolicySection(
    shortTitle: 'Disclaimer',
    title: 'Accuracy and Safety Disclaimer',
    subtitle: 'Predictions can be affected by many limitations',
    icon: LucideIcons.shieldAlert,
    color: Color(0xFFB91C1C),
    body:
        'HillSafe AI provides estimated landslide-risk information using available weather, terrain, and machine learning data. It cannot guarantee that a landslide will or will not occur. Predictions may be affected by inaccurate GPS location, delayed weather updates, missing terrain data, external API limitations, model limitations, sudden environmental changes, connectivity issues, backend downtime, or device permission restrictions.',
  ),
  _PolicySection(
    shortTitle: 'Third Party',
    title: 'Third-Party Links and Services',
    subtitle: 'External services have their own policies',
    icon: LucideIcons.externalLink,
    color: Color(0xFF4F46E5),
    body:
        'HillSafe AI may include links, integrations, or connections to third-party services. We are not responsible for the privacy practices, security, content, or policies of external services. Users should review third-party privacy policies before using those services.',
  ),
  _PolicySection(
    shortTitle: 'Cloud',
    title: 'International Data Processing',
    subtitle: 'Cloud infrastructure may process data outside the local region',
    icon: LucideIcons.cloud,
    color: Color(0xFF0EA5E9),
    body:
        'HillSafe AI may use cloud services that store or process data outside the user local region. By using the app, users understand that their data may be processed through cloud infrastructure used by the project.',
  ),
  _PolicySection(
    shortTitle: 'Changes',
    title: 'Changes to This Privacy Policy',
    subtitle: 'Updates may reflect app, backend, or legal changes',
    icon: LucideIcons.filePenLine,
    color: Color(0xFF65A30D),
    body:
        'We may update this Privacy Policy from time to time to reflect new app features, backend changes, legal requirements, security improvements, data processing changes, or third-party service updates. Updates will include a new effective date. Continued use of the app after updates means you accept the revised Privacy Policy.',
  ),
  _PolicySection(
    shortTitle: 'Contact',
    title: 'Contact Us',
    subtitle: 'Support and privacy questions',
    icon: LucideIcons.mail,
    color: AppTheme.accentTeal,
    body:
        'If you have questions, requests, or concerns about this Privacy Policy or your data, contact the HillSafe AI team through the app Help and Support section or by email at support@hillsafeai.com. If this email is not yet active, replace it with the official project support email before publishing.',
  ),
  _PolicySection(
    shortTitle: 'Consent',
    title: 'Consent',
    subtitle: 'Your agreement when using HillSafe AI',
    icon: LucideIcons.checkCircle2,
    color: Color(0xFF059669),
    body:
        'By using HillSafe AI, you confirm that you have read, understood, and agreed to this Privacy Policy. You also consent to the collection and use of information as described in this policy. If you do not agree, stop using the app and disable permissions such as location and notifications from your device settings.',
  ),
];

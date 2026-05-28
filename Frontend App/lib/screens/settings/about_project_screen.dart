import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:frontend_app/theme/app_theme.dart';

/// About Project Screen
/// Information about HillSafe AI and the development team
class AboutProjectScreen extends StatelessWidget {
  const AboutProjectScreen({super.key});

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'hillsafeai@gmail.com',
      queryParameters: {
        'subject': 'HillSafe AI Support Request',
      },
    );
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('About HillSafe AI'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Logo and Name
            Center(
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Container(
                        width: 120,
                        height: 120,
                        color: Colors.white,
                        child: Image.asset(
                          'assets/images/Logo.jpeg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMedium),
                  const Text(
                    'HillSafe AI',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall / 2),
                  Text(
                    'Disaster Early Warning System',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white70 
                          : AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingSmall),
                  const Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.9, 0.9)),

            const SizedBox(height: AppTheme.spacingXLarge),

            // Mission Section
            _buildSection(
              context,
              'Our Mission',
              'HillSafe AI leverages cutting-edge machine learning and IoT technology to predict landslides and provide early warnings to communities in mountainous regions, particularly in the Hazara Division of Pakistan.',
              LucideIcons.target,
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 200.ms)
                .slideX(begin: -0.2, end: 0),

            const SizedBox(height: AppTheme.spacingLarge),

            // Institution Section
            _buildSection(
              context,
              'Institution',
              'University of Central Punjab (UCP)\nLahore, Pakistan',
              LucideIcons.building2,
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 400.ms)
                .slideX(begin: 0.2, end: 0),

            const SizedBox(height: AppTheme.spacingLarge),

            // Development Team
            _buildTeamSection(context)
                .animate()
                .fadeIn(duration: 600.ms, delay: 600.ms)
                .slideY(begin: 0.2, end: 0),

            const SizedBox(height: AppTheme.spacingXLarge),

            // Contact Section
            Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppTheme.spacingLarge),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.mail,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: AppTheme.spacingMedium),
                    const Text(
                      'Get in Touch',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppTheme.spacingSmall),
                    const Text(
                      'Have questions or feedback?',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppTheme.spacingMedium),
                    ElevatedButton.icon(
                      onPressed: _launchEmail,
                      icon: const Icon(LucideIcons.send),
                      label: const Text('hillsafeai@gmail.com'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        elevation: 4,
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 800.ms)
                .scale(begin: const Offset(0.9, 0.9)),

            const SizedBox(height: AppTheme.spacingLarge),

            // Copyright
            Center(
              child: Text(
                '© 2026 HillSafe AI. All rights reserved.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 1000.ms),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingSmall),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: AppTheme.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSmall),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white70 
                        : AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSmall),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  LucideIcons.users,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              const Text(
                'Development Team',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLarge),
          _buildTeamMember(context, 'Zain Farrukh'),
          _buildTeamMember(context, 'Syed Hashim'),
          _buildTeamMember(context, 'Ali Azwar'),
        ],
      ),
    );
  }

  Widget _buildTeamMember(BuildContext context, String name) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF3B82F6) 
                  : AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name[0],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMedium),
          Text(
            name,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}


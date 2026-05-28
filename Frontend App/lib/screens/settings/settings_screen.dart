import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:frontend_app/theme/app_theme.dart';
import 'package:frontend_app/theme/theme_provider.dart';
import 'package:frontend_app/providers/user_provider.dart';
import 'package:frontend_app/providers/language_provider.dart';

/// Settings Screen - App Configuration
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _smsAlertsEnabled = true;
  bool _locationEnabled = true;

  void _showEditNameDialog() {
    final controller = TextEditingController(
      text: context.read<UserProvider>().username,
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Your Name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<UserProvider>().updateUsername(controller.text);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Name updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await context.read<UserProvider>().logout();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/role_selection',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? const Color(0xFF1E293B) // Keep dark navy but ensured high contrast
                      : AppTheme.primaryColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.shield, color: Colors.white),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Privacy Policy',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: SelectableText.rich(
                    TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium,
                      children: [
                        TextSpan(
                          text: 'Last Updated: February 2026\n\n',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                        ),
                        const TextSpan(
                          text: '1. Data Collection\n',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const TextSpan(text: 'We collect minimal data to ensure your safety:\n\n'),
                        const TextSpan(text: '• Location Data: ', style: TextStyle(fontWeight: FontWeight.w600)),
                        const TextSpan(text: 'GPS coordinates to determine landslide-prone regions.\n\n'),
                        const TextSpan(text: '• Device Information: ', style: TextStyle(fontWeight: FontWeight.w600)),
                        const TextSpan(text: 'Firebase Device Token for emergency notifications.\n\n'),
                        const TextSpan(text: '2. How We Use Your Data\n', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const TextSpan(text: '\n• Risk Prediction: ', style: TextStyle(fontWeight: FontWeight.w600)),
                        const TextSpan(text: 'Random Forest and LSTM models calculate landslide susceptibility.\n\n'),
                        const TextSpan(text: '• Authority Alerts: ', style: TextStyle(fontWeight: FontWeight.w600)),
                        const TextSpan(text: 'Safety status shared with disaster management.\n\n'),
                        const TextSpan(text: '3. Data Security\n', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const TextSpan(text: '\nSecure Django server. No selling of personal data.\n\n'),
                        const TextSpan(text: '4. Location Permissions\n', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const TextSpan(text: '\nBackground tracking enables 2-hour risk assessments.\n\n'),
                        const TextSpan(text: '5. Contact\n', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const TextSpan(text: '\nhillsafeai@gmail.com', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.blue)),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpSupportDialog() {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(LucideIcons.helpCircle, color: primary),
            const SizedBox(width: 12),
            const Text('Help & Support'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Need assistance? We\'re here to help!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            const Text('Contact Us:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.mail, color: primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SelectableText(
                      'hillsafeai@gmail.com',
                      style: TextStyle(
                        fontSize: 15, 
                        color: primary, 
                        fontWeight: FontWeight.w600
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('We typically respond within 24-48 hours.', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final langProvider = context.watch<LanguageProvider>();
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: Text(langProvider.settings),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildProfileCard(userProvider.username)
                .animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.1, end: 0),

            const SizedBox(height: AppTheme.spacingLarge),

            // Notifications Section
            Text(
              langProvider.notifications,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            _buildNotificationSettings()
                .animate()
                .fadeIn(duration: 600.ms, delay: 200.ms),

            const SizedBox(height: AppTheme.spacingLarge),

            // Preferences Section
            const Text(
              'Preferences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            _buildPreferencesSettings()
                .animate()
                .fadeIn(duration: 600.ms, delay: 400.ms),

            const SizedBox(height: AppTheme.spacingLarge),

            // About Section
            _buildAboutLinks()
                .animate()
                .fadeIn(duration: 600.ms, delay: 600.ms),

            const SizedBox(height: AppTheme.spacingLarge),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showLogoutDialog,
                icon: const Icon(LucideIcons.logOut),
                label: Text(langProvider.logout),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 800.ms)
                .scale(begin: const Offset(0.9, 0.9)),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(String username) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? const Color(0xFF3B82F6) 
                  : AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                username.isNotEmpty ? username[0].toUpperCase() : 'J',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'john.doe@example.com',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(LucideIcons.pencil, size: 20),
            onPressed: _showEditNameDialog,
            tooltip: 'Edit Name',
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Push Notifications'),
            subtitle: const Text('Receive alerts in the app'),
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('SMS Alerts'),
            subtitle: const Text('Get critical alerts via SMS'),
            value: _smsAlertsEnabled,
            onChanged: (value) => setState(() => _smsAlertsEnabled = value),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSettings() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Use dark theme'),
            value: context.watch<ThemeProvider>().isDarkMode,
            onChanged: (value) {
              context.read<ThemeProvider>().toggleTheme(value);
            },
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Location Services'),
            subtitle: const Text('For accurate alerts'),
            value: _locationEnabled,
            onChanged: (value) => setState(() => _locationEnabled = value),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          ListTile(
            title: const Text('Language'),
            subtitle: Text(
              context.watch<LanguageProvider>().isEnglish ? 'English' : 'Urdu',
            ),
            trailing: const Icon(LucideIcons.chevronRight),
            contentPadding: EdgeInsets.zero,
            onTap: () => Navigator.pushNamed(context, '/language_selection'),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutLinks() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(LucideIcons.info, color: Theme.of(context).colorScheme.primary),
            title: const Text('About HillSafe AI'),
            trailing: const Icon(LucideIcons.chevronRight),
            contentPadding: EdgeInsets.zero,
            onTap: () => Navigator.pushNamed(context, '/about'),
          ),
          const Divider(),
          ListTile(
            leading: Icon(LucideIcons.fileText, color: Theme.of(context).colorScheme.primary),
            title: const Text('Privacy Policy'),
            trailing: const Icon(LucideIcons.chevronRight),
            contentPadding: EdgeInsets.zero,
            onTap: _showPrivacyPolicyDialog,
          ),
          const Divider(),
          ListTile(
            leading: Icon(LucideIcons.helpCircle, color: Theme.of(context).colorScheme.primary),
            title: const Text('Help & Support'),
            trailing: const Icon(LucideIcons.chevronRight),
            contentPadding: EdgeInsets.zero,
            onTap: _showHelpSupportDialog,
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:frontend_app/theme/app_theme.dart';
import 'package:frontend_app/theme/theme_provider.dart';
import 'package:frontend_app/providers/user_provider.dart';
import 'package:frontend_app/providers/language_provider.dart';
import 'package:frontend_app/services/api_service.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userProv = context.read<UserProvider>();
      await userProv.refreshProfileFromDb();
      if (userProv.userType == 'authority') {
        final langProv = context.read<LanguageProvider>();
        if (langProv.languageCode != 'en') {
          await langProv.setLanguage('en');
        }
      }
    });
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(
      text: context.read<UserProvider>().username,
    );
    final emailController = TextEditingController(
      text: context.read<UserProvider>().email,
    );
    final phoneController = TextEditingController(
      text: context.read<UserProvider>().phoneNumber,
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.watch<LanguageProvider>().tr('Edit Profile')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: context.read<LanguageProvider>().tr('Name'),
                  hintText: context.read<LanguageProvider>().tr('Enter your username'),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: context.read<LanguageProvider>().tr('Phone Number'),
                  hintText: context.read<LanguageProvider>().tr('Enter phone number'),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: context.read<LanguageProvider>().tr('Email'),
                  hintText: context.read<LanguageProvider>().tr('Enter your email'),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.read<LanguageProvider>().tr('Cancel')),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await context.read<UserProvider>().updateProfile(
                    name: nameController.text.trim(),
                    email: emailController.text.trim(),
                    phoneNumber: phoneController.text.trim(),
                  );
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Profile updated successfully'
                        : 'Could not update profile'),
                    backgroundColor: success ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            child: Text(context.read<LanguageProvider>().tr('Save')),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.watch<LanguageProvider>().tr('Log Out')),
        content: Text(context.watch<LanguageProvider>().tr('Are you sure you want to log out?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.read<LanguageProvider>().tr('Cancel')),
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
            child: Text(context.read<LanguageProvider>().tr('Log Out')),
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
                  color: AppTheme.primaryDark,
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
                        const TextSpan(text: '\nhillsafeai@gmail.com', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.accentTeal)),
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
                      backgroundColor: AppTheme.accentTeal,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.white,
                    ),
                    child: Text(context.read<LanguageProvider>().tr('Close')),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _emailChannel = MethodChannel('com.example.frontend_app/email');

  Future<void> _launchEmail() async {
    try {
      await _emailChannel.invokeMethod('sendEmail', {
        'to': 'hillsafeai@gmail.com',
        'subject': 'HillSafe AI Support Request',
      });
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open email app')),
        );
      }
    }
  }

  void _showHelpSupportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.helpCircle, color: AppTheme.accentTeal),
            const SizedBox(width: 12),
            Text(context.watch<LanguageProvider>().tr('Help & Support')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.watch<LanguageProvider>().tr('Need assistance? We\'re here to help!'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            Text(context.watch<LanguageProvider>().tr('Contact Us:'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _launchEmail,
                icon: const Icon(LucideIcons.mail),
                label: Text('hillsafeai@gmail.com'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentTeal,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(context.watch<LanguageProvider>().tr('We typically respond within 24-48 hours.'), style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.read<LanguageProvider>().tr('Close'))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();
    final langProvider = context.watch<LanguageProvider>();
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        title: Text(langProvider.settings),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildProfileCard(userProvider)
                .animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.1, end: 0),

            const SizedBox(height: AppTheme.spacingLarge),

            // Notifications Section header
            Text(
              langProvider.notifications,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            _buildNotificationSettings()
                .animate()
                .fadeIn(duration: 600.ms, delay: 200.ms),

            const SizedBox(height: AppTheme.spacingLarge),

            // Preferences Section header
            Text(
              langProvider.tr('Preferences'),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
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

  Widget _buildProfileCard(UserProvider userProvider) {
    final username = userProvider.username;
    final phoneNumber = userProvider.phoneNumber.isEmpty
        ? 'No phone number'
        : userProvider.phoneNumber;
    final email = userProvider.email.isEmpty
        ? 'Add email address'
        : userProvider.email;

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.accentTeal,
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      LucideIcons.phone,
                      size: 13,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        phoneNumber,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      LucideIcons.mail,
                      size: 13,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        email,
                        style: TextStyle(
                          fontSize: 12,
                          color: userProvider.email.isEmpty
                              ? AppTheme.accentTeal
                              : AppTheme.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(LucideIcons.pencil, size: 20, color: AppTheme.textSecondary),
            onPressed: _showEditProfileDialog,
            tooltip: context.read<LanguageProvider>().tr('Edit Profile'),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(context.watch<LanguageProvider>().tr('Push Notifications')),
            subtitle: Text(context.watch<LanguageProvider>().tr('Receive alerts in the app')),
            value: _notificationsEnabled,
            activeColor: AppTheme.accentTeal,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          SwitchListTile(
            title: Text(context.watch<LanguageProvider>().tr('SMS Alerts')),
            subtitle: Text(context.watch<LanguageProvider>().tr('Get critical alerts via SMS')),
            value: _smsAlertsEnabled,
            activeColor: AppTheme.accentTeal,
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: Text(context.watch<LanguageProvider>().tr('Dark Mode')),
            subtitle: Text(context.watch<LanguageProvider>().tr('Use dark theme')),
            value: context.watch<ThemeProvider>().isDarkMode,
            activeColor: AppTheme.accentTeal,
            onChanged: (value) async {
              context.read<ThemeProvider>().toggleTheme(value);
              await ApiService().updateDarkMode(value);
            },
            contentPadding: EdgeInsets.zero,
          ),
          const Divider(),
          SwitchListTile(
            title: Text(context.watch<LanguageProvider>().tr('Location Services')),
            subtitle: Text(context.watch<LanguageProvider>().tr('For accurate alerts')),
            value: _locationEnabled,
            activeColor: AppTheme.accentTeal,
            onChanged: (value) => setState(() => _locationEnabled = value),
            contentPadding: EdgeInsets.zero,
          ),
          if (context.read<UserProvider>().userType != 'authority') ...[
            const Divider(),
            ListTile(
              title: Text(context.watch<LanguageProvider>().tr('Language')),
              subtitle: Text(
                context.watch<LanguageProvider>().isEnglish ? 'English' : 'Urdu',
              ),
              trailing: Icon(LucideIcons.chevronRight, color: AppTheme.textSecondary),
              contentPadding: EdgeInsets.zero,
              onTap: () => Navigator.pushNamed(context, '/language_selection'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAboutLinks() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(LucideIcons.info, color: AppTheme.accentTeal),
            title: Text(context.watch<LanguageProvider>().tr('About HillSafe AI')),
            trailing: Icon(LucideIcons.chevronRight, color: AppTheme.textSecondary),
            contentPadding: EdgeInsets.zero,
            onTap: () => Navigator.pushNamed(context, '/about'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(LucideIcons.fileText, color: AppTheme.accentTeal),
            title: Text(context.watch<LanguageProvider>().tr('Privacy Policy')),
            trailing: Icon(LucideIcons.chevronRight, color: AppTheme.textSecondary),
            contentPadding: EdgeInsets.zero,
            onTap: _showPrivacyPolicyDialog,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(LucideIcons.helpCircle, color: AppTheme.accentTeal),
            title: Text(context.watch<LanguageProvider>().tr('Help & Support')),
            trailing: Icon(LucideIcons.chevronRight, color: AppTheme.textSecondary),
            contentPadding: EdgeInsets.zero,
            onTap: _showHelpSupportDialog,
          ),
        ],
      ),
    );
  }
}

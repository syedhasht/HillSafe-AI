import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:frontend_app/theme/app_theme.dart';
import 'package:frontend_app/theme/theme_provider.dart';
import 'package:frontend_app/providers/user_provider.dart';
import 'package:frontend_app/providers/language_provider.dart';
import 'package:frontend_app/services/api_service.dart';
import 'package:frontend_app/screens/settings/privacy_policy_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:frontend_app/services/notification_service.dart';

/// Settings Screen - App Configuration
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationEnabled = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load local preferences immediately
      try {
        final prefs = await SharedPreferences.getInstance();
        if (mounted) {
          setState(() {
            _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
            _locationEnabled = prefs.getBool('location_enabled') ?? true;
          });
        }
      } catch (e) {
        print('Error loading preferences: $e');
      }

      final userProv = context.read<UserProvider>();
      try {
        await userProv.refreshProfileFromDb();
      } catch (e) {
        print('Error refreshing profile: $e');
      }

      if (!mounted) return;
      if (userProv.userType == 'authority') {
        final langProv = context.read<LanguageProvider>();
        if (langProv.languageCode != 'en') {
          await langProv.setLanguage('en');
        }
      }
      if (mounted) setState(() {});
    });
  }

  Future<void> _showEditProfileDialog() async {
    final langProvider = context.read<LanguageProvider>();
    final userProvider = context.read<UserProvider>();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => _EditProfileDialog(
        langProvider: langProvider,
        initialName: userProvider.username,
        initialEmail: userProvider.email,
        initialPhone: _normalizeProfilePhone(userProvider.phoneNumber),
        normalizePhone: _normalizeProfilePhone,
        isValidPhone: _isValidPakistanPhone,
        protectPhonePrefix: _protectPakistanPhonePrefix,
        movePhoneCursorAfterPrefix: _movePhoneCursorAfterPrefix,
      ),
    );

    if (result == null || !mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 450), () async {
        if (!mounted) return;

        final success = await userProvider.updateProfile(
          name: result['name'] ?? '',
          email: result['email'] ?? '',
          phoneNumber: result['phoneNumber'] ?? '',
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? langProvider.tr('Profile updated successfully')
                : langProvider.tr('Could not update profile')),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      });
    });
  }

  String _normalizeProfilePhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    var local = digits.startsWith('92') ? digits.substring(2) : digits;
    if (local.startsWith('0')) {
      local = local.substring(1);
    }
    if (local.length > 10) {
      local = local.substring(0, 10);
    }
    if (local.isEmpty) return '+92 ';
    if (local.length <= 3) return '+92 $local';
    return '+92 ${local.substring(0, 3)}-${local.substring(3)}';
  }

  void _movePhoneCursorAfterPrefix(TextEditingController controller) {
    if (controller.selection.baseOffset < 4) {
      controller.selection = const TextSelection.collapsed(offset: 4);
    }
  }

  bool _isValidPakistanPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    var local = digits.startsWith('92') ? digits.substring(2) : digits;
    if (local.startsWith('0')) {
      local = local.substring(1);
    }
    return local.length == 10;
  }

  void _protectPakistanPhonePrefix(TextEditingController controller) {
    const prefix = '+92 ';
    final text = controller.text;
    final formatted = _normalizeProfilePhone(text);

    if (text != formatted) {
      final oldOffset = controller.selection.baseOffset;
      final safeOffset = oldOffset < prefix.length
          ? prefix.length
          : formatted.length.clamp(prefix.length, formatted.length);
      controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: safeOffset),
      );
      return;
    }

    _movePhoneCursorAfterPrefix(controller);
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

  void _showHelpSupportDialog() {
    const supportEmail = 'hillsafeai@gmail.com';
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 18, 24, 8),
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.accentTealLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(LucideIcons.headphones, color: AppTheme.accentTeal),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                context.watch<LanguageProvider>().tr('Help & Support'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.watch<LanguageProvider>().tr('Need assistance? We are here to help.'),
              style: TextStyle(color: AppTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.mail, color: AppTheme.accentTeal, size: 20),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      supportEmail,
                      style: TextStyle(fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(const ClipboardData(text: supportEmail));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Support email copied')),
                        );
                      }
                    },
                    icon: const Icon(LucideIcons.copy, size: 16),
                    label: Text(context.read<LanguageProvider>().tr('Copy Email')),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.watch<LanguageProvider>().tr('We typically respond within 24-48 hours.'),
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(context.read<LanguageProvider>().tr('Close')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final userProvider = context.watch<UserProvider>();
    final langProvider = context.watch<LanguageProvider>();
    
    return Scaffold(
      key: ValueKey(
        themeProvider.isDarkMode ? 'settings-dark' : 'settings-light',
      ),
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: const Color(0xFF0F172A),
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: AppTheme.background,
          systemNavigationBarIconBrightness:
              themeProvider.isDarkMode ? Brightness.light : Brightness.dark,
        ),
        title: Text(langProvider.settings),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildProfileCard(userProvider),

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
            _buildNotificationSettings(),

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
            _buildPreferencesSettings(themeProvider),

            const SizedBox(height: AppTheme.spacingLarge),

            // About Section
            _buildAboutLinks(),

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
            ),
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
    final isRtl = Directionality.of(context) == TextDirection.rtl;

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
                Align(
                  alignment:
                      isRtl ? Alignment.centerRight : Alignment.centerLeft,
                  child: Text(
                    username,
                    textAlign: isRtl ? TextAlign.right : TextAlign.left,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                  child: _ContactLine(
                    icon: LucideIcons.phone,
                    text: phoneNumber,
                    color: AppTheme.textSecondary,
                    isRtl: isRtl,
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                  child: _ContactLine(
                    icon: LucideIcons.mail,
                    text: email,
                    color: userProvider.email.isEmpty
                        ? AppTheme.accentTeal
                        : AppTheme.textSecondary,
                    isRtl: isRtl,
                  ),
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
            onChanged: (value) async {
              setState(() => _notificationsEnabled = value);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('notifications_enabled', value);
              if (!value) {
                try {
                  await FirebaseMessaging.instance.deleteToken();
                  print('FCM Token deleted successfully.');
                } catch (e) {
                  print('Error deleting FCM Token: $e');
                }
                await NotificationService().cancelAll();
              } else {
                try {
                  final position = await ApiService().getCurrentPosition();
                  if (position != null) {
                    await ApiService().registerDeviceForAlerts(
                      latitude: position.latitude,
                      longitude: position.longitude,
                    );
                  } else {
                    final messaging = FirebaseMessaging.instance;
                    await messaging.requestPermission(alert: true, badge: true, sound: true);
                    await messaging.getToken();
                  }
                } catch (e) {
                  print('Error registering device token: $e');
                }
              }
            },
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesSettings(ThemeProvider themeProvider) {
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
            value: themeProvider.isDarkMode,
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
            onChanged: (value) async {
              setState(() => _locationEnabled = value);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('location_enabled', value);
            },
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
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PrivacyPolicyScreen(),
              ),
            ),
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

class _ContactLine extends StatelessWidget {
  const _ContactLine({
    required this.icon,
    required this.text,
    required this.color,
    required this.isRtl,
  });

  final IconData icon;
  final String text;
  final Color color;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    final children = [
      Icon(icon, size: 13, color: AppTheme.textSecondary),
      const SizedBox(width: 6),
      Flexible(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            text,
            textAlign: isRtl ? TextAlign.right : TextAlign.left,
            style: TextStyle(fontSize: 12, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: isRtl ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: isRtl ? children.reversed.toList() : children,
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({
    required this.langProvider,
    required this.initialName,
    required this.initialEmail,
    required this.initialPhone,
    required this.normalizePhone,
    required this.isValidPhone,
    required this.protectPhonePrefix,
    required this.movePhoneCursorAfterPrefix,
  });

  final LanguageProvider langProvider;
  final String initialName;
  final String initialEmail;
  final String initialPhone;
  final String Function(String value) normalizePhone;
  final bool Function(String value) isValidPhone;
  final void Function(TextEditingController controller) protectPhonePrefix;
  final void Function(TextEditingController controller) movePhoneCursorAfterPrefix;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _phoneController.addListener(_protectPhonePrefix);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_protectPhonePrefix);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _protectPhonePrefix() {
    widget.protectPhonePrefix(_phoneController);
  }

  void _save() {
    final phoneNumber = widget.normalizePhone(_phoneController.text);
    final hasPhoneDigits = phoneNumber.replaceAll(RegExp(r'\D'), '').length > 2;
    if (hasPhoneDigits && !widget.isValidPhone(phoneNumber)) {
      setState(() {
        _phoneError = widget.langProvider.tr('Enter exactly 10 digits after +92');
      });
      return;
    }

    Navigator.pop(context, {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phoneNumber': hasPhoneDigits ? phoneNumber : '',
    });
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = widget.langProvider;

    return AlertDialog(
      title: Text(langProvider.tr('Edit Profile')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: langProvider.tr('Name'),
                hintText: langProvider.tr('Enter your username'),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
              ],
              decoration: InputDecoration(
                labelText: langProvider.tr('Phone Number'),
                hintText: '+92 300-1234567',
                helperText: _phoneError == null
                    ? langProvider.tr('Only edit 10 digits after +92')
                    : null,
                errorText: _phoneError,
              ),
              onTap: () => widget.movePhoneCursorAfterPrefix(_phoneController),
              onChanged: (_) {
                if (_phoneError != null) {
                  setState(() => _phoneError = null);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: langProvider.tr('Email'),
                hintText: langProvider.tr('Enter your email'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(langProvider.tr('Cancel')),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text(langProvider.tr('Save')),
        ),
      ],
    );
  }
}

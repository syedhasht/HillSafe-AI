import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:frontend_app/theme/app_theme.dart';
import 'package:frontend_app/providers/language_provider.dart';
import 'package:frontend_app/providers/user_provider.dart';
import 'package:frontend_app/services/api_service.dart';
import 'package:frontend_app/utils/pakistan_phone_number_formatter.dart';
import 'package:frontend_app/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Resident Login Screen
/// Simplified passwordless login for community members (username + phone number)
class ResidentLoginScreen extends StatefulWidget {
  const ResidentLoginScreen({super.key});

  @override
  State<ResidentLoginScreen> createState() => _ResidentLoginScreenState();
}

class _ResidentLoginScreenState extends State<ResidentLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+92 ');
  final _apiService = ApiService();
  bool _isLoading = false;
  bool _hasSubmitted = false;
  String? _phoneError;

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final phoneError = validatePakistanPhoneNumber(_phoneController.text);

    setState(() {
      _hasSubmitted = true;
      _phoneError = phoneError;
    });

    if (_formKey.currentState!.validate() && phoneError == null) {
      setState(() => _isLoading = true);

      try {
        final errorMsg = await _apiService.loginWithError(
          _usernameController.text.trim(),
          _phoneController.text.trim(),
          role: 'COMMUNITY',
        );

        if (!mounted) return;

        setState(() => _isLoading = false);

        if (errorMsg != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
          return;
        }

        await context.read<UserProvider>().login(
              await _apiService.getUsername() ?? _usernameController.text.trim(),
              'community',
              phoneNumber: await _apiService.getPhoneNumber() ??
                  _phoneController.text.trim(),
              email: await _apiService.getEmail() ?? '',
            );
        final prefs = await SharedPreferences.getInstance();
        final isDark = prefs.getBool('isDarkMode') ?? false;
        if (mounted) {
          await context.read<ThemeProvider>().toggleTheme(isDark);
        }
        await context.read<LanguageProvider>().loadLanguage();

        Navigator.of(context).pushNamedAndRemoveUntil('/community_dashboard', (route) => false);
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
          backgroundColor: AppTheme.lightBackground,
          body: SafeArea(
            child: Stack(
              children: [
                // ── Scrollable form content ───────────────────────────────
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingLarge,
                      56, // leave room for the back button
                      AppTheme.spacingLarge,
                      AppTheme.spacingLarge,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppTheme.spacingLarge),
  
                          // Logo
                          Center(
                            child: Container(
                              width: 120,
                              height: 120,
                              padding: const EdgeInsets.all(AppTheme.spacingMedium),
                              decoration: BoxDecoration(
                                color: AppTheme.lightSurface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Image.asset(
                                  'assets/images/Logo.jpeg',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          )
                              .animate()
                              .fadeIn(duration: 600.ms)
                              .scale(begin: const Offset(0.8, 0.8)),
  
                          const SizedBox(height: AppTheme.spacingLarge),
  
                          // Title
                          Text(
                            'Resident Login',
                            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  color: AppTheme.lightTextPrimary,
                                ),
                            textAlign: TextAlign.center,
                          )
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 200.ms)
                              .slideY(begin: 0.2, end: 0),
  
                          const SizedBox(height: AppTheme.spacingSmall),
  
                          // Subtitle
                          Text(
                            'Access safety alerts and guidelines',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.lightTextSecondary,
                                ),
                            textAlign: TextAlign.center,
                          )
                              .animate()
                              .fadeIn(duration: 600.ms, delay: 300.ms)
                              .slideY(begin: 0.2, end: 0),
  
                          const SizedBox(height: AppTheme.spacingXLarge * 1.5),

                        // Username Field
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.lightSurface,
                            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                            border: Border.all(color: AppTheme.lightBorderColor),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingMedium,
                            vertical: AppTheme.spacingSmall / 2,
                          ),
                          child: TextFormField(
                            controller: _usernameController,
                            keyboardType: TextInputType.text,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppTheme.lightTextPrimary,
                                ),
                            decoration: InputDecoration(
                              labelText: 'Username',
                              labelStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppTheme.lightTextSecondary),
                              prefixIcon: const Icon(
                                LucideIcons.user,
                                color: AppTheme.accentTeal,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                                borderSide: const BorderSide(
                                  color: AppTheme.accentTeal,
                                  width: 1.5,
                                ),
                              ),
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your username';
                              }
                              return null;
                            },
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 400.ms)
                            .slideY(begin: 0.2, end: 0),
  
                        const SizedBox(height: AppTheme.spacingMedium),
  
                        // Phone Number Field
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.lightSurface,
                            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                            border: Border.all(color: AppTheme.lightBorderColor),
                            boxShadow: AppTheme.cardShadow,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingMedium,
                            vertical: AppTheme.spacingSmall / 2,
                          ),
                          child: TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [PakistanPhoneNumberFormatter()],
                            enableSuggestions: false,
                            autocorrect: false,
                            onChanged: (value) {
                              if (!_hasSubmitted) return;
                              setState(() {
                                _phoneError = validatePakistanPhoneNumber(value);
                              });
                            },
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: AppTheme.lightTextPrimary,
                                ),
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              hintText: '+92 300-1234567',
                              labelStyle: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppTheme.lightTextSecondary),
                              prefixIcon: const Icon(
                                LucideIcons.phone,
                                color: AppTheme.accentTeal,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                                borderSide: const BorderSide(
                                  color: AppTheme.accentTeal,
                                  width: 1.5,
                                ),
                              ),
                              errorBorder: InputBorder.none,
                              focusedErrorBorder: InputBorder.none,
                            ),
                            validator: (_) => null,
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 500.ms)
                            .slideY(begin: 0.2, end: 0),

                        if (_phoneError != null) ...[
                          const SizedBox(height: AppTheme.spacingSmall),
                          Padding(
                            padding: const EdgeInsets.only(
                              left: AppTheme.spacingMedium,
                            ),
                            child: Text(
                              _phoneError!,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                            ),
                          ),
                        ],

                        const SizedBox(height: AppTheme.spacingLarge * 1.5),

                        // Login Button
                        Container(
                          height: 56,
                          decoration: BoxDecoration(
                            color: AppTheme.accentTeal,
                            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentTeal.withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isLoading ? null : _handleLogin,
                              borderRadius:
                                  BorderRadius.circular(AppTheme.cardRadius),
                              child: Center(
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        color: AppTheme.textOnDark,
                                        strokeWidth: 2,
                                      )
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(
                                            LucideIcons.logIn,
                                            color: AppTheme.textOnDark,
                                            size: 20,
                                          ),
                                          const SizedBox(
                                              width: AppTheme.spacingSmall),
                                          Text(
                                            'Continue',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium
                                                ?.copyWith(
                                                  color: AppTheme.textOnDark,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 16,
                                                ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 600.ms, delay: 600.ms)
                            .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: AppTheme.spacingXLarge),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Back button pinned to top-left ────────────────────────
              Positioned(
                top: 4,
                left: 4,
                child: IconButton(
                  icon: const Icon(LucideIcons.arrowLeft),
                  onPressed: () => Navigator.of(context).pop(),
                  color: AppTheme.lightTextPrimary,
                )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: -0.2, end: 0),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}

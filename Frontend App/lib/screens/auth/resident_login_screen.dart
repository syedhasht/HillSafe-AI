import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:frontend_app/theme/app_theme.dart';
import 'package:frontend_app/providers/user_provider.dart';
import 'package:frontend_app/services/api_service.dart';

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
  final _phoneController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // SIMULATED LOGIN FOR DEMO
      print("Demo Mode: Bypassing authentication...");
      
      try {
        // Simulate network delay
        await Future.delayed(const Duration(seconds: 1));
        
        if (!mounted) return;
        
        setState(() => _isLoading = false);

        // Check username to simulate role
        final username = _usernameController.text.toLowerCase();
        if (username.contains('admin') || username.contains('authority')) {
           Navigator.of(context).pushReplacementNamed('/authority_dashboard');
        } else {
           Navigator.of(context).pushReplacementNamed('/community_dashboard');
        }
      } catch (e) {
         print("Error in bypass: $e");
         if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Back Button
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(LucideIcons.arrowLeft),
                      onPressed: () => Navigator.of(context).pop(),
                      color: Theme.of(context).iconTheme.color,
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),

                  const SizedBox(height: AppTheme.spacingLarge),

                  // Logo
                  Center(
                    child: Container(
                      width: 120,
                      height: 120,
                      padding: const EdgeInsets.all(AppTheme.spacingMedium),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.1),
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
                  ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),

                  const SizedBox(height: AppTheme.spacingLarge),

                  // Title
                  Text(
                    'Resident Login',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: AppTheme.spacingSmall),

                  // Subtitle
                  Text(
                    'Access safety alerts and guidelines',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(duration: 600.ms, delay: 300.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: AppTheme.spacingXLarge * 1.5),

                  // Username Field
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMedium,
                      vertical: AppTheme.spacingSmall / 2,
                    ),
                    child: TextFormField(
                      controller: _usernameController,
                      keyboardType: TextInputType.text,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                        prefixIcon: Icon(
                          LucideIcons.user,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
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
                  ).animate().fadeIn(duration: 600.ms, delay: 400.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: AppTheme.spacingMedium),

                  // Phone Number Field
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingMedium,
                      vertical: AppTheme.spacingSmall / 2,
                    ),
                    child: TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: Theme.of(context).textTheme.bodyLarge,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                        prefixIcon: Icon(
                          LucideIcons.phone,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        return null;
                      },
                    ),
                  ).animate().fadeIn(duration: 600.ms, delay: 500.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: AppTheme.spacingLarge * 1.5),

                  // Login Button
                  Container(
                    height: 56,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _isLoading ? null : _handleLogin,
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        child: Center(
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
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
                                    const SizedBox(width: AppTheme.spacingSmall),
                                    Text(
                                      'Continue',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                  ).animate().fadeIn(duration: 600.ms, delay: 600.ms).slideY(begin: 0.2, end: 0),

                  const SizedBox(height: AppTheme.spacingXLarge),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


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

/// Authority Sign-Up Screen
///
/// Allows a new authority user to register with:
/// - Username
/// - Phone number (Pakistan format)
/// - Password (min 6 chars)
/// - Optional email
class AuthoritySignupScreen extends StatefulWidget {
  const AuthoritySignupScreen({super.key});

  @override
  State<AuthoritySignupScreen> createState() => _AuthoritySignupScreenState();
}

class _AuthoritySignupScreenState extends State<AuthoritySignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+92 ');
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _apiService = ApiService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _hasSubmitted = false;
  String? _phoneError;
  String? _signupError;

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleSignup() async {
    final phoneError = validatePakistanPhoneNumber(_phoneController.text);

    setState(() {
      _hasSubmitted = true;
      _phoneError = phoneError;
      _signupError = null;
    });

    if (!_formKey.currentState!.validate() || phoneError != null) return;

    setState(() => _isLoading = true);

    try {
      final error = await _apiService.signupAuthority(
        username: _usernameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _signupError = error;
      });

      if (error != null) return;

      // Auto-login: credentials are saved by signupAuthority()
      await context.read<UserProvider>().login(
            await _apiService.getUsername() ??
                _usernameController.text.trim(),
            'authority',
            phoneNumber:
                await _apiService.getPhoneNumber() ?? _phoneController.text.trim(),
            email: await _apiService.getEmail() ?? _emailController.text.trim(),
          );
      final prefs = await SharedPreferences.getInstance();
      final isDark = prefs.getBool('isDarkMode') ?? false;
      if (mounted) {
        await context.read<ThemeProvider>().toggleTheme(isDark);
      }
      await context.read<LanguageProvider>().loadLanguage();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully! Welcome.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pushReplacementNamed('/authority_dashboard');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _signupError = 'Unexpected error: $e';
      });
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    VoidCallback? onToggleObscure,
    List<dynamic>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Container(
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
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        onChanged: onChanged,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.lightTextPrimary,
            ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTextSecondary,
              ),
          prefixIcon: Icon(
            icon,
            color: AppTheme.accentTeal,
          ),
          suffixIcon: onToggleObscure != null
              ? IconButton(
                  icon: Icon(
                    obscure ? LucideIcons.eye : LucideIcons.eyeOff,
                    color: AppTheme.lightTextSecondary,
                  ),
                  onPressed: onToggleObscure,
                )
              : null,
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
        validator: validator,
      ),
    );
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
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.spacingLarge,
                      56,
                      AppTheme.spacingLarge,
                      AppTheme.spacingLarge,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppTheme.spacingMedium),
  
                      // Logo
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
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
                        'Create Authority Account',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppTheme.lightTextPrimary,
                            ),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(duration: 600.ms, delay: 200.ms)
                          .slideY(begin: 0.2, end: 0),
  
                      const SizedBox(height: AppTheme.spacingSmall),
  
                      Text(
                        'Register as a disaster management authority',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.lightTextSecondary,
                            ),
                      textAlign: TextAlign.center,
                    )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 300.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: AppTheme.spacingXLarge),

                    // Username
                    _buildField(
                      controller: _usernameController,
                      label: 'Username',
                      icon: LucideIcons.user,
                      onChanged: (_) {
                        if (_signupError != null) setState(() => _signupError = null);
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a username';
                        }
                        if (value.trim().length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        return null;
                      },
                    )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 350.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: AppTheme.spacingMedium),

                    // Phone Number
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                        border: Border.all(color: AppTheme.borderColor),
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
                          if (_signupError != null) setState(() => _signupError = null);
                          if (!_hasSubmitted) return;
                          setState(() {
                            _phoneError = validatePakistanPhoneNumber(value);
                          });
                        },
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppTheme.textPrimary,
                            ),
                        decoration: InputDecoration(
                          labelText: 'Phone Number',
                          hintText: '+92 300-1234567',
                          labelStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
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
                        .fadeIn(duration: 600.ms, delay: 400.ms)
                        .slideY(begin: 0.2, end: 0),

                    if (_phoneError != null) ...[
                      const SizedBox(height: AppTheme.spacingSmall),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: AppTheme.spacingMedium),
                        child: Text(
                          _phoneError!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ),
                    ],

                    const SizedBox(height: AppTheme.spacingMedium),

                    // Email (optional)
                    _buildField(
                      controller: _emailController,
                      label: 'Email (optional)',
                      icon: LucideIcons.mail,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) {
                        if (_signupError != null) setState(() => _signupError = null);
                      },
                      validator: (value) {
                        if (value != null &&
                            value.trim().isNotEmpty &&
                            !value.trim().contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 450.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: AppTheme.spacingMedium),

                    // Password
                    _buildField(
                      controller: _passwordController,
                      label: 'Password',
                      icon: LucideIcons.lock,
                      obscure: _obscurePassword,
                      onToggleObscure: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      onChanged: (_) {
                        if (_signupError != null) setState(() => _signupError = null);
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a password';
                        }
                        if (value.trim().length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 500.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: AppTheme.spacingMedium),

                    // Confirm Password
                    _buildField(
                      controller: _confirmPasswordController,
                      label: 'Confirm Password',
                      icon: LucideIcons.lock,
                      obscure: _obscureConfirmPassword,
                      onToggleObscure: () => setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword),
                      onChanged: (_) {
                        if (_signupError != null) setState(() => _signupError = null);
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please confirm your password';
                        }
                        if (value.trim() != _passwordController.text.trim()) {
                          return 'Passwords do not match';
                        }
                        return null;
                      },
                    )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 550.ms)
                        .slideY(begin: 0.2, end: 0),

                    // Error message from backend
                    if (_signupError != null) ...[
                      const SizedBox(height: AppTheme.spacingMedium),
                      Container(
                        padding: const EdgeInsets.all(AppTheme.spacingMedium),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .error
                              .withOpacity(0.1),
                          borderRadius:
                              BorderRadius.circular(AppTheme.cardRadius),
                          border: Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .error
                                .withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.alertCircle,
                              color: Theme.of(context).colorScheme.error,
                              size: 18,
                            ),
                            const SizedBox(width: AppTheme.spacingSmall),
                            Expanded(
                              child: Text(
                                _signupError!,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.error,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1, end: 0),
                    ],

                    const SizedBox(height: AppTheme.spacingLarge * 1.5),

                    // Sign Up Button
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
                          onTap: _isLoading ? null : _handleSignup,
                          borderRadius:
                              BorderRadius.circular(AppTheme.cardRadius),
                          child: Center(
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: AppTheme.textOnDark,
                                    strokeWidth: 2,
                                  )
                                : Text(
                                    'Create Account',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppTheme.textOnDark,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                        ),
                                  ),
                          ),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(duration: 600.ms, delay: 600.ms)
                        .slideY(begin: 0.2, end: 0),

                    const SizedBox(height: AppTheme.spacingLarge),

                    // Already have an account
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.lightTextSecondary,
                              ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Login',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.accentTeal,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 600.ms, delay: 700.ms),

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

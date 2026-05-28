import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend_app/theme/app_theme.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              // Logo
              Container(
                width: 120,
                height: 120,
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: Colors.white,
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
              )
              .animate()
              .fadeIn(duration: 800.ms, curve: Curves.easeOut)
              .scale(begin: const Offset(0.8, 0.8), curve: Curves.elasticOut),

              const SizedBox(height: AppTheme.spacingXLarge),

              // Header
              Text(
                'Welcome to HillSafe AI',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                  letterSpacing: -0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              Text(
                'Choose your role to continue',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppTheme.spacingXLarge * 2),

              // Role Cards
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Community User Card
                    _RoleCard(
                      icon: LucideIcons.home,
                      title: 'I am a Resident',
                      subtitle: 'Receive alerts and safety tips.',
                      isDark: false,
                      onTap: () {
                        Navigator.of(context).pushNamed('/resident_login');
                      },
                    )
                        .animate()
                        .fadeIn(
                          duration: 600.ms,
                          delay: 200.ms,
                          curve: Curves.easeOut,
                        )
                        .slideY(
                          begin: 0.3,
                          end: 0,
                          duration: 600.ms,
                          delay: 200.ms,
                          curve: Curves.easeOutCubic,
                        ),

                    const SizedBox(height: AppTheme.spacingLarge),

                    // Disaster Authority Card
                    _RoleCard(
                      icon: LucideIcons.shieldCheck,
                      title: 'Disaster Authority',
                      subtitle: 'Monitor risks and manage alerts.',
                      isDark: true,
                      onTap: () {
                        Navigator.of(context).pushNamed('/login');
                      },
                    )
                        .animate()
                        .fadeIn(
                          duration: 600.ms,
                          delay: 400.ms,
                          curve: Curves.easeOut,
                        )
                        .slideY(
                          begin: 0.3,
                          end: 0,
                          duration: 600.ms,
                          delay: 400.ms,
                          curve: Curves.easeOutCubic,
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(AppTheme.spacingLarge * 1.5),
          decoration: widget.isDark
              ? AppTheme.bentoCardDark.copyWith(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(_isHovered ? 0.2 : 0.1),
                      blurRadius: _isHovered ? 20 : 10,
                      offset: const Offset(0, 5),
                      spreadRadius: _isHovered ? 2 : 0,
                    ),
                  ],
                )
              : AppTheme.bentoCardLight.copyWith(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(_isHovered ? 0.15 : 0.08),
                      blurRadius: _isHovered ? 20 : 10,
                      offset: const Offset(0, 5),
                      spreadRadius: _isHovered ? 2 : 0,
                    ),
                  ],
                ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMedium),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? Colors.white.withOpacity(0.15)
                      : AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  widget.icon,
                  size: 32,
                  color: widget.isDark
                      ? AppTheme.textOnDark
                      : AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: widget.isDark
                                ? AppTheme.textOnDark
                                : AppTheme.textPrimary,
                            fontSize: 20,
                          ),
                    ),
                    const SizedBox(height: AppTheme.spacingSmall / 2),
                    Text(
                      widget.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: widget.isDark
                                ? AppTheme.textOnDark.withOpacity(0.8)
                                : AppTheme.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(
                LucideIcons.chevronRight,
                color: widget.isDark
                    ? AppTheme.textOnDark.withOpacity(0.6)
                    : AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


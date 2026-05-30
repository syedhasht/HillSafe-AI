import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend_app/theme/app_theme.dart';

import 'package:frontend_app/theme/theme_provider.dart';
import 'package:provider/provider.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: AppTheme.lightTheme,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
          backgroundColor: AppTheme.lightBackground,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingLarge,
                vertical: AppTheme.spacingMedium,
              ),
              child: Column(
                children: [
                  const Spacer(flex: 2),
  
                  // Logo
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: AppTheme.lightSurface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
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
                    .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                    .scale(
                      begin: const Offset(0.8, 0.8),
                      curve: Curves.easeOutBack,
                    ),

                const SizedBox(height: AppTheme.spacingLarge),

                // Title
                Text(
                  'Welcome to HillSafe AI',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.lightTextPrimary,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 200.ms, duration: 500.ms)
                    .slideY(begin: 0.15, end: 0),

                const SizedBox(height: 6),

                Text(
                  'Choose your role to continue',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.lightTextSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 500.ms),

                const Spacer(flex: 2),

                // Resident Card
                _RoleCard(
                  icon: LucideIcons.home,
                  title: 'I am a Resident',
                  subtitle: 'Receive alerts and safety tips.',
                  isDark: false,
                  onTap: () =>
                      Navigator.of(context).pushNamed('/resident_login'),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 500.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: AppTheme.spacingMedium),

                // Authority Card
                _RoleCard(
                  icon: LucideIcons.shieldCheck,
                  title: 'Disaster Authority',
                  subtitle: 'Monitor risks and manage alerts.',
                  isDark: true,
                  onTap: () => Navigator.of(context).pushNamed('/login'),
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 500.ms)
                    .slideY(begin: 0.2, end: 0),

                const Spacer(flex: 1),
              ],
            ),
          ),
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
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? AppTheme.primaryDark : AppTheme.lightSurface;
    final titleColor =
        widget.isDark ? Colors.white : AppTheme.lightTextPrimary;
    final subtitleColor =
        widget.isDark ? Colors.white.withOpacity(0.65) : AppTheme.lightTextSecondary;
    final iconBg = widget.isDark
        ? Colors.white.withOpacity(0.12)
        : AppTheme.accentTealLight;
    final iconColor =
        widget.isDark ? Colors.white : AppTheme.accentTeal;
    final arrowColor =
        widget.isDark ? Colors.white.withOpacity(0.5) : AppTheme.lightTextSecondary;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            boxShadow: widget.isDark
                ? [
                    BoxShadow(
                      color: AppTheme.primaryDark.withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : AppTheme.cardShadow,
          ),
          child: Row(
            children: [
              // Icon container
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, size: 26, color: iconColor),
              ),

              const SizedBox(width: AppTheme.spacingMedium),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: subtitleColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(LucideIcons.chevronRight, size: 20, color: arrowColor),
            ],
          ),
        ),
      ),
    );
  }
}

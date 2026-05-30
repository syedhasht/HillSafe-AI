import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:frontend_app/theme/app_theme.dart';
import 'package:frontend_app/providers/language_provider.dart';
import 'package:frontend_app/theme/theme_provider.dart';

/// Language Selection Screen - English/Urdu Toggle
class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  late String _selectedCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedCode = context.read<LanguageProvider>().languageCode;
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final langProvider = context.watch<LanguageProvider>();

    return Scaffold(
      // Light warm-white scaffold background
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        // White AppBar with dark text
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        title: Text(
          langProvider.language,
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              langProvider.selectLanguage,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLarge),
            _buildLanguageCard(
              code: 'en',
              language: langProvider.english,
              nativeName: 'English',
              badge: 'EN',
              index: 0,
            ),
            const SizedBox(height: AppTheme.spacingMedium),
            _buildLanguageCard(
              code: 'ur',
              language: langProvider.urdu,
              nativeName: 'اردو',
              badge: 'UR',
              index: 1,
            ),
            const Spacer(),
            // Apply button — solid accentTeal background
            ElevatedButton(
              onPressed: () async {
                await context
                    .read<LanguageProvider>()
                    .setLanguage(_selectedCode);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      _selectedCode == 'ur'
                          ? 'زبان اردو میں تبدیل ہوگئی'
                          : 'Language changed to English',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentTeal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.cardRadius),
                ),
                elevation: 0,
              ),
              child: Text(
                langProvider.apply,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 400.ms)
                .scale(begin: const Offset(0.9, 0.9)),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required String code,
    required String language,
    required String nativeName,
    required String badge,
    required int index,
  }) {
    final isSelected = _selectedCode == code;

    return GestureDetector(
      onTap: () => setState(() => _selectedCode = code),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(
            // Teal selected indicator border
            color: isSelected ? AppTheme.accentTeal : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? AppTheme.tealShadow : AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                // Teal icon container
                color: AppTheme.accentTealLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentTeal,
                ),
              ),
            ),
            const SizedBox(width: AppTheme.spacingMedium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          isSelected ? AppTheme.accentTeal : AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    nativeName,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Teal checkmark for selected language
            if (isSelected)
              Icon(
                LucideIcons.checkCircle2,
                color: AppTheme.accentTeal,
                size: 28,
              ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 600.ms, delay: (100 * index).ms)
          .slideX(begin: 0.2, end: 0),
    );
  }
}

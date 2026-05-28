import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend_app/theme/app_theme.dart';

/// Language Selection Screen - English/Urdu Toggle
/// Interface for changing app language
class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text('Language'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select your preferred language',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLarge),

            // English Option
            _buildLanguageCard(
              'English',
              'English',
              '🇬🇧',
              0,
            ),

            const SizedBox(height: AppTheme.spacingMedium),

            // Urdu Option
            _buildLanguageCard(
              'Urdu',
              'اردو',
              '🇵🇰',
              1,
            ),

            const Spacer(),

            // Apply Button
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF06B6D4)],
                ),
                borderRadius: BorderRadius.circular(AppTheme.cardRadius),
              ),
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✓ Language changed to $_selectedLanguage'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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

  Widget _buildLanguageCard(
    String language,
    String nativeName,
    String flag,
    int index,
  ) {
    final isSelected = _selectedLanguage == language;

    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = language),
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingLarge),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          border: Border.all(
            color: isSelected ? AppTheme.accentBlue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.accentBlue.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 40),
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
                      color: isSelected ? AppTheme.accentBlue : AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    nativeName,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                LucideIcons.checkCircle2,
                color: AppTheme.accentBlue,
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


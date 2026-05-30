import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:frontend_app/providers/language_provider.dart';
import 'package:frontend_app/services/api_service.dart';
import 'package:frontend_app/theme/app_theme.dart';
import 'package:frontend_app/theme/theme_provider.dart';

class HillSafeAssistantScreen extends StatefulWidget {
  const HillSafeAssistantScreen({super.key});

  @override
  State<HillSafeAssistantScreen> createState() =>
      _HillSafeAssistantScreenState();
}

class _HillSafeAssistantScreenState extends State<HillSafeAssistantScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _isSending = false;

  final List<_FaqItem> _faqs = const [
    _FaqItem(
      question: 'What is HillSafe AI?',
      answer:
          'HillSafe AI is a landslide early-warning app. It uses location, weather, terrain, and a machine learning model to estimate risk and guide residents.',
    ),
    _FaqItem(
      question: 'Why is my area risky?',
      answer:
          'Risk increases when rainfall is heavy, slopes are steep, soil is weak, elevation changes quickly, or the area has past landslide activity.',
    ),
    _FaqItem(
      question: 'What should I do during high risk?',
      answer:
          'Avoid steep roads, stay away from loose slopes, keep your phone charged, prepare emergency supplies, and follow authority alerts immediately.',
    ),
    _FaqItem(
      question: 'What does moderate risk mean?',
      answer:
          'Moderate risk means conditions are not critical yet, but weather or terrain can become unsafe. Stay alert and avoid unnecessary travel near slopes.',
    ),
    _FaqItem(
      question: 'How do I report an incident?',
      answer:
          'Open Report, describe the incident, allow location access, and submit. The report is sent to the backend for authority review.',
    ),
    _FaqItem(
      question: 'What should be in an emergency kit?',
      answer:
          'Keep water, dry food, flashlight, power bank, first-aid items, medicines, CNIC copy, warm clothes, and emergency contacts.',
    ),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _answerFaq(_FaqItem faq) {
    final langProvider = context.read<LanguageProvider>();
    setState(() {
      _messages.add(_ChatMessage(
        text: langProvider.tr(faq.question),
        isUser: true,
      ));
      _messages.add(_ChatMessage(
        text: langProvider.tr(faq.answer),
        isUser: false,
      ));
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    _messageController.clear();
    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isSending = true;
    });

    final langProvider = context.read<LanguageProvider>();
    final reply = await _apiService.askHillSafeAssistant(
      message: text,
      language: langProvider.isEnglish ? 'English' : 'Urdu',
    );

    if (!mounted) return;
    setState(() {
      _messages.add(_ChatMessage(text: reply, isUser: false));
      _isSending = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    final langProvider = context.watch<LanguageProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        title: Text(langProvider.tr('HillSafe Assistant')),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              children: [
                _AssistantHero(langProvider: langProvider)
                    .animate()
                    .fadeIn(duration: 450.ms)
                    .slideY(begin: -0.08, end: 0),
                const SizedBox(height: AppTheme.spacingMedium),
                _ProjectExplanationCard(langProvider: langProvider)
                    .animate()
                    .fadeIn(duration: 500.ms, delay: 80.ms)
                    .slideY(begin: 0.08, end: 0),
                const SizedBox(height: AppTheme.spacingLarge),
                Text(
                  langProvider.tr('FAQs'),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                ),
                const SizedBox(height: AppTheme.spacingMedium),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _faqs.map((faq) {
                    return _FaqChip(
                      label: langProvider.tr(faq.question),
                      onPressed: () => _answerFaq(faq),
                    )
                        .animate()
                        .fadeIn(duration: 350.ms, delay: (40 * _faqs.indexOf(faq)).ms)
                        .scale(begin: const Offset(0.92, 0.92));
                  }).toList(),
                ),
                const SizedBox(height: AppTheme.spacingLarge),
                ..._messages.asMap().entries.map(
                      (entry) => _ChatBubble(message: entry.value)
                          .animate(key: ValueKey('${entry.key}-${entry.value.text}'))
                          .fadeIn(duration: 250.ms)
                          .slideY(begin: 0.08, end: 0),
                    ),
                if (_isSending)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.borderColor),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.accentTeal,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(langProvider.tr('Thinking...')),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 250.ms),
              ],
            ),
          ),
          // Input bar — white background at bottom
          SafeArea(
            top: false,
            child: Container(
              color: AppTheme.surface,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: langProvider.tr('Ask about risk or safety'),
                        filled: true,
                        fillColor: AppTheme.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.borderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppTheme.accentTeal, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: const Icon(LucideIcons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.accentTeal,
                      foregroundColor: Colors.white,
                    ),
                    tooltip: langProvider.tr('Send'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssistantHero extends StatelessWidget {
  final LanguageProvider langProvider;

  const _AssistantHero({required this.langProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        // Intentionally dark authority panel — deep navy
        color: AppTheme.primaryDark,
        borderRadius: BorderRadius.circular(8),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: const Icon(LucideIcons.bot, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  langProvider.tr('HillSafe Assistant'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  langProvider.tr('Ask about risk, alerts, reports, and safety steps.'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.86),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectExplanationCard extends StatelessWidget {
  final LanguageProvider langProvider;

  const _ProjectExplanationCard({required this.langProvider});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(8),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentTealLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.bot,
                  color: AppTheme.accentTeal,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  langProvider.tr('Project Explanation'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            langProvider.tr(
              'HillSafe AI predicts landslide risk for mountainous regions of Pakistan. The mobile app sends location data to the Django backend, where weather and terrain signals are processed by the machine learning model.',
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          _Point(
            icon: LucideIcons.cloudRain,
            text: langProvider.tr('Weather shows rainfall and temperature.'),
          ),
          _Point(
            icon: LucideIcons.mountain,
            text: langProvider.tr('Terrain explains slope, elevation, and soil.'),
          ),
          _Point(
            icon: LucideIcons.brain,
            text: langProvider.tr('The model combines these signals into Low, Moderate, or High risk.'),
          ),
        ],
      ),
    );
  }
}

class _FaqChip extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _FaqChip({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(LucideIcons.messageCircle, size: 16, color: AppTheme.accentTeal),
      label: Text(label, overflow: TextOverflow.ellipsis),
      onPressed: onPressed,
      backgroundColor: AppTheme.surface,
      side: BorderSide(color: AppTheme.borderColor),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 0,
      pressElevation: 1,
    );
  }
}

class _Point extends StatelessWidget {
  final IconData icon;
  final String text;

  const _Point({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.accentTeal),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final _ChatMessage message;

  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final alignment =
        message.isUser ? Alignment.centerRight : Alignment.centerLeft;
    // User bubble: accentTeal; bot bubble: white with border
    final color = message.isUser ? AppTheme.accentTeal : AppTheme.surface;
    final textColor = message.isUser ? Colors.white : AppTheme.textPrimary;

    return Align(
      alignment: alignment,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 300),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: message.isUser
              ? null
              : Border.all(color: AppTheme.borderColor),
          boxShadow: message.isUser ? null : AppTheme.cardShadow,
        ),
        child: message.isUser
            ? Text(
                message.text,
                style: TextStyle(color: textColor, height: 1.35),
              )
            : _FormattedAssistantText(
                text: message.text,
                color: textColor,
              ),
      ),
    );
  }
}

class _FormattedAssistantText extends StatelessWidget {
  final String text;
  final Color color;

  const _FormattedAssistantText({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final normalized = text
        .replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (match) => match.group(1) ?? '')
        .replaceAllMapped(RegExp(r'__(.*?)__'), (match) => match.group(1) ?? '')
        .replaceAllMapped(RegExp(r'`([^`]*)`'), (match) => match.group(1) ?? '')
        .trim();
    final lines = normalized
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    if (lines.length <= 1) {
      return Text(
        normalized,
        style: TextStyle(color: color, height: 1.42),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: lines.map((line) {
        final isBullet = line.startsWith('- ') ||
            line.startsWith('* ') ||
            RegExp(r'^\d+\.\s').hasMatch(line);
        final cleaned = line
            .replaceFirst(RegExp(r'^[-*]\s+'), '')
            .replaceFirst(RegExp(r'^\d+\.\s+'), '');

        if (!isBullet) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              cleaned,
              style: TextStyle(
                color: color,
                height: 1.42,
                fontWeight: cleaned.endsWith(':') ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 6,
                height: 6,
                margin: const EdgeInsets.only(top: 7, right: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accentTeal,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Expanded(
                child: Text(
                  cleaned,
                  style: TextStyle(color: color, height: 1.42),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({required this.text, required this.isUser});
}

class _FaqItem {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});
}

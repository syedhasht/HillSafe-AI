import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:frontend_app/providers/language_provider.dart';
import 'package:frontend_app/theme/app_theme.dart';
import 'package:frontend_app/services/api_service.dart';

/// Safety Topic Detail - Specific Safety Article
/// Detailed safety information with steps and illustrations
class SafetyTopicDetail extends StatefulWidget {
  const SafetyTopicDetail({super.key});

  @override
  State<SafetyTopicDetail> createState() => _SafetyTopicDetailState();
}

class _SafetyTopicDetailState extends State<SafetyTopicDetail> {
  final ApiService _apiService = ApiService();
  bool _isSaving = false;
  bool _isSaved = false;

  Future<void> _saveGuide() async {
    if (_isSaving || _isSaved) return;

    setState(() => _isSaving = true);

    final success = await _apiService.saveSafetyTip(
      tipId: 'during_landslide_guide',
      title: 'During a Landslide',
      description:
          'Immediate actions, warning signs, and after-event guidance for landslide safety.',
    );

    if (!mounted) return;

    setState(() {
      _isSaving = false;
      _isSaved = success;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.read<LanguageProvider>().tr(success ? 'Guide saved successfully' : 'Could not save guide')),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(context.watch<LanguageProvider>().tr('During a Landslide')),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.red.shade600, Colors.red.shade800],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    LucideIcons.mountain,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.spacingLarge),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildInfoCard(
                  'Immediate Actions',
                  [
                    'Move away from the path of the landslide as quickly as possible',
                    'If escape is not possible, curl into a tight ball and protect your head',
                    'Stay alert and awake - listen for unusual sounds',
                    'Move to higher ground if near a stream or river',
                  ],
                ).animate().fadeIn(duration: 600.ms),
                const SizedBox(height: AppTheme.spacingMedium),
                _buildInfoCard(
                  'Warning Signs',
                  [
                    'Unusual sounds like trees cracking or boulders knocking',
                    'Changes in creek/stream water levels',
                    'Cracks appearing in roads or structures',
                    'Tilting trees, retaining walls, or fences',
                  ],
                ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
                const SizedBox(height: AppTheme.spacingMedium),
                _buildInfoCard(
                  'After the Event',
                  [
                    'Stay away from the affected area',
                    'Check for injured or trapped persons',
                    'Report landslide to local authorities',
                    'Watch for flooding which may occur after',
                  ],
                ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving || _isSaved ? null : _saveGuide,
        backgroundColor: Colors.green,
        icon: _isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(_isSaved ? LucideIcons.bookmarkCheck : LucideIcons.bookmark),
        label: Text(context.watch<LanguageProvider>().tr(_isSaved ? 'Saved' : 'Save Guide')),
      ).animate().scale(begin: const Offset(0, 0), delay: 600.ms),
    );
  }

  Widget _buildInfoCard(String title, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: AppTheme.bentoCardLight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          ...items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    LucideIcons.checkCircle2,
                    size: 18,
                    color: Colors.green,
                  ),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}


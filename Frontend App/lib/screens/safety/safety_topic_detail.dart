import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend_app/theme/app_theme.dart';

/// Safety Topic Detail - Specific Safety Article
/// Detailed safety information with steps and illustrations
class SafetyTopicDetail extends StatelessWidget {
  const SafetyTopicDetail({super.key});

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
              title: const Text('During a Landslide'),
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
        onPressed: () {},
        backgroundColor: Colors.green,
        icon: const Icon(LucideIcons.bookmark),
        label: const Text('Save Guide'),
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


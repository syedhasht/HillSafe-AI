import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend_app/theme/app_theme.dart';
import 'package:frontend_app/theme/theme_provider.dart';
import 'package:provider/provider.dart';

/// District Detail Screen - Drill-down View for Specific Area
/// Comprehensive district information with metrics and history
class DistrictDetailScreen extends StatelessWidget {
  const DistrictDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // App Bar — light surface, dark text
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppTheme.surface,
            foregroundColor: AppTheme.textPrimary,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Murree District',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              titlePadding: const EdgeInsetsDirectional.only(start: 16, bottom: 16),
              background: Container(
                decoration: BoxDecoration(
                  // Teal gradient banner replaces dark blue gradient
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppTheme.accentTeal, Color(0xFF1A5C54)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      bottom: 20,
                      left: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red, width: 1.5),
                            ),
                            child: const Text(
                              'HIGH RISK',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Risk Score Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacingLarge),
              child: _buildRiskScoreCard()
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.1, end: 0),
            ),
          ),

          // Key Metrics
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Key Metrics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMedium),
                  _buildMetricsGrid()
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 200.ms)
                      .slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spacingLarge)),

          // Recent History
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingMedium),
                  _buildHistoryTimeline()
                      .animate()
                      .fadeIn(duration: 600.ms, delay: 400.ms)
                      .slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppTheme.spacingXLarge)),
        ],
      ),
    );
  }

  Widget _buildRiskScoreCard() {
    // Risk score card — intentionally keeps red danger gradient (danger semantic)
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingXLarge),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Current Risk Score',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          const Text(
            '92',
            style: TextStyle(
              color: Colors.white,
              fontSize: 72,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const Text(
            '/100',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 24,
            ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.trendingUp, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(
                '+7 from yesterday',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: LucideIcons.users,
            label: 'Population',
            value: '1.2M',
            color: AppTheme.accentTeal,
          ),
        ),
        const SizedBox(width: AppTheme.spacingMedium),
        Expanded(
          child: _MetricCard(
            icon: LucideIcons.cloudRain,
            label: 'Rainfall',
            value: '52mm',
            color: AppTheme.accentTeal,
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryTimeline() {
    return Column(
      children: [
        _TimelineEvent(
          date: 'Today',
          title: 'Risk Level Increased',
          description: 'Heavy rainfall detected',
          icon: LucideIcons.alertTriangle,
          color: Colors.red,
        ),
        _TimelineEvent(
          date: 'Yesterday',
          title: 'Soil Saturation Alert',
          description: 'Moisture level at 85%',
          icon: LucideIcons.droplet,
          color: Colors.orange,
        ),
        _TimelineEvent(
          date: '2 days ago',
          title: 'Weather Warning',
          description: 'Storm forecast issued',
          icon: LucideIcons.cloud,
          color: Colors.amber,
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: AppTheme.bentoCardLight,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingSmall),
            decoration: BoxDecoration(
              color: AppTheme.accentTealLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineEvent extends StatelessWidget {
  final String date;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _TimelineEvent({
    required this.date,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppTheme.spacingMedium),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(AppTheme.spacingMedium),
              decoration: AppTheme.bentoCardLight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
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

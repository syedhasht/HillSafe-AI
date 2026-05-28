import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend_app/theme/app_theme.dart';
import 'package:frontend_app/services/api_service.dart';

/// Authority Dashboard - Main Control Center for Disaster Authorities
/// Complete dashboard with quick access to all authority features
class AuthorityDashboard extends StatefulWidget {
  const AuthorityDashboard({super.key});

  @override
  State<AuthorityDashboard> createState() => _AuthorityDashboardState();
}

class _AuthorityDashboardState extends State<AuthorityDashboard> {
  final ApiService _apiService = ApiService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              backgroundColor: AppTheme.primaryColor,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                title: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Command Center',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Real-time Disaster Management',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.8),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0F172A),
                        Color(0xFF1E293B),
                        Color(0xFF334155),
                      ],
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.2),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(LucideIcons.settings, color: Colors.white),
                    onPressed: () => Navigator.pushNamed(context, '/settings'),
                  ),
                ),
              ],
            ),

            // Quick Stats
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLarge),
                child: _buildQuickStats()
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: 0.1, end: 0),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
                child: _buildRecentSafetyCheckins()
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 100.ms)
                    .slideY(begin: 0.1, end: 0),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.spacingLarge),
            ),

            // Main Menu Grid
            SliverPadding(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.sizeOf(context).width < 360
                    ? AppTheme.spacingMedium
                    : AppTheme.spacingLarge,
              ),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: MediaQuery.sizeOf(context).width < 360 ? 0.92 : 1,
                  crossAxisSpacing: AppTheme.spacingMedium,
                  mainAxisSpacing: AppTheme.spacingMedium,
                ),
                delegate: SliverChildListDelegate([
                  _buildMenuItem(
                    context,
                    'War Room',
                    'Live map & sensors',
                    LucideIcons.map,
                    const Color(0xFF3B82F6),
                    '/authority_map',
                    0,
                  ),
                  _buildMenuItem(
                    context,
                    'Regional Summary',
                    'District risk scores',
                    LucideIcons.barChart3,
                    const Color(0xFF8B5CF6),
                    '/regional_summary',
                    1,
                  ),
                  _buildMenuItem(
                    context,
                    'Analytics',
                    'Trends & forecasts',
                    LucideIcons.trendingUp,
                    const Color(0xFF06B6D4),
                    '/analytics_trends',
                    2,
                  ),
                  _buildMenuItem(
                    context,
                    'Alert Residents',
                    'Create & broadcast',
                    LucideIcons.megaphone,
                    const Color(0xFFEF4444),
                    '/alert_management',
                    3,
                  ),
                  _buildMenuItem(
                    context,
                    'Alert History',
                    'Past warnings',
                    LucideIcons.history,
                    const Color(0xFFF59E0B),
                    '/alert_feed',
                    4,
                  ),
                  _buildMenuItem(
                    context,
                    'Resident Reports',
                    'View community alerts',
                    LucideIcons.fileText,
                    const Color(0xFF10B981),
                    '/resident_reports',
                    5,
                  ),
                ]),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.spacingXLarge),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _apiService.fetchSafetyStatus(),
      builder: (context, snapshot) {
        final safetyData = snapshot.data ?? {};
        final totalSafe = safetyData['total_safe'] ?? 0;
        final totalUsers = safetyData['total_users'] ?? 0;
        
        return LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 380;
            final cardWidth = compact
                ? (constraints.maxWidth - AppTheme.spacingMedium) / 2
                : (constraints.maxWidth - (AppTheme.spacingMedium * 2)) / 3;

            return Wrap(
              spacing: AppTheme.spacingMedium,
              runSpacing: AppTheme.spacingMedium,
              children: [
                SizedBox(
                  width: cardWidth,
                  child: _StatCard(
                    label: 'High Risk',
                    value: '3',
                    icon: LucideIcons.alertTriangle,
                    color: Colors.red,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _StatCard(
                    label: 'Active Alerts',
                    value: '5',
                    icon: LucideIcons.bell,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _StatCard(
                    label: 'Users Safe',
                    value: '$totalSafe/$totalUsers',
                    icon: LucideIcons.shieldCheck,
                    color: Colors.green,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRecentSafetyCheckins() {
    return FutureBuilder<Map<String, dynamic>>(
      future: _apiService.fetchSafetyStatus(),
      builder: (context, snapshot) {
        final checkins = (snapshot.data?['recent_checkins'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.shieldCheck, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Recent Safety Check-ins',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator(minHeight: 2)
              else if (checkins.isEmpty)
                Text(
                  'No active safety check-ins in the last 30 minutes.',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                ...checkins.take(3).map((checkin) {
                  final lat = (checkin['latitude'] as num?)?.toDouble();
                  final lon = (checkin['longitude'] as num?)?.toDouble();
                  final timestamp = DateTime.tryParse('${checkin['last_marked_at']}');
                  final timeLabel = timestamp == null
                      ? 'Unknown time'
                      : DateFormat('MMM d, h:mm a').format(timestamp.toLocal());
                  final area = (checkin['area_name'] as String?)?.trim();

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${checkin['user_name'] ?? 'Resident'} marked safe',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (area != null && area.isNotEmpty) area,
                            checkin['region_name'] ?? 'Unknown region',
                            if (lat != null && lon != null)
                              '${lat.toStringAsFixed(5)}, ${lon.toStringAsFixed(5)}',
                            timeLabel,
                          ].join(' • '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuItem(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String route,
    int index,
  ) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: 0,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.15),
                    color.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppTheme.textSecondary,
                letterSpacing: 0.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 600.ms, delay: (100 * index).ms)
          .scale(begin: const Offset(0.8, 0.8)),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).cardColor,
            Theme.of(context).cardColor.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: MediaQuery.sizeOf(context).width < 360 ? 28 : 34,
              fontWeight: FontWeight.w700,
              color: color,
              height: 1,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}


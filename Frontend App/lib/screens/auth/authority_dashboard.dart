import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend_app/theme/app_theme.dart';
import 'package:frontend_app/services/api_service.dart';
import 'package:frontend_app/theme/theme_provider.dart';
import 'package:provider/provider.dart';

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
    context.watch<ThemeProvider>();
    return Scaffold(
      // Light warm-white scaffold background
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header — intentionally dark navy panel for authority branding
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryDark,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      top: -20,
                      child: Icon(
                        LucideIcons.shield,
                        size: 120,
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text.rich(
                                TextSpan(
                                  children: [
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: ShaderMask(
                                        shaderCallback: (bounds) => LinearGradient(
                                          colors: [Colors.white, Colors.cyan.shade200, Colors.teal.shade200],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ).createShader(bounds),
                                        child: Text(
                                          'COMMAND',
                                          style: TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.w200,
                                            letterSpacing: 8,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 12, offset: const Offset(0, 4)),
                                              Shadow(color: Colors.cyan.withOpacity(0.2), blurRadius: 20, offset: Offset.zero),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: Text(
                                        '   ',
                                        style: TextStyle(fontSize: 8),
                                      ),
                                    ),
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: Container(
                                        width: 4,
                                        height: 4,
                                        decoration: BoxDecoration(
                                          color: AppTheme.accentTeal,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(color: AppTheme.accentTeal.withOpacity(0.6), blurRadius: 6, spreadRadius: 1),
                                          ],
                                        ),
                                      ),
                                    ),
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: Text(
                                        '   ',
                                        style: TextStyle(fontSize: 8),
                                      ),
                                    ),
                                    WidgetSpan(
                                      alignment: PlaceholderAlignment.middle,
                                      child: ShaderMask(
                                        shaderCallback: (bounds) => LinearGradient(
                                          colors: [Colors.white, Colors.cyan.shade100, AppTheme.accentTeal],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ).createShader(bounds),
                                        child: Text(
                                          'CENTER',
                                          style: TextStyle(
                                            fontSize: 36,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 10,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(color: Colors.black.withOpacity(0.5), blurRadius: 12, offset: const Offset(0, 4)),
                                              Shadow(color: AppTheme.accentTeal.withOpacity(0.2), blurRadius: 20, offset: Offset.zero),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 2,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [AppTheme.accentTeal, Colors.transparent],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: AppTheme.accentTeal,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(color: AppTheme.accentTeal.withOpacity(0.6), blurRadius: 8, spreadRadius: 1),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'DISASTER MANAGEMENT',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white.withOpacity(0.6),
                                      letterSpacing: 3,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
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
                  ],
                ),
              ),
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

            // Recent Safety Check-ins
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLarge),
                child: _buildRecentSafetyCheckins()
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 100.ms)
                    .slideY(begin: 0.1, end: 0),
              ),
            ),

            // SOS Requests
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spacingLarge,
                  AppTheme.spacingLarge,
                  AppTheme.spacingLarge,
                  0,
                ),
                child: _buildSOSRequests()
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 150.ms)
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
                  childAspectRatio:
                      MediaQuery.sizeOf(context).width < 360 ? 0.92 : 1,
                  crossAxisSpacing: AppTheme.spacingMedium,
                  mainAxisSpacing: AppTheme.spacingMedium,
                ),
                delegate: SliverChildListDelegate([
                  _buildMenuItem(context, 'War Room', 'Live map & sensors', LucideIcons.map, AppTheme.accentTeal, '/authority_map', 0),
                  _buildMenuItem(context, 'Regional Summary', 'District risk scores', LucideIcons.barChart3, const Color(0xFF8B5CF6), '/regional_summary', 1),
                  _buildMenuItem(context, 'Analytics', 'Trends & forecasts', LucideIcons.trendingUp, const Color(0xFF06B6D4), '/analytics_trends', 2),
                  _buildMenuItem(context, 'Alert Residents', 'Create & broadcast', LucideIcons.megaphone, const Color(0xFFEF4444), '/alert_management', 3),
                  _buildMenuItem(context, 'Alert History', 'Past warnings', LucideIcons.history, const Color(0xFFF59E0B), '/alert_feed', 4),
                  _buildMenuItem(context, 'Resident Reports', 'View community alerts', LucideIcons.fileText, const Color(0xFF10B981), '/resident_reports', 5),
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
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        _apiService.fetchSafetyStatus(),
        _apiService.fetchRegions(),
        _apiService.fetchAlerts(),
      ]),
      builder: (context, snapshot) {
        final safetyData = (snapshot.data?[0] as Map<String, dynamic>?) ?? {};
        final regions = (snapshot.data?[1] as List<dynamic>?) ?? [];
        final alerts = (snapshot.data?[2] as List<dynamic>?) ?? [];

        final totalSafe = safetyData['total_safe'] ?? 0;
        final totalUsers = safetyData['total_users'] ?? 0;

        final highRiskCount = regions.where((r) {
          final score = (r['current_risk_score'] as num?)?.toDouble() ?? 0.0;
          return score >= 0.5;
        }).length;

        final activeAlertCount = alerts.where((a) => a['is_active'] == true).length;

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
                    value: '$highRiskCount',
                    icon: LucideIcons.alertTriangle,
                    color: Colors.red,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _StatCard(
                    label: 'Active Alerts',
                    value: '$activeAlertCount',
                    icon: LucideIcons.bell,
                    color: Colors.orange,
                  ),
                ),
                SizedBox(
                  width: cardWidth,
                  child: _StatCard(
                    label: 'Users Safe',
                    value: '$totalSafe / $totalUsers',
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
        final checkins =
            (snapshot.data?['recent_checkins'] as List<dynamic>? ?? [])
                .cast<Map<String, dynamic>>();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.shieldCheck,
                      color: Colors.green, size: 20),
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
                LinearProgressIndicator(
                  minHeight: 2,
                  color: AppTheme.accentTeal,
                )
              else if (checkins.isEmpty)
                Text(
                  'No active safety check-ins in the last 30 minutes.',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                ...checkins.take(3).map((checkin) {
                  final lat = (checkin['latitude'] as num?)?.toDouble();
                  final lon = (checkin['longitude'] as num?)?.toDouble();
                  final timestamp =
                      DateTime.tryParse('${checkin['last_marked_at']}');
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
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Widget _buildSOSRequests() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _apiService.fetchSOSRequests(),
      builder: (context, snapshot) {
        final requests = snapshot.data ?? [];

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            border: Border.all(color: Colors.red.withOpacity(0.22)),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.siren, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'SOS Requests',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${requests.length}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                LinearProgressIndicator(
                  minHeight: 2,
                  color: AppTheme.accentTeal,
                )
              else if (requests.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No emergency SOS requests received.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                )
              else
                ...requests.take(5).map((request) {
                  final timestamp = DateTime.tryParse('${request['timestamp']}');
                  final timeAgo = timestamp == null ? '' : _formatTimeAgo(timestamp);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _showSOSDetail(request),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.red.withOpacity(0.15)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(LucideIcons.siren, color: Colors.red, size: 18),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          request['name'] ?? 'Unknown',
                                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          request['region_name'] ?? request['area_name'] ?? 'Unknown location',
                                          style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Icon(LucideIcons.clock, size: 12, color: AppTheme.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(
                                    timeAgo.isNotEmpty ? timeAgo : 'Just now',
                                    style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      request['status_label'] ?? 'Needs Help',
                                      style: const TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        );
      },
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inDays > 0) {
      return '${duration.inDays}d ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ago';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _showSOSDetail(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(LucideIcons.siren, color: Colors.red, size: 22),
            const SizedBox(width: 10),
            const Text('SOS Detail', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Name', request['name'] ?? 'Unknown'),
            _detailRow('Location', request['region_name'] ?? request['area_name'] ?? 'Unknown'),
            _detailRow('Status', request['status_label'] ?? 'Needs Help'),
            _detailRow('Timestamp', request['timestamp'] ?? 'Unknown'),
            if (request['area_name'] != null) _detailRow('Area', request['area_name']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
        ],
      ),
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
          color: AppTheme.surface,
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
              style: TextStyle(
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
    // Stat cards use AppTheme.surface (white) with colored accent — authority branding via color
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
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
            style: TextStyle(
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

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_HeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}

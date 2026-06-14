import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend_app/theme/app_theme.dart';
import 'package:frontend_app/services/api_service.dart';
import 'package:frontend_app/theme/theme_provider.dart';
import 'package:provider/provider.dart';

/// Alert Feed Screen - Community Alert History
/// Chronological list of all alerts with filtering
class AlertFeedScreen extends StatefulWidget {
  const AlertFeedScreen({super.key});

  @override
  State<AlertFeedScreen> createState() => _AlertFeedScreenState();
}

class _AlertFeedScreenState extends State<AlertFeedScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _alertsFuture;

  @override
  void initState() {
    super.initState();
    _refreshAlerts();
  }

  void _refreshAlerts() {
    setState(() {
      _alertsFuture = _apiService.fetchAlerts();
    });
  }

  Future<void> _showClearAlertsConfirmation() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: Colors.red, size: 24),
            const SizedBox(width: 10),
            const Text('Clear All Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure? This will permanently delete all alerts '
          'and residents won\'t be able to see them.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final success = await _apiService.clearAlerts();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Alerts cleared' : 'Failed to clear alerts')),
      );
      if (success) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _refreshAlerts();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.accentTeal,
          onRefresh: () async => _refreshAlerts(),
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: AppTheme.surface,
                title: Text('Alert History',
                    style: TextStyle(color: AppTheme.textPrimary)),
                foregroundColor: AppTheme.textPrimary,
                actions: [
                  TextButton.icon(
                    onPressed: () => _showClearAlertsConfirmation(),
                    icon: Icon(LucideIcons.trash2, size: 16, color: AppTheme.textSecondary),
                    label: Text('Clear All',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),

              // Alert List
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _alertsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accentTeal,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: Center(child: Text('Error: ${snapshot.error}')),
                    );
                  }

                  final allAlerts = snapshot.data ?? [];

                  // Keep only the latest alert per region within the last 24 hours
                  final regionMap = <dynamic, Map<String, dynamic>>{};
                  final now = DateTime.now();
                  for (final alert in allAlerts) {
                    final regionId = alert['region'];
                    final ts = DateTime.tryParse(alert['timestamp'] ?? '');
                    if (ts != null && now.difference(ts).inHours < 24) {
                      final existing = regionMap[regionId];
                      final existingTs = existing != null ? DateTime.tryParse(existing['timestamp'] ?? '') : null;
                      if (existingTs == null || ts.isAfter(existingTs)) {
                        regionMap[regionId] = alert;
                      }
                    }
                  }
                  final alerts = regionMap.values.toList()
                    ..sort((a, b) {
                      final ta = DateTime.tryParse(a['timestamp'] ?? '');
                      final tb = DateTime.tryParse(b['timestamp'] ?? '');
                      return (tb?.millisecondsSinceEpoch ?? 0).compareTo(ta?.millisecondsSinceEpoch ?? 0);
                    });

                  if (alerts.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(child: Text('No alerts found')),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.only(
                      left: AppTheme.spacingMedium,
                      right: AppTheme.spacingMedium,
                      top: AppTheme.spacingMedium,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                           final alert = alerts[index];
                           return _buildAlertCard(alert, index);
                        },
                        childCount: alerts.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert, int index) {
    final severity = (alert['severity'] as String).toUpperCase();
    final severityColor = _getSeverityColor(severity);
    final timestamp = DateTime.parse(alert['timestamp']);
    final timeAgo = _formatTimeAgo(timestamp);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: GestureDetector(
        onTap: () {
          // Pass the generic alert data to detail screen
          Navigator.of(context).pushNamed(
            '/alert_detail',
            arguments: alert,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          decoration: AppTheme.bentoCardLight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: severityColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.alertTriangle,
                      color: severityColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingSmall),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          severity == 'MEDIUM' ? 'Moderate Alert' :
                          '${severity.substring(0, 1)}${severity.substring(1).toLowerCase()} Alert',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${alert['region_name'] ?? 'Unknown Region'}, ${alert['region_district'] ?? ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: severityColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: severityColor, width: 1),
                    ),
                    child: Text(
                      severity == 'MEDIUM' ? 'Moderate' :
                      '${severity.substring(0, 1)}${severity.substring(1).toLowerCase()}',
                      style: TextStyle(
                        color: severityColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              Text(
                alert['message'] ?? 'No details available.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              Row(
                children: [
                   Icon(LucideIcons.clock, size: 12, color: AppTheme.textSecondary),
                   const SizedBox(width: 4),
                   Text(
                    timeAgo,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Icon(LucideIcons.chevronRight, size: 16, color: AppTheme.accentTeal),
                ],
              ),
            ],
          ),
        ),
      )
          .animate()
          .fadeIn(duration: 600.ms, delay: (100 * (index > 5 ? 5 : index)).ms)
          .slideX(begin: 0.2, end: 0),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'CRITICAL': return Colors.red;
      case 'HIGH': return Colors.orange;
      case 'MEDIUM': return Colors.amber;
      case 'LOW': return Colors.green;
      default: return Colors.grey;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final duration = DateTime.now().difference(dateTime);
    if (duration.inDays > 0) {
      return '${duration.inDays} days ago';
    } else if (duration.inHours > 0) {
      return '${duration.inHours} hours ago';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes} mins ago';
    } else {
      return 'Just now';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_application_2/theme/app_theme.dart';
import 'package:flutter_application_2/services/api_service.dart';
import 'package:intl/intl.dart';

/// Alert Feed Screen - Community Alert History
/// Chronological list of all alerts with filtering
class AlertFeedScreen extends StatefulWidget {
  const AlertFeedScreen({super.key});

  @override
  State<AlertFeedScreen> createState() => _AlertFeedScreenState();
}

class _AlertFeedScreenState extends State<AlertFeedScreen> {
  String _filterSeverity = 'All';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _refreshAlerts(),
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverAppBar(
                floating: true,
                backgroundColor: AppTheme.primaryColor,
                title: const Text('Alert History'),
                foregroundColor: Colors.white,
                actions: [
                  IconButton(
                    icon: const Icon(LucideIcons.filter),
                    onPressed: () {},
                  ),
                ],
              ),

              // Filter Chips
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingMedium),
                  child: _buildFilterChips()
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: -0.1, end: 0),
                ),
              ),

              // Alert List
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _alertsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return SliverFillRemaining(
                      child: Center(child: Text('Error: ${snapshot.error}')),
                    );
                  }

                  final alerts = snapshot.data ?? [];
                  
                  // Apply Filter
                  final filteredAlerts = alerts.where((alert) {
                    if (_filterSeverity == 'All') return true;
                    
                    final severity = (alert['severity'] as String).toUpperCase();
                    var filterKey = _filterSeverity.toUpperCase();
                    if (_filterSeverity == 'Moderate') filterKey = 'MEDIUM';
                    
                    return severity == filterKey;
                  }).toList();

                  if (filteredAlerts.isEmpty) {
                    return const SliverFillRemaining(
                      child: Center(child: Text('No alerts found')),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMedium),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                           final alert = filteredAlerts[index];
                           return _buildAlertCard(alert, index);
                        },
                        childCount: filteredAlerts.length,
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

  Widget _buildFilterChips() {
    final filters = ['All', 'Critical', 'High', 'Moderate', 'Low'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _filterSeverity == filter;
          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacingSmall),
            child: GestureDetector(
              onTap: () => setState(() => _filterSeverity = filter),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMedium,
                  vertical: AppTheme.spacingSmall,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  filter,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${alert['region_name'] ?? 'Unknown Region'}, ${alert['region_district'] ?? ''}',
                          style: const TextStyle(
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
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppTheme.spacingSmall),
              Row(
                children: [
                   const Icon(LucideIcons.clock, size: 12, color: AppTheme.textSecondary),
                   const SizedBox(width: 4),
                   Text(
                    timeAgo,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(LucideIcons.chevronRight, size: 16, color: AppTheme.primaryColor),
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

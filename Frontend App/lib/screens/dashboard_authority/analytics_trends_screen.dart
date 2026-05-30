import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend_app/theme/app_theme.dart';
import 'package:frontend_app/services/api_service.dart';
import 'package:intl/intl.dart';

/// Analytics Trends Screen â€” Light theme, professional chart displays
import 'package:frontend_app/theme/theme_provider.dart';
import 'package:provider/provider.dart';

class AnalyticsTrendsScreen extends StatefulWidget {
  const AnalyticsTrendsScreen({super.key});

  @override
  State<AnalyticsTrendsScreen> createState() => _AnalyticsTrendsScreenState();
}

// Stat Card

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String change;
  final bool? changePositive;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.change,
    required this.changePositive,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            label,
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: changePositive == null
                      ? AppTheme.accentTeal.withOpacity(0.12)
                      : (changePositive!
                          ? Colors.green.withOpacity(0.12)
                          : Colors.red.withOpacity(0.12)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  change,
                  style: TextStyle(
                    color: changePositive == null
                        ? AppTheme.accentTeal
                        : (changePositive! ? Colors.green : Colors.red),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Bar Chart

class _BarChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final Color color;

  const _BarChart({
    required this.data,
    required this.labels,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox();

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final showValueLabels = data.length <= 7 && maxValue > 0;
    const double labelReserve = 20.0;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableHeight =
                  constraints.maxHeight - (showValueLabels ? labelReserve : 0);

              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(data.length, (index) {
                  final value = data[index];
                  final barHeight = maxValue > 0
                      ? ((value / maxValue) * availableHeight)
                          .clamp(0.0, availableHeight)
                      : 0.0;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: data.length > 10 ? 1 : 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showValueLabels) ...[
                            Text(
                              value == 0 ? '' : '${value.toInt()}',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
                          Container(
                            height: barHeight,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  color.withOpacity(0.7),
                                  color,
                                ],
                              ),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(4),
                              ),
                            ),
                          )
                              .animate()
                              .scaleY(
                                begin: 0,
                                end: 1,
                                alignment: Alignment.bottomCenter,
                                duration: 700.ms,
                                delay: (index * (data.length > 10 ? 15 : 80))
                                    .ms,
                                curve: Curves.easeOutCubic,
                              ),
                        ],
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(labels.length, (i) {
            bool showLabel = false;
            if (labels.length <= 7) {
              showLabel = true;
            } else if (labels.length == 30) {
              showLabel = (i == 0 || i == 6 || i == 12 || i == 18 || i == 24 || i == 29);
            } else {
              showLabel = (i == 0 || i == labels.length - 1 || (labels.length > 2 ? i == (labels.length ~/ 2) : false));
            }
            return Expanded(
              child: Text(
                showLabel ? labels[i] : '',
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
                softWrap: false,
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 9),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _AnalyticsTrendsScreenState extends State<AnalyticsTrendsScreen> {
  final ApiService _apiService = ApiService();

  String _selectedPeriod = '7 Days';
  Map<String, dynamic> _analyticsData = {};
  List<Map<String, dynamic>> _regions = [];
  String? _selectedRegionId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRegions();
    _loadAnalytics();
  }

  Future<void> _loadRegions() async {
    try {
      final regions = await _apiService.fetchRegions();
      if (mounted) {
        setState(() {
          _regions = regions;
        });
      }
    } catch (e) {
      print('Error loading regions: $e');
    }
  }

  Future<void> _loadAnalytics({bool force = false}) async {
    setState(() => _isLoading = true);

    try {
      final data = await _apiService.fetchAnalytics(
        period: _getPeriodParam(_selectedPeriod),
        regionId: _selectedRegionId != null
            ? int.tryParse(_selectedRegionId!)
            : null,
        force: force,
      );

      if (data.isEmpty) {
        print('[Analytics] Backend returned empty data.');
      } else {
        print('[Analytics] Loaded ${data.length} keys: ${data.keys.toList()}');
      }

      if (mounted) {
        setState(() {
          _analyticsData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[Analytics] Error loading analytics: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getPeriodParam(String period) {
    switch (period) {
      case '24 Hours':
        return '24hours';
      case '7 Days':
        return '7days';
      case '30 Days':
        return '30days';
      default:
        return '7days';
    }
  }

  List<String> _generateLabels(int count) {
    if (count == 1) return ['Now'];
    final now = DateTime.now();
    final dateFormat = DateFormat('E');
    if (count == 7) {
      return List.generate(7, (i) {
        final date = now.subtract(Duration(days: 6 - i));
        return dateFormat.format(date);
      });
    }
    if (count == 30) {
      return List.generate(6, (i) {
        final dayIndex = (i + 1) * 5;
        final date = now.subtract(Duration(days: 30 - dayIndex));
        return '${date.day}';
      });
    }
    return List.generate(count, (i) => '${i + 1}');
  }

  String get periodName => _selectedPeriod;

  @override
  Widget build(BuildContext context) {
    context.watch<ThemeProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: AppTheme.surface,
              foregroundColor: AppTheme.textPrimary,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              title: Text(
                'Analytics & Trends',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              actions: [
                IconButton(
                  icon: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.accentTeal,
                          ),
                        )
                      : Icon(LucideIcons.refreshCw,
                          color: AppTheme.textPrimary),
                  onPressed: _isLoading ? null : () => _loadAnalytics(force: true),
                  tooltip: 'Reload',
                ),
              ],
            ),

            // Region Filter
            if (_regions.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingLarge,
                    AppTheme.spacingLarge,
                    AppTheme.spacingLarge,
                    AppTheme.spacingSmall,
                  ),
                  child: _buildRegionFilter(),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.1, end: 0),
              ),

            // Period Selector
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLarge,
                  vertical: AppTheme.spacingSmall,
                ),
                child: _buildPeriodSelector(),
              )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: -0.1, end: 0),
            ),

            // Stats Cards
            if (!_isLoading && _analyticsData.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLarge,
                  ),
                  child: _buildStatsCards(),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 200.ms)
                    .slideY(begin: 0.1, end: 0),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.spacingLarge),
            ),

            // Alerts per Day Chart
            if (!_isLoading && _analyticsData.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLarge,
                  ),
                  child: _buildAlertsChart(),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 400.ms)
                    .slideY(begin: 0.1, end: 0),
              ),

            // Loading State
            if (_isLoading)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: CircularProgressIndicator(
                      color: AppTheme.accentTeal,
                    ),
                  ),
                ),
              ),

            // Empty / Error State
            if (!_isLoading && _analyticsData.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.accentTealLight,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            LucideIcons.barChart2,
                            size: 48,
                            color: AppTheme.accentTeal,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Analytics Data',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Could not load analytics.\nMake sure the backend server is running and regions are set up.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: () => _loadAnalytics(force: true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentTeal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(LucideIcons.refreshCw, size: 18),
                          label: const Text(
                            'Try Again',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
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

  Widget _buildRegionFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: AppTheme.cardShadow,
      ),
      child: DropdownButton<String>(
        value: _selectedRegionId,
        hint: Text(
          'All Regions',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        dropdownColor: AppTheme.surface,
        underline: const SizedBox(),
        isExpanded: true,
        icon: Icon(LucideIcons.chevronDown,
            color: AppTheme.textSecondary, size: 20),
        style: TextStyle(color: AppTheme.textPrimary),
        items: [
          DropdownMenuItem(
            value: null,
            child: Text('All Regions',
                style: TextStyle(color: AppTheme.textPrimary)),
          ),
          ..._regions.map((region) => DropdownMenuItem(
                value: region['id'].toString(),
                child: Text(
                  '${region['name']} - ${region['district']}',
                  style: TextStyle(color: AppTheme.textPrimary),
                ),
              )),
        ],
        onChanged: (value) {
          setState(() => _selectedRegionId = value);
          _loadAnalytics();
        },
      ),
    );
  }

  Widget _buildPeriodSelector() {
    final periods = ['24 Hours', '7 Days', '30 Days'];
    return Row(
      children: periods.map((period) {
        final isSelected = _selectedPeriod == period;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedPeriod = period);
                _loadAnalytics();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.accentTeal : AppTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.accentTeal
                        : AppTheme.borderColor,
                    width: 1.5,
                  ),
                  boxShadow:
                      isSelected ? AppTheme.tealShadow : AppTheme.cardShadow,
                ),
                child: Text(
                  period,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStatsCards() {
    final highRiskCount = (_analyticsData['high_count'] ?? 0) +
        (_analyticsData['critical_count'] ?? 0);
    final totalRegions = _analyticsData['total_regions'] ?? 0;
    final totalAlerts = _analyticsData['total_alerts'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: LucideIcons.alertTriangle,
            label: 'High Risk Areas',
            value: '$highRiskCount / $totalRegions',
            change: 'Active',
            changePositive: null,
            color: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: AppTheme.spacingMedium),
        Expanded(
          child: _StatCard(
            icon: LucideIcons.bellRing,
            label: 'Total Alerts',
            value: '$totalAlerts',
            change: 'Period',
            changePositive: null,
            color: AppTheme.accentTeal,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertsChart() {
    final rawData = _analyticsData['alerts_per_day'] as List<dynamic>?;
    final backendLabels = _analyticsData['labels'] as List<dynamic>?;
    final chartData =
        rawData?.map<double>((e) => (e as num).toDouble()).toList() ?? [];
    final labels = backendLabels?.map((e) => e.toString()).toList() ??
        _generateLabels(chartData.length);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentTealLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  LucideIcons.bellRing,
                  color: AppTheme.accentTeal,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Text(
                'Alerts per Day ($periodName)',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLarge),
          SizedBox(
            height: 200,
            child: chartData.isNotEmpty
                ? _BarChart(
                    data: chartData,
                    labels: labels,
                    color: AppTheme.accentTeal,
                  )
                : Center(
                    child: Text(
                      'No alert data for this period',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.accentTeal,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Number of Alerts per Day',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}


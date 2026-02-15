import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_2/theme/app_theme.dart';
import 'package:flutter_application_2/services/api_service.dart';
import 'package:intl/intl.dart';

/// Analytics Trends Screen - Data Visualization
/// Dark mode focused with professional chart displays
class AnalyticsTrendsScreen extends StatefulWidget {
  const AnalyticsTrendsScreen({super.key});

  @override
  State<AnalyticsTrendsScreen> createState() => _AnalyticsTrendsScreenState();
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

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);
    
    try {
      final data = await _apiService.fetchAnalytics(
        period: _getPeriodParam(_selectedPeriod),
        regionId: _selectedRegionId != null ? int.tryParse(_selectedRegionId!) : null,
      );
      
      if (mounted) {
        setState(() {
          _analyticsData = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading analytics: $e');
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
    final dateFormat = DateFormat('E'); // Mon, Tue
    
    if (count == 7) {
      // Return last 7 days ending today
      return List.generate(7, (i) {
        final date = now.subtract(Duration(days: 6 - i));
        return dateFormat.format(date);
      });
    }
    
    if (count == 30) {
      // Return 6 labels spread across 30 days
      return List.generate(6, (i) {
        final dayIndex = (i + 1) * 5;
        final date = now.subtract(Duration(days: 30 - dayIndex));
        return '${date.day}';
      });
    }
    
    return List.generate(count, (i) => '${i + 1}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark background
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: const Color(0xFF1E293B),
              title: const Text('Analytics & Trends'),
              actions: [
                IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(LucideIcons.refreshCw),
                  onPressed: _isLoading ? null : _loadAnalytics,
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

            // Rainfall Chart
            if (!_isLoading && _analyticsData.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLarge,
                  ),
                  child: _buildRainfallChart(),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 400.ms)
                    .slideY(begin: 0.1, end: 0),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.spacingLarge),
            ),

            // Susceptibility Chart
            if (!_isLoading && _analyticsData.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLarge,
                  ),
                  child: _buildSusceptibilityChart(),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 600.ms)
                    .slideY(begin: 0.1, end: 0),
              ),

            // Loading State
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Colors.white),
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
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: DropdownButton<String>(
        value: _selectedRegionId,
        hint: const Text(
          'All Regions',
          style: TextStyle(color: Colors.white70),
        ),
        dropdownColor: const Color(0xFF1E293B),
        underline: const SizedBox(),
        isExpanded: true,
        icon: const Icon(LucideIcons.chevronDown, color: Colors.white70, size: 20),
        style: const TextStyle(color: Colors.white),
        items: [
          const DropdownMenuItem(
            value: null,
            child: Text('All Regions', style: TextStyle(color: Colors.white)),
          ),
          ..._regions.map((region) => DropdownMenuItem(
                value: region['id'].toString(),
                child: Text(
                  '${region['name']} - ${region['district']}',
                  style: const TextStyle(color: Colors.white),
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
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF3B82F6)
                        : Colors.white.withOpacity(0.1),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  period,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 11,
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
    final avgRainfall = _analyticsData['avg_rainfall'] ?? 0;
    final highRiskCount = _analyticsData['high_risk_count'] ?? 0;
    
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: LucideIcons.trendingUp,
            label: 'Avg Rainfall',
            value: '${avgRainfall}mm',
            change: 'Live',
            changePositive: null,
            color: const Color(0xFF3B82F6),
          ),
        ),
        const SizedBox(width: AppTheme.spacingMedium),
        Expanded(
          child: _StatCard(
            icon: LucideIcons.alertTriangle,
            label: 'High Risk Areas',
            value: '$highRiskCount',
            change: 'Active',
            changePositive: null,
            color: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  Widget _buildRainfallChart() {
    final rainfallData = (_analyticsData['rainfall_trend'] as List<dynamic>?)
            ?.map<double>((e) => (e as num).toDouble())
            .toList() ??
        [];
    final labels = _generateLabels(rainfallData.length);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.cloudRain,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Text(
                'Rainfall ($periodName)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLarge),
          SizedBox(
            height: 200,
            child: rainfallData.isNotEmpty
                ? _BarChart(
                    data: rainfallData,
                    labels: labels,
                    color: const Color(0xFF3B82F6),
                  )
                : const Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(color: Colors.white54),
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
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Daily Rainfall (mm)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get periodName => _selectedPeriod;

  Widget _buildSusceptibilityChart() {
    final riskData = (_analyticsData['risk_trend'] as List<dynamic>?)
            ?.map<double>((e) => (e as num).toDouble())
            .toList() ??
        [];
    final labels = _generateLabels(riskData.length);

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.mountain,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Text(
                'Risk Index ($periodName)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLarge),
          SizedBox(
            height: 200,
            child: riskData.isNotEmpty
                ? _LineChart(
                    data: riskData,
                    labels: labels,
                    color: const Color(0xFFF59E0B),
                  )
                : const Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 12,
                height: 3,
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Susceptibility Score (0-100)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.6),
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
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: AppTheme.spacingSmall),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 11,
                ),
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
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: changePositive == null
                      ? Colors.blue.withOpacity(0.2)
                      : (changePositive!
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  change,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: changePositive == null
                            ? Colors.blue
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
    final showValueLabels = data.length <= 10;

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(data.length, (index) {
                  final value = data[index];
                  final normalizedHeight = maxValue > 0
                      ? (value / maxValue) * constraints.maxHeight
                      : 0.0;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: data.length > 10 ? 1 : 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (showValueLabels) ...[
                            Text(
                              '${value.toInt()}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Container(
                            height: showValueLabels 
                                ? normalizedHeight - 20 
                                : normalizedHeight,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [color.withOpacity(0.8), color],
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
                                duration: 800.ms,
                                delay: (index * (data.length > 10 ? 20 : 100)).ms,
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
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labels.map((label) {
            return Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                  ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _LineChart extends StatelessWidget {
  final List<double> data;
  final List<String> labels;
  final Color color;

  const _LineChart({
    required this.data,
    required this.labels,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _LineChartPainter(data, color),
            size: const Size(double.infinity, double.infinity),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: labels.map((label) {
            return Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 10,
                  ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _LineChartPainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;
    final showDots = data.length <= 10;

    // Line Paint
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Fill Paint with Gradient
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withOpacity(0.3), color.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final path = Path();
    final stepX = size.width / (data.length - 1);

    // Calculate points
    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue = range > 0 ? (data[i] - minValue) / range : 0.5;
      final y = size.height - (normalizedValue * size.height);
      points.add(Offset(x, y));
    }

    // Draw Smooth Path (Quadratic Bezier)
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final controlPoint = Offset(p0.dx + (p1.dx - p0.dx) / 2, p0.dy);
      final endPoint = Offset(p0.dx + (p1.dx - p0.dx) / 2, p1.dy);
      // Simple smoothing: using midpoints. 
      // Better: Cubic to or just connect cleanly. 
      // Let's use simple straight lines for accuracy but without dots for clutter, 
      // OR use a Catmull-Rom like simplified approach.
      // For now, let's stick to straight lines but cleaner, as simple smoothing often overshoots.
      path.lineTo(p1.dx, p1.dy); 
    }
    
    // Create fill path
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    // Points (Only if sparse)
    if (showDots) {
      for (final point in points) {
        canvas.drawCircle(point, 5, Paint()..color = color);
        canvas.drawCircle(point, 3, Paint()..color = const Color(0xFF1E293B));
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

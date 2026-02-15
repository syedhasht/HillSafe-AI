import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_2/theme/app_theme.dart';
import 'package:flutter_application_2/services/api_service.dart';
import 'package:flutter_application_2/screens/community/risk_map_screen.dart';
import 'package:flutter_application_2/constants/risk_constants.dart';

/// Regional Summary Screen - District Data List
/// Bento Grid of district cards with risk badges and sparklines
class RegionalSummaryScreen extends StatefulWidget {
  const RegionalSummaryScreen({super.key});

  @override
  State<RegionalSummaryScreen> createState() => _RegionalSummaryScreenState();
}

class _RegionalSummaryScreenState extends State<RegionalSummaryScreen> {
  final ApiService _apiService = ApiService();
  List<Map<String, dynamic>> _regions = [];
  bool _isLoading = true;
  String? _errorMessage;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

  Future<void> _loadRegions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final regions = await _apiService.fetchRegions();
      if (mounted) {
        setState(() {
          _regions = regions;
          _isLoading = false;
          _lastUpdated = DateTime.now();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load regions: $e';
        });
      }
    }
  }

  String _getLastUpdatedText() {
    if (_lastUpdated == null) return 'Never';
    
    final diff = DateTime.now().difference(_lastUpdated!);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  Map<String, int> _calculateStats() {
    int highRiskCount = 0;
    int moderateRiskCount = 0;
    int lowRiskCount = 0;

    for (var region in _regions) {
      final score = (region['current_risk_score'] as num?)?.toDouble() ?? 0.0;
      if (score >= RiskConstants.highRiskThreshold) {
        highRiskCount++;
      } else if (score >= RiskConstants.moderateRiskThreshold) {
        moderateRiskCount++;
      } else {
        lowRiskCount++;
      }
    }

    return {
      'high': highRiskCount,
      'moderate': moderateRiskCount,
      'low': lowRiskCount,
    };
  }

  String _getRiskLevel(double score) {
    if (score >= RiskConstants.highRiskThreshold) return 'High';
    if (score >= RiskConstants.moderateRiskThreshold) return 'Moderate';
    return 'Low';
  }

  Color _getRiskColor(double score) {
    if (score >= RiskConstants.highRiskThreshold) return Colors.red;
    if (score >= RiskConstants.moderateRiskThreshold) return Colors.orange;
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceGrey,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              floating: true,
              backgroundColor: AppTheme.primaryColor,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Regional Summary'),
                  if (_lastUpdated != null)
                    Text(
                      'Updated ${_getLastUpdatedText()}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                ],
              ),
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
                  onPressed: _isLoading ? null : _loadRegions,
                  tooltip: 'Reload',
                ),
              ],
            ),

            // Error Message
            if (_errorMessage != null && !_isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingLarge),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.alertCircle, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Stats Summary Header
            if (!_isLoading && _regions.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingLarge),
                  child: _buildStatsSummary(context),
                )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .slideY(begin: -0.2, end: 0),
              ),

            // Loading State
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),

            // District Cards Grid
            if (!_isLoading && _regions.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingLarge,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final region = _regions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
                        child: _buildDistrictCard(context, region, index),
                      );
                    },
                    childCount: _regions.length,
                  ),
                ),
              ),

            // Empty State
            if (!_isLoading && _regions.isEmpty && _errorMessage == null)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          LucideIcons.mapPin,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No regions available',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppTheme.spacingLarge),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSummary(BuildContext context) {
    final stats = _calculateStats();
    
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingLarge),
          decoration: AppTheme.gradientCard,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                '${stats['high']}',
                'High Risk',
                Colors.red.shade100,
              ),
              _buildStatItem(
                context,
                '${stats['moderate']}',
                'Moderate',
                Colors.amber.shade100,
              ),
              _buildStatItem(
                context,
                '${stats['low']}',
                'Low Risk',
                Colors.green.shade100,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.spacingMedium),
        // Live Map Action Button
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const RiskMapScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.map, color: AppTheme.primaryColor, size: 20),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Global Risk Map',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'View interactive live monitoring data',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(LucideIcons.chevronRight, color: AppTheme.primaryColor, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String count, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              count,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingSmall),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontSize: 11,
              ),
        ),
      ],
    );
  }

  Widget _buildDistrictCard(
    BuildContext context,
    Map<String, dynamic> region,
    int index,
  ) {
    final name = region['name'] ?? 'Unknown';
    final district = region['district'] ?? 'Unknown';
    final riskScore = (region['current_risk_score'] as num?)?.toDouble() ?? 0.0;
    final riskLevel = _getRiskLevel(riskScore);
    final riskColor = _getRiskColor(riskScore);
    final riskPercentage = (riskScore * 100).toInt();

    // Generate trend data based on risk score (simulated)
    final trendData = List.generate(
      7,
      (i) => (riskScore * 100 - (6 - i) * 5).clamp(0.0, 100.0),
    );

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => RiskMapScreen(selectedRegion: region),
          ),
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
                // District Icon
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSmall),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    LucideIcons.mapPin,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMedium),

                // District Name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'District - $district',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                      ),
                    ],
                  ),
                ),

                // Risk Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSmall,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: riskColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: riskColor, width: 1.5),
                  ),
                  child: Text(
                    riskLevel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: riskColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingLarge),

            // Risk Score and Sparkline
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Risk Score
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Risk Score',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            '$riskPercentage',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  color: riskColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 36,
                                ),
                          ),
                          Text(
                            '/100',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Sparkline Chart
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '7-Day Trend',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 60,
                        child: CustomPaint(
                          painter: _SparklinePainter(trendData, riskColor),
                          size: const Size(double.infinity, 60),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingMedium),

            // Action Row
            Row(
              children: [
                Icon(
                  LucideIcons.activity,
                  size: 14,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  'Live monitoring',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                ),
                const Spacer(),
                Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(width: 4),
                Text(
                  'View Details',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(duration: 600.ms, delay: (100 * index).ms)
          .slideX(begin: 0.2, end: 0, duration: 600.ms),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _SparklinePainter(this.data, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = color.withOpacity(0.2)
      ..style = PaintingStyle.fill;

    final path = Path();
    final fillPath = Path();

    final maxValue = data.reduce((a, b) => a > b ? a : b);
    final minValue = data.reduce((a, b) => a < b ? a : b);
    final range = maxValue - minValue;

    final stepX = size.width / (data.length - 1);

    // Build paths
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue = range > 0 ? (data[i] - minValue) / range : 0.5;
      final y = size.height - (normalizedValue * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    // Complete fill path
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Draw
    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw dots
    for (int i = 0; i < data.length; i++) {
      final x = i * stepX;
      final normalizedValue = range > 0 ? (data[i] - minValue) / range : 0.5;
      final y = size.height - (normalizedValue * size.height);

      canvas.drawCircle(
        Offset(x, y),
        3,
        Paint()..color = color,
      );
      canvas.drawCircle(
        Offset(x, y),
        2,
        Paint()..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

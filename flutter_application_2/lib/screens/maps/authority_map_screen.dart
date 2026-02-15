import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_application_2/theme/app_theme.dart';
import 'package:flutter_application_2/services/api_service.dart';
import 'dart:async';

/// Authority Map Screen - "War Room" View
/// Full-screen map with live sensor data and heatmap controls
class AuthorityMapScreen extends StatefulWidget {
  const AuthorityMapScreen({super.key});

  @override
  State<AuthorityMapScreen> createState() => _AuthorityMapScreenState();
}

class _AuthorityMapScreenState extends State<AuthorityMapScreen> {
  final ApiService _apiService = ApiService();
  
  bool _showHeatmap = false;
  String _selectedLayer = 'Risk';
  List<Map<String, dynamic>> _regions = [];
  Map<String, dynamic> _sensorData = {};
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _loadRegions();
    _loadSensorData();
    // Auto-refresh every 30 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadRegions();
      _loadSensorData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadRegions() async {
    try {
      final regions = await _apiService.fetchRegions();
      if (mounted) {
        setState(() {
          _regions = regions;
          _isLoading = false;
          _errorMessage = null;
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

  Future<void> _loadSensorData() async {
    try {
      final data = await _apiService.fetchSensorData();
      if (mounted) {
        setState(() {
          _sensorData = data;
        });
      }
    } catch (e) {
      print('Error loading sensor data: $e');
    }
  }

  // Get sensor data from backend
  Map<String, dynamic> _getAggregatedSensorData() {
    if (_sensorData.isEmpty) {
      return {
        'rainfall': '0mm',
        'soilMoisture': '0%',
        'avgRisk': '0%',
        'highRiskCount': 0,
      };
    }
    
    return {
      'rainfall': _sensorData['rainfall'] ?? '0mm',
      'soilMoisture': _sensorData['soil_moisture'] ?? '0%',
      'avgRisk': _sensorData['avg_risk'] ?? '0%',
      'highRiskCount': _sensorData['high_risk_count'] ?? 0,
    };
  }

  Color _getHeatmapColor() {
    switch (_selectedLayer) {
      case 'Rainfall':
        return Colors.blue;
      case 'Soil':
        return Colors.brown;
      case 'Elevation':
        return Colors.green;
      case 'Risk':
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Stack(
          children: [
            // Map Background
            _MapPlaceholder(
              showHeatmap: _showHeatmap,
              regions: _regions,
              selectedLayer: _selectedLayer,
              heatmapColor: _getHeatmapColor(),
            ),

            // Top App Bar
            _buildTopBar(),

            // Bottom Sensor Data Panel
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildSensorDataPanel()
                  .animate()
                  .slideY(begin: 0.2, end: 0, duration: 600.ms)
                  .fadeIn(duration: 600.ms),
            ),

            // Layer Selection Chips
            Positioned(
              top: 80,
              left: AppTheme.spacingMedium,
              child: _buildLayerChips()
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 200.ms)
                  .slideX(begin: -0.2, end: 0),
            ),

            // Heatmap Toggle Button - Better placement
            Positioned(
              top: 80,
              right: AppTheme.spacingMedium,
              child: _buildHeatmapButton()
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 300.ms)
                  .slideX(begin: 0.2, end: 0),
            ),

            // Loading Overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),

            // Error Message
            if (_errorMessage != null && !_isLoading)
              Positioned(
                top: 100,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppTheme.primaryColor.withOpacity(0.9),
            AppTheme.primaryColor.withOpacity(0),
          ],
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: AppTheme.spacingSmall),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'War Room',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              Text(
                '${_regions.length} Regions Monitored',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                    ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingSmall,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'LIVE',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayerChips() {
    final layers = ['Risk', 'Rainfall', 'Soil', 'Elevation'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: layers.map((layer) {
        final isSelected = _selectedLayer == layer;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.spacingSmall),
          child: GestureDetector(
            onTap: () => setState(() => _selectedLayer = layer),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingMedium,
                vertical: AppTheme.spacingSmall,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withOpacity(0.3)
                    : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(isSelected ? 0.6 : 0.3),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                layer,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      fontSize: 12,
                    ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeatmapButton() {
    return GestureDetector(
      onTap: () => setState(() => _showHeatmap = !_showHeatmap),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: _showHeatmap
              ? _getHeatmapColor().withOpacity(0.9)
              : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _showHeatmap ? LucideIcons.eye : LucideIcons.eyeOff,
              color: _showHeatmap ? Colors.white : AppTheme.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              _showHeatmap ? 'Hide Heatmap' : 'Show Heatmap',
              style: TextStyle(
                color: _showHeatmap ? Colors.white : AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSensorDataPanel() {
    final sensorData = _getAggregatedSensorData();
    
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacingMedium),
      padding: const EdgeInsets.all(AppTheme.spacingLarge),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.activity,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSmall),
              Text(
                'Live Sensor Data',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber, width: 1),
                ),
                child: Text(
                  'Updated ${_getLastUpdatedText()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.amber,
                        fontSize: 10,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLarge),
          Row(
            children: [
              Expanded(
                child: _SensorCard(
                  icon: LucideIcons.cloudRain,
                  label: 'Rainfall',
                  value: sensorData['rainfall'],
                  trend: _selectedLayer == 'Rainfall' ? 'Active' : 'Monitoring',
                  trendUp: null,
                  color: const Color(0xFF3B82F6),
                  isHighlighted: _selectedLayer == 'Rainfall',
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: _SensorCard(
                  icon: LucideIcons.droplet,
                  label: 'Soil Moisture',
                  value: sensorData['soilMoisture'],
                  trend: _selectedLayer == 'Soil' ? 'Active' : 'Monitoring',
                  trendUp: null,
                  color: const Color(0xFFF59E0B),
                  isHighlighted: _selectedLayer == 'Soil',
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMedium),
          Row(
            children: [
              Expanded(
                child: _SensorCard(
                  icon: LucideIcons.alertTriangle,
                  label: 'Avg Risk',
                  value: sensorData['avgRisk'],
                  trend: '${sensorData['highRiskCount']} High Risk',
                  trendUp: null,
                  color: const Color(0xFFEF4444),
                  isHighlighted: _selectedLayer == 'Risk',
                ),
              ),
              const SizedBox(width: AppTheme.spacingMedium),
              Expanded(
                child: _SensorCard(
                  icon: LucideIcons.mountain,
                  label: 'Elevation',
                  value: '${_regions.length}',
                  trend: _selectedLayer == 'Elevation' ? 'Active' : 'Regions',
                  trendUp: null,
                  color: const Color(0xFF10B981),
                  isHighlighted: _selectedLayer == 'Elevation',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SensorCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String trend;
  final bool? trendUp;
  final Color color;
  final bool isHighlighted;

  const _SensorCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.trend,
    required this.trendUp,
    required this.color,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMedium),
      decoration: BoxDecoration(
        color: isHighlighted 
            ? color.withOpacity(0.2)
            : Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted
              ? color.withOpacity(0.5)
              : Colors.white.withOpacity(0.2),
          width: isHighlighted ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 11,
                      ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            trend,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 10,
                ),
          ),
        ],
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  final bool showHeatmap;
  final List<Map<String, dynamic>> regions;
  final String selectedLayer;
  final Color heatmapColor;

  const _MapPlaceholder({
    required this.showHeatmap,
    required this.regions,
    required this.selectedLayer,
    required this.heatmapColor,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base Map
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF334155),
                Color(0xFF1E293B),
                Color(0xFF0F172A),
              ],
            ),
          ),
          child: CustomPaint(
            painter: _MapGridPainter(),
            size: Size.infinite,
          ),
        ),

        // Heatmap Overlay
        if (showHeatmap)
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.3, -0.2),
                radius: 0.8,
                colors: [
                  heatmapColor.withOpacity(0.4),
                  heatmapColor.withOpacity(0.3),
                  heatmapColor.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),

        // Dynamic Location Markers from Backend
        ..._buildDynamicLocationMarkers(context),
      ],
    );
  }

  List<Widget> _buildDynamicLocationMarkers(BuildContext context) {
    if (regions.isEmpty) return [];

    // Get screen size for positioning
    final screenSize = MediaQuery.of(context).size;
    
    return regions.asMap().entries.map((entry) {
      final index = entry.key;
      final region = entry.value;
      
      final riskScore = (region['current_risk_score'] as num?)?.toDouble() ?? 0.0;
      final name = region['name'] ?? 'Unknown';
      final district = region['district'] ?? '';
      
      // Determine color based on selected layer and risk score
      Color markerColor;
      if (selectedLayer == 'Risk') {
        markerColor = riskScore >= 0.7
            ? Colors.red
            : riskScore >= 0.3
                ? Colors.orange
                : Colors.green;
      } else if (selectedLayer == 'Rainfall') {
        markerColor = Colors.blue;
      } else if (selectedLayer == 'Soil') {
        markerColor = Colors.brown;
      } else {
        markerColor = Colors.green;
      }
      
      // Distribute markers across screen (in production, use actual lat/lng)
      // For now, create a grid-like distribution
      final row = index ~/ 3;
      final col = index % 3;
      final top = 150.0 + (row * 150.0);
      final left = 80.0 + (col * 100.0);
      
      return Positioned(
        top: top.clamp(100.0, screenSize.height - 200),
        left: left.clamp(50.0, screenSize.width - 100),
        child: GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$name, $district\nRisk: ${(riskScore * 100).toInt()}%'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          child: Column(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: markerColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: markerColor.withOpacity(0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ).animate(onPlay: (controller) => controller.repeat())
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.5, 1.5),
                    duration: 1500.ms,
                  )
                  .then()
                  .scale(
                    begin: const Offset(1.5, 1.5),
                    end: const Offset(1, 1),
                    duration: 1500.ms,
                  ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  name.length > 10 ? '${name.substring(0, 10)}...' : name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..strokeWidth = 0.5;

    const gridSize = 40.0;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

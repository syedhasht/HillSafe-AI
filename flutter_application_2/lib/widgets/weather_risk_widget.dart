import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_2/theme/app_theme.dart';
import 'package:flutter_application_2/services/api_service.dart';

/// Smart Weather & Risk Widget
/// 
/// Location-aware widget that displays weather and landslide risk
/// for the user's nearest region with auto-refresh functionality
class WeatherRiskWidget extends StatefulWidget {
  const WeatherRiskWidget({super.key});

  @override
  State<WeatherRiskWidget> createState() => _WeatherRiskWidgetState();
}

class _WeatherRiskWidgetState extends State<WeatherRiskWidget> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  
  // State variables
  // State variables
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _nearestRegion;
  String? _locationName; // Added for reverse geocoding
  double? _riskScore;
  String? _riskLevel;
  DateTime? _lastUpdated;
  Timer? _autoRefreshTimer;
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _loadData();
    _setupAutoRefresh();
  }
  
  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }
  
  /// Setup auto-refresh every 30 seconds for a "live" feel
  void _setupAutoRefresh() {
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadData();
    });
  }
  
  /// Main data loading function
  Future<void> _loadData() async {
    if (_isLoading && _nearestRegion != null) return; // Prevent double loads
    
    _animationController.repeat();
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Step 1: Check location permission
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permission denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permission denied permanently');
      }
      
      // Step 2: Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high, // Increased accuracy
        timeLimit: const Duration(seconds: 10),
      );
      
      // Step 2.5: Fetch Location Name (Reverse Geocoding)
      String? locationName;
      try {
        locationName = await _apiService.fetchLocationName(position.latitude, position.longitude);
      } catch (e) {
        print('Location name fetch failed: $e');
      }
      
      // Step 3: Fetch all regions
      final regions = await _apiService.fetchRegions();
      if (regions.isEmpty) {
        throw Exception('No regions available');
      }
      
      // Step 4: Find nearest region (for Risk)
      final nearest = _findNearestRegion(
        position.latitude,
        position.longitude,
        regions,
      );
      
      if (nearest == null) {
        throw Exception('Could not find nearest region');
      }

      // Step 4.5: Fetch Live Weather (Open-Meteo) using USER coordinates for accuracy
      double rainfall = (nearest['current_rainfall'] as num?)?.toDouble() ?? 0.0;
      double temperature = (nearest['current_temperature'] as num?)?.toDouble() ?? 20.0;
      
      try {
        final liveWeather = await _apiService.fetchLiveWeather(position.latitude, position.longitude);
        if (liveWeather != null) {
           temperature = (liveWeather['temperature'] as num).toDouble();
           rainfall = (liveWeather['rainfall'] as num).toDouble();
           
           // Update nearest map locally for UI consistency (optional)
           nearest['current_temperature'] = temperature;
           nearest['current_rainfall'] = rainfall;
        }
      } catch (e) {
        print('Live weather fetch failed: $e');
      }
      
      // Step 5: Get risk prediction
      final slope = (nearest['average_slope'] as num?)?.toDouble() ?? 0.0;
      final soil = nearest['soil_type'] ?? 'loam';
      final lithology = nearest['lithology_type'] ?? 'sedimentary';
      
      final riskData = await _apiService.predictRisk(
        rainfall: rainfall,
        slope: slope,
        soil: soil,
        lithology: lithology,
      );
      
      if (mounted) {
        setState(() {
          _nearestRegion = nearest;
          _locationName = locationName; // Update location name
          _riskScore = riskData != null 
              ? (riskData['risk_score'] as num?)?.toDouble() ?? (nearest['current_risk_score'] as num?)?.toDouble() ?? 0.0
              : (nearest['current_risk_score'] as num?)?.toDouble() ?? 0.0;
          _riskLevel = _getRiskLevel(_riskScore!);
          _lastUpdated = DateTime.now();
          _isLoading = false;
        });
        _animationController.stop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
        _animationController.stop();
      }
    }
  }
  
  /// Calculate nearest region using Haversine formula
  Map<String, dynamic>? _findNearestRegion(
    double userLat,
    double userLon,
    List<Map<String, dynamic>> regions,
  ) {
    Map<String, dynamic>? nearest;
    double minDistance = double.infinity;
    
    for (var region in regions) {
      final regionLat = (region['latitude'] as num?)?.toDouble();
      final regionLon = (region['longitude'] as num?)?.toDouble();
      
      if (regionLat == null || regionLon == null) continue;
      
      final distance = _calculateDistance(
        userLat,
        userLon,
        regionLat,
        regionLon,
      );
      
      if (distance < minDistance) {
        minDistance = distance;
        nearest = region;
      }
    }
    
    return nearest;
  }
  
  /// Haversine formula to calculate distance between two points
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    
    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }
  
  /// Get risk level from score
  String _getRiskLevel(double score) {
    if (score >= 0.7) return 'HIGH';
    if (score >= 0.3) return 'MODERATE';
    return 'LOW';
  }
  
  /// Get background color based on risk
  Color _getRiskColor(double score) {
    if (score >= 0.7) return Colors.red.shade400;
    if (score >= 0.3) return Colors.orange.shade400;
    return Colors.green.shade400;
  }
  
  /// Get weather icon based on rainfall
  IconData _getWeatherIcon(double rainfall) {
    if (rainfall > 50) return LucideIcons.cloudRain;
    if (rainfall > 20) return LucideIcons.cloudDrizzle;
    if (rainfall > 0) return LucideIcons.cloud;
    return LucideIcons.sun;
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      child: _isLoading
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorState()
              : _buildWeatherRiskCard(),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }
  
  Widget _buildLoadingState() {
    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.3),
            AppTheme.primaryColor.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.white),
            SizedBox(height: 12),
            Text(
              'Updating live data...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorState() {
    return Container(
      constraints: const BoxConstraints(minHeight: 140),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade300,
            Colors.grey.shade200,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.grey.shade400,
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LucideIcons.alertCircle,
              color: Colors.red,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!.replaceAll('Exception: ', ''),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _loadData,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  bool get _isNight {
    final hour = DateTime.now().hour;
    return hour < 6 || hour > 18;
  }

  LinearGradient _getWeatherGradient(double rainfall, double temp) {
    if (_isNight) {
      return const LinearGradient(
        colors: [Color(0xFF0F172A), Color(0xFF1E293B)], // Deep Night Blue
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    
    // Snow (Cold + Precipitation)
    if (rainfall > 0 && temp <= 4) {
      return const LinearGradient(
        colors: [Color(0xFF93C5FD), Color(0xFFDBEAFE)], // Icy Blue
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    
    // Rain
    if (rainfall > 0) {
      return const LinearGradient(
        colors: [Color(0xFF334155), Color(0xFF475569)], // Stormy Grey
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    
    // Sunny / Clear
    return const LinearGradient(
      colors: [Color(0xFFF59E0B), Color(0xFFF97316)], // Vibrant Orange
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  IconData _getBackgroundIcon(double rainfall, double temp) {
    if (_isNight) return LucideIcons.moon;
    if (rainfall > 0 && temp <= 4) return LucideIcons.snowflake;
    if (rainfall > 0) return LucideIcons.cloudRain;
    return LucideIcons.sun;
  }

  Color _getRiskBadgeColor(double score) {
    if (score >= 0.7) return Colors.red;
    if (score >= 0.3) return Colors.orange;
    return Colors.green;
  }

  Widget _buildWeatherRiskCard() {
    final rainfall = (_nearestRegion!['current_rainfall'] as num?)?.toDouble() ?? 0.0;
    final temperature = (_nearestRegion!['current_temperature'] as num?)?.toDouble() ?? 20.0;
    // Use fetched location name, fallback to region name
    final regionName = _locationName ?? _nearestRegion!['name'] ?? 'Unknown';
    
    final gradient = _getWeatherGradient(rainfall, temperature);
    final bgIcon = _getBackgroundIcon(rainfall, temperature);
    final riskBadgeColor = _getRiskBadgeColor(_riskScore!);

    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Large Background Icon (The "Pic" effect)
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                bgIcon,
                size: 180,
                color: Colors.white.withOpacity(0.15),
              ),
            ),
            
            // Glassmorphism overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.transparent,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Location & Time
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.mapPin, color: Colors.white, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                regionName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            DateFormat('EEE, d MMM • h:mm a').format(_lastUpdated ?? DateTime.now()),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      
                      // Refresh Button
                       Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _loadData,
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: RotationTransition(
                              turns: _animationController,
                              child: const Icon(
                                LucideIcons.refreshCw,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Weather & Risk Info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Weather Temp
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${temperature.toStringAsFixed(0)}°',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(_getWeatherIcon(rainfall), color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                rainfall > 0 
                                    ? (temperature <= 4 ? 'Snow' : 'Rain') 
                                    : (_isNight ? 'Clear Night' : 'Sunny'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const Spacer(),
                      
                      // Risk Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: riskBadgeColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: riskBadgeColor.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.alertTriangle, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              '$_riskLevel RISK',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

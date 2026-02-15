import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_application_2/services/api_service.dart';
import 'package:flutter_application_2/services/notification_service.dart';

/// Safety Controller
/// 
/// Global state manager for automated weather and risk updates
/// Runs auto-refresh cycle every 2 hours
class SafetyController extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final NotificationService _notificationService = NotificationService();
  
  // State variables
  double? _currentRiskScore;
  double? _previousRiskScore;
  Map<String, dynamic>? _weatherData;
  Map<String, dynamic>? _locationData;
  Map<String, dynamic>? _nearestRegion;
  DateTime? _lastUpdate;
  bool _isUpdating = false;
  String? _errorMessage;
  
  Timer? _autoRefreshTimer;
  
  // Getters
  double? get currentRiskScore => _currentRiskScore;
  double? get previousRiskScore => _previousRiskScore;
  Map<String, dynamic>? get weatherData => _weatherData;
  Map<String, dynamic>? get locationData => _locationData;
  Map<String, dynamic>? get nearestRegion => _nearestRegion;
  DateTime? get lastUpdate => _lastUpdate;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;
  
  String get riskLevel {
    if (_currentRiskScore == null) return 'UNKNOWN';
    if (_currentRiskScore! >= 0.7) return 'HIGH';
    if (_currentRiskScore! >= 0.3) return 'MODERATE';
    return 'LOW';
  }
  
  Color get riskColor {
    if (_currentRiskScore == null) return Colors.grey;
    if (_currentRiskScore! >= 0.7) return Colors.red;
    if (_currentRiskScore! >= 0.3) return Colors.orange;
    return Colors.green;
  }
  
  /// Initialize controller and start auto-refresh
  Future<void> initialize() async {
    print('SafetyController: Initializing...');
    
    // Initialize notification service
    await _notificationService.initialize();
    await _notificationService.requestPermissions();
    
    // Perform initial data update
    await updateAllData();
    
    // Start 2-hour auto-refresh timer
    _startAutoRefresh();
    
    print('SafetyController: Initialized successfully');
  }
  
  /// Start 2-hour periodic refresh
  void _startAutoRefresh() {
    // Cancel existing timer if any
    _autoRefreshTimer?.cancel();
    
    // Create new timer that runs every 2 hours
    _autoRefreshTimer = Timer.periodic(
      const Duration(hours: 2),
      (_) async {
        print('SafetyController: Auto-refresh triggered');
        await updateAllData();
      },
    );
    
    print('SafetyController: Auto-refresh started (2-hour cycle)');
  }
  
  /// Main update sequence
  Future<void> updateAllData() async {
    if (_isUpdating) {
      print('SafetyController: Update already in progress, skipping');
      return;
    }
    
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();
    
    try {
      print('SafetyController: Starting update sequence...');
      
      // Step 1: Get Location
      print('SafetyController: [1/4] Getting location...');
      final position = await _getUserLocation();
      if (position == null) {
        throw Exception('Unable to get location');
      }
      
      _locationData = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'timestamp': DateTime.now().toIso8601String(),
      };
      print('SafetyController: Location obtained: ${position.latitude}, ${position.longitude}');
      
      // Step 2: Find Nearest Region
      print('SafetyController: [2/4] Finding nearest region...');
      final regions = await _apiService.fetchRegions();
      if (regions.isEmpty) {
        throw Exception('No regions available');
      }
      
      _nearestRegion = _findNearestRegion(
        position.latitude,
        position.longitude,
        regions,
      );
      
      if (_nearestRegion == null) {
        throw Exception('Could not find nearest region');
      }
      
      print('SafetyController: Nearest region: ${_nearestRegion!['name']}');
      
      // Step 3: Fetch Weather Data
      print('SafetyController: [3/4] Fetching weather data...');
      _weatherData = {
        'temperature': _nearestRegion!['current_temperature'] ?? 20.0,
        'rainfall': _nearestRegion!['current_rainfall'] ?? 0.0,
        'humidity': _nearestRegion!['current_humidity'] ?? 50.0,
        'timestamp': DateTime.now().toIso8601String(),
      };
      print('SafetyController: Weather data obtained');
      
      // Step 4: Get AI Risk Prediction
      print('SafetyController: [4/4] Calling AI prediction...');
      final rainfall = (_weatherData!['rainfall'] as num).toDouble();
      final slope = (_nearestRegion!['average_slope'] as num?)?.toDouble() ?? 0.0;
      final soil = _nearestRegion!['soil_type'] ?? 'loam';
      final lithology = _nearestRegion!['lithology_type'] ?? 'sedimentary';
      
      final riskData = await _apiService.predictRisk(
        rainfall: rainfall,
        slope: slope,
        soil: soil,
        lithology: lithology,
      );
      
      // Save previous score before updating
      _previousRiskScore = _currentRiskScore;
      
      // Update risk score
      if (riskData != null) {
        _currentRiskScore = (riskData['risk_score'] as num).toDouble();
        print('SafetyController: AI prediction received: ${(_currentRiskScore! * 100).toInt()}%');
      } else {
        // Fallback to region's current risk score
        _currentRiskScore = (_nearestRegion!['current_risk_score'] as num?)?.toDouble() ?? 0.0;
        print('SafetyController: Using region risk score: ${(_currentRiskScore! * 100).toInt()}%');
      }
      
      _lastUpdate = DateTime.now();
      
      // Step 5: Check if notification should be triggered
      _checkRiskThreshold();
      
      print('SafetyController: Update completed successfully');
      
    } catch (e) {
      _errorMessage = e.toString();
      print('SafetyController: Update failed: $e');
    } finally {
      _isUpdating = false;
      notifyListeners();
    }
  }
  
  /// Get user's current location
  Future<Position?> _getUserLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('SafetyController: Location services disabled');
        return null;
      }
      
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('SafetyController: Location permission denied');
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        print('SafetyController: Location permission denied forever');
        return null;
      }
      
      // Get position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      
      return position;
    } catch (e) {
      print('SafetyController: Error getting location: $e');
      return null;
    }
  }
  
  /// Find nearest region using distance calculation
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
  
  /// Calculate distance using Haversine formula
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
  
  /// Check if risk crossed threshold and trigger notification
  void _checkRiskThreshold() {
    // Only trigger if we have both current and previous scores
    if (_currentRiskScore == null) return;
    
    // Critical condition: current risk is high (>= 0.7) AND previous was lower
    bool shouldNotify = _currentRiskScore! >= 0.7 && 
                       (_previousRiskScore == null || _previousRiskScore! < 0.7);
    
    if (shouldNotify && _nearestRegion != null) {
      print('SafetyController: Risk threshold crossed! Triggering notification...');
      
      _notificationService.showRiskNotification(
        regionName: _nearestRegion!['name'] ?? 'Your Area',
        riskScore: _currentRiskScore!,
      );
    }
  }
  
  /// Manual refresh (for pull-to-refresh or button)
  Future<void> refresh() async {
    print('SafetyController: Manual refresh requested');
    await updateAllData();
  }
  
  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
    print('SafetyController: Disposed');
  }
}

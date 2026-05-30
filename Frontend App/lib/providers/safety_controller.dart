import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:frontend_app/services/api_service.dart';
import 'package:frontend_app/services/notification_service.dart';

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
    if (_currentRiskScore! >= 0.7) return 'CRITICAL';
    if (_currentRiskScore! >= 0.5) return 'HIGH';
    if (_currentRiskScore! >= 0.3) return 'MEDIUM';
    return 'LOW';
  }
  
  Color get riskColor {
    if (_currentRiskScore == null) return Colors.grey;
    if (_currentRiskScore! >= 0.7) return Colors.red;
    if (_currentRiskScore! >= 0.5) return Colors.orange;
    if (_currentRiskScore! >= 0.3) return Colors.amber;
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
      
      // Step 2: Backend location-based prediction
      print('SafetyController: [2/4] Calling backend location-risk prediction...');
      final riskData = await _apiService.predictLocationRisk(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (riskData == null) {
        throw Exception('Backend prediction unavailable');
      }

      _nearestRegion = riskData['nearest_region'] as Map<String, dynamic>?;
      _weatherData = riskData['weather'] as Map<String, dynamic>?;

      if (_nearestRegion == null || _weatherData == null) {
        throw Exception('Backend prediction response missing location or weather data');
      }

      print('SafetyController: Nearest region: ${_nearestRegion!['name']}');
      print('SafetyController: Weather data obtained from ${_weatherData!['source']}');
      
      // Save previous score before updating
      _previousRiskScore = _currentRiskScore;
      
      _currentRiskScore = (riskData['risk_score'] as num).toDouble();
      print('SafetyController: AI prediction received: ${(_currentRiskScore! * 100).toInt()}%');
      
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


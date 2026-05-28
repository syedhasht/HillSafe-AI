import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';

/// API Service for HillSafe AI Backend Communication
/// 
/// Handles all API calls to the Django backend including:
/// - User authentication
/// - Fetching regions
/// - Fetching alerts
/// - Data ingestion triggers
class ApiService {
  // Base URL - Use 10.0.2.2 for Android Emulator (maps to localhost on host machine)
  // For physical devices, use your computer's IP address (e.g., 192.168.1.100:8000)
  // For production: replace with your Render backend URL
  // For local dev: use your computer's IP or 10.0.2.2 (Android emulator)
  static const String baseUrl = 'https://hillsafe-ai.onrender.com/api';


  
  // Secure storage for authentication token
  final _storage = const FlutterSecureStorage();
  
  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _roleKey = 'user_role';
  static const String _usernameKey = 'username';
  static const String _userIdKey = 'user_id';

  /// Login Function
  /// 
  /// Authenticates user with username and phone number (passwordless)
  /// Saves token and user info to secure storage on success
  /// 
  /// Returns true if login successful, false otherwise
  Future<bool> login(String username, String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'phone_number': phoneNumber,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Save authentication data to secure storage
        await _storage.write(key: _tokenKey, value: data['token']);
        await _storage.write(key: _roleKey, value: data['role']);
        await _storage.write(key: _usernameKey, value: data['username']);
        await _storage.write(key: _userIdKey, value: data['user_id'].toString());
        
        return true;
      } else if (response.statusCode == 401) {
        // Invalid credentials
        return false;
      } else {
        // Other error
        print('Login error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Login exception: $e');
      return false;
    }
  }

  /// Logout Function
  /// 
  /// Clears all stored authentication data
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _userIdKey);
  }

  /// Get current GPS position with permissions check
  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 5),
      );
    } catch (e) {
      print('Get position error: $e');
      return null;
    }
  }

  /// Get stored authentication token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Get stored user role
  Future<String?> getRole() async {
    return await _storage.read(key: _roleKey);
  }

  /// Get stored username
  Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }

  /// Check if user is logged in
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Fetch Sensor Data
  /// 
  /// Retrieves aggregated sensor data from all regions
  /// Used by War Room to display live sensor metrics
  /// 
  /// Returns map with sensor data or empty map on error
  Future<Map<String, dynamic>> fetchSensorData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sensor-data/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Fetch sensor data error: ${response.statusCode} - ${response.body}');
        return {};
      }
    } catch (e) {
      print('Error fetching sensor data: $e');
      return {};
    }
  }

  /// Fetch Districts
  /// 
  /// Retrieves list of unique districts from regions
  /// Used for dynamic district dropdowns throughout the app
  /// 
  /// Returns list of district names or empty list on error
  Future<List<String>> fetchDistricts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/districts/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['districts']);
      } else {
        print('Fetch districts error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error fetching districts: $e');
      return [];
    }
  }

  /// Fetch Safety Status
  /// 
  /// Retrieves count of users who marked themselves safe, grouped by region
  /// 
  /// Returns safety status data map or empty map on error
  Future<Map<String, dynamic>> fetchSafetyStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/safety-status/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Fetch safety status error: ${response.statusCode} - ${response.body}');
        return {};
      }
    } catch (e) {
      print('Error fetching safety status: $e');
      return {};
    }
  }

  /// Mark User as Safe
  /// 
  /// Allows users to mark themselves as safe or unsafe
  /// 
  /// Parameters:
  /// - userId: User ID to update
  /// - regionId: Optional region ID for user's location
  /// - isSafe: Whether user is safe (default: true)
  /// 
  /// Returns true if successful
  Future<bool> markUserSafe({
    required int userId,
    int? regionId,
    bool isSafe = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/mark-safe/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'region_id': regionId,
          'is_safe': isSafe,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      } else {
        print('Mark safe error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      print('Error marking user safe: $e');
      return false;
    }
  }

  /// Fetch Alerts Function
  /// 
  /// Retrieves list of active alerts from backend
  /// Requires authentication token
  /// 
  /// Returns list of alert maps or empty list on error
  Future<List<Map<String, dynamic>>> fetchAlerts() async {
    try {
      final token = await getToken();
      
      final headers = {'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Token $token';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/alerts/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        print('Fetch alerts error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Fetch alerts exception: $e');
      return [];
    }
  }

  /// Fetch Regions Function
  /// 
  /// Retrieves list of all regions from backend
  /// 
  /// Returns list of region maps or empty list on error
  Future<List<Map<String, dynamic>>> fetchRegions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/regions/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        print('Fetch regions error: ${response.statusCode} - ${response.body}');
        throw Exception('Server is not live right now. Please try again in a few minutes.');
      }
    } catch (e) {
      print('Fetch regions exception: $e');
      throw Exception('Server is not live right now. Please try again in a few minutes.');
    }
  }

  /// Predict Risk Function
  /// 
  /// Calls ML Engine API to predict landslide risk for given parameters
  /// 
  /// Returns Map with risk_score, risk_level, and is_safe
  Future<Map<String, dynamic>?> predictRisk({
    required double rainfall,
    required double slope,
    required String soil,
    required String lithology,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/predict/risk/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'rainfall': rainfall,
          'slope': slope,
          'soil': soil,
          'lithology': lithology,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('Predict risk error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Predict risk exception: $e');
      return null;
    }
  }

  /// Predict Risk From Location
  ///
  /// Sends only the user's GPS location. The backend fetches weather, finds the
  /// nearest region, prepares numeric model inputs, and runs the ML model.
  Future<Map<String, dynamic>?> predictLocationRisk({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/predict/location-risk/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('Predict location risk error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Predict location risk exception: $e');
      return null;
    }
  }

  /// Trigger Data Ingestion
  /// 
  /// Manually triggers weather data fetch and risk calculation for all regions
  /// Requires authentication (typically for authorities)
  /// 
  /// Returns response data or null on error
  Future<Map<String, dynamic>?> triggerDataIngestion() async {
    try {
      final token = await getToken();
      
      if (token == null) {
        print('No authentication token found');
        return null;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/ingest/trigger/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Trigger ingestion error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Trigger ingestion exception: $e');
      return null;
    }
  }

  /// Submit Incident Report
  /// 
  /// Submits an incident report to the backend
  /// 
  /// Returns true if successful, false otherwise
  Future<bool> submitIncident(String description, int regionId, [String? imagePath]) async {
    try {
      print('=== SUBMIT INCIDENT API CALL ===');
      print('Region ID: $regionId');
      print('Description length: ${description.length}');
      print('Has image: ${imagePath != null}');
      
      final token = await getToken();
      
      if (token == null) {
        print('ERROR: No authentication token found');
        throw Exception('Not authenticated. Please log in.');
      }

      print('Token found: ${token.substring(0, 10)}...');
      print('Sending request to: $baseUrl/reports/submit/');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/reports/submit/'),
      );

      request.headers['Authorization'] = 'Token $token';
      request.fields['description'] = description;
      request.fields['region_id'] = regionId.toString();

      print('Request headers: ${request.headers}');
      print('Request fields: ${request.fields}');

      // Add image if provided
      if (imagePath != null && imagePath.isNotEmpty) {
        request.files.add(await http.MultipartFile.fromPath('image', imagePath));
        print('Image added to request');
      }

      print('Sending request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('✓ Incident report submitted successfully');
        return true;
      } else {
        print('✗ Submit incident error: ${response.statusCode}');
        print('Response body: ${response.body}');
        if (response.statusCode == 401) {
          throw Exception('Unauthorized. Please login again.');
        } else if (response.statusCode == 400) {
          throw Exception('Invalid data: ${response.body}');
        }
        throw Exception('Failed to submit (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('✗ Submit incident exception: $e');
      rethrow;
    }
  }

  /// Check if User is Safe in a Region
  /// 
  /// Calls the backend GET endpoint for safety status
  /// 
  /// Returns true if user is marked as safe, false otherwise
  Future<bool> checkSafetyStatus(int regionId) async {
    final data = await checkSafetyStatusDetails(regionId);
    return data['is_active'] == true;
  }

  /// Returns full safety check-in state, including cooldown timing.
  Future<Map<String, dynamic>> checkSafetyStatusDetails(int regionId) async {
    try {
      final token = await getToken();
      
      if (token == null) return {};

      final response = await http.get(
        Uri.parse('$baseUrl/reports/mark-safe/?region_id=$regionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      print('Check safety status response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return {};
    } catch (e) {
      print('Check safety status exception: $e');
      return {};
    }
  }

  /// Mark User as Safe
  /// 
  /// Marks the current user as safe in a specific region
  /// 
  /// Returns true if successful, false otherwise
  Future<Map<String, dynamic>?> markAsSafe(
    int regionId, {
    double? latitude,
    double? longitude,
    String? areaName,
  }) async {
    try {
      final token = await getToken();
      
      if (token == null) {
        print('No authentication token found');
        return null;
      }

      print('Marking safe for region: $regionId');

      final response = await http.post(
        Uri.parse('$baseUrl/reports/mark-safe/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'region_id': regionId,
          'latitude': latitude,
          'longitude': longitude,
          'area_name': areaName,
        }),
      );

      print('Mark safe response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        print('Marked as safe successfully');
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('Mark safe error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Mark safe exception: $e');
      return null;
    }
  }

  /// Get Region Statistics
  /// 
  /// Retrieves safety statistics for a region (for authorities)
  /// 
  /// Returns statistics data or null on error
  Future<Map<String, dynamic>?> getRegionStats(int regionId) async {
    try {
      final token = await getToken();
      
      if (token == null) {
        print('No authentication token found');
        return null;
      }

      final response = await http.get(
        Uri.parse('$baseUrl/reports/stats/$regionId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Get stats error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Get stats exception: $e');
      return null;
    }
  }

  /// Fetch Analytics Data
  /// 
  /// Retrieves analytics data including rainfall and risk trends
  /// 
  /// Parameters:
  /// - period: '24hours', '7days', or '30days'
  /// - regionId: Optional region ID to filter analytics
  /// 
  /// Returns analytics data map or empty map on error
  Future<Map<String, dynamic>> fetchAnalytics({
    required String period,
    int? regionId,
  }) async {
    try {
      String url = '$baseUrl/analytics/?period=$period';
      if (regionId != null) {
        url += '&region_id=$regionId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print('Fetch analytics error: ${response.statusCode} - ${response.body}');
        return {};
      }
    } catch (e) {
      print('Fetch analytics exception: $e');
      return {};
    }
  }
  /// Fetch Live Weather Function
  /// 
  /// Retrieves real-time weather data from Open-Meteo API
  /// No API key required.
  /// 
  /// Returns Map with temperature, rainfall, and weather code
  Future<Map<String, dynamic>?> fetchLiveWeather(double lat, double lon) async {
    try {
      final url = 'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,rain,snowfall,weather_code';
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current'];
        return {
          'temperature': current['temperature_2m'],
          'rainfall': (current['rain'] as num).toDouble() + (current['snowfall'] as num).toDouble(),
          'is_snowing': (current['snowfall'] as num) > 0,
          'weather_code': current['weather_code'],
        };
      } else {
        print('Fetch live weather error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Fetch live weather exception: $e');
      return null;
    }
  }

  /// Fetch All Reports Function
  /// 
  /// Retrieves list of all incident reports from backend (for authorities)
  /// 
  /// Returns list of report maps or empty list on error
  Future<List<Map<String, dynamic>>> fetchAllReports({int? regionId}) async {
    try {
      final token = await getToken();
      
      final headers = {'Content-Type': 'application/json'};
      if (token != null) {
        headers['Authorization'] = 'Token $token';
      }

      String url = '$baseUrl/reports/list/';
      if (regionId != null) {
        url += '?region_id=$regionId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        print('Fetch reports error: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      print('Fetch reports exception: $e');
      return [];
    }
  }

  /// Fetch Location Name (Reverse Geocoding)
  /// 
  /// Uses OpenStreetMap Nominatim API to get location name from coordinates
  /// No API key required, but requires User-Agent
  /// 
  /// Returns city/town/village name or null
  Future<String?> fetchLocationName(double lat, double lon) async {
    try {
      final url = 'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'HillSafeAI/1.0 (flutter_app)',
          'Accept-Language': 'en',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'];
        if (address == null) return null;
        
        // Prefer the most local label so the weather card reflects the
        // user's actual GPS area, not only the nearest major region.
        return address['neighbourhood'] ??
               address['suburb'] ??
               address['quarter'] ??
               address['hamlet'] ??
               address['village'] ??
               address['town'] ??
               address['city'] ??
               address['municipality'] ??
               address['county'] ??
               address['state_district'] ??
               address['state'];
      }
      return null;
    } catch (e) {
      print('Reverse geocoding error: $e');
      return null;
    }
  }
}



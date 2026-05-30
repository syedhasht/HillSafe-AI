import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  // For local dev: static const String baseUrl = 'http://192.168.100.217:8001/api';
  static const String baseUrl = 'https://hillsafe-ai.onrender.com/api';

  // Shared persistent HTTP client for TCP connection pooling & keep-alive
  static final http.Client _client = http.Client();

  // Secure storage for authentication token
  final _storage = const FlutterSecureStorage();

  // Storage keys
  static const String _tokenKey = 'auth_token';
  static const String _roleKey = 'user_role';
  static const String _usernameKey = 'username';
  static const String _userIdKey = 'user_id';
  static const String _phoneKey = 'phone_number';
  static const String _emailKey = 'email';
  static const String _languageKey = 'language';

  /// Login Function
  ///
  /// Authenticates user. Authority: username + password. Community: username + phone (passwordless).
  /// Returns true if login successful, false otherwise.
  Future<bool> login(
    String username,
    String phoneNumber, {
    String role = 'COMMUNITY',
    String password = '',
  }) async {
    final error = await loginWithError(username, phoneNumber,
        role: role, password: password);
    return error == null;
  }

  /// Login with detailed error message.
  ///
  /// Returns null on success, or an error string on failure.
  Future<String?> loginWithError(
    String username,
    String phoneNumber, {
    String role = 'COMMUNITY',
    String password = '',
  }) async {
    try {
      final body = <String, dynamic>{
        'username': username,
        'phone_number': phoneNumber,
        'role': role,
      };
      if (password.isNotEmpty) {
        body['password'] = password;
      }

      final response = await _client.post(
        Uri.parse('$baseUrl/login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Save authentication data to secure storage
        await _storage.write(key: _tokenKey, value: data['token']);
        await _storage.write(key: _roleKey, value: data['role']);
        await _storage.write(key: _usernameKey, value: data['username']);
        await _storage.write(
            key: _phoneKey, value: data['phone_number'] ?? phoneNumber);
        await _storage.write(key: _emailKey, value: data['email'] ?? '');
        await _storage.write(key: _languageKey, value: data['language'] ?? 'en');
        await _storage.write(
            key: _userIdKey, value: data['user_id'].toString());

        // Save dark mode preference to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final isDark = data['dark_mode'] == true;
        await prefs.setBool('isDarkMode', isDark);

        return null; // success
      }

      // Try to extract error message from backend
      try {
        final errData = jsonDecode(response.body);
        return errData['error']?.toString() ?? 'Login failed. Please try again.';
      } catch (_) {
        return 'Login failed. Please try again.';
      }
    } catch (e) {
      print('Login exception: $e');
      return 'Network error. Please check your connection.';
    }
  }

  /// Sign Up Authority
  ///
  /// Creates a new AUTHORITY account. Returns null on success or an error string.
  Future<String?> signupAuthority({
    required String username,
    required String password,
    String email = '',
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/signup/authority/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'email': email,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _storage.write(key: _tokenKey, value: data['token']);
        await _storage.write(key: _roleKey, value: data['role']);
        await _storage.write(key: _usernameKey, value: data['username']);
        await _storage.write(
            key: _phoneKey, value: data['phone_number'] ?? '');
        await _storage.write(key: _emailKey, value: data['email'] ?? '');
        await _storage.write(key: _languageKey, value: data['language'] ?? 'en');
        await _storage.write(
            key: _userIdKey, value: data['user_id'].toString());

        // Save dark mode preference to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final isDark = data['dark_mode'] == true;
        await prefs.setBool('isDarkMode', isDark);

        return null; // success
      }

      try {
        final errData = jsonDecode(response.body);
        return errData['error']?.toString() ?? 'Sign-up failed. Please try again.';
      } catch (_) {
        return 'Sign-up failed. Please try again.';
      }
    } catch (e) {
      print('Signup exception: $e');
      return 'Network error. Please check your connection.';
    }
  }


  /// Logout Function
  ///
  /// Clears all stored authentication data
  Future<void> logout() async {
    final token = await _storage.read(key: _tokenKey);

    if (token != null) {
      try {
        await _client.post(
          Uri.parse('$baseUrl/logout/'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Token $token',
          },
        ).timeout(const Duration(seconds: 15));
      } catch (e) {
        print('Logout exception: $e');
      }
    }

    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _roleKey);
    await _storage.delete(key: _usernameKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _phoneKey);
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _languageKey);
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
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 12),
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

  /// Register this device for radius-based Firebase alerts.
  ///
  /// The backend stores the FCM token with the latest GPS point, and authority
  /// alerts are sent only to devices within the selected region's alert radius.
  Future<bool> registerDeviceForAlerts({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final authToken = await getToken();
      if (authToken == null || authToken.isEmpty) return false;

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      final fcmToken = await messaging.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return false;

      final response = await _client.post(
        Uri.parse('$baseUrl/accounts/save-device-token/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $authToken',
        },
        body: jsonEncode({
          'token': fcmToken,
          'latitude': latitude,
          'longitude': longitude,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) return true;
      print('Save device token error: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      print('Save device token exception: $e');
      return false;
    }
  }

  /// Get stored user role
  Future<String?> getRole() async {
    return await _storage.read(key: _roleKey);
  }

  /// Get stored username
  Future<String?> getUsername() async {
    return await _storage.read(key: _usernameKey);
  }

  Future<String?> getPhoneNumber() async {
    return await _storage.read(key: _phoneKey);
  }

  Future<String?> getEmail() async {
    return await _storage.read(key: _emailKey);
  }

  Future<String?> getLanguage() async {
    return await _storage.read(key: _languageKey);
  }

  Future<Map<String, dynamic>?> fetchProfile() async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await _client.get(
        Uri.parse('$baseUrl/accounts/profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _storage.write(
            key: _usernameKey, value: data['username']?.toString() ?? '');
        await _storage.write(
            key: _phoneKey, value: data['phone_number']?.toString() ?? '');
        await _storage.write(
            key: _emailKey, value: data['email']?.toString() ?? '');
        await _storage.write(
            key: _languageKey, value: data['language']?.toString() ?? 'en');

        // Save dark mode preference to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        final isDark = data['dark_mode'] == true;
        await prefs.setBool('isDarkMode', isDark);

        return data;
      }

      print('Fetch profile error: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Fetch profile exception: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> updateProfile({
    required String username,
    required String email,
    String? phoneNumber,
    String? language,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await _client.patch(
        Uri.parse('$baseUrl/accounts/profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'username': username,
          'email': email,
          if (phoneNumber != null) 'phone_number': phoneNumber,
          if (language != null) 'language': language,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _storage.write(key: _usernameKey, value: data['username'] ?? username);
        await _storage.write(key: _emailKey, value: data['email'] ?? email);
        await _storage.write(
            key: _languageKey, value: data['language']?.toString() ?? 'en');
        await _storage.write(
            key: _phoneKey, value: data['phone_number']?.toString() ?? '');

        // Save dark mode preference to SharedPreferences if returned
        if (data.containsKey('dark_mode')) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isDarkMode', data['dark_mode'] == true);
        }

        return data;
      }

      print('Update profile error: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Update profile exception: $e');
      return null;
    }
  }

  Future<bool> updateDarkMode(bool isDark) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await _client.patch(
        Uri.parse('$baseUrl/accounts/profile/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'dark_mode': isDark,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isDarkMode', data['dark_mode'] == true);
        return true;
      }
      return false;
    } catch (e) {
      print('Update dark mode exception: $e');
      return false;
    }
  }

  Future<int?> getUserId() async {
    final value = await _storage.read(key: _userIdKey);
    return int.tryParse(value ?? '');
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
      final response = await _client.get(
        Uri.parse('$baseUrl/sensor-data/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print(
            'Fetch sensor data error: ${response.statusCode} - ${response.body}');
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
      final response = await _client.get(
        Uri.parse('$baseUrl/districts/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['districts']);
      } else {
        print(
            'Fetch districts error: ${response.statusCode} - ${response.body}');
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
      final response = await _client.get(
        Uri.parse('$baseUrl/safety-status/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print(
            'Fetch safety status error: ${response.statusCode} - ${response.body}');
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
      final response = await _client.post(
        Uri.parse('$baseUrl/mark-safe/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'region_id': regionId,
          'is_safe': isSafe,
        }),
      ).timeout(const Duration(seconds: 30));

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

      final response = await _client.get(
        Uri.parse('$baseUrl/alerts/'),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

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
      final response = await _getRegionsResponse(refresh: true);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        print('Fetch regions error: ${response.statusCode} - ${response.body}');
        throw Exception(
            'Server is not live right now. Please try again in a few minutes.');
      }
    } catch (e) {
      print('Fetch regions refresh exception: $e');

      try {
        final fallbackResponse = await _getRegionsResponse(refresh: false);
        if (fallbackResponse.statusCode == 200) {
          final List<dynamic> data = jsonDecode(fallbackResponse.body);
          return data.cast<Map<String, dynamic>>();
        }
        print(
            'Fetch regions fallback error: ${fallbackResponse.statusCode} - ${fallbackResponse.body}');
      } catch (fallbackError) {
        print('Fetch regions fallback exception: $fallbackError');
      }

      throw Exception('Unable to load monitored regions. Please try again.');
    }
  }

  Future<http.Response> _getRegionsResponse({required bool refresh}) {
    final uri = refresh
        ? Uri.parse('$baseUrl/regions/')
        : Uri.parse('$baseUrl/regions/?refresh=false');

    return _client.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    ).timeout(Duration(seconds: refresh ? 60 : 30));
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
      final response = await _client.post(
        Uri.parse('$baseUrl/predict/risk/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'rainfall': rainfall,
          'slope': slope,
          'soil': soil,
          'lithology': lithology,
        }),
      ).timeout(const Duration(seconds: 30));

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
      final response = await _client.post(
        Uri.parse('$baseUrl/predict/location-risk/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print(
            'Predict location risk error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Predict location risk exception: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> submitSOS({
    required double latitude,
    required double longitude,
    int? regionId,
    String? areaName,
    String? riskLevel,
    double? riskScore,
    String message = 'Emergency SOS. User needs immediate help.',
  }) async {
    try {
      final token = await getToken();
      if (token == null) return null;

      final response = await _client
          .post(
            Uri.parse('$baseUrl/reports/sos/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Token $token',
            },
            body: jsonEncode({
              'latitude': latitude,
              'longitude': longitude,
              'region_id': regionId,
              'area_name': areaName,
              'risk_level': riskLevel,
              'risk_score': riskScore,
              'message': message,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      print('Submit SOS error: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Submit SOS exception: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> fetchSOSStatus() async {
    try {
      final token = await getToken();
      if (token == null) return {};

      final response = await _client.get(
        Uri.parse('$baseUrl/reports/sos/status/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }

      print('Fetch SOS status error: ${response.statusCode} - ${response.body}');
      return {};
    } catch (e) {
      print('Fetch SOS status exception: $e');
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> fetchSOSRequests() async {
    try {
      final token = await getToken();
      if (token == null) return [];

      final response = await _client.get(
        Uri.parse('$baseUrl/reports/sos/list/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }

      print('Fetch SOS error: ${response.statusCode} - ${response.body}');
      return [];
    } catch (e) {
      print('Fetch SOS exception: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchSavedSafetyTips() async {
    try {
      final token = await getToken();
      if (token == null) return [];

      final response = await _client.get(
        Uri.parse('$baseUrl/safety/saved-tips/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }

      print('Fetch saved safety tips error: ${response.statusCode} - ${response.body}');
      return [];
    } catch (e) {
      print('Fetch saved safety tips exception: $e');
      return [];
    }
  }

  Future<bool> saveSafetyTip({
    required String tipId,
    required String title,
    required String description,
  }) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await _client.post(
        Uri.parse('$baseUrl/safety/saved-tips/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
        body: jsonEncode({
          'tip_id': tipId,
          'tip_title': title,
          'tip_description': description,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      print('Save safety tip error: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      print('Save safety tip exception: $e');
      return false;
    }
  }

  Future<bool> removeSavedSafetyTip(String tipId) async {
    try {
      final token = await getToken();
      if (token == null) return false;

      final response = await _client.delete(
        Uri.parse('$baseUrl/safety/saved-tips/$tipId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 204 || response.statusCode == 200) {
        return true;
      }

      print('Remove safety tip error: ${response.statusCode} - ${response.body}');
      return false;
    } catch (e) {
      print('Remove safety tip exception: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> fetchEmergencyContacts() async {
    try {
      final response = await _client.get(
        Uri.parse('$baseUrl/safety/emergency-contacts/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      }

      print('Fetch emergency contacts error: ${response.statusCode} - ${response.body}');
      return [];
    } catch (e) {
      print('Fetch emergency contacts exception: $e');
      return [];
    }
  }

  Future<String> askHillSafeAssistant({
    required String message,
    String? region,
    String? riskLevel,
    String? rainfall,
    String? temperature,
    String language = 'English',
  }) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/chatbot/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'message': message,
          'region': region ?? 'Unknown',
          'risk_level': riskLevel ?? 'Unknown',
          'rainfall': rainfall ?? 'Unknown',
          'temperature': temperature ?? 'Unknown',
          'language': language,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['reply']?.toString() ?? 'No response received.';
      }

      print('Assistant error: ${response.statusCode} - ${response.body}');
      return 'Assistant is temporarily unavailable. Please use the FAQs for quick guidance.';
    } catch (e) {
      print('Assistant exception: $e');
      return 'Assistant is temporarily unavailable. Please use the FAQs for quick guidance.';
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

      final response = await _client.post(
        Uri.parse('$baseUrl/ingest/trigger/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print(
            'Trigger ingestion error: ${response.statusCode} - ${response.body}');
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
  Future<bool> submitIncident(
    String description,
    int? regionId, {
    String? imagePath,
    double? latitude,
    double? longitude,
    String? areaName,
    double reportRadiusKm = 50.0,
  }) async {
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
      if (regionId != null) {
        request.fields['region_id'] = regionId.toString();
      }
      if (latitude != null) {
        request.fields['latitude'] = latitude.toString();
      }
      if (longitude != null) {
        request.fields['longitude'] = longitude.toString();
      }
      request.fields['report_radius_km'] = reportRadiusKm.toString();
      if (areaName != null && areaName.trim().isNotEmpty) {
        request.fields['area_name'] = areaName.trim();
      }

      print('Request headers: ${request.headers}');
      print('Request fields: ${request.fields}');

      // Add image if provided
      if (imagePath != null && imagePath.isNotEmpty) {
        request.files
            .add(await http.MultipartFile.fromPath('image', imagePath));
        print('Image added to request');
      }

      print('Sending request...');
      final streamedResponse = await _client.send(request).timeout(const Duration(seconds: 45));
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        print('âœ“ Incident report submitted successfully');
        return true;
      } else {
        print('âœ— Submit incident error: ${response.statusCode}');
        print('Response body: ${response.body}');
        if (response.statusCode == 401) {
          throw Exception('Unauthorized. Please login again.');
        } else if (response.statusCode == 400) {
          throw Exception('Invalid data: ${response.body}');
        }
        throw Exception(
            'Failed to submit (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      print('âœ— Submit incident exception: $e');
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

      final response = await _client.get(
        Uri.parse('$baseUrl/reports/mark-safe/?region_id=$regionId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 30));

      print(
          'Check safety status response: ${response.statusCode} - ${response.body}');

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

      final response = await _client.post(
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
      ).timeout(const Duration(seconds: 30));

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

      final response = await _client.get(
        Uri.parse('$baseUrl/reports/stats/$regionId/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Token $token',
        },
      ).timeout(const Duration(seconds: 30));

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
    bool force = false,
  }) async {
    try {
      String url = '$baseUrl/analytics/?period=$period';
      if (regionId != null) {
        url += '&region_id=$regionId';
      }
      if (force) {
        url += '&force=true';
      }

      final response = await _client.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print(
            'Fetch analytics error: ${response.statusCode} - ${response.body}');
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
      final url =
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,rain,snowfall,weather_code,is_day&timezone=auto&forecast_days=1';

      final response = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current'];
        return {
          'temperature': current['temperature_2m'],
          'rainfall_mm': (current['rain'] as num).toDouble() +
              (current['snowfall'] as num).toDouble(),
          'humidity': current['relative_humidity_2m'],
          'is_snowing': (current['snowfall'] as num) > 0,
          'weather_code': current['weather_code'],
          'is_day': current['is_day'],
          'source': 'open-meteo',
        };
      } else {
        print(
            'Fetch live weather error: ${response.statusCode} - ${response.body}');
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

      final response = await _client.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 30));

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
      final url =
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&zoom=18&addressdetails=1';

      final response = await _client.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'HillSafeAI/1.0 (flutter_app)',
          'Accept-Language': 'en',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'];
        if (address == null) return null;

        String? pick(List<String> keys) {
          for (final key in keys) {
            final value = address[key];
            if (value is String && value.trim().isNotEmpty) {
              return value.trim();
            }
          }
          return null;
        }

        // Keep this based on the user's actual GPS point. Monitored-region
        // matching remains a separate backend concern.
        final area = pick([
          'neighbourhood',
          'suburb',
          'quarter',
          'residential',
          'hamlet',
          'village',
          'road',
        ]);
        final city = pick(['city', 'town', 'municipality']);
        final district = pick(['county', 'state_district']);
        final state = pick(['state']);

        final parts = <String>[];
        for (final part in [area, city, district, state]) {
          if (part != null && !parts.contains(part)) {
            parts.add(part);
          }
        }

        if (parts.isNotEmpty) {
          return parts.take(3).join(', ');
        }

        final displayName = data['display_name'];
        if (displayName is String && displayName.trim().isNotEmpty) {
          return displayName.split(',').take(3).map((p) => p.trim()).join(', ');
        }
      }
      return null;
    } catch (e) {
      print('Reverse geocoding error: $e');
      return null;
    }
  }

  /// Create Alert
  ///
  /// POST /api/alerts/create/
  /// Saves a new alert to the DB and triggers Firebase push notifications.
  ///
  /// [regionId]   â€” ID of the target region
  /// [severity]   â€” 'LOW' | 'MEDIUM' | 'HIGH' | 'CRITICAL'
  /// [message]    â€” Alert body text shown to users
  /// [affectedPopulation] â€” optional estimated count
  ///
  /// Returns the response map on success or throws on error.
  Future<Map<String, dynamic>> createAlert({
    int? regionId,
    required String severity,
    required String message,
    int affectedPopulation = 0,
    bool sendToAll = false,
  }) async {
    final token = await getToken();
    final response = await _client.post(
      Uri.parse('$baseUrl/alerts/create/'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Token $token',
      },
      body: jsonEncode({
        if (regionId != null) 'region_id': regionId,
        'severity': severity.toUpperCase(),
        'message': message,
        'affected_population': affectedPopulation,
        'send_to_all': sendToAll,
      }),
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode == 201) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    final body = jsonDecode(response.body);
    throw Exception(body['error'] ?? 'Failed to create alert (${response.statusCode})');
  }
}

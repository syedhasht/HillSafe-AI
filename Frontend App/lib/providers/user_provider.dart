import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend_app/services/api_service.dart';

/// User Provider for managing user session and profile
class UserProvider extends ChangeNotifier {
  String _username = 'John Doe';
  String _phoneNumber = '';
  String _email = '';
  bool _isLoggedIn = false;
  String _userType = ''; // 'community' or 'authority'

  String get username => _username;
  String get phoneNumber => _phoneNumber;
  String get email => _email;
  bool get isLoggedIn => _isLoggedIn;
  String get userType => _userType;

  UserProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final apiService = ApiService();

    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _username = await apiService.getUsername() ??
        prefs.getString('username') ??
        'John Doe';
    _phoneNumber = await apiService.getPhoneNumber() ??
        prefs.getString('phoneNumber') ??
        '';
    _email = await apiService.getEmail() ?? prefs.getString('email') ?? '';
    _userType = prefs.getString('userType') ?? '';
    notifyListeners();
  }

  Future<void> refreshProfileFromDb() async {
    final profile = await ApiService().fetchProfile();
    if (profile == null) return;

    _username = profile['username']?.toString() ?? _username;
    _phoneNumber = profile['phone_number']?.toString() ?? _phoneNumber;
    _email = profile['email']?.toString() ?? _email;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', _username);
    await prefs.setString('phoneNumber', _phoneNumber);
    await prefs.setString('email', _email);

    notifyListeners();
  }

  Future<void> login(
    String username,
    String type, {
    String phoneNumber = '',
    String email = '',
  }) async {
    _username = username;
    _phoneNumber = phoneNumber;
    _email = email;
    _isLoggedIn = true;
    _userType = type;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('username', username);
    await prefs.setString('phoneNumber', phoneNumber);
    await prefs.setString('email', email);
    await prefs.setString('userType', type);

    notifyListeners();
  }

  Future<void> logout() async {
    await ApiService().logout();

    _isLoggedIn = false;
    _username = 'John Doe';
    _phoneNumber = '';
    _email = '';
    _userType = '';

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    notifyListeners();
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
    String? phoneNumber,
    bool notify = true,
  }) async {
    final updated = await ApiService().updateProfile(
      username: name,
      email: email,
      phoneNumber: phoneNumber,
    );

    if (updated == null) return false;

    _username = updated['username']?.toString() ?? name;
    _phoneNumber = updated['phone_number']?.toString() ?? phoneNumber ?? _phoneNumber;
    _email = updated['email']?.toString() ?? email;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', _username);
    await prefs.setString('phoneNumber', _phoneNumber);
    await prefs.setString('email', _email);

    if (notify) {
      notifyListeners();
    }
    return true;
  }

  Future<void> updateUsername(String newName) async {
    _username = newName;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', newName);

    notifyListeners();
  }
}

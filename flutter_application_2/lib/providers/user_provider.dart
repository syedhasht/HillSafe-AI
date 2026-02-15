import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User Provider for managing user session and profile
class UserProvider extends ChangeNotifier {
  String _username = 'John Doe';
  bool _isLoggedIn = false;
  String _userType = ''; // 'community' or 'authority'

  String get username => _username;
  bool get isLoggedIn => _isLoggedIn;
  String get userType => _userType;

  UserProvider() {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _username = prefs.getString('username') ?? 'John Doe';
    _userType = prefs.getString('userType') ?? '';
    notifyListeners();
  }

  Future<void> login(String username, String type) async {
    _username = username;
    _isLoggedIn = true;
    _userType = type;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('username', username);
    await prefs.setString('userType', type);
    
    notifyListeners();
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _username = 'John Doe';
    _userType = '';
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    
    notifyListeners();
  }

  Future<void> updateUsername(String newName) async {
    _username = newName;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', newName);
    
    notifyListeners();
  }
}

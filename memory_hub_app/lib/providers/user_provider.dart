import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../config/api_config.dart';

class UserProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  
  final AuthService _authService = AuthService();

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _currentUser != null;

  Future<void> loadCurrentUser() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _authService.getAccessToken();
      if (token == null) {
        throw Exception('Not authenticated');
      }

      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final userData = jsonDecode(response.body);
        _currentUser = User.fromJson(userData);
        _error = null;
      } else {
        throw Exception('Failed to load user profile');
      }
    } catch (e) {
      _error = e.toString();
      _currentUser = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final tokens = await _authService.login(email, password);
      if (tokens == null) {
        throw Exception('Login failed');
      }
      
      await loadCurrentUser();
      
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      _currentUser = null;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
      _currentUser = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUser(Map<String, dynamic> updates) async {
    if (_currentUser == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = User(
        id: _currentUser!.id,
        username: updates['username'] ?? _currentUser!.username,
        email: updates['email'] ?? _currentUser!.email,
        fullName: updates['full_name'] ?? _currentUser!.fullName,
        bio: updates['bio'] ?? _currentUser!.bio,
        avatarUrl: updates['avatar_url'] ?? _currentUser!.avatarUrl,
        isActive: _currentUser!.isActive,
        role: _currentUser!.role,
        createdAt: _currentUser!.createdAt,
        updatedAt: DateTime.now(),
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

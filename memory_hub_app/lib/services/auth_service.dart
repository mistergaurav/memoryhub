import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decode/jwt_decode.dart';
import '../models/user.dart';
import '../config/api_config.dart';

class AuthService {
  static String get baseUrl => ApiConfig.baseUrl;
  
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';

  Future<AuthTokens?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final tokens = AuthTokens.fromJson(jsonDecode(response.body));
        await _saveTokens(tokens);
        return tokens;
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          throw Exception(errorBody['detail'] ?? 'Login failed');
        } catch (e) {
          throw Exception('Login failed: ${response.body}');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Login error: $e');
    }
  }

  Future<AuthTokens> signup(String email, String password, String? fullName) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'full_name': fullName,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final tokens = AuthTokens.fromJson(responseData);
        await _saveTokens(tokens);
        return tokens;
      } else {
        try {
          final errorBody = jsonDecode(response.body);
          throw Exception(errorBody['detail'] ?? 'Signup failed');
        } catch (e) {
          throw Exception('Signup failed: ${response.body}');
        }
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Signup error: $e');
    }
  }

  Future<void> _saveTokens(AuthTokens tokens) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, tokens.accessToken);
    await prefs.setString(_refreshTokenKey, tokens.refreshToken);
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshTokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<AuthTokens?> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return null;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode == 200) {
        final tokens = AuthTokens.fromJson(jsonDecode(response.body));
        await _saveTokens(tokens);
        return tokens;
      } else {
        await logout();
        return null;
      }
    } catch (e) {
      await logout();
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
  }

  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, String>> getMultipartAuthHeaders() async {
    final token = await getAccessToken();
    return {
      'Authorization': 'Bearer $token',
    };
  }

  Future<String?> getCurrentUserId() async {
    try {
      final token = await getAccessToken();
      if (token == null) return null;
      
      final payload = Jwt.parseJwt(token);
      return payload['sub'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<AuthTokens?> signInWithGoogle() async {
    try {
      // Step 1: Get Google OAuth auth URL from backend
      final response = await http.get(
        Uri.parse('$baseUrl/auth/google/login'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 503) {
        throw Exception('Google Sign In is not configured on the server');
      }

      if (response.statusCode != 200) {
        throw Exception('Failed to initiate Google Sign In');
      }

      final authData = jsonDecode(response.body);
      final authUrl = authData['auth_url'];

      // Step 2: Open Google OAuth in browser/webview
      // Note: This requires url_launcher package
      // For now, return the URL so the UI can handle it
      throw Exception('Google Sign In URL: $authUrl\n\nPlease implement url_launcher to open this URL');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Google Sign In error: $e');
    }
  }

  Future<AuthTokens?> handleGoogleCallback(String code) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/google/callback?code=$code'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final tokens = AuthTokens.fromJson(responseData);
        await _saveTokens(tokens);
        return tokens;
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody['detail'] ?? 'Google Sign In failed');
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Google callback error: $e');
    }
  }
}

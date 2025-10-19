import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/api_config.dart';

class DashboardService {
  static String get baseUrl => ApiConfig.baseUrl;
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getDashboardStats() async {
    final headers = await _authService.getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/overview'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load dashboard stats');
  }

  Future<List<Map<String, dynamic>>> getRecentActivity({int limit = 10}) async {
    final headers = await _authService.getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/activity?limit=$limit'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Failed to load recent activity');
  }

  Future<Map<String, dynamic>> getUserSummary() async {
    final headers = await _authService.getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/users/me/summary'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    // Return default values if endpoint doesn't exist
    return {
      'memories': 0,
      'files': 0,
      'collections': 0,
      'followers': 0,
    };
  }
}

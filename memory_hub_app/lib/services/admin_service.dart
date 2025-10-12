import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AdminService {
  static String get baseUrl => ApiConfig.fullBaseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getOverview() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/stats/overview'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load admin overview');
  }

  Future<Map<String, dynamic>> getUsers({int page = 1, String? search}) async {
    final headers = await _getHeaders();
    var url = '$baseUrl/admin/users?page=$page';
    if (search != null && search.isNotEmpty) {
      url += '&search=$search';
    }
    
    final response = await http.get(
      Uri.parse(url),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load users');
  }

  Future<void> updateUserRole(String userId, String role) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/admin/users/$userId/role?role=$role'),
      headers: headers,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to update user role');
    }
  }

  Future<void> updateUserStatus(String userId, bool isActive) async {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/admin/users/$userId/status?is_active=$isActive'),
      headers: headers,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to update user status');
    }
  }

  Future<void> deleteUser(String userId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/admin/users/$userId'),
      headers: headers,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to delete user');
    }
  }

  Future<Map<String, dynamic>> getActivityStats(String period) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/admin/stats/activity?period=$period'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load activity stats');
  }
}

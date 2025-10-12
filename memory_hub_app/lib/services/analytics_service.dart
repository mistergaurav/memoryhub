import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AnalyticsService {
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
      Uri.parse('$baseUrl/analytics/overview'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load analytics');
  }

  Future<Map<String, dynamic>> getActivityChart(String period) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/activity-chart?period=$period'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load activity chart');
  }

  Future<Map<String, dynamic>> getTopTags() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/analytics/top-tags'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load top tags');
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class NotificationsService {
  static String get baseUrl => ApiConfig.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getNotifications({int page = 1, int limit = 20}) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/?page=$page&limit=$limit'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load notifications');
  }

  Future<void> markAsRead(String notificationId) async {
    final headers = await _getHeaders();
    await http.put(
      Uri.parse('$baseUrl/notifications/$notificationId/read'),
      headers: headers,
    );
  }

  Future<void> markAllAsRead() async {
    final headers = await _getHeaders();
    await http.put(
      Uri.parse('$baseUrl/notifications/read-all'),
      headers: headers,
    );
  }

  Future<Map<String, dynamic>> getNotificationDetails(String notificationId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/notifications/$notificationId/details'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] ?? data;
    } else if (response.statusCode == 404) {
      throw Exception('Notification not found');
    } else {
      throw Exception('Failed to load notification details');
    }
  }
}

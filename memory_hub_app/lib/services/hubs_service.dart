import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/api_config.dart';

class HubsService {
  static String get baseUrl => ApiConfig.baseUrl;
  final AuthService _authService = AuthService();

  Future<List<Map<String, dynamic>>> getMyHubs() async {
    final headers = await _authService.getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/hub/my-hubs'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Failed to load hubs');
  }

  Future<List<Map<String, dynamic>>> getAvailableHubs() async {
    final headers = await _authService.getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/social/hubs'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Failed to load hubs');
  }

  Future<Map<String, dynamic>> getHubDetails(String hubId) async {
    final headers = await _authService.getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/social/hubs/$hubId'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load hub details');
  }

  Future<void> joinHub(String hubId) async {
    final headers = await _authService.getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/social/hubs/$hubId/join'),
      headers: headers,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to join hub');
    }
  }

  Future<void> leaveHub(String hubId) async {
    final headers = await _authService.getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/social/hubs/$hubId/leave'),
      headers: headers,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to leave hub');
    }
  }

  Future<Map<String, dynamic>> createHub(Map<String, dynamic> hubData) async {
    final headers = await _authService.getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/social/hubs'),
      headers: headers,
      body: json.encode(hubData),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    }
    throw Exception('Failed to create hub');
  }

  Future<void> shareToHub(String hubId, String itemType, String itemId) async {
    final headers = await _authService.getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/hub/items'),
      headers: headers,
      body: json.encode({
        'hub_id': hubId,
        'item_type': itemType,
        'item_id': itemId,
      }),
    );
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to share to hub');
    }
  }

  Future<List<Map<String, dynamic>>> searchHubs(String query) async {
    final headers = await _authService.getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/social/hubs/search?q=$query'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Failed to search hubs');
  }
}

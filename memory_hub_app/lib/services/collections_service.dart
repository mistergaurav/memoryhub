import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class CollectionsService {
  static String get baseUrl => ApiConfig.fullBaseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<dynamic>> getCollections() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/collections/'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load collections');
  }

  Future<void> createCollection(String name, String description) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/collections/'),
      headers: headers,
      body: json.encode({
        'name': name,
        'description': description,
        'privacy': 'private',
      }),
    );
    
    if (response.statusCode != 201) {
      throw Exception('Failed to create collection');
    }
  }

  Future<void> addMemoryToCollection(String collectionId, String memoryId) async {
    final headers = await _getHeaders();
    await http.post(
      Uri.parse('$baseUrl/collections/$collectionId/memories/$memoryId'),
      headers: headers,
    );
  }
}

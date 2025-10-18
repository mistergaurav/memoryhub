import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class CollectionsService {
  static String get baseUrl => ApiConfig.baseUrl;

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

  Future<void> createCollection({
    required String name,
    String? description,
    String privacy = 'private',
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/collections/'),
      headers: headers,
      body: json.encode({
        'name': name,
        'description': description,
        'privacy': privacy,
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

  Future<Map<String, dynamic>> getCollection(String collectionId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/collections/$collectionId'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load collection');
  }

  Future<List<dynamic>> getCollectionMemories(String collectionId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/collections/$collectionId/memories'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load collection memories');
  }

  Future<void> removeMemoryFromCollection(String collectionId, String memoryId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/collections/$collectionId/memories/$memoryId'),
      headers: headers,
    );
    
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to remove memory from collection');
    }
  }

  Future<void> deleteCollection(String collectionId) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/collections/$collectionId'),
      headers: headers,
    );
    
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete collection');
    }
  }
}

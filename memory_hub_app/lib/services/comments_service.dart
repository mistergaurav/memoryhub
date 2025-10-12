import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CommentsService {
  static const String baseUrl = 'http://localhost:5000/api/v1';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<dynamic>> getComments(String targetType, String targetId) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/comments/?target_type=$targetType&target_id=$targetId'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['comments'] ?? [];
    }
    throw Exception('Failed to load comments');
  }

  Future<void> createComment(String targetType, String targetId, String content) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/comments/'),
      headers: headers,
      body: json.encode({
        'target_type': targetType,
        'target_id': targetId,
        'content': content,
      }),
    );
    
    if (response.statusCode != 201) {
      throw Exception('Failed to create comment');
    }
  }

  Future<void> likeComment(String commentId) async {
    final headers = await _getHeaders();
    await http.post(
      Uri.parse('$baseUrl/comments/$commentId/like'),
      headers: headers,
    );
  }

  Future<void> deleteComment(String commentId) async {
    final headers = await _getHeaders();
    await http.delete(
      Uri.parse('$baseUrl/comments/$commentId'),
      headers: headers,
    );
  }
}

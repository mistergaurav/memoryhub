import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/api_config.dart';

class ReactionsService {
  static String get baseUrl => ApiConfig.baseUrl;
  final AuthService _authService = AuthService();

  Future<List<Map<String, dynamic>>> getReactions(
    String targetType,
    String targetId,
  ) async {
    final headers = await _authService.getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/reactions/$targetType/$targetId'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      
      if (data['reactions'] != null && data['reactions'] is Map) {
        final reactionsMap = Map<String, dynamic>.from(data['reactions']);
        final List<Map<String, dynamic>> normalizedReactions = [];
        
        reactionsMap.forEach((emoji, users) {
          if (users is List) {
            for (var user in users) {
              normalizedReactions.add({
                ...Map<String, dynamic>.from(user),
                'reaction_type': emoji,
              });
            }
          }
        });
        
        return normalizedReactions;
      }
    }
    return [];
  }

  Future<void> addReaction(
    String targetType,
    String targetId,
    String emoji,
  ) async {
    final headers = await _authService.getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/reactions/$targetType/$targetId'),
      headers: headers,
      body: json.encode({'reaction_type': emoji}),
    );
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add reaction');
    }
  }

  Future<void> removeReaction(
    String targetType,
    String targetId,
    String emoji,
  ) async {
    final headers = await _authService.getAuthHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/reactions/$targetType/$targetId/$emoji'),
      headers: headers,
    );
    
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to remove reaction');
    }
  }
}

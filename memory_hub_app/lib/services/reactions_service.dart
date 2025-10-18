import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class ReactionsService {
  final ApiService _apiService = ApiService();

  Future<Map<String, List<Map<String, dynamic>>>> getReactions({
    required String targetType,
    required String targetId,
  }) async {
    try {
      final response = await _apiService.get('/reactions/$targetType/$targetId');
      final reactions = Map<String, List<dynamic>>.from(response['reactions']);
      
      return reactions.map((emoji, users) => MapEntry(
        emoji,
        List<Map<String, dynamic>>.from(users),
      ));
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addReaction({
    required String targetType,
    required String targetId,
    required String emoji,
  }) async {
    try {
      await _apiService.post('/reactions/$targetType/$targetId', body: {
        'emoji': emoji,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeReaction({
    required String targetType,
    required String targetId,
    required String emoji,
  }) async {
    try {
      await _apiService.delete('/reactions/$targetType/$targetId/$emoji');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, int>> getUserReactionStats() async {
    try {
      final response = await _apiService.get('/reactions/stats');
      return Map<String, int>.from(response['stats']);
    } catch (e) {
      rethrow;
    }
  }
}

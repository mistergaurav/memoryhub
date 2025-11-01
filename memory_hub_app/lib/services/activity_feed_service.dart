import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/api_config.dart';

class ActivityFeedService {
  static String get baseUrl => ApiConfig.baseUrl;
  final AuthService _authService = AuthService();

  Future<http.Response> _handleRequest(Future<http.Response> Function() requestBuilder) async {
    try {
      final response = await requestBuilder();
      
      if (response.statusCode == 401) {
        await _authService.refreshAccessToken();
        final retryResponse = await requestBuilder();
        if (retryResponse.statusCode == 401) {
          throw Exception('Unauthorized - Please login again');
        }
        return retryResponse;
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getActivityFeed({
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final uri = Uri.parse('$baseUrl/activity/feed').replace(queryParameters: queryParams);
    final response = await _handleRequest(
      () async {
        final headers = await _authService.getAuthHeaders();
        return http.get(uri, headers: headers);
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'activities': data['activities'] ?? [],
        'total': data['total'] ?? 0,
        'page': data['page'] ?? page,
        'has_more': (data['activities'] ?? []).length >= limit,
      };
    } else {
      throw Exception('Failed to load activity feed');
    }
  }

  Future<Map<String, dynamic>> getUserActivity({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final uri = Uri.parse('$baseUrl/activity/user/$userId').replace(queryParameters: queryParams);
    final response = await _handleRequest(
      () async {
        final headers = await _authService.getAuthHeaders();
        return http.get(uri, headers: headers);
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'activities': data['activities'] ?? [],
        'total': data['total'] ?? 0,
        'page': data['page'] ?? page,
      };
    } else {
      throw Exception('Failed to load user activity');
    }
  }
}

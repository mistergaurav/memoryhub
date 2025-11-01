import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/api_config.dart';

class HubService {
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

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await _handleRequest(
      () async {
        final headers = await _authService.getAuthHeaders();
        return http.get(Uri.parse('$baseUrl/hub/dashboard'), headers: headers);
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return data['data'];
      }
      return data;
    } else {
      throw Exception('Failed to load hub dashboard');
    }
  }

  Future<Map<String, dynamic>> getHubItems({
    int page = 1,
    int pageSize = 20,
    String? itemType,
    String? tag,
  }) async {
    final queryParams = {
      'page': page.toString(),
      'page_size': pageSize.toString(),
      if (itemType != null) 'item_type': itemType,
      if (tag != null) 'tag': tag,
    };

    final uri = Uri.parse('$baseUrl/hub/items').replace(queryParameters: queryParams);
    final response = await _handleRequest(
      () async {
        final headers = await _authService.getAuthHeaders();
        return http.get(uri, headers: headers);
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        return {
          'items': data['data'] ?? [],
          'total': data['pagination']?['total'] ?? 0,
          'page': data['pagination']?['page'] ?? page,
          'page_size': data['pagination']?['page_size'] ?? pageSize,
          'total_pages': data['pagination']?['total_pages'] ?? 1,
        };
      }
      return data;
    } else {
      throw Exception('Failed to load hub items');
    }
  }

  Future<Map<String, dynamic>> createHubItem(Map<String, dynamic> data) async {
    final response = await _handleRequest(
      () async {
        final headers = await _authService.getAuthHeaders();
        return http.post(
          Uri.parse('$baseUrl/hub/items'),
          headers: headers,
          body: jsonEncode(data),
        );
      },
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData['success'] == true && responseData['data'] != null) {
        return responseData['data'];
      }
      return responseData;
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['detail'] ?? 'Failed to create hub item');
    }
  }

  Future<void> toggleLike(String itemId, bool isCurrentlyLiked) async {
    final uri = Uri.parse('$baseUrl/hub/items/$itemId/like');
    
    final response = await _handleRequest(
      () async {
        final headers = await _authService.getAuthHeaders();
        return isCurrentlyLiked 
          ? http.delete(uri, headers: headers)
          : http.post(uri, headers: headers);
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to ${isCurrentlyLiked ? 'unlike' : 'like'} hub item');
    }
  }

  Future<void> toggleBookmark(String itemId, bool isCurrentlyBookmarked) async {
    final uri = Uri.parse('$baseUrl/hub/items/$itemId/bookmark');
    
    final response = await _handleRequest(
      () async {
        final headers = await _authService.getAuthHeaders();
        return isCurrentlyBookmarked
          ? http.delete(uri, headers: headers)
          : http.post(uri, headers: headers);
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to ${isCurrentlyBookmarked ? 'unbookmark' : 'bookmark'} hub item');
    }
  }

  Future<Map<String, dynamic>> getHubStats() async {
    final response = await _handleRequest(
      () async {
        final headers = await _authService.getAuthHeaders();
        return http.get(Uri.parse('$baseUrl/hub/stats'), headers: headers);
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true && data['data'] != null) {
        return data['data'];
      }
      return data;
    } else {
      throw Exception('Failed to load hub stats');
    }
  }

  Future<void> deleteHubItem(String itemId) async {
    final response = await _handleRequest(
      () async {
        final headers = await _authService.getAuthHeaders();
        return http.delete(Uri.parse('$baseUrl/hub/items/$itemId'), headers: headers);
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete hub item');
    }
  }
}

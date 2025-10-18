import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/memory.dart';
import '../models/vault_file.dart';
import '../models/hub_item.dart';
import 'auth_service.dart';
import '../config/api_config.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;
  final AuthService _authService = AuthService();

  Future<http.Response> _handleRequest(Future<http.Response> request) async {
    try {
      final response = await request;
      
      if (response.statusCode == 401) {
        final newTokens = await _authService.refreshAccessToken();
        if (newTokens != null) {
          return await request;
        }
        throw Exception('Unauthorized - Please login again');
      }
      
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<User> getCurrentUser() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/users/me'), headers: headers),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load user');
    }
  }

  Future<User> updateUser(UserUpdate userUpdate) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.put(
        Uri.parse('$baseUrl/users/me'),
        headers: headers,
        body: jsonEncode(userUpdate.toJson()),
      ),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to update user');
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.put(
        Uri.parse('$baseUrl/users/me/password'),
        headers: headers,
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Failed to change password');
    }
  }

  Future<void> requestPasswordReset(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/password-reset/request'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Failed to request password reset');
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    final response = await http.post(
      Uri.parse('$baseUrl/password-reset/confirm'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'new_password': newPassword,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Failed to reset password');
    }
  }

  Future<void> createPlace(Map<String, dynamic> placeData) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/places'),
        headers: headers,
        body: jsonEncode(placeData),
      ),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['detail'] ?? 'Failed to create place');
    }
  }

  Future<User> uploadAvatar(File file) async {
    final headers = await _authService.getMultipartAuthHeaders();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/users/me/avatar'),
    );
    
    request.headers.addAll(headers);
    request.files.add(await http.MultipartFile.fromPath('file', file.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to upload avatar');
    }
  }

  Future<List<Memory>> searchMemories({
    String? query,
    List<String>? tags,
    String? privacy,
    int page = 1,
    int limit = 20,
  }) async {
    final headers = await _authService.getAuthHeaders();
    final queryParams = {
      if (query != null) 'query': query,
      if (tags != null) 'tags': tags.join(','),
      if (privacy != null) 'privacy': privacy,
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final uri = Uri.parse('$baseUrl/memories/search/').replace(queryParameters: queryParams);
    final response = await _handleRequest(
      http.get(uri, headers: headers),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Memory.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load memories');
    }
  }

  Future<Memory> getMemory(String id) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/memories/$id'), headers: headers),
    );

    if (response.statusCode == 200) {
      return Memory.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load memory');
    }
  }

  Future<Memory> createMemory(MemoryCreate memoryCreate, List<File>? files) async {
    final headers = await _authService.getMultipartAuthHeaders();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/memories/'),
    );
    
    request.headers.addAll(headers);
    
    // Add form fields
    request.fields['title'] = memoryCreate.title;
    request.fields['content'] = memoryCreate.content;
    request.fields['tags'] = jsonEncode(memoryCreate.tags);  // JSON encode tags array
    request.fields['privacy'] = memoryCreate.privacy;
    if (memoryCreate.location != null) {
      request.fields['location'] = memoryCreate.location!;
    }
    if (memoryCreate.mood != null) {
      request.fields['mood'] = memoryCreate.mood!;
    }

    if (files != null) {
      for (var file in files) {
        request.files.add(await http.MultipartFile.fromPath('files', file.path));
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Memory.fromJson(jsonDecode(response.body));
    } else {
      final errorBody = response.body.isNotEmpty ? response.body : 'Failed to create memory';
      throw Exception(errorBody);
    }
  }

  Future<void> likeMemory(String id) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(Uri.parse('$baseUrl/memories/$id/like'), headers: headers),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to like memory');
    }
  }

  Future<void> bookmarkMemory(String id) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(Uri.parse('$baseUrl/memories/$id/bookmark'), headers: headers),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to bookmark memory');
    }
  }

  Future<List<VaultFile>> listFiles({
    String? fileType,
    String? privacy,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final headers = await _authService.getAuthHeaders();
    final queryParams = {
      if (fileType != null) 'file_type': fileType,
      if (privacy != null) 'privacy': privacy,
      if (search != null) 'search': search,
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final uri = Uri.parse('$baseUrl/vault/').replace(queryParameters: queryParams);
    final response = await _handleRequest(
      http.get(uri, headers: headers),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => VaultFile.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load files');
    }
  }

  Future<VaultFile> uploadFile(
    File file, {
    String? name,
    String? description,
    List<String>? tags,
    String privacy = 'private',
  }) async {
    final headers = await _authService.getMultipartAuthHeaders();
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/vault/upload'),
    );
    
    request.headers.addAll(headers);
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    
    if (name != null) request.fields['name'] = name;
    if (description != null) request.fields['description'] = description;
    if (tags != null) request.fields['tags'] = tags.join(',');
    request.fields['privacy'] = privacy;

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return VaultFile.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to upload file');
    }
  }

  Future<VaultFile> getFile(String id) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/vault/files/$id'), headers: headers),
    );

    if (response.statusCode == 200) {
      return VaultFile.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load file');
    }
  }

  String getFileDownloadUrl(String id) {
    return '$baseUrl/vault/download/$id';
  }

  Future<Map<String, dynamic>> getHubDashboard() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/hub/dashboard'), headers: headers),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load dashboard');
    }
  }

  Future<List<HubItem>> listHubItems({
    String? itemType,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final headers = await _authService.getAuthHeaders();
    final queryParams = {
      if (itemType != null) 'item_type': itemType,
      if (search != null) 'search': search,
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final uri = Uri.parse('$baseUrl/hub/items').replace(queryParameters: queryParams);
    final response = await _handleRequest(
      http.get(uri, headers: headers),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => HubItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load hub items');
    }
  }

  Future<Map<String, dynamic>> globalSearch(String query) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/search?q=$query'), headers: headers),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to search');
    }
  }

  Future<List<String>> getSearchSuggestions(String query) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/search/suggestions?q=$query'), headers: headers),
    );
    if (response.statusCode == 200) {
      return List<String>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to get suggestions');
    }
  }

  Future<List<Map<String, dynamic>>> getAllTags() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/tags'), headers: headers),
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load tags');
    }
  }

  Future<List<Map<String, dynamic>>> getPopularTags() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/tags/popular'), headers: headers),
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load popular tags');
    }
  }

  Future<List<Map<String, dynamic>>> getStories() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/stories'), headers: headers),
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load stories');
    }
  }

  Future<List<Map<String, dynamic>>> getVoiceNotes() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/voice-notes'), headers: headers),
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load voice notes');
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/categories'), headers: headers),
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<void> createCategory(Map<String, dynamic> data) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/categories'),
        headers: headers,
        body: jsonEncode(data),
      ),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create category');
    }
  }

  Future<List<Map<String, dynamic>>> getReminders() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/reminders'), headers: headers),
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load reminders');
    }
  }

  Future<void> deleteReminder(String id) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.delete(Uri.parse('$baseUrl/reminders/$id'), headers: headers),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete reminder');
    }
  }

  Future<void> exportMemoriesJson() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/export/memories'), headers: headers),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to export memories');
    }
  }

  Future<void> exportFilesZip() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/export/files'), headers: headers),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to export files');
    }
  }

  Future<void> exportFullBackup() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/export/full'), headers: headers),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to export backup');
    }
  }

  Future<Map<String, dynamic>> getPrivacySettings() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/privacy/settings'), headers: headers),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load privacy settings');
    }
  }

  Future<void> updatePrivacySettings(Map<String, dynamic> settings) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.put(
        Uri.parse('$baseUrl/privacy/settings'),
        headers: headers,
        body: jsonEncode(settings),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update privacy settings');
    }
  }

  Future<List<Map<String, dynamic>>> getPlaces() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/places'), headers: headers),
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load places');
    }
  }

  Future<Map<String, dynamic>> get2FAStatus() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/auth/2fa/status'), headers: headers),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get 2FA status');
    }
  }

  Future<Map<String, dynamic>> enable2FA() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(Uri.parse('$baseUrl/auth/2fa/enable'), headers: headers),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to enable 2FA');
    }
  }

  Future<void> verifyEnable2FA(String code) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/auth/2fa/verify'),
        headers: headers,
        body: jsonEncode({'code': code}),
      ),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to verify 2FA');
    }
  }

  Future<void> disable2FA() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(Uri.parse('$baseUrl/auth/2fa/disable'), headers: headers),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to disable 2FA');
    }
  }

  Future<List<Map<String, dynamic>>> getScheduledPosts() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/scheduled-posts'), headers: headers),
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load scheduled posts');
    }
  }

  Future<void> publishScheduledPostNow(String id) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(Uri.parse('$baseUrl/scheduled-posts/$id/publish'), headers: headers),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to publish post');
    }
  }

  Future<void> deleteScheduledPost(String id) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.delete(Uri.parse('$baseUrl/scheduled-posts/$id'), headers: headers),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete post');
    }
  }

  Future<List<Map<String, dynamic>>> getMemoryTemplates() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/templates'), headers: headers),
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load templates');
    }
  }

  Future<List<Map<String, dynamic>>> getComments(String targetType, String targetId) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/comments/$targetType/$targetId'), headers: headers),
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load comments');
    }
  }

  Future<void> createComment(Map<String, dynamic> data) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(
        Uri.parse('$baseUrl/comments'),
        headers: headers,
        body: jsonEncode(data),
      ),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create comment');
    }
  }

  Future<void> likeComment(String commentId) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.post(Uri.parse('$baseUrl/comments/$commentId/like'), headers: headers),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to like comment');
    }
  }

  Future<void> deleteComment(String commentId) async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.delete(Uri.parse('$baseUrl/comments/$commentId'), headers: headers),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete comment');
    }
  }

  Future<List<Map<String, dynamic>>> getSharedFiles() async {
    final headers = await _authService.getAuthHeaders();
    final response = await _handleRequest(
      http.get(Uri.parse('$baseUrl/sharing/files'), headers: headers),
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load shared files');
    }
  }
}

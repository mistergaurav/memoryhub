import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/memory.dart';
import '../models/vault_file.dart';
import '../models/hub_item.dart';
import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'https://55ffb8e1-7a3f-41ea-b940-6a0568597a5a-00-1fms3et0zzs02.kirk.replit.dev:8000/api/v1';
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
    request.fields.addAll(memoryCreate.toFormData().map(
      (key, value) => MapEntry(key, value.toString()),
    ));

    if (files != null) {
      for (var file in files) {
        request.files.add(await http.MultipartFile.fromPath('files', file.path));
      }
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      return Memory.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create memory');
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
}

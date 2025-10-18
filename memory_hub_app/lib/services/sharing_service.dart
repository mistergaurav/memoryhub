import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class SharingService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> createShareLink({
    required String resourceType,
    required String resourceId,
    String? password,
    DateTime? expiresAt,
    int? maxUses,
  }) async {
    try {
      final body = {
        'resource_type': resourceType,
        'resource_id': resourceId,
        if (password != null) 'password': password,
        if (expiresAt != null) 'expires_at': expiresAt.toIso8601String(),
        if (maxUses != null) 'max_uses': maxUses,
      };

      final response = await _apiService.post('/sharing/create', body: body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getMyShares() async {
    try {
      final response = await _apiService.get('/sharing/my-shares');
      return List<Map<String, dynamic>>.from(response['shares']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> revokeShareLink(String shareId) async {
    try {
      await _apiService.delete('/sharing/revoke/$shareId');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getSharedResource({
    required String token,
    String? password,
  }) async {
    try {
      final body = password != null ? {'password': password} : null;
      final response = await _apiService.post('/sharing/access/$token', body: body);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> generateQRCode({
    required String resourceType,
    required String resourceId,
  }) async {
    try {
      final response = await _apiService.get(
        '/sharing/qr-code/$resourceType/$resourceId',
      );
      return response['qr_code'];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getShareStats() async {
    try {
      final response = await _apiService.get('/sharing/stats');
      return response;
    } catch (e) {
      rethrow;
    }
  }
}

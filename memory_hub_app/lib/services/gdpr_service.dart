import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config/api_config.dart';

class GdprService {
  static String get baseUrl => ApiConfig.baseUrl;
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>> getConsentSettings() async {
    final headers = await _authService.getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/gdpr/consent'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Failed to load consent settings');
  }

  Future<void> updateConsentSettings(Map<String, dynamic> settings) async {
    final headers = await _authService.getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl/gdpr/consent'),
      headers: headers,
      body: json.encode(settings),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to update consent settings');
    }
  }

  Future<void> requestDataExport(String format) async {
    final headers = await _authService.getAuthHeaders();
    final endpoint = format == 'json' ? '/export/json' : '/export/archive';
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to request export');
    }
  }

  Future<List<Map<String, dynamic>>> getExportHistory() async {
    final headers = await _authService.getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/export/history'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    return [];
  }

  Future<void> requestAccountDeletion() async {
    final headers = await _authService.getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/gdpr/delete-account'),
      headers: headers,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to request account deletion');
    }
  }

  Future<void> cancelAccountDeletion() async {
    final headers = await _authService.getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/gdpr/cancel-deletion'),
      headers: headers,
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to cancel account deletion');
    }
  }

  Future<Map<String, dynamic>> getDeletionStatus() async {
    final headers = await _authService.getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/gdpr/deletion-status'),
      headers: headers,
    );
    
    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    return {'pending': false, 'scheduled_date': null};
  }
}

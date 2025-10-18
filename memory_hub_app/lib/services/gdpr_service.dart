import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_service.dart';

class GDPRService {
  final ApiService _apiService = ApiService();

  Future<Map<String, bool>> getConsentSettings() async {
    try {
      final response = await _apiService.get('/gdpr/consent');
      return Map<String, bool>.from(response['consent_settings']);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateConsentSettings(Map<String, bool> settings) async {
    try {
      await _apiService.put('/gdpr/consent', body: {
        'consent_settings': settings,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> requestDataExport(String format) async {
    try {
      final endpoint = format == 'json' ? '/export/json' : '/export/archive';
      final response = await _apiService.post(endpoint);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getExportHistory() async {
    try {
      final response = await _apiService.get('/export/history');
      return List<Map<String, dynamic>>.from(response['exports']);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> requestAccountDeletion() async {
    try {
      final response = await _apiService.post('/gdpr/delete-account');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelAccountDeletion() async {
    try {
      await _apiService.post('/gdpr/cancel-deletion');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDeletionStatus() async {
    try {
      final response = await _apiService.get('/gdpr/deletion-status');
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getDataProcessingInfo() async {
    try {
      final response = await _apiService.get('/gdpr/data-info');
      return response;
    } catch (e) {
      rethrow;
    }
  }
}

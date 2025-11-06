import '../common/family_api_client.dart';
import '../common/family_exceptions.dart';
import '../../../models/family/health_record.dart';

class FamilyHealthRecordsService extends FamilyApiClient {
  Future<Map<String, dynamic>> getDashboard() async {
    try {
      final data = await get('/family/health-records/dashboard', useCache: true);
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load health dashboard',
        originalError: e,
      );
    }
  }

  Future<List<HealthRecord>> getRecords({
    int page = 1,
    int limit = 20,
    String? recordType,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (recordType != null) 'record_type': recordType,
      };
      
      final data = await get('/family/health-records', params: params, useCache: true);
      
      final items = data['data'] ?? data['items'] ?? [];
      if (items is List) {
        return items.map((item) => HealthRecord.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load health records',
        originalError: e,
      );
    }
  }

  Future<HealthRecord> createRecord(Map<String, dynamic> recordData) async {
    try {
      final data = await post('/family/health-records', body: recordData);
      return HealthRecord.fromJson(data['data'] ?? data);
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to create health record',
        originalError: e,
      );
    }
  }

  Future<void> deleteRecord(String recordId) async {
    try {
      await delete('/family/health-records/$recordId');
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to delete health record',
        originalError: e,
      );
    }
  }

  Future<HealthRecord> approveHealthRecord(String recordId) async {
    try {
      if (recordId.isEmpty) {
        throw ApiException(
          message: 'Invalid record ID',
          statusCode: 400,
          detail: 'Record ID cannot be empty',
        );
      }

      final data = await post('/family/health-records/$recordId/approve');
      return HealthRecord.fromJson(data['data'] ?? data);
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to approve health record',
        originalError: e,
      );
    }
  }

  Future<HealthRecord> rejectHealthRecord(String recordId, {String? rejectionReason}) async {
    try {
      if (recordId.isEmpty) {
        throw ApiException(
          message: 'Invalid record ID',
          statusCode: 400,
          detail: 'Record ID cannot be empty',
        );
      }

      final params = rejectionReason != null && rejectionReason.isNotEmpty
          ? {'rejection_reason': rejectionReason}
          : null;

      final data = await post(
        '/family/health-records/$recordId/reject',
        params: params,
      );
      return HealthRecord.fromJson(data['data'] ?? data);
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to reject health record',
        originalError: e,
      );
    }
  }
}

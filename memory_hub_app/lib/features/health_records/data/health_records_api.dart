import '../../../services/family/common/family_api_client.dart';
import '../../../services/family/common/family_exceptions.dart';

class HealthRecordsApi extends FamilyApiClient {
  Future<Map<String, dynamic>> getDashboard() async {
    try {
      print('[HealthRecordsApi] Fetching dashboard from /family/health-records/dashboard');
      final data = await get('/family/health-records/dashboard', useCache: true);
      print('[HealthRecordsApi] Dashboard response keys: ${data.keys.toList()}');
      final result = data['data'] ?? data;
      print('[HealthRecordsApi] Dashboard data keys: ${result.keys.toList()}');
      return result;
    } catch (e) {
      print('[HealthRecordsApi] Error loading dashboard: $e');
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load health dashboard',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> getRecords({
    int page = 1,
    int limit = 50,
    String? recordType,
    String? severity,
    String? subjectType,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (recordType != null && recordType != 'all') 'record_type': recordType,
        if (severity != null) 'severity': severity,
        if (subjectType != null) 'subject_type': subjectType,
      };
      
      print('[HealthRecordsApi] Fetching records from /family/health-records with params: $params');
      final data = await get('/family/health-records', params: params, useCache: true);
      print('[HealthRecordsApi] Records response keys: ${data.keys.toList()}');
      return data;
    } catch (e) {
      print('[HealthRecordsApi] Error loading records: $e');
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load health records',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> getRecordById(String recordId) async {
    try {
      final data = await get('/family/health-records/$recordId');
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load health record',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> createRecord(Map<String, dynamic> recordData) async {
    try {
      final data = await post('/family/health-records', body: recordData);
      return data['data'] ?? data;
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

  Future<Map<String, dynamic>> updateRecord(String recordId, Map<String, dynamic> recordData) async {
    try {
      final data = await put('/family/health-records/$recordId', body: recordData);
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to update health record',
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

  Future<Map<String, dynamic>> createReminder(Map<String, dynamic> reminderData) async {
    try {
      final data = await post('/family/health-records/reminders', body: reminderData);
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to create reminder',
        originalError: e,
      );
    }
  }

  Future<List<dynamic>> getReminders({String? recordId}) async {
    try {
      final params = recordId != null ? {'record_id': recordId} : <String, String>{};
      final data = await get('/family/health-records/reminders', params: params);
      return (data['data'] ?? data['items'] ?? []) as List;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load reminders',
        originalError: e,
      );
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    try {
      await delete('/family/health-records/reminders/$reminderId');
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to delete reminder',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> skipReminder(String reminderId) async {
    try {
      final data = await post('/family/health-records/reminders/$reminderId/complete');
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to skip reminder',
        originalError: e,
      );
    }
  }
}

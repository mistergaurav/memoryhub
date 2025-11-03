import '../common/family_api_client.dart';
import '../common/family_exceptions.dart';

class FamilyTimelineService extends FamilyApiClient {
  Future<List<Map<String, dynamic>>> getTimelineEvents({
    int page = 1,
    int limit = 20,
    String? eventType,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (eventType != null) 'event_type': eventType,
      };
      
      final data = await get(
        '/api/v1/family/timeline/events',
        params: params,
        useCache: true,
      );
      
      final items = data['data'] ?? data['items'] ?? [];
      if (items is List) {
        return items.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load timeline events',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> getEvent(String eventId) async {
    try {
      final data = await get('/api/v1/family/timeline/events/$eventId', useCache: true);
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load event',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> createEvent(Map<String, dynamic> eventData) async {
    try {
      final data = await post('/api/v1/family/timeline/events', body: eventData);
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to create timeline event',
        originalError: e,
      );
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await delete('/api/v1/family/timeline/events/$eventId');
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to delete event',
        originalError: e,
      );
    }
  }
}

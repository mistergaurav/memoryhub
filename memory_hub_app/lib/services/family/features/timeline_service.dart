import '../common/family_api_client.dart';
import '../common/family_exceptions.dart';
import '../../../models/family/family_timeline.dart';

class FamilyTimelineService extends FamilyApiClient {
  Future<List<TimelineEvent>> getTimelineEvents({
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
        '/family/timeline/events',
        params: params,
        useCache: true,
      );
      
      final items = data['data'] ?? data['items'] ?? [];
      if (items is List) {
        return items.map((item) => TimelineEvent.fromJson(item as Map<String, dynamic>)).toList();
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

  Future<TimelineEvent> getEvent(String eventId) async {
    try {
      final data = await get('/family/timeline/events/$eventId', useCache: true);
      final eventData = data['data'] ?? data;
      return TimelineEvent.fromJson(eventData as Map<String, dynamic>);
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

  Future<TimelineEvent> createEvent(Map<String, dynamic> eventData) async {
    try {
      final data = await post('/family/timeline/events', body: eventData);
      final eventResponse = data['data'] ?? data;
      return TimelineEvent.fromJson(eventResponse as Map<String, dynamic>);
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
      await delete('/family/timeline/events/$eventId');
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

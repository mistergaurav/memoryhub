import '../common/family_api_client.dart';
import '../common/family_exceptions.dart';
import '../../../models/family/family_calendar.dart';

class FamilyCalendarService extends FamilyApiClient {
  Future<List<FamilyCalendarEvent>> getEvents({
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
      
      final data = await get('/api/v1/family/calendar', params: params, useCache: true);
      
      final items = data['data'] ?? data['items'] ?? [];
      if (items is List) {
        return items.map((item) => FamilyCalendarEvent.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load events',
        originalError: e,
      );
    }
  }

  Future<List<FamilyCalendarEvent>> getBirthdays() async {
    try {
      final data = await get(
        '/api/v1/family/calendar',
        params: {'event_type': 'birthday'},
        useCache: true,
      );
      
      final items = data['data'] ?? data['items'] ?? [];
      if (items is List) {
        return items.map((item) => FamilyCalendarEvent.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load birthdays',
        originalError: e,
      );
    }
  }

  Future<FamilyCalendarEvent> createEvent(Map<String, dynamic> eventData) async {
    try {
      final data = await post('/api/v1/family/calendar', body: eventData);
      return FamilyCalendarEvent.fromJson(data['data'] ?? data);
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to create event',
        originalError: e,
      );
    }
  }

  Future<void> deleteEvent(String eventId) async {
    try {
      await delete('/api/v1/family/calendar/$eventId');
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

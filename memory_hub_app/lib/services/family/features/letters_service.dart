import '../common/family_api_client.dart';
import '../common/family_exceptions.dart';

class FamilyLettersService extends FamilyApiClient {
  Future<List<Map<String, dynamic>>> getLetters({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      final data = await get('/api/v1/family/legacy-letters', params: params, useCache: true);
      
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
        message: 'Failed to load legacy letters',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> getLetter(String letterId) async {
    try {
      final data = await get('/api/v1/family/legacy-letters/$letterId', useCache: true);
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load letter',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> createLetter(Map<String, dynamic> letterData) async {
    try {
      final data = await post('/api/v1/family/legacy-letters', body: letterData);
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to create legacy letter',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> sendLetter(String letterId, String recipientId) async {
    try {
      final data = await post(
        '/api/v1/family/legacy-letters/$letterId/send',
        body: {'recipient_id': recipientId},
      );
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to send letter',
        originalError: e,
      );
    }
  }

  Future<void> deleteLetter(String letterId) async {
    try {
      await delete('/api/v1/family/legacy-letters/$letterId');
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to delete letter',
        originalError: e,
      );
    }
  }
}

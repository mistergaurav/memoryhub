import '../common/family_api_client.dart';
import '../common/family_exceptions.dart';
import '../../../models/family/legacy_letter.dart';

class FamilyLettersService extends FamilyApiClient {
  Future<List<LegacyLetter>> getLetters({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      final data = await get('/family/legacy-letters', params: params, useCache: true);
      
      final items = data['data'] ?? data['items'] ?? [];
      if (items is List) {
        return items.map((item) => LegacyLetter.fromJson(item as Map<String, dynamic>)).toList();
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

  Future<LegacyLetter> getLetter(String letterId) async {
    try {
      final data = await get('/family/legacy-letters/$letterId', useCache: true);
      return LegacyLetter.fromJson(data['data'] ?? data);
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

  Future<LegacyLetter> createLetter(Map<String, dynamic> letterData) async {
    try {
      final data = await post('/family/legacy-letters', body: letterData);
      return LegacyLetter.fromJson(data['data'] ?? data);
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

  Future<LegacyLetter> sendLetter(String letterId, String recipientId) async {
    try {
      final data = await post(
        '/family/legacy-letters/$letterId/send',
        body: {'recipient_id': recipientId},
      );
      return LegacyLetter.fromJson(data['data'] ?? data);
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
      await delete('/family/legacy-letters/$letterId');
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

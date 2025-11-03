import '../common/family_api_client.dart';
import '../common/family_exceptions.dart';

class FamilyTraditionsService extends FamilyApiClient {
  Future<List<Map<String, dynamic>>> getTraditions({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      final data = await get('/api/v1/family/traditions', params: params, useCache: true);
      
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
        message: 'Failed to load traditions',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> getTradition(String traditionId) async {
    try {
      final data = await get('/api/v1/family/traditions/$traditionId', useCache: true);
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load tradition',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> createTradition(Map<String, dynamic> traditionData) async {
    try {
      final data = await post('/api/v1/family/traditions', body: traditionData);
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to create tradition',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> followTradition(String traditionId) async {
    try {
      final data = await post('/api/v1/family/traditions/$traditionId/follow', body: {});
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to follow tradition',
        originalError: e,
      );
    }
  }

  Future<void> deleteTradition(String traditionId) async {
    try {
      await delete('/api/v1/family/traditions/$traditionId');
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to delete tradition',
        originalError: e,
      );
    }
  }
}

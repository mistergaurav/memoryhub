import '../common/family_api_client.dart';
import '../common/family_exceptions.dart';
import '../../../models/family/family_tradition.dart';

class FamilyTraditionsService extends FamilyApiClient {
  Future<List<FamilyTradition>> getTraditions({
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
        return items.map((item) => FamilyTradition.fromJson(item as Map<String, dynamic>)).toList();
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

  Future<FamilyTradition> getTradition(String traditionId) async {
    try {
      final data = await get('/api/v1/family/traditions/$traditionId', useCache: true);
      return FamilyTradition.fromJson(data['data'] ?? data);
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

  Future<FamilyTradition> createTradition(Map<String, dynamic> traditionData) async {
    try {
      final data = await post('/api/v1/family/traditions', body: traditionData);
      return FamilyTradition.fromJson(data['data'] ?? data);
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

  Future<FamilyTradition> followTradition(String traditionId) async {
    try {
      final data = await post('/api/v1/family/traditions/$traditionId/follow', body: {});
      return FamilyTradition.fromJson(data['data'] ?? data);
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

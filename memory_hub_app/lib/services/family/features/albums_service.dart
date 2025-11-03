import '../common/family_api_client.dart';
import '../common/family_exceptions.dart';

class FamilyAlbumsService extends FamilyApiClient {
  Future<List<Map<String, dynamic>>> getAlbums({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final data = await get(
        '/api/v1/family/albums',
        params: {'page': page.toString(), 'limit': limit.toString()},
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
        message: 'Failed to load albums',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> getAlbum(String albumId) async {
    try {
      final data = await get('/api/v1/family/albums/$albumId', useCache: true);
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load album',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> createAlbum(Map<String, dynamic> albumData) async {
    try {
      final data = await post('/api/v1/family/albums', body: albumData);
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to create album',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> addPhotos(String albumId, List<String> photoUrls) async {
    try {
      final data = await post(
        '/api/v1/family/albums/$albumId/photos',
        body: {'photos': photoUrls},
      );
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to add photos',
        originalError: e,
      );
    }
  }

  Future<void> deleteAlbum(String albumId) async {
    try {
      await delete('/api/v1/family/albums/$albumId');
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to delete album',
        originalError: e,
      );
    }
  }
}

import '../common/family_api_client.dart';
import '../common/family_exceptions.dart';
import '../../../models/family/family_album.dart';

class FamilyAlbumsService extends FamilyApiClient {
  Future<List<FamilyAlbum>> getAlbums({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final data = await get(
        '/family/albums',
        params: {'page': page.toString(), 'limit': limit.toString()},
        useCache: true,
      );
      
      final items = data['data'] ?? data['items'] ?? [];
      if (items is List) {
        return items.map((item) => FamilyAlbum.fromJson(item as Map<String, dynamic>)).toList();
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

  Future<FamilyAlbum> getAlbum(String albumId) async {
    try {
      final data = await get('/family/albums/$albumId', useCache: true);
      return FamilyAlbum.fromJson(data['data'] ?? data);
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

  Future<FamilyAlbum> createAlbum(Map<String, dynamic> albumData) async {
    try {
      final data = await post('/family/albums', body: albumData);
      return FamilyAlbum.fromJson(data['data'] ?? data);
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

  Future<FamilyAlbum> addPhotos(String albumId, List<String> photoUrls) async {
    try {
      final data = await post(
        '/family/albums/$albumId/photos',
        body: {'photos': photoUrls},
      );
      return FamilyAlbum.fromJson(data['data'] ?? data);
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
      await delete('/family/albums/$albumId');
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

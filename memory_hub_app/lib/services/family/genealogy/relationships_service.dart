import '../common/family_api_client.dart';
import '../common/family_exceptions.dart';

class GenealogyRelationshipsService extends FamilyApiClient {
  Future<List<Map<String, dynamic>>> getRelationships({
    String? personId,
    String? treeId,
    int page = 1,
    int limit = 100,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (personId != null) 'person_id': personId,
        if (treeId != null) 'tree_id': treeId,
      };
      
      final data = await get(
        '/api/v1/family/genealogy/relationships',
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
        message: 'Failed to load relationships',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> createRelationship(
    Map<String, dynamic> relationshipData,
  ) async {
    try {
      final data = await post(
        '/api/v1/family/genealogy/relationships',
        body: relationshipData,
      );
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to create relationship',
        originalError: e,
      );
    }
  }

  Future<void> deleteRelationship(String relationshipId) async {
    try {
      await delete('/api/v1/family/genealogy/relationships/$relationshipId');
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to delete relationship',
        originalError: e,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getPersonRelationships(String personId) async {
    return getRelationships(personId: personId);
  }
}

import '../common/family_api_client.dart';
import '../common/family_exceptions.dart';

class GenealogyTreeService extends FamilyApiClient {
  Future<Map<String, dynamic>> getTree({String? treeId}) async {
    try {
      final endpoint = treeId != null 
          ? '/api/v1/family/genealogy/tree/$treeId'
          : '/api/v1/family/genealogy/tree';
      
      final data = await get(endpoint, useCache: true);
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load genealogy tree',
        originalError: e,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getTreeNodes({String? treeId}) async {
    try {
      final tree = await getTree(treeId: treeId);
      final data = tree['data'] ?? tree;
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load tree nodes',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> buildTree(String userId) async {
    try {
      final data = await post(
        '/api/v1/family/genealogy/tree/build',
        body: {'user_id': userId},
      );
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to build genealogy tree',
        originalError: e,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getTreeMembers({String? treeId}) async {
    try {
      final endpoint = treeId != null
          ? '/api/v1/family/genealogy/tree/members?tree_id=$treeId'
          : '/api/v1/family/genealogy/tree/members';
      
      final data = await get(endpoint, useCache: true);
      
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
        message: 'Failed to load tree members',
        originalError: e,
      );
    }
  }
}

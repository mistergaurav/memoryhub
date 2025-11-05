import '../common/family_api_client.dart';
import '../common/family_exceptions.dart';
import '../../../models/family/genealogy_tree_node.dart';

class GenealogyTreeService extends FamilyApiClient {
  Future<Map<String, dynamic>> getTree({String? treeId}) async {
    try {
      final endpoint = treeId != null 
          ? '/family/genealogy/tree/$treeId'
          : '/family/genealogy/tree';
      
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

  Future<List<GenealogyTreeNode>> getTreeNodes({String? treeId}) async {
    try {
      final tree = await getTree(treeId: treeId);
      
      // Backend returns: {nodes: [...], relationships: [...], stats: {...}}
      // Try to unwrap the nodes array from different possible structures
      dynamic nodesData = tree['nodes'] ?? tree['data'];
      
      // If still a map, try to get nodes or data from it
      if (nodesData is Map<String, dynamic>) {
        nodesData = nodesData['nodes'] ?? nodesData['data'];
      }
      
      // Now check if we have a list
      if (nodesData is List) {
        return nodesData
            .where((node) => node is Map<String, dynamic>)
            .map((node) => GenealogyTreeNode.fromJson(node as Map<String, dynamic>))
            .toList();
      }
      
      // If we couldn't find nodes, throw a descriptive error
      if (tree is Map && tree.isNotEmpty) {
        throw NetworkException(
          message: 'Invalid tree data format. Expected "nodes" array but got: ${tree.keys.join(", ")}',
          originalError: null,
        );
      }
      
      return [];
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load tree nodes: ${e.toString()}',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> buildTree(String userId) async {
    try {
      final data = await post(
        '/family/genealogy/tree/build',
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
          ? '/family/genealogy/tree/members?tree_id=$treeId'
          : '/family/genealogy/tree/members';
      
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

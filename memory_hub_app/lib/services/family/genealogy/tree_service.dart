import '../common/family_api_client.dart';
import '../common/family_exceptions.dart';
import '../../../models/family/genealogy_tree_node.dart';

class GenealogyTreeService extends FamilyApiClient {
  Future<dynamic> getTree({String? treeId}) async {
    try {
      final endpoint = treeId != null 
          ? '/family/genealogy/tree?tree_id=$treeId'
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
      
      // Backend returns nested structure:
      // [{person: {...}, parents: [{...}], children: [{...}], spouses: [{...}]}, ...]
      
      // Check if we have a list (the data array from backend)
      if (tree is List) {
        return (tree as List)
            .where((node) => node is Map<String, dynamic>)
            .map((node) => _convertNestedNodeToFlat(node as Map<String, dynamic>))
            .toList();
      }
      
      // If tree is a map, it might be wrapped
      if (tree is Map<String, dynamic>) {
        final nodesData = tree['nodes'] ?? tree['data'];
        if (nodesData is List) {
          return (nodesData as List)
              .where((node) => node is Map<String, dynamic>)
              .map((node) => _convertNestedNodeToFlat(node as Map<String, dynamic>))
              .toList();
        }
        
        throw NetworkException(
          message: 'Invalid tree data format. Expected array but got: ${tree.keys.join(", ")}',
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

  GenealogyTreeNode _convertNestedNodeToFlat(Map<String, dynamic> nestedNode) {
    // Extract the person object
    final person = nestedNode['person'] as Map<String, dynamic>? ?? {};
    
    // Extract relationship arrays
    final parents = nestedNode['parents'] as List<dynamic>? ?? [];
    final children = nestedNode['children'] as List<dynamic>? ?? [];
    final spouses = nestedNode['spouses'] as List<dynamic>? ?? [];
    
    // Convert person arrays to ID arrays
    List<String> extractIds(List<dynamic> personArray) {
      return personArray
          .where((p) => p is Map<String, dynamic>)
          .map((p) => (p as Map<String, dynamic>)['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
    }
    
    // Build flat structure compatible with GenealogyTreeNode
    return GenealogyTreeNode.fromJson({
      'id': person['id'] ?? '',
      'person_id': person['id'] ?? '',
      'first_name': person['first_name'] ?? '',
      'last_name': person['last_name'] ?? '',
      'middle_name': person['maiden_name'],
      'gender': person['gender'] ?? 'unknown',
      'generation': 0,
      'position': 0,
      'photo_url': person['photo_url'],
      'parent_ids': extractIds(parents),
      'children_ids': extractIds(children),
      'spouse_ids': extractIds(spouses),
      'birth_date': person['birth_date'],
      'death_date': person['death_date'],
      'relationship_to_root': null,
      'created_at': person['created_at'] ?? DateTime.now().toIso8601String(),
      'updated_at': person['updated_at'] ?? DateTime.now().toIso8601String(),
    });
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

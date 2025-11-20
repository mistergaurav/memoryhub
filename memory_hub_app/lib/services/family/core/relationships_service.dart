import '../common/family_api_client.dart';
import '../common/family_exceptions.dart';

class RelationshipsService extends FamilyApiClient {
  Future<Map<String, dynamic>> sendInvite({
    required String relatedUserId,
    required String relationshipType,
    String? relationshipLabel,
    String? message,
  }) async {
    try {
      final data = await post('/family/relationships/invite', body: {
        'related_user_id': relatedUserId,
        'relationship_type': relationshipType,
        if (relationshipLabel != null) 'relationship_label': relationshipLabel,
        if (message != null) 'message': message,
      });
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to send relationship invitation',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> getRelationships({
    String? statusFilter,
    String? relationshipTypeFilter,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'page_size': pageSize.toString(),
        if (statusFilter != null) 'status_filter': statusFilter,
        if (relationshipTypeFilter != null) 'relationship_type_filter': relationshipTypeFilter,
      };
      
      final data = await get('/family/relationships', params: params, useCache: false);
      
      return data;
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

  Future<Map<String, dynamic>> getRequests({
    String type = 'pending',
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final params = {
        'type': type,
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };
      
      final data = await get('/family/relationships/pending', params: params, useCache: false);
      
      return data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load relationship requests',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> acceptRequest(String relationshipId) async {
    try {
      final data = await put('/family/relationships/$relationshipId/accept');
      invalidateCache('relationships');
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to accept relationship request',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> rejectRequest(String relationshipId) async {
    try {
      final data = await put('/family/relationships/$relationshipId/reject');
      invalidateCache('relationships');
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to reject relationship request',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> blockRelationship(String relationshipId) async {
    try {
      final data = await put('/family/relationships/$relationshipId/block');
      invalidateCache('relationships');
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to block relationship',
        originalError: e,
      );
    }
  }

  Future<void> deleteRelationship(String relationshipId) async {
    try {
      await delete('/family/relationships/$relationshipId');
      invalidateCache('relationships');
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

  Future<Map<String, dynamic>> getRelationship(String relationshipId) async {
    try {
      final data = await get('/family/relationships/$relationshipId');
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load relationship',
        originalError: e,
      );
    }
  }
}

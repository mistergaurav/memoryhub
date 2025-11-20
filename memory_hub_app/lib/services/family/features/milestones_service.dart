import '../common/family_api_client.dart';
import '../common/family_exceptions.dart';
import '../../../models/family/family_milestone.dart';

class FamilyMilestonesService extends FamilyApiClient {
  Future<Map<String, dynamic>> getTimelineFeed({
    int page = 1,
    int limit = 20,
    String? scope,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'page_size': limit.toString(),
        if (scope != null) 'scope': scope,
      };
      
      final data = await get('/family/timeline/feed', params: params, useCache: false);
      
      return data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load timeline feed',
        originalError: e,
      );
    }
  }

  Future<FamilyMilestone> getMilestone(String milestoneId) async {
    try {
      final data = await get('/family/timeline/milestones/$milestoneId');
      return FamilyMilestone.fromJson(data['data'] ?? data);
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load milestone',
        originalError: e,
      );
    }
  }

  Future<FamilyMilestone> createMilestone(Map<String, dynamic> milestoneData) async {
    try {
      final data = await post('/family/timeline/milestones', body: milestoneData);
      return FamilyMilestone.fromJson(data['data'] ?? data);
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to create milestone',
        originalError: e,
      );
    }
  }

  Future<FamilyMilestone> updateMilestone(
    String milestoneId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final data = await put('/family/timeline/milestones/$milestoneId', body: updates);
      return FamilyMilestone.fromJson(data['data'] ?? data);
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to update milestone',
        originalError: e,
      );
    }
  }

  Future<void> deleteMilestone(String milestoneId) async {
    try {
      await delete('/family/timeline/milestones/$milestoneId');
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to delete milestone',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> addComment(
    String milestoneId,
    Map<String, dynamic> commentData,
  ) async {
    try {
      final data = await post(
        '/family/timeline/milestones/$milestoneId/comments',
        body: commentData,
      );
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to add comment',
        originalError: e,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getComments(
    String milestoneId, {
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'page_size': limit.toString(),
      };
      
      final data = await get(
        '/family/timeline/milestones/$milestoneId/comments',
        params: params,
      );
      
      final items = data['data'] ?? data['items'] ?? [];
      if (items is List) {
        return List<Map<String, dynamic>>.from(items);
      }
      return [];
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load comments',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> updateComment(
    String milestoneId,
    String commentId,
    Map<String, dynamic> updates,
  ) async {
    try {
      final data = await put(
        '/family/timeline/milestones/$milestoneId/comments/$commentId',
        body: updates,
      );
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to update comment',
        originalError: e,
      );
    }
  }

  Future<void> deleteComment(String milestoneId, String commentId) async {
    try {
      await delete('/family/timeline/milestones/$milestoneId/comments/$commentId');
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to delete comment',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> addReaction(
    String milestoneId,
    String reactionType,
  ) async {
    try {
      final data = await post(
        '/family/timeline/milestones/$milestoneId/reactions',
        body: {'reaction_type': reactionType},
      );
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to add reaction',
        originalError: e,
      );
    }
  }

  Future<void> removeReaction(String milestoneId) async {
    try {
      await delete('/family/timeline/milestones/$milestoneId/reactions');
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to remove reaction',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> getReactions(
    String milestoneId, {
    String? reactionType,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'page_size': limit.toString(),
        if (reactionType != null) 'reaction_type': reactionType,
      };
      
      final data = await get(
        '/family/timeline/milestones/$milestoneId/reactions',
        params: params,
      );
      
      return data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load reactions',
        originalError: e,
      );
    }
  }
}

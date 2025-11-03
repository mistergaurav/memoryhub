import '../common/family_api_client.dart';
import '../common/family_exceptions.dart';
import '../../../models/family/family_milestone.dart';

class FamilyMilestonesService extends FamilyApiClient {
  Future<List<FamilyMilestone>> getMilestones({
    int page = 1,
    int limit = 20,
    String? milestoneType,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (milestoneType != null) 'milestone_type': milestoneType,
      };
      
      final data = await get('/api/v1/family/milestones', params: params, useCache: true);
      
      final items = data['data'] ?? data['items'] ?? [];
      if (items is List) {
        return items.map((item) => FamilyMilestone.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load milestones',
        originalError: e,
      );
    }
  }

  Future<FamilyMilestone> createMilestone(Map<String, dynamic> milestoneData) async {
    try {
      final data = await post('/api/v1/family/milestones', body: milestoneData);
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

  Future<FamilyMilestone> likeMilestone(String milestoneId) async {
    try {
      final data = await post('/api/v1/family/milestones/$milestoneId/like', body: {});
      return FamilyMilestone.fromJson(data['data'] ?? data);
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to like milestone',
        originalError: e,
      );
    }
  }

  Future<void> deleteMilestone(String milestoneId) async {
    try {
      await delete('/api/v1/family/milestones/$milestoneId');
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
}

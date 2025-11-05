import '../common/family_api_client.dart';
import '../common/family_exceptions.dart';
import '../../../models/family/family_circle.dart';

class FamilyCirclesService extends FamilyApiClient {
  Future<Map<String, dynamic>> getFamilyCircles({
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final data = await get(
        '/family/core/circles',
        params: {
          'page': page.toString(),
          'page_size': pageSize.toString(),
        },
        useCache: true,
      );
      
      final items = data['data'] ?? data['items'] ?? [];
      final total = data['total'] ?? 0;
      
      final circles = (items as List)
          .map((item) => FamilyCircle.fromJson(item as Map<String, dynamic>))
          .toList();
      
      return {
        'circles': circles,
        'total': total,
        'page': page,
        'pageSize': pageSize,
        'hasMore': (page * pageSize) < total,
      };
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load family circles',
        originalError: e,
      );
    }
  }

  Future<FamilyCircle> getFamilyCircleById(String circleId) async {
    try {
      final data = await get('/family/core/circles/$circleId', useCache: true);
      return FamilyCircle.fromJson(data['data'] ?? data);
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load family circle',
        originalError: e,
      );
    }
  }

  Future<FamilyCircle> createFamilyCircle(FamilyCircleCreate circle) async {
    try {
      final data = await post('/family/core/circles', body: circle.toJson());
      return FamilyCircle.fromJson(data['data'] ?? data);
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to create family circle',
        originalError: e,
      );
    }
  }

  Future<FamilyCircle> updateFamilyCircle(
    String circleId,
    FamilyCircleUpdate updates,
  ) async {
    try {
      final data = await put('/family/core/circles/$circleId', body: updates.toJson());
      return FamilyCircle.fromJson(data['data'] ?? data);
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to update family circle',
        originalError: e,
      );
    }
  }

  Future<void> deleteFamilyCircle(String circleId) async {
    try {
      await delete('/family/core/circles/$circleId');
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to delete family circle',
        originalError: e,
      );
    }
  }

  Future<void> addCircleMember(String circleId, String userId) async {
    try {
      await post('/family/core/circles/$circleId/members/$userId');
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to add member to circle',
        originalError: e,
      );
    }
  }

  Future<void> removeCircleMember(String circleId, String memberId) async {
    try {
      await delete('/family/core/circles/$circleId/members/$memberId');
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to remove member from circle',
        originalError: e,
      );
    }
  }
}

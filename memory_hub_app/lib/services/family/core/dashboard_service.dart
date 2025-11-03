import '../common/family_api_client.dart';
import '../common/family_exceptions.dart';

class FamilyDashboardService extends FamilyApiClient {
  Future<Map<String, dynamic>> getFamilyDashboard() async {
    try {
      final data = await get('/family/dashboard', useCache: true);
      
      if (data['data'] != null) {
        return data['data'] as Map<String, dynamic>;
      }
      return data as Map<String, dynamic>;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load family dashboard',
        originalError: e,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getQuickActions() async {
    try {
      final dashboard = await getFamilyDashboard();
      final actions = dashboard['quick_actions'];
      if (actions is List) {
        return actions.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load quick actions',
        originalError: e,
      );
    }
  }
}

import '../common/family_api_client.dart';
import '../common/family_exceptions.dart';

class FamilyRecipesService extends FamilyApiClient {
  Future<List<Map<String, dynamic>>> getRecipes({
    int page = 1,
    int limit = 20,
    String? category,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (category != null) 'category': category,
      };
      
      final data = await get('/api/v1/family/recipes', params: params, useCache: true);
      
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
        message: 'Failed to load recipes',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> getRecipe(String recipeId) async {
    try {
      final data = await get('/api/v1/family/recipes/$recipeId', useCache: true);
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load recipe',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> createRecipe(Map<String, dynamic> recipeData) async {
    try {
      final data = await post('/api/v1/family/recipes', body: recipeData);
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to create recipe',
        originalError: e,
      );
    }
  }

  Future<List<Map<String, dynamic>>> filterByCategory(String category) async {
    return getRecipes(category: category);
  }

  Future<void> deleteRecipe(String recipeId) async {
    try {
      await delete('/api/v1/family/recipes/$recipeId');
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to delete recipe',
        originalError: e,
      );
    }
  }
}

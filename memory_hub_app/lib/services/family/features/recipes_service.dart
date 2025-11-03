import '../common/family_api_client.dart';
import '../common/family_exceptions.dart';
import '../../../models/family/family_recipe.dart';

class FamilyRecipesService extends FamilyApiClient {
  Future<List<FamilyRecipe>> getRecipes({
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
      
      final data = await get('/family/recipes', params: params, useCache: true);
      
      final items = data['data'] ?? data['items'] ?? [];
      if (items is List) {
        return items.map((item) => FamilyRecipe.fromJson(item as Map<String, dynamic>)).toList();
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

  Future<FamilyRecipe> getRecipe(String recipeId) async {
    try {
      final data = await get('/family/recipes/$recipeId', useCache: true);
      return FamilyRecipe.fromJson(data['data'] ?? data);
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

  Future<FamilyRecipe> createRecipe(Map<String, dynamic> recipeData) async {
    try {
      final data = await post('/family/recipes', body: recipeData);
      return FamilyRecipe.fromJson(data['data'] ?? data);
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

  Future<List<FamilyRecipe>> filterByCategory(String category) async {
    return getRecipes(category: category);
  }

  Future<void> deleteRecipe(String recipeId) async {
    try {
      await delete('/family/recipes/$recipeId');
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

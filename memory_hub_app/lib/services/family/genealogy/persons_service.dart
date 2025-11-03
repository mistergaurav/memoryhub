import '../common/family_api_client.dart';
import '../common/family_exceptions.dart';
import '../../../models/family/genealogy_person.dart';

class GenealogyPersonsService extends FamilyApiClient {
  Future<List<GenealogyPerson>> getPersons({
    int page = 1,
    int limit = 100,
    String? treeId,
  }) async {
    try {
      final params = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (treeId != null) 'tree_id': treeId,
      };
      
      final data = await get(
        '/family/genealogy/persons',
        params: params,
        useCache: true,
      );
      
      final items = data['data'] ?? data['items'] ?? [];
      if (items is List) {
        return items.map((item) => GenealogyPerson.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load persons',
        originalError: e,
      );
    }
  }

  Future<GenealogyPerson> getPerson(String personId) async {
    try {
      final data = await get('/family/genealogy/persons/$personId', useCache: true);
      return GenealogyPerson.fromJson(data['data'] ?? data);
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to load person',
        originalError: e,
      );
    }
  }

  Future<GenealogyPerson> createPerson(Map<String, dynamic> personData) async {
    try {
      final data = await post('/family/genealogy/persons', body: personData);
      return GenealogyPerson.fromJson(data['data'] ?? data);
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to create person',
        originalError: e,
      );
    }
  }

  Future<GenealogyPerson> updatePerson(
    String personId,
    Map<String, dynamic> personData,
  ) async {
    try {
      final data = await put(
        '/family/genealogy/persons/$personId',
        body: personData,
      );
      return GenealogyPerson.fromJson(data['data'] ?? data);
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to update person',
        originalError: e,
      );
    }
  }

  Future<void> deletePerson(String personId) async {
    try {
      await delete('/family/genealogy/persons/$personId');
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to delete person',
        originalError: e,
      );
    }
  }

  Future<List<GenealogyPerson>> searchPersons(String query) async {
    try {
      final data = await get(
        '/family/genealogy/persons/search',
        params: {'q': query},
        useCache: true,
      );
      
      final items = data['data'] ?? data['items'] ?? [];
      if (items is List) {
        return items.map((item) => GenealogyPerson.fromJson(item as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to search persons',
        originalError: e,
      );
    }
  }
}

import '../common/family_api_client.dart';
import '../common/family_exceptions.dart';
import '../../../models/family/genealogy_person.dart';

class GenealogyPersonsService extends FamilyApiClient {
  int _currentPage = 1;
  bool _hasMore = true;
  final int _pageSize = 50;

  /// Create self-person (user's own profile in family tree)
  Future<Map<String, dynamic>> createSelfPerson() async {
    try {
      final data = await post(
        '/family/genealogy/persons/self',
        body: {},
      );
      return data['data'] ?? data;
    } catch (e) {
      if (e is ApiException) {
        if (e.statusCode == 400) {
          throw Exception('You already have a profile in your family tree');
        }
        throw Exception('Failed to create your profile: ${e.message}');
      }
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Error creating self-person',
        originalError: e,
      );
    }
  }
  
  /// Reset pagination state
  void resetPagination() {
    _currentPage = 1;
    _hasMore = true;
  }
  
  /// Check if more persons can be loaded
  bool get hasMore => _hasMore;
  
  /// Get current page
  int get currentPage => _currentPage;
  
  Future<List<GenealogyPerson>> getPersons({
    int? page,
    int? limit,
    String? treeId,
    bool append = false,  // If true, load next page; if false, reset
  }) async {
    try {
      // If not appending, reset to first page
      if (!append) {
        _currentPage = 1;
        _hasMore = true;
      }
      
      final pageToFetch = page ?? _currentPage;
      final pageSize = limit ?? _pageSize;
      
      final params = {
        'page': pageToFetch.toString(),
        'page_size': pageSize.toString(),
        if (treeId != null) 'tree_id': treeId,
      };
      
      final data = await get(
        '/family/genealogy/persons',
        params: params,
        useCache: false,  // Don't cache paginated results
      );
      
      final items = data['data']?['items'] ?? data['items'] ?? [];
      final total = data['data']?['total'] ?? data['total'] ?? 0;
      
      // Update pagination state
      if (append) {
        _currentPage++;
      }
      
      // Check if there are more pages
      _hasMore = (pageToFetch * pageSize) < total;
      
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
  
  /// Load next page of persons
  Future<List<GenealogyPerson>> loadMorePersons({String? treeId}) async {
    return getPersons(append: true, treeId: treeId);
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

  Future<GenealogyPerson> createPerson(Map<String, dynamic> personData, {String? treeId}) async {
    try {
      final queryParams = treeId != null ? {'tree_id': treeId} : null;
      final data = await post(
        '/family/genealogy/persons', 
        body: personData,
        params: queryParams,
      );
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

  Future<GenealogyPerson> approvePerson(String personId) async {
    try {
      final data = await post('/family/genealogy/persons/$personId/approve');
      return GenealogyPerson.fromJson(data['data'] ?? data);
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to approve person',
        originalError: e,
      );
    }
  }

  Future<GenealogyPerson> rejectPerson(String personId, {String? reason}) async {
    try {
      final queryParams = reason != null ? {'reason': reason} : null;
      final data = await post(
        '/family/genealogy/persons/$personId/reject',
        params: queryParams,
      );
      return GenealogyPerson.fromJson(data['data'] ?? data);
    } catch (e) {
      if (e is ApiException || e is NetworkException || e is AuthException) {
        rethrow;
      }
      throw NetworkException(
        message: 'Failed to reject person',
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
      // Use the new search endpoint
      final data = await get(
        '/family/genealogy/persons/search',
        params: {'q': query, 'limit': '50'},
        useCache: false,  // Don't cache search results
      );
      
      final items = data['data']?['items'] ?? data['items'] ?? [];
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

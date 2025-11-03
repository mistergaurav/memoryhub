import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../auth_service.dart';
import '../../config/api_config.dart';
import '../../models/family/family_album.dart';
import '../../models/family/family_timeline.dart';
import '../../models/family/family_milestone.dart';
import '../../models/family/family_recipe.dart';
import '../../models/family/legacy_letter.dart';
import '../../models/family/family_tradition.dart';
import '../../models/family/parental_control.dart';
import '../../models/family/family_calendar.dart';
import '../../models/family/paginated_response.dart';
import '../../models/user_search_result.dart';
import 'common/family_exceptions.dart';

class FamilyService {
  static String get baseUrl => ApiConfig.baseUrl;
  final AuthService _authService = AuthService();

  static const int _maxRetries = 3;
  static const Duration _requestTimeout = Duration(seconds: 30);
  static const Duration _initialRetryDelay = Duration(milliseconds: 500);

  Future<T> _executeWithRetry<T>(
    Future<T> Function() operation, {
    int retryCount = 0,
  }) async {
    try {
      return await operation().timeout(_requestTimeout);
    } on TimeoutException {
      if (retryCount < _maxRetries) {
        final delay = _initialRetryDelay * (1 << retryCount);
        await Future.delayed(delay);
        return _executeWithRetry(operation, retryCount: retryCount + 1);
      }
      throw NetworkException(
        message: 'Request timeout after ${_requestTimeout.inSeconds} seconds',
        statusCode: 408,
      );
    } on SocketException catch (e) {
      if (retryCount < _maxRetries) {
        final delay = _initialRetryDelay * (1 << retryCount);
        await Future.delayed(delay);
        return _executeWithRetry(operation, retryCount: retryCount + 1);
      }
      throw NetworkException(
        message: 'Network connection failed: ${e.message}',
        originalError: e,
      );
    } on http.ClientException catch (e) {
      if (retryCount < _maxRetries) {
        final delay = _initialRetryDelay * (1 << retryCount);
        await Future.delayed(delay);
        return _executeWithRetry(operation, retryCount: retryCount + 1);
      }
      throw NetworkException(
        message: 'HTTP client error: ${e.message}',
        originalError: e,
      );
    }
  }

  Future<http.Response> _handleRequest(
    Future<http.Response> Function() requestFunction,
  ) async {
    return await _executeWithRetry(() async {
      try {
        final response = await requestFunction();
        
        if (response.statusCode == 401) {
          final newTokens = await _authService.refreshAccessToken();
          if (newTokens != null) {
            return await requestFunction();
          }
          throw AuthException(
            message: 'Session expired. Please log in again.',
            requiresLogin: true,
          );
        }
        
        _validateResponse(response);
        return response;
      } catch (e) {
        if (e is AuthException || e is ApiException || e is NetworkException) {
          rethrow;
        }
        throw NetworkException(
          message: 'Unexpected error occurred',
          originalError: e,
        );
      }
    });
  }

  void _validateResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    String? detail;
    Map<String, dynamic>? errors;

    try {
      final body = jsonDecode(response.body);
      if (body is Map<String, dynamic>) {
        detail = body['detail']?.toString() ?? body['message']?.toString();
        errors = body['errors'] as Map<String, dynamic>?;
      }
    } catch (_) {
    }

    switch (response.statusCode) {
      case 400:
        throw ApiException(
          message: 'Invalid request data',
          statusCode: 400,
          detail: detail ?? 'The request could not be processed',
          errors: errors,
        );
      case 403:
        throw ApiException(
          message: 'Access forbidden',
          statusCode: 403,
          detail: detail ?? 'You do not have permission to perform this action',
        );
      case 404:
        throw ApiException(
          message: 'Resource not found',
          statusCode: 404,
          detail: detail ?? 'The requested resource was not found',
        );
      case 409:
        throw ApiException(
          message: 'Resource conflict',
          statusCode: 409,
          detail: detail ?? 'The resource already exists or conflicts with existing data',
        );
      case 422:
        throw ApiException(
          message: 'Validation error',
          statusCode: 422,
          detail: detail ?? 'The provided data is invalid',
          errors: errors,
        );
      case 429:
        throw ApiException(
          message: 'Too many requests',
          statusCode: 429,
          detail: detail ?? 'Rate limit exceeded. Please try again later',
        );
      case 500:
        throw ApiException(
          message: 'Internal server error',
          statusCode: 500,
          detail: detail ?? 'An unexpected error occurred on the server',
        );
      case 502:
        throw ApiException(
          message: 'Bad gateway',
          statusCode: 502,
          detail: detail ?? 'The server received an invalid response',
        );
      case 503:
        throw ApiException(
          message: 'Service unavailable',
          statusCode: 503,
          detail: detail ?? 'The service is temporarily unavailable',
        );
      default:
        throw ApiException(
          message: 'Request failed',
          statusCode: response.statusCode,
          detail: detail ?? 'An error occurred processing your request',
        );
    }
  }

  Future<PaginatedResponse<FamilyAlbum>> getFamilyAlbums({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/family-albums/?page=$page&page_size=$pageSize'),
          headers: headers,
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      return PaginatedResponse.fromJson(
        responseBody,
        (json) => FamilyAlbum.fromJson(json),
      );
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load family albums',
        originalError: e,
      );
    }
  }

  Future<List<AlbumPhoto>> getAlbumPhotos(String albumId) async {
    if (albumId.isEmpty) {
      throw ApiException(
        message: 'Invalid album ID',
        statusCode: 400,
        detail: 'Album ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/family-albums/$albumId/photos'),
          headers: headers,
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      final data = responseBody['data'];
      if (data is List) {
        return data.map((json) => AlbumPhoto.fromJson(json)).toList();
      }
      return [];
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load album photos',
        originalError: e,
      );
    }
  }

  Future<FamilyAlbum> createAlbum(Map<String, dynamic> albumData) async {
    if (albumData.isEmpty) {
      throw ApiException(
        message: 'Invalid album data',
        statusCode: 400,
        detail: 'Album data cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/family-albums/'),
          headers: headers,
          body: jsonEncode(albumData),
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      final data = responseBody['data'] ?? responseBody;
      return FamilyAlbum.fromJson(data);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to create album',
        originalError: e,
      );
    }
  }

  Future<FamilyAlbum> updateAlbum(
    String albumId,
    Map<String, dynamic> albumData,
  ) async {
    if (albumId.isEmpty) {
      throw ApiException(
        message: 'Invalid album ID',
        statusCode: 400,
        detail: 'Album ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.put(
          Uri.parse('$baseUrl/family-albums/$albumId'),
          headers: headers,
          body: jsonEncode(albumData),
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      final data = responseBody['data'] ?? responseBody;
      return FamilyAlbum.fromJson(data);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to update album',
        originalError: e,
      );
    }
  }

  Future<void> deleteAlbum(String albumId) async {
    if (albumId.isEmpty) {
      throw ApiException(
        message: 'Invalid album ID',
        statusCode: 400,
        detail: 'Album ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      await _handleRequest(
        () => http.delete(
          Uri.parse('$baseUrl/family-albums/$albumId'),
          headers: headers,
        ),
      );
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to delete album',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> addPhotoToAlbum(
    String albumId,
    Map<String, dynamic> photoData,
  ) async {
    if (albumId.isEmpty) {
      throw ApiException(
        message: 'Invalid album ID',
        statusCode: 400,
        detail: 'Album ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/family-albums/$albumId/photos'),
          headers: headers,
          body: jsonEncode(photoData),
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      return responseBody['data'] ?? responseBody;
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to add photo to album',
        originalError: e,
      );
    }
  }

  Future<void> deletePhotoFromAlbum(String albumId, String photoId) async {
    if (albumId.isEmpty || photoId.isEmpty) {
      throw ApiException(
        message: 'Invalid parameters',
        statusCode: 400,
        detail: 'Album ID and photo ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      await _handleRequest(
        () => http.delete(
          Uri.parse('$baseUrl/family-albums/$albumId/photos/$photoId'),
          headers: headers,
        ),
      );
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to delete photo',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> likePhoto(String albumId, String photoId) async {
    if (albumId.isEmpty || photoId.isEmpty) {
      throw ApiException(
        message: 'Invalid parameters',
        statusCode: 400,
        detail: 'Album ID and photo ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/family-albums/$albumId/photos/$photoId/like'),
          headers: headers,
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      return responseBody['data'] ?? responseBody;
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to like photo',
        originalError: e,
      );
    }
  }

  Future<PaginatedResponse<TimelineEvent>> getTimelineEvents({
    String? filter,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      var url = '$baseUrl/family-timeline/?page=$page&page_size=$pageSize';
      if (filter != null && filter.isNotEmpty) {
        url += '&filter=${Uri.encodeComponent(filter)}';
      }
      
      final response = await _handleRequest(
        () => http.get(Uri.parse(url), headers: headers),
      );
      
      final responseBody = jsonDecode(response.body);
      
      if (responseBody is Map<String, dynamic>) {
        return PaginatedResponse.fromJson(
          responseBody,
          (json) => TimelineEvent.fromJson(json),
        );
      } else if (responseBody is List) {
        return PaginatedResponse(
          items: responseBody.map((json) => TimelineEvent.fromJson(json)).toList(),
          total: responseBody.length,
          page: page,
          pageSize: pageSize,
          hasMore: false,
        );
      }
      
      return PaginatedResponse(
        items: [],
        total: 0,
        page: page,
        pageSize: pageSize,
        hasMore: false,
      );
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load timeline events',
        originalError: e,
      );
    }
  }

  Future<PaginatedResponse<FamilyMilestone>> getMilestones({
    int page = 1,
    int pageSize = 50,
    String? personId,
    String? milestoneType,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      var url = '$baseUrl/family-milestones/?page=$page&page_size=$pageSize';
      if (personId != null && personId.isNotEmpty) {
        url += '&person_id=${Uri.encodeComponent(personId)}';
      }
      if (milestoneType != null && milestoneType.isNotEmpty) {
        url += '&milestone_type=${Uri.encodeComponent(milestoneType)}';
      }
      
      final response = await _handleRequest(
        () => http.get(Uri.parse(url), headers: headers),
      );
      
      final responseBody = jsonDecode(response.body);
      return PaginatedResponse.fromJson(
        responseBody,
        (json) => FamilyMilestone.fromJson(json),
      );
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load milestones',
        originalError: e,
      );
    }
  }

  Future<FamilyMilestone> getMilestoneDetail(String milestoneId) async {
    if (milestoneId.isEmpty) {
      throw ApiException(
        message: 'Invalid milestone ID',
        statusCode: 400,
        detail: 'Milestone ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/family-milestones/$milestoneId'),
          headers: headers,
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      final data = responseBody['data'] ?? responseBody;
      return FamilyMilestone.fromJson(data);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load milestone details',
        originalError: e,
      );
    }
  }

  Future<FamilyMilestone> createMilestone(
    Map<String, dynamic> milestoneData,
  ) async {
    if (milestoneData.isEmpty) {
      throw ApiException(
        message: 'Invalid milestone data',
        statusCode: 400,
        detail: 'Milestone data cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/family-milestones/'),
          headers: headers,
          body: jsonEncode(milestoneData),
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      final data = responseBody['data'] ?? responseBody;
      return FamilyMilestone.fromJson(data);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to create milestone',
        originalError: e,
      );
    }
  }

  Future<FamilyMilestone> updateMilestone(
    String milestoneId,
    Map<String, dynamic> milestoneData,
  ) async {
    if (milestoneId.isEmpty) {
      throw ApiException(
        message: 'Invalid milestone ID',
        statusCode: 400,
        detail: 'Milestone ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.put(
          Uri.parse('$baseUrl/family-milestones/$milestoneId'),
          headers: headers,
          body: jsonEncode(milestoneData),
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      final data = responseBody['data'] ?? responseBody;
      return FamilyMilestone.fromJson(data);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to update milestone',
        originalError: e,
      );
    }
  }

  Future<void> deleteMilestone(String milestoneId) async {
    if (milestoneId.isEmpty) {
      throw ApiException(
        message: 'Invalid milestone ID',
        statusCode: 400,
        detail: 'Milestone ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      await _handleRequest(
        () => http.delete(
          Uri.parse('$baseUrl/family-milestones/$milestoneId'),
          headers: headers,
        ),
      );
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to delete milestone',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> likeMilestone(String milestoneId) async {
    if (milestoneId.isEmpty) {
      throw ApiException(
        message: 'Invalid milestone ID',
        statusCode: 400,
        detail: 'Milestone ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/family-milestones/$milestoneId/like'),
          headers: headers,
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      return responseBody['data'] ?? responseBody;
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to like milestone',
        originalError: e,
      );
    }
  }

  Future<PaginatedResponse<FamilyRecipe>> getRecipes({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/family-recipes/?page=$page&page_size=$pageSize'),
          headers: headers,
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      return PaginatedResponse.fromJson(
        responseBody,
        (json) => FamilyRecipe.fromJson(json),
      );
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load recipes',
        originalError: e,
      );
    }
  }

  Future<FamilyRecipe> getRecipeDetail(String id) async {
    if (id.isEmpty) {
      throw ApiException(
        message: 'Invalid recipe ID',
        statusCode: 400,
        detail: 'Recipe ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/family-recipes/$id'),
          headers: headers,
        ),
      );
      
      return FamilyRecipe.fromJson(jsonDecode(response.body));
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load recipe',
        originalError: e,
      );
    }
  }

  Future<FamilyRecipe> createRecipe(Map<String, dynamic> recipeData) async {
    if (recipeData.isEmpty) {
      throw ApiException(
        message: 'Invalid recipe data',
        statusCode: 400,
        detail: 'Recipe data cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/family-recipes/'),
          headers: headers,
          body: jsonEncode(recipeData),
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      final data = responseBody['data'] ?? responseBody;
      return FamilyRecipe.fromJson(data);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to create recipe',
        originalError: e,
      );
    }
  }

  Future<void> rateRecipe(String recipeId, int rating) async {
    if (recipeId.isEmpty) {
      throw ApiException(
        message: 'Invalid recipe ID',
        statusCode: 400,
        detail: 'Recipe ID cannot be empty',
      );
    }

    if (rating < 1 || rating > 5) {
      throw ApiException(
        message: 'Invalid rating',
        statusCode: 400,
        detail: 'Rating must be between 1 and 5',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/family-recipes/$recipeId/rate'),
          headers: headers,
          body: jsonEncode({'rating': rating}),
        ),
      );
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to rate recipe',
        originalError: e,
      );
    }
  }

  Future<void> favoriteRecipe(String recipeId) async {
    if (recipeId.isEmpty) {
      throw ApiException(
        message: 'Invalid recipe ID',
        statusCode: 400,
        detail: 'Recipe ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/family-recipes/$recipeId/favorite'),
          headers: headers,
        ),
      );
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to favorite recipe',
        originalError: e,
      );
    }
  }

  Future<void> unfavoriteRecipe(String recipeId) async {
    if (recipeId.isEmpty) {
      throw ApiException(
        message: 'Invalid recipe ID',
        statusCode: 400,
        detail: 'Recipe ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      await _handleRequest(
        () => http.delete(
          Uri.parse('$baseUrl/family-recipes/$recipeId/favorite'),
          headers: headers,
        ),
      );
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to unfavorite recipe',
        originalError: e,
      );
    }
  }

  Future<void> markRecipeMade(String recipeId) async {
    if (recipeId.isEmpty) {
      throw ApiException(
        message: 'Invalid recipe ID',
        statusCode: 400,
        detail: 'Recipe ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/family-recipes/$recipeId/made'),
          headers: headers,
        ),
      );
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to mark recipe as made',
        originalError: e,
      );
    }
  }

  Future<List<LegacyLetter>> getLegacyLetters() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/legacy-letters/'),
          headers: headers,
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      final List<dynamic> items = responseBody['items'] ?? [];
      return items.map((json) => LegacyLetter.fromJson(json)).toList();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load legacy letters',
        originalError: e,
      );
    }
  }

  Future<LegacyLetter> createLegacyLetter(
    Map<String, dynamic> letterData,
  ) async {
    if (letterData.isEmpty) {
      throw ApiException(
        message: 'Invalid letter data',
        statusCode: 400,
        detail: 'Letter data cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/legacy-letters/'),
          headers: headers,
          body: jsonEncode(letterData),
        ),
      );
      
      return LegacyLetter.fromJson(jsonDecode(response.body));
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to create legacy letter',
        originalError: e,
      );
    }
  }

  Future<List<LegacyLetter>> getSentLetters() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/legacy-letters/sent'),
          headers: headers,
        ),
      );
      
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => LegacyLetter.fromJson(json)).toList();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load sent letters',
        originalError: e,
      );
    }
  }

  Future<List<ReceivedLetter>> getReceivedLetters() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/legacy-letters/received'),
          headers: headers,
        ),
      );
      
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ReceivedLetter.fromJson(json)).toList();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load received letters',
        originalError: e,
      );
    }
  }

  Future<LegacyLetter> getLetterDetail(String id) async {
    if (id.isEmpty) {
      throw ApiException(
        message: 'Invalid letter ID',
        statusCode: 400,
        detail: 'Letter ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/legacy-letters/$id'),
          headers: headers,
        ),
      );
      
      return LegacyLetter.fromJson(jsonDecode(response.body));
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load letter detail',
        originalError: e,
      );
    }
  }

  Future<void> markLetterAsRead(String id) async {
    if (id.isEmpty) {
      throw ApiException(
        message: 'Invalid letter ID',
        statusCode: 400,
        detail: 'Letter ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/legacy-letters/$id/mark-read'),
          headers: headers,
        ),
      );
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to mark letter as read',
        originalError: e,
      );
    }
  }

  Future<PaginatedResponse<FamilyTradition>> getTraditions({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/family-traditions/?page=$page&page_size=$pageSize'),
          headers: headers,
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      return PaginatedResponse.fromJson(
        responseBody,
        (json) => FamilyTradition.fromJson(json),
      );
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load traditions',
        originalError: e,
      );
    }
  }

  Future<FamilyTradition> createTradition(
    Map<String, dynamic> traditionData,
  ) async {
    if (traditionData.isEmpty) {
      throw ApiException(
        message: 'Invalid tradition data',
        statusCode: 400,
        detail: 'Tradition data cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/family-traditions/'),
          headers: headers,
          body: jsonEncode(traditionData),
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      final data = responseBody['data'] ?? responseBody;
      return FamilyTradition.fromJson(data);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to create tradition',
        originalError: e,
      );
    }
  }

  Future<ParentalControlSettings> getParentalControls() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/parental-controls/settings'),
          headers: headers,
        ),
      );
      
      return ParentalControlSettings.fromJson(jsonDecode(response.body));
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load parental controls',
        originalError: e,
      );
    }
  }

  Future<List<ApprovalRequest>> getApprovalQueue() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/parental-controls/approvals'),
          headers: headers,
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      final List<dynamic> items = responseBody['items'] ?? [];
      return items.map((json) => ApprovalRequest.fromJson(json)).toList();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load approval queue',
        originalError: e,
      );
    }
  }

  Future<void> approveRequest(String requestId) async {
    if (requestId.isEmpty) {
      throw ApiException(
        message: 'Invalid request ID',
        statusCode: 400,
        detail: 'Request ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/parental-controls/approvals/$requestId/approve'),
          headers: headers,
        ),
      );
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to approve request',
        originalError: e,
      );
    }
  }

  Future<void> rejectRequest(String requestId, String reason) async {
    if (requestId.isEmpty) {
      throw ApiException(
        message: 'Invalid request ID',
        statusCode: 400,
        detail: 'Request ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/parental-controls/approvals/$requestId/reject'),
          headers: headers,
          body: jsonEncode({'reason': reason}),
        ),
      );
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to reject request',
        originalError: e,
      );
    }
  }

  Future<PaginatedResponse<FamilyCalendarEvent>> getCalendarEvents({
    DateTime? startDate,
    DateTime? endDate,
    String? eventType,
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      var url = '$baseUrl/family-calendar/events?page=$page&page_size=$pageSize';
      if (startDate != null) {
        url += '&start_date=${startDate.toIso8601String()}';
      }
      if (endDate != null) {
        url += '&end_date=${endDate.toIso8601String()}';
      }
      if (eventType != null && eventType.isNotEmpty) {
        url += '&event_type=${Uri.encodeComponent(eventType)}';
      }
      
      final response = await _handleRequest(
        () => http.get(Uri.parse(url), headers: headers),
      );
      
      final responseBody = jsonDecode(response.body);
      return PaginatedResponse.fromJson(
        responseBody,
        (json) => FamilyCalendarEvent.fromJson(json),
      );
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load calendar events',
        originalError: e,
      );
    }
  }

  Future<FamilyCalendarEvent> getCalendarEvent(String eventId) async {
    if (eventId.isEmpty) {
      throw ApiException(
        message: 'Invalid event ID',
        statusCode: 400,
        detail: 'Event ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/family-calendar/events/$eventId'),
          headers: headers,
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      final data = responseBody['data'] ?? responseBody;
      return FamilyCalendarEvent.fromJson(data);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load calendar event',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> createCalendarEvent(
    Map<String, dynamic> eventData,
  ) async {
    if (eventData.isEmpty) {
      throw ApiException(
        message: 'Invalid event data',
        statusCode: 400,
        detail: 'Event data cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/family-calendar/events'),
          headers: headers,
          body: jsonEncode(eventData),
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      return responseBody['data'] ?? responseBody;
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to create calendar event',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> updateCalendarEvent(
    String eventId,
    Map<String, dynamic> eventData,
  ) async {
    if (eventId.isEmpty) {
      throw ApiException(
        message: 'Invalid event ID',
        statusCode: 400,
        detail: 'Event ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.put(
          Uri.parse('$baseUrl/family-calendar/events/$eventId'),
          headers: headers,
          body: jsonEncode(eventData),
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      return responseBody['data'] ?? responseBody;
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to update calendar event',
        originalError: e,
      );
    }
  }

  Future<void> deleteCalendarEvent(String eventId) async {
    if (eventId.isEmpty) {
      throw ApiException(
        message: 'Invalid event ID',
        statusCode: 400,
        detail: 'Event ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      await _handleRequest(
        () => http.delete(
          Uri.parse('$baseUrl/family-calendar/events/$eventId'),
          headers: headers,
        ),
      );
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to delete calendar event',
        originalError: e,
      );
    }
  }

  Future<List<FamilyCalendarEvent>> getUpcomingBirthdays({
    int daysAhead = 30,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/family-calendar/birthdays?days_ahead=$daysAhead'),
          headers: headers,
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      final List<dynamic> data = responseBody['data'] ?? [];
      return data.map((json) => FamilyCalendarEvent.fromJson(json)).toList();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load upcoming birthdays',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> detectEventConflicts(String eventId) async {
    if (eventId.isEmpty) {
      throw ApiException(
        message: 'Invalid event ID',
        statusCode: 400,
        detail: 'Event ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/family-calendar/events/$eventId/conflicts'),
          headers: headers,
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      return responseBody['data'] ?? responseBody;
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to detect conflicts',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> getFamilyDashboard() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/family/dashboard'),
          headers: headers,
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      if (responseBody['data'] != null) {
        return responseBody['data'] as Map<String, dynamic>;
      }
      return responseBody;
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load family dashboard',
        originalError: e,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getPersons() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/genealogy/persons'),
          headers: headers,
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      final List<dynamic> items = responseBody['items'] ?? [];
      return items.cast<Map<String, dynamic>>();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load persons',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> createPerson(
    Map<String, dynamic> personData,
  ) async {
    if (personData.isEmpty) {
      throw ApiException(
        message: 'Invalid person data',
        statusCode: 400,
        detail: 'Person data cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/genealogy/persons'),
          headers: headers,
          body: jsonEncode(personData),
        ),
      );
      
      return jsonDecode(response.body);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to create person',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> updatePerson(
    String personId,
    Map<String, dynamic> personData,
  ) async {
    if (personId.isEmpty) {
      throw ApiException(
        message: 'Invalid person ID',
        statusCode: 400,
        detail: 'Person ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.put(
          Uri.parse('$baseUrl/genealogy/persons/$personId'),
          headers: headers,
          body: jsonEncode(personData),
        ),
      );
      
      return jsonDecode(response.body);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to update person',
        originalError: e,
      );
    }
  }

  Future<void> deletePerson(String personId) async {
    if (personId.isEmpty) {
      throw ApiException(
        message: 'Invalid person ID',
        statusCode: 400,
        detail: 'Person ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      await _handleRequest(
        () => http.delete(
          Uri.parse('$baseUrl/genealogy/persons/$personId'),
          headers: headers,
        ),
      );
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to delete person',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> createRelationship(
    Map<String, dynamic> relationshipData,
  ) async {
    if (relationshipData.isEmpty) {
      throw ApiException(
        message: 'Invalid relationship data',
        statusCode: 400,
        detail: 'Relationship data cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/genealogy/relationships'),
          headers: headers,
          body: jsonEncode(relationshipData),
        ),
      );
      
      return jsonDecode(response.body);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to create relationship',
        originalError: e,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getRelationships() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/genealogy/relationships'),
          headers: headers,
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      final List<dynamic> items = responseBody['items'] ?? [];
      return items.cast<Map<String, dynamic>>();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load relationships',
        originalError: e,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getFamilyTree() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/genealogy/tree'),
          headers: headers,
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      final List<dynamic> items = responseBody['items'] ?? [];
      return items.cast<Map<String, dynamic>>();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load family tree',
        originalError: e,
      );
    }
  }

  Future<List<Map<String, dynamic>>> searchPlatformUsers(String query) async {
    if (query.isEmpty) {
      throw ApiException(
        message: 'Invalid search query',
        statusCode: 400,
        detail: 'Search query cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/genealogy/search-users?query=${Uri.encodeComponent(query)}'),
          headers: headers,
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      final List<dynamic> items = responseBody['items'] ?? [];
      return items.cast<Map<String, dynamic>>();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to search users',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> sendFamilyHubInvitation(
    String personId,
    String invitedUserId,
    String? message,
  ) async {
    if (personId.isEmpty || invitedUserId.isEmpty) {
      throw ApiException(
        message: 'Invalid parameters',
        statusCode: 400,
        detail: 'Person ID and invited user ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final invitationData = {
        'person_id': personId,
        'invited_user_id': invitedUserId,
        if (message != null && message.isNotEmpty) 'message': message,
      };
      
      final response = await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/genealogy/invitations'),
          headers: headers,
          body: jsonEncode(invitationData),
        ),
      );
      
      return jsonDecode(response.body);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to send invitation',
        originalError: e,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getSentInvitations({
    String? statusFilter,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      var url = '$baseUrl/genealogy/invitations/sent';
      if (statusFilter != null && statusFilter.isNotEmpty) {
        url += '?status_filter=${Uri.encodeComponent(statusFilter)}';
      }
      
      final response = await _handleRequest(
        () => http.get(Uri.parse(url), headers: headers),
      );
      
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load sent invitations',
        originalError: e,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getReceivedInvitations({
    String? statusFilter,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      var url = '$baseUrl/genealogy/invitations/received';
      if (statusFilter != null && statusFilter.isNotEmpty) {
        url += '?status_filter=${Uri.encodeComponent(statusFilter)}';
      }
      
      final response = await _handleRequest(
        () => http.get(Uri.parse(url), headers: headers),
      );
      
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load received invitations',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> respondToInvitation(
    String invitationId,
    String action,
  ) async {
    if (invitationId.isEmpty || action.isEmpty) {
      throw ApiException(
        message: 'Invalid parameters',
        statusCode: 400,
        detail: 'Invitation ID and action cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/genealogy/invitations/$invitationId/respond'),
          headers: headers,
          body: jsonEncode({'action': action}),
        ),
      );
      
      return jsonDecode(response.body);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to respond to invitation',
        originalError: e,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getFamilyMembers() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/family/relationships'),
          headers: headers,
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      final List<dynamic> items = responseBody['items'] ?? [];
      return items
          .map((item) => {
                'id': item['related_user_id'] ?? item['id'],
                'name': item['related_user_name'] ?? item['name'] ?? 'Unknown',
                'relation_type': item['relation_type'] ?? 'family',
              })
          .toList();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load family members',
        originalError: e,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getFriendCircles() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/family/circles'),
          headers: headers,
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      final List<dynamic> items = responseBody['items'] ?? [];
      return items
          .map((item) => {
                'id': item['id'] ?? '',
                'name': item['name'] ?? 'Unknown',
                'circle_type': item['circle_type'] ?? 'friend',
              })
          .toList();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load friend circles',
        originalError: e,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getHealthRecords({
    String? memberId,
    String? recordType,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      var url = '$baseUrl/health-records/';
      final queryParams = <String, String>{};
      if (memberId != null && memberId.isNotEmpty) {
        queryParams['family_member_id'] = memberId;
      }
      if (recordType != null && recordType.isNotEmpty) {
        queryParams['record_type'] = recordType;
      }
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
      }
      
      final response = await _handleRequest(
        () => http.get(Uri.parse(url), headers: headers),
      );
      
      final responseBody = jsonDecode(response.body);
      final data = responseBody['data'] ?? {};
      final List<dynamic> items = data['items'] ?? [];
      return items.cast<Map<String, dynamic>>();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load health records',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> createHealthRecord(
    Map<String, dynamic> recordData,
  ) async {
    if (recordData.isEmpty) {
      throw ApiException(
        message: 'Invalid health record data',
        statusCode: 400,
        detail: 'Health record data cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/health-records/'),
          headers: headers,
          body: jsonEncode(recordData),
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      return responseBody['data'] ?? responseBody;
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to create health record',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> updateHealthRecord(
    String recordId,
    Map<String, dynamic> recordData,
  ) async {
    if (recordId.isEmpty) {
      throw ApiException(
        message: 'Invalid health record ID',
        statusCode: 400,
        detail: 'Health record ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.put(
          Uri.parse('$baseUrl/health-records/$recordId'),
          headers: headers,
          body: jsonEncode(recordData),
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      return responseBody['data'] ?? responseBody;
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to update health record',
        originalError: e,
      );
    }
  }

  Future<void> deleteHealthRecord(String recordId) async {
    if (recordId.isEmpty) {
      throw ApiException(
        message: 'Invalid health record ID',
        statusCode: 400,
        detail: 'Health record ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      await _handleRequest(
        () => http.delete(
          Uri.parse('$baseUrl/health-records/$recordId'),
          headers: headers,
        ),
      );
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to delete health record',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> createVaccination(
    Map<String, dynamic> vaccinationData,
  ) async {
    if (vaccinationData.isEmpty) {
      throw ApiException(
        message: 'Invalid vaccination data',
        statusCode: 400,
        detail: 'Vaccination data cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/health-records/vaccinations'),
          headers: headers,
          body: jsonEncode(vaccinationData),
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      return responseBody['data'] ?? responseBody;
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to create vaccination',
        originalError: e,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getVaccinations() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/health-records/vaccinations'),
          headers: headers,
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      final data = responseBody['data'] ?? {};
      final List<dynamic> items = data['items'] ?? [];
      return items.cast<Map<String, dynamic>>();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load vaccinations',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> getMemberHealthSummary(String memberId) async {
    if (memberId.isEmpty) {
      throw ApiException(
        message: 'Invalid member ID',
        statusCode: 400,
        detail: 'Member ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/health-records/member/$memberId/summary'),
          headers: headers,
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      return responseBody['data'] ?? responseBody;
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load health summary',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> createReminder(
    Map<String, dynamic> reminderData,
  ) async {
    if (reminderData.isEmpty) {
      throw ApiException(
        message: 'Invalid reminder data',
        statusCode: 400,
        detail: 'Reminder data cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/health-records/reminders/'),
          headers: headers,
          body: jsonEncode(reminderData),
        ),
      );
      
      final responseData = jsonDecode(response.body);
      return responseData['data'] ?? responseData;
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to create reminder',
        originalError: e,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getReminders({
    String? recordId,
    String? assignedUserId,
    String? status,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      var url = '$baseUrl/health-records/reminders/';
      final queryParams = <String, String>{};
      if (recordId != null && recordId.isNotEmpty) {
        queryParams['record_id'] = recordId;
      }
      if (assignedUserId != null && assignedUserId.isNotEmpty) {
        queryParams['assigned_user_id'] = assignedUserId;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&')}';
      }
      
      final response = await _handleRequest(
        () => http.get(Uri.parse(url), headers: headers),
      );
      
      final responseData = jsonDecode(response.body);
      if (responseData is Map && responseData.containsKey('items')) {
        return List<Map<String, dynamic>>.from(responseData['items']);
      } else if (responseData is List) {
        return responseData.cast<Map<String, dynamic>>();
      }
      return [];
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load reminders',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> updateReminder(
    String reminderId,
    Map<String, dynamic> reminderData,
  ) async {
    if (reminderId.isEmpty) {
      throw ApiException(
        message: 'Invalid reminder ID',
        statusCode: 400,
        detail: 'Reminder ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.put(
          Uri.parse('$baseUrl/health-records/reminders/$reminderId'),
          headers: headers,
          body: jsonEncode(reminderData),
        ),
      );
      
      final responseData = jsonDecode(response.body);
      return responseData['data'] ?? responseData;
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to update reminder',
        originalError: e,
      );
    }
  }

  Future<void> deleteReminder(String reminderId) async {
    if (reminderId.isEmpty) {
      throw ApiException(
        message: 'Invalid reminder ID',
        statusCode: 400,
        detail: 'Reminder ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      await _handleRequest(
        () => http.delete(
          Uri.parse('$baseUrl/health-records/reminders/$reminderId'),
          headers: headers,
        ),
      );
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to delete reminder',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> snoozeReminder(
    String reminderId,
    DateTime snoozeUntil,
  ) async {
    if (reminderId.isEmpty) {
      throw ApiException(
        message: 'Invalid reminder ID',
        statusCode: 400,
        detail: 'Reminder ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/health-records/reminders/$reminderId/snooze'),
          headers: headers,
          body: jsonEncode({'snooze_until': snoozeUntil.toIso8601String()}),
        ),
      );
      
      final responseData = jsonDecode(response.body);
      return responseData['data'] ?? responseData;
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to snooze reminder',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> completeReminder(String reminderId) async {
    if (reminderId.isEmpty) {
      throw ApiException(
        message: 'Invalid reminder ID',
        statusCode: 400,
        detail: 'Reminder ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/health-records/reminders/$reminderId/complete'),
          headers: headers,
        ),
      );
      
      final responseData = jsonDecode(response.body);
      return responseData['data'] ?? responseData;
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to complete reminder',
        originalError: e,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getDocuments({
    String? documentType,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      var url = '$baseUrl/document-vault/';
      if (documentType != null && documentType.isNotEmpty) {
        url += '?document_type=${Uri.encodeComponent(documentType)}';
      }
      
      final response = await _handleRequest(
        () => http.get(Uri.parse(url), headers: headers),
      );
      
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load documents',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> createDocument(
    Map<String, dynamic> documentData,
  ) async {
    if (documentData.isEmpty) {
      throw ApiException(
        message: 'Invalid document data',
        statusCode: 400,
        detail: 'Document data cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/document-vault/'),
          headers: headers,
          body: jsonEncode(documentData),
        ),
      );
      
      return jsonDecode(response.body);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to create document',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> updateDocument(
    String documentId,
    Map<String, dynamic> documentData,
  ) async {
    if (documentId.isEmpty) {
      throw ApiException(
        message: 'Invalid document ID',
        statusCode: 400,
        detail: 'Document ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.put(
          Uri.parse('$baseUrl/document-vault/$documentId'),
          headers: headers,
          body: jsonEncode(documentData),
        ),
      );
      
      return jsonDecode(response.body);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to update document',
        originalError: e,
      );
    }
  }

  Future<void> deleteDocument(String documentId) async {
    if (documentId.isEmpty) {
      throw ApiException(
        message: 'Invalid document ID',
        statusCode: 400,
        detail: 'Document ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      await _handleRequest(
        () => http.delete(
          Uri.parse('$baseUrl/document-vault/$documentId'),
          headers: headers,
        ),
      );
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to delete document',
        originalError: e,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getDocumentAccessLog(
    String documentId,
  ) async {
    if (documentId.isEmpty) {
      throw ApiException(
        message: 'Invalid document ID',
        statusCode: 400,
        detail: 'Document ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/document-vault/$documentId/access-log'),
          headers: headers,
        ),
      );
      
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load access log',
        originalError: e,
      );
    }
  }

  Future<void> logDocumentAccess(
    String documentId,
    String action, {
    String? ipAddress,
  }) async {
    if (documentId.isEmpty || action.isEmpty) {
      throw ApiException(
        message: 'Invalid parameters',
        statusCode: 400,
        detail: 'Document ID and action cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final body = {'action': action};
      if (ipAddress != null && ipAddress.isNotEmpty) {
        body['ip_address'] = ipAddress;
      }
      
      await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/document-vault/$documentId/log-access'),
          headers: headers,
          body: jsonEncode(body),
        ),
      );
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to log access',
        originalError: e,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getInviteLinks({
    String? statusFilter,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      var url = '$baseUrl/genealogy/invite-links';
      if (statusFilter != null && statusFilter.isNotEmpty) {
        url += '?status_filter=${Uri.encodeComponent(statusFilter)}';
      }
      
      final response = await _handleRequest(
        () => http.get(Uri.parse(url), headers: headers),
      );
      
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load invite links',
        originalError: e,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getPersonTimeline(String personId) async {
    if (personId.isEmpty) {
      throw ApiException(
        message: 'Invalid person ID',
        statusCode: 400,
        detail: 'Person ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/genealogy/persons/$personId/timeline'),
          headers: headers,
        ),
      );
      
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load person timeline',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> createInviteLink(
    String personId,
    String email, {
    String? message,
    int expiresInDays = 7,
  }) async {
    if (personId.isEmpty || email.isEmpty) {
      throw ApiException(
        message: 'Invalid parameters',
        statusCode: 400,
        detail: 'Person ID and email cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final inviteData = {
        'person_id': personId,
        'email': email,
        if (message != null && message.isNotEmpty) 'message': message,
        'expires_in_days': expiresInDays,
      };
      
      final response = await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/genealogy/invite-links'),
          headers: headers,
          body: jsonEncode(inviteData),
        ),
      );
      
      return jsonDecode(response.body);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to create invite link',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> redeemInviteLink(String token) async {
    if (token.isEmpty) {
      throw ApiException(
        message: 'Invalid token',
        statusCode: 400,
        detail: 'Token cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/genealogy/join/$token'),
          headers: headers,
        ),
      );
      
      return jsonDecode(response.body);
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to redeem invite link',
        originalError: e,
      );
    }
  }

  Future<String> generateInviteLink() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/genealogy/generate-invite-link'),
          headers: headers,
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      return responseBody['invite_link'];
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to generate invite link',
        originalError: e,
      );
    }
  }

  Future<List<UserSearchResult>> searchFamilyCircleUsers(String query) async {
    if (query.isEmpty) {
      throw ApiException(
        message: 'Invalid search query',
        statusCode: 400,
        detail: 'Search query cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/users/search?query=${Uri.encodeComponent(query)}'),
          headers: headers,
        ),
      );
      
      final data = jsonDecode(response.body);
      final List<dynamic> items = data is List
          ? data
          : (data['data']?['results'] ?? data['results'] ?? []);
      return items.map((json) => UserSearchResult.fromJson(json)).toList();
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to search users',
        originalError: e,
      );
    }
  }

  Future<void> approveHealthRecord(String recordId) async {
    if (recordId.isEmpty) {
      throw ApiException(
        message: 'Invalid health record ID',
        statusCode: 400,
        detail: 'Health record ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      await _handleRequest(
        () => http.post(
          Uri.parse('$baseUrl/family/health-records/$recordId/approve'),
          headers: headers,
        ),
      );
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to approve health record',
        originalError: e,
      );
    }
  }

  Future<void> rejectHealthRecord(String recordId, String? reason) async {
    if (recordId.isEmpty) {
      throw ApiException(
        message: 'Invalid health record ID',
        statusCode: 400,
        detail: 'Health record ID cannot be empty',
      );
    }

    try {
      final headers = await _authService.getAuthHeaders();
      final url = reason != null && reason.isNotEmpty
          ? '$baseUrl/family/health-records/$recordId/reject?rejection_reason=${Uri.encodeComponent(reason)}'
          : '$baseUrl/family/health-records/$recordId/reject';
      
      await _handleRequest(
        () => http.post(Uri.parse(url), headers: headers),
      );
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to reject health record',
        originalError: e,
      );
    }
  }

  Future<Map<String, dynamic>> getHealthDashboard() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await _handleRequest(
        () => http.get(
          Uri.parse('$baseUrl/family/health-records/dashboard'),
          headers: headers,
        ),
      );
      
      final responseBody = jsonDecode(response.body);
      return responseBody['data'] ?? responseBody;
    } on ApiException {
      rethrow;
    } on AuthException {
      rethrow;
    } on NetworkException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        message: 'Failed to load health dashboard',
        originalError: e,
      );
    }
  }
}

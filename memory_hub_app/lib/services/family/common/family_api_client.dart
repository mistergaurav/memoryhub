import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../auth_service.dart';
import '../../../config/api_config.dart';
import 'family_exceptions.dart';

class FamilyApiClient {
  final AuthService _authService = AuthService();
  
  static const int _maxRetries = 3;
  static const Duration _requestTimeout = Duration(seconds: 30);
  static const Duration _initialRetryDelay = Duration(milliseconds: 500);
  
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _defaultCacheTTL = Duration(minutes: 5);

  String get _baseUrl => ApiConfig.baseUrl;

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
    } catch (_) {}

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

  String _getCacheKey(String method, String path, Map<String, String>? params) {
    final paramStr = params?.entries.map((e) => '${e.key}=${e.value}').join('&') ?? '';
    return '$method:$path?$paramStr';
  }

  bool _isCacheValid(String cacheKey, Duration? ttl) {
    if (!_cache.containsKey(cacheKey)) return false;
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;
    final cacheTTL = ttl ?? _defaultCacheTTL;
    return DateTime.now().difference(timestamp) < cacheTTL;
  }

  void _setCache(String cacheKey, dynamic data) {
    _cache[cacheKey] = data;
    _cacheTimestamps[cacheKey] = DateTime.now();
  }

  void invalidateCache([String? pattern]) {
    if (pattern == null) {
      _cache.clear();
      _cacheTimestamps.clear();
    } else {
      _cache.removeWhere((key, _) => key.contains(pattern));
      _cacheTimestamps.removeWhere((key, _) => key.contains(pattern));
    }
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? params,
    bool useCache = false,
    Duration? cacheTTL,
  }) async {
    final cacheKey = _getCacheKey('GET', path, params);
    
    if (useCache && _isCacheValid(cacheKey, cacheTTL)) {
      return _cache[cacheKey] as Map<String, dynamic>;
    }

    final headers = await _authService.getAuthHeaders();
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: params);
    
    final response = await _handleRequest(
      () => http.get(uri, headers: headers),
    );
    
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    
    if (useCache) {
      _setCache(cacheKey, data);
    }
    
    return data;
  }

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? params,
    bool invalidateCacheOnSuccess = true,
  }) async {
    final headers = await _authService.getAuthHeaders();
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: params);
    
    final response = await _handleRequest(
      () => http.post(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
    );
    
    if (invalidateCacheOnSuccess) {
      invalidateCache(path.split('/').first);
    }
    
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? params,
    bool invalidateCacheOnSuccess = true,
  }) async {
    final headers = await _authService.getAuthHeaders();
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: params);
    
    final response = await _handleRequest(
      () => http.put(
        uri,
        headers: headers,
        body: body != null ? jsonEncode(body) : null,
      ),
    );
    
    if (invalidateCacheOnSuccess) {
      invalidateCache(path.split('/').first);
    }
    
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<void> delete(
    String path, {
    Map<String, String>? params,
    bool invalidateCacheOnSuccess = true,
  }) async {
    final headers = await _authService.getAuthHeaders();
    final uri = Uri.parse('$_baseUrl$path').replace(queryParameters: params);
    
    await _handleRequest(
      () => http.delete(uri, headers: headers),
    );
    
    if (invalidateCacheOnSuccess) {
      invalidateCache(path.split('/').first);
    }
  }
}

class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic originalError;

  NetworkException({
    required this.message,
    this.statusCode,
    this.originalError,
  });

  @override
  String toString() {
    if (statusCode != null) {
      return 'NetworkException (HTTP $statusCode): $message';
    }
    return 'NetworkException: $message';
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final String? detail;
  final Map<String, dynamic>? errors;

  ApiException({
    required this.message,
    required this.statusCode,
    this.detail,
    this.errors,
  });

  @override
  String toString() {
    if (detail != null) {
      return 'ApiException (HTTP $statusCode): $message - $detail';
    }
    return 'ApiException (HTTP $statusCode): $message';
  }
}

class AuthException implements Exception {
  final String message;
  final bool requiresLogin;

  AuthException({
    required this.message,
    this.requiresLogin = true,
  });

  @override
  String toString() => 'AuthException: $message';
}

class ApiConfig {
  static String get baseUrl {
    // For web builds, use relative URL to work with the backend serving the Flutter app
    // For mobile/desktop, use environment variable or default
    const String? envUrl = String.fromEnvironment('API_URL', defaultValue: '');
    
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    
    // Default for web when served by the same backend
    return '/api/v1';
  }
  
  static String get fullBaseUrl {
    const String? envUrl = String.fromEnvironment('API_URL', defaultValue: '');
    
    if (envUrl.isNotEmpty) {
      return envUrl;
    }
    
    // For local development
    return 'http://localhost:5000/api/v1';
  }
}

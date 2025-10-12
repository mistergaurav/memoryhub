import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

class ApiConfig {
  // Environment configuration
  // For Windows local development, use: localhost:8000
  // For Replit deployment, use the Replit URL
  // For mobile builds, set API_URL environment variable
  
  static const String _replitApiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:8000',
  );
  
  static const String _localApiUrl = 'http://localhost:8000';
  
  // Set this to true when running locally on Windows
  static const bool _useLocalhost = String.fromEnvironment('USE_LOCALHOST', defaultValue: 'true') == 'true';
  
  static String get _apiUrl {
    // Priority: Environment variable > Local setting > Replit default
    if (_useLocalhost && !kIsWeb) {
      return _localApiUrl;
    }
    return _replitApiUrl;
  }
  
  static String get baseUrl {
    if (kIsWeb) {
      // For web builds, use relative path (proxied by backend)
      return '/api/v1';
    } else {
      return '$_apiUrl/api/v1';
    }
  }
  
  static String get wsBaseUrl {
    if (kIsWeb) {
      final wsProtocol = Uri.base.scheme == 'https' ? 'wss' : 'ws';
      return '$wsProtocol://${Uri.base.authority}/ws';
    } else {
      final apiUri = Uri.parse(_apiUrl);
      final wsProtocol = apiUri.scheme == 'https' ? 'wss' : 'ws';
      return '$wsProtocol://${apiUri.authority}/ws';
    }
  }
  
  static String getAssetUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    
    if (kIsWeb) {
      return path;
    } else {
      return '$_apiUrl$path';
    }
  }
  
  // Helper method to check which environment is being used
  static String get currentEnvironment {
    if (kIsWeb) return 'Web (Proxied)';
    if (_useLocalhost) return 'Local Windows ($_localApiUrl)';
    return 'Replit ($_replitApiUrl)';
  }
}

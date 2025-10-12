import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Backend runs on port 8000 in Replit
  static const String _backendPort = '8000';
  
  static String get baseUrl {
    if (kIsWeb) {
      // For web builds, detect the current host and use port 8000 for backend
      // In Replit, we'll use the same domain but port 8000
      // In local dev, it will use localhost:8000
      return 'http://localhost:8000/api/v1';
    } else {
      // For mobile/desktop builds
      return 'http://localhost:8000/api/v1';
    }
  }
  
  static String get wsBaseUrl {
    if (kIsWeb) {
      return 'ws://localhost:8000/ws';
    } else {
      return 'ws://localhost:8000/ws';
    }
  }
  
  static String getAssetUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    
    if (kIsWeb) {
      // For web, use localhost:8000 for assets
      return 'http://localhost:8000$path';
    } else {
      return 'http://localhost:8000$path';
    }
  }
  
  // Helper method to check which environment is being used
  static String get currentEnvironment {
    return 'Backend: localhost:8000';
  }
}

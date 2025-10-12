import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static const String _replitDomain = 'https://f1f703b2-5ae2-4384-84cb-cc0d43774e0d-00-1xb1vbt5sy6oi.janeway.replit.dev';
  
  static String get baseUrl {
    if (kIsWeb) {
      return '/api/v1';
    } else {
      return '$_replitDomain/api/v1';
    }
  }
  
  static String get wsBaseUrl {
    if (kIsWeb) {
      return 'wss://f1f703b2-5ae2-4384-84cb-cc0d43774e0d-00-1xb1vbt5sy6oi.janeway.replit.dev/ws';
    } else {
      return 'wss://f1f703b2-5ae2-4384-84cb-cc0d43774e0d-00-1xb1vbt5sy6oi.janeway.replit.dev/ws';
    }
  }
  
  static String getAssetUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    
    if (kIsWeb) {
      return path;
    } else {
      return '$_replitDomain$path';
    }
  }
}

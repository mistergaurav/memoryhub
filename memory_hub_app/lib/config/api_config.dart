import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  static const String _replitDomain = 'https://14535a8b-db67-4f4d-9926-05522d0ee98c-00-lc0syjpx9rpz.spock.replit.dev';
  
  static String get baseUrl {
    if (kIsWeb) {
      return '/api/v1';
    } else {
      return '$_replitDomain/api/v1';
    }
  }
  
  static String get wsBaseUrl {
    if (kIsWeb) {
      final wsProtocol = Uri.base.scheme == 'https' ? 'wss' : 'ws';
      return '$wsProtocol://${Uri.base.host}/ws';
    } else {
      return 'wss://14535a8b-db67-4f4d-9926-05522d0ee98c-00-lc0syjpx9rpz.spock.replit.dev/ws';
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

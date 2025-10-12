import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Get the base URL dynamically based on the platform
  static String get baseUrl {
    if (kIsWeb) {
      // For web builds, derive the backend URL from the current location
      return _getWebBackendUrl();
    } else {
      // For mobile/desktop builds, use localhost
      return 'http://localhost:8000/api/v1';
    }
  }
  
  static String get wsBaseUrl {
    if (kIsWeb) {
      return _getWebBackendWsUrl();
    } else {
      return 'ws://localhost:8000/ws';
    }
  }
  
  static String getAssetUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    
    if (kIsWeb) {
      final backendBase = _getWebBackendBase();
      return '$backendBase$path';
    } else {
      return 'http://localhost:8000$path';
    }
  }
  
  // Get backend URL for web platform
  static String _getWebBackendUrl() {
    try {
      final location = _getWindowLocation();
      final hostname = location['hostname'] as String;
      final protocol = location['protocol'] as String;
      
      // Check if running on Replit
      if (hostname.contains('replit.dev') || hostname.contains('.repl.co')) {
        String backendHostname;
        if (hostname.startsWith('5000-')) {
          // Port-prefixed hostname: replace 5000- with 8000-
          backendHostname = hostname.replaceFirst('5000-', '8000-');
        } else {
          // Non-port-prefixed hostname: prepend 8000-
          backendHostname = '8000-$hostname';
        }
        return '$protocol//$backendHostname/api/v1';
      } else if (hostname == 'localhost' || hostname == '127.0.0.1') {
        // Local development
        return 'http://localhost:8000/api/v1';
      } else {
        // Generic fallback - try same host with port 8000
        return '$protocol//$hostname:8000/api/v1';
      }
    } catch (e) {
      // Fallback to localhost if we can't access window.location
      return 'http://localhost:8000/api/v1';
    }
  }
  
  static String _getWebBackendWsUrl() {
    try {
      final location = _getWindowLocation();
      final hostname = location['hostname'] as String;
      final isSecure = (location['protocol'] as String) == 'https:';
      final wsProtocol = isSecure ? 'wss' : 'ws';
      
      if (hostname.contains('replit.dev') || hostname.contains('.repl.co')) {
        String backendHostname;
        if (hostname.startsWith('5000-')) {
          backendHostname = hostname.replaceFirst('5000-', '8000-');
        } else {
          backendHostname = '8000-$hostname';
        }
        return '$wsProtocol://$backendHostname/ws';
      } else if (hostname == 'localhost' || hostname == '127.0.0.1') {
        return 'ws://localhost:8000/ws';
      } else {
        return '$wsProtocol://$hostname:8000/ws';
      }
    } catch (e) {
      return 'ws://localhost:8000/ws';
    }
  }
  
  static String _getWebBackendBase() {
    try {
      final location = _getWindowLocation();
      final hostname = location['hostname'] as String;
      final protocol = location['protocol'] as String;
      
      if (hostname.contains('replit.dev') || hostname.contains('.repl.co')) {
        String backendHostname;
        if (hostname.startsWith('5000-')) {
          backendHostname = hostname.replaceFirst('5000-', '8000-');
        } else {
          backendHostname = '8000-$hostname';
        }
        return '$protocol//$backendHostname';
      } else if (hostname == 'localhost' || hostname == '127.0.0.1') {
        return 'http://localhost:8000';
      } else {
        return '$protocol//$hostname:8000';
      }
    } catch (e) {
      return 'http://localhost:8000';
    }
  }
  
  // Access window.location using dart:js to avoid dart:html issues
  static Map<String, String> _getWindowLocation() {
    if (!kIsWeb) {
      return {'hostname': 'localhost', 'protocol': 'http:'};
    }
    
    try {
      // Use Uri.base to access browser location without importing dart:html
      final uri = Uri.base;
      return {
        'hostname': uri.host.isNotEmpty ? uri.host : 'localhost',
        'protocol': uri.scheme.isNotEmpty ? '${uri.scheme}:' : 'http:',
      };
    } catch (e) {
      return {'hostname': 'localhost', 'protocol': 'http:'};
    }
  }
  
  // Helper method to check which environment is being used
  static String get currentEnvironment {
    if (kIsWeb) {
      try {
        final location = _getWindowLocation();
        final hostname = location['hostname'] as String;
        if (hostname.contains('replit.dev') || hostname.contains('.repl.co')) {
          final backendHostname = hostname.replaceFirst(RegExp(r'^[^-]+-'), '8000-').replaceFirst('5000-', '8000-');
          return 'Replit Web ($backendHostname)';
        } else if (hostname == 'localhost') {
          return 'Local Web (localhost:8000)';
        } else {
          return 'Web ($hostname:8000)';
        }
      } catch (e) {
        return 'Web (localhost:8000)';
      }
    }
    return 'Native (localhost:8000)';
  }
}

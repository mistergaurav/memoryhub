import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // Environment variables for custom backend URLs (useful for desktop builds)
  static const String _envBackendUrl = String.fromEnvironment('BACKEND_URL', defaultValue: '');
  static const String _envBackendWsUrl = String.fromEnvironment('BACKEND_WS_URL', defaultValue: '');
  
  // Default backend URL for Replit deployment
  // Set this to your Replit backend URL for Windows builds
  // Example: flutter build windows --dart-define=DEFAULT_BACKEND=https://8000-yourapp.replit.dev
  static const String _defaultReplitBackend = String.fromEnvironment('DEFAULT_BACKEND', defaultValue: '');
  
  // Helper to normalize backend URL (remove trailing slashes)
  static String _normalizeUrl(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
  
  // Get the base URL dynamically based on the platform and environment
  static String get baseUrl {
    // 1. Check for environment variable override (highest priority)
    if (_envBackendUrl.isNotEmpty) {
      final normalized = _normalizeUrl(_envBackendUrl);
      return normalized.endsWith('/api/v1') 
          ? normalized 
          : '$normalized/api/v1';
    }
    
    if (kIsWeb) {
      // 2. For web builds, derive the backend URL from the current location
      return _getWebBackendUrl();
    } else {
      // 3. For mobile/desktop builds
      if (_defaultReplitBackend.isNotEmpty) {
        // Use the default Replit backend if configured
        final normalized = _normalizeUrl(_defaultReplitBackend);
        return normalized.endsWith('/api/v1')
            ? normalized
            : '$normalized/api/v1';
      }
      // Fallback to localhost for local development
      // WARNING: This will only work if backend is running locally!
      // For production builds, always set BACKEND_URL or DEFAULT_BACKEND
      return 'http://localhost:5000/api/v1';
    }
  }
  
  static String get wsBaseUrl {
    // Check for environment variable override
    if (_envBackendWsUrl.isNotEmpty) {
      return _normalizeUrl(_envBackendWsUrl);
    }
    
    if (kIsWeb) {
      return _getWebBackendWsUrl();
    } else {
      // For native builds, derive WebSocket URL from base URL
      final base = baseUrl.replaceAll('/api/v1', '');
      if (base.startsWith('https://')) {
        return '${base.replaceFirst('https://', 'wss://')}/api/v1/ws';
      } else {
        return '${base.replaceFirst('http://', 'ws://')}/api/v1/ws';
      }
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
      // For native builds, use the base URL without /api/v1
      final base = baseUrl.replaceAll('/api/v1', '');
      return '$base$path';
    }
  }
  
  // Get backend URL for web platform
  static String _getWebBackendUrl() {
    try {
      final location = _getWindowLocation();
      final hostname = location['hostname'] as String;
      final protocol = location['protocol'] as String;
      
      // Check if running on Replit or same-origin
      if (hostname.contains('replit.dev') || hostname.contains('.repl.co')) {
        // Frontend and backend are served from the same server on port 5000
        // Use relative URL which will hit the same server
        return '/api/v1';
      } else if (hostname == 'localhost' || hostname == '127.0.0.1') {
        // Local development - backend on port 5000
        return 'http://localhost:5000/api/v1';
      } else {
        // Generic fallback - same host (relative URL)
        return '/api/v1';
      }
    } catch (e) {
      // Fallback to relative URL
      return '/api/v1';
    }
  }
  
  static String _getWebBackendWsUrl() {
    try {
      final location = _getWindowLocation();
      final hostname = location['hostname'] as String;
      final isSecure = (location['protocol'] as String) == 'https:';
      final wsProtocol = isSecure ? 'wss' : 'ws';
      
      if (hostname.contains('replit.dev') || hostname.contains('.repl.co')) {
        // Frontend and backend on same server - use same hostname
        return '$wsProtocol://$hostname/api/v1/ws';
      } else if (hostname == 'localhost' || hostname == '127.0.0.1') {
        return 'ws://localhost:5000/api/v1/ws';
      } else {
        return '$wsProtocol://$hostname/api/v1/ws';
      }
    } catch (e) {
      return 'ws://localhost:5000/api/v1/ws';
    }
  }
  
  static String _getWebBackendBase() {
    try {
      final location = _getWindowLocation();
      final hostname = location['hostname'] as String;
      final protocol = location['protocol'] as String;
      
      if (hostname.contains('replit.dev') || hostname.contains('.repl.co')) {
        // Frontend and backend on same server - use same hostname
        return '$protocol//$hostname';
      } else if (hostname == 'localhost' || hostname == '127.0.0.1') {
        return 'http://localhost:5000';
      } else {
        return '$protocol//$hostname';
      }
    } catch (e) {
      return '';
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
    if (_envBackendUrl.isNotEmpty) {
      return 'Custom Backend ($_envBackendUrl)';
    }
    
    if (kIsWeb) {
      try {
        final location = _getWindowLocation();
        final hostname = location['hostname'] as String;
        if (hostname.contains('replit.dev') || hostname.contains('.repl.co')) {
          final backendUrl = _getWebBackendUrl();
          return 'Replit Web ($backendUrl)';
        } else if (hostname == 'localhost') {
          return 'Local Web (localhost:5000)';
        } else {
          return 'Web ($hostname:5000)';
        }
      } catch (e) {
        return 'Web (localhost:5000)';
      }
    }
    
    if (_defaultReplitBackend.isNotEmpty) {
      return 'Native Desktop ($_defaultReplitBackend)';
    }
    
    // For native platforms, we can't use Platform.operatingSystem without dart:io
    // So we just return a generic message
    return 'Native (localhost:5000 - Set BACKEND_URL for remote server!)';
  }
  
  // Helper to get platform-specific info for debugging
  static Map<String, String> get debugInfo {
    return {
      'platform': kIsWeb ? 'web' : 'native',
      'baseUrl': baseUrl,
      'wsBaseUrl': wsBaseUrl,
      'environment': currentEnvironment,
      'envBackendUrl': _envBackendUrl,
      'envWsUrl': _envBackendWsUrl,
      'defaultBackend': _defaultReplitBackend,
    };
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/notification.dart';
import '../services/notifications_service.dart';
import '../services/websocket_service.dart';

class NotificationsProvider with ChangeNotifier {
  final NotificationsService _notificationsService = NotificationsService();
  final WebSocketService _wsService = WebSocketService();

  List<Notification> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;

  StreamSubscription<WebSocketEvent>? _wsEventSubscription;
  StreamSubscription<WebSocketConnectionState>? _wsStateSubscription;
  WebSocketConnectionState _wsConnectionState = WebSocketConnectionState.disconnected;

  List<Notification> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  WebSocketConnectionState get wsConnectionState => _wsConnectionState;
  bool get isConnected => _wsConnectionState == WebSocketConnectionState.connected;

  Map<String, bool> _settings = {};
  bool _settingsLoading = false;

  Map<String, bool> get settings => _settings;
  bool get settingsLoading => _settingsLoading;

  NotificationsProvider() {
    _initializeWebSocket();
    loadNotifications();
    loadSettings();
  }

  // ... existing methods ...

  Future<void> loadSettings() async {
    try {
      _settingsLoading = true;
      notifyListeners();

      final settings = await _notificationsService.getNotificationSettings();
      _settings = Map<String, bool>.from(settings);
      
      _settingsLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notification settings: $e');
      _settingsLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateSettings(Map<String, bool> newSettings) async {
    try {
      // Optimistic update
      final oldSettings = Map<String, bool>.from(_settings);
      _settings = newSettings;
      notifyListeners();

      try {
        final updated = await _notificationsService.updateNotificationSettings(newSettings);
        _settings = Map<String, bool>.from(updated);
      } catch (e) {
        // Revert on error
        _settings = oldSettings;
        debugPrint('Error updating notification settings: $e');
        rethrow;
      }
      
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _wsEventSubscription?.cancel();
    _wsStateSubscription?.cancel();
    _wsService.disconnect();
    super.dispose();
  }
}

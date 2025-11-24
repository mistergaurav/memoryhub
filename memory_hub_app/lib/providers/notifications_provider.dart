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

  void _initializeWebSocket() {
    // Listen to connection state changes
    _wsStateSubscription = _wsService.connectionState.listen((state) {
      _wsConnectionState = state;
      notifyListeners();
    });

    // Listen to incoming events
    _wsEventSubscription = _wsService.events.listen((event) {
      if (event.type == 'notification_new') {
        _handleNewNotification(event.data);
      } else if (event.type == 'notifications_read') {
        _handleNotificationsRead(event.data);
      }
    });

    // Connect to WebSocket
    _wsService.connect();
  }

  void _handleNewNotification(Map<String, dynamic> data) {
    try {
      final notification = Notification.fromJson(data);
      _notifications.insert(0, notification);
      _unreadCount++;
      notifyListeners();
    } catch (e) {
      debugPrint('Error parsing real-time notification: $e');
    }
  }

  void _handleNotificationsRead(Map<String, dynamic> data) {
    // Handle remote read status updates if necessary
    // For now, we usually handle this optimistically in markAsRead
  }

  Future<void> loadNotifications({bool refresh = false}) async {
    if (_isLoading) return;
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _notifications.clear();
    }

    if (!_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _notificationsService.getNotifications(
        page: _currentPage,
        limit: 20,
      );

      // The API returns: { status, message, data: { notifications: [], total, unread_count, page, pages } }
      final dataObject = response['data'] as Map<String, dynamic>?;
      if (dataObject == null) {
        throw Exception('Invalid API response: missing data object');
      }

      final List<dynamic> items = dataObject['notifications'] ?? [];
      final newNotifications = items.map((item) => Notification.fromJson(item)).toList();

      if (refresh) {
        _notifications = newNotifications;
      } else {
        _notifications.addAll(newNotifications);
      }

      // Extract metadata from data object
      final total = dataObject['total'] as int?  ?? 0;
      final unreadCount = dataObject['unread_count'] as int? ?? _unreadCount;
      final currentPage = dataObject['page'] as int? ?? _currentPage;
      final totalPages = dataObject['pages'] as int? ?? 1;

      _unreadCount = unreadCount;
      _hasMore = currentPage < totalPages;

      if (newNotifications.isNotEmpty) {
        _currentPage++;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    await loadNotifications();
  }

  Future<void> refresh() async {
    await loadNotifications(refresh: true);
    // Also refresh settings when pulling to refresh
    await loadSettings();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      // Optimistic update
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        if (_unreadCount > 0) _unreadCount--;
        notifyListeners();
      }

      await _notificationsService.markAsRead(notificationId);
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      // Revert optimistic update if needed, though usually not critical for read status
      // We could reload notifications to sync state
    }
  }

  Future<void> markAllAsRead() async {
    try {
      // Optimistic update
      bool needsUpdate = false;
      for (var i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
          needsUpdate = true;
        }
      }
      
      if (needsUpdate) {
        _unreadCount = 0;
        notifyListeners();
      }

      await _notificationsService.markAllAsRead();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      // On error, we might want to refresh to ensure correct state
      await refresh();
    }
  }

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
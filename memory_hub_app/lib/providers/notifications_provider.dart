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

  NotificationsProvider() {
    _initializeWebSocket();
    loadNotifications();
  }

  void _initializeWebSocket() {
    _wsStateSubscription = _wsService.connectionState.listen((state) {
      _wsConnectionState = state;
      notifyListeners();
    });

    _wsEventSubscription = _wsService.events.listen(_handleWebSocketEvent);

    _wsService.connect();
  }

  void _handleWebSocketEvent(WebSocketEvent event) {
    switch (event.type) {
      case 'notification.created':
      case 'notification_created':
        _handleNotificationCreated(event.data);
        break;
      case 'notification.updated':
      case 'notification_updated':
        _handleNotificationUpdated(event.data);
        break;
      case 'health_record.status_changed':
      case 'health_record_status_changed':
        _handleHealthRecordStatusChanged(event.data);
        break;
      case 'health_record.assigned':
      case 'health_record_assigned':
        _handleHealthRecordAssigned(event.data);
        break;
      case 'health_record.approved':
      case 'health_record_approved':
        _handleHealthRecordApproved(event.data);
        break;
      case 'health_record.rejected':
      case 'health_record_rejected':
        _handleHealthRecordRejected(event.data);
        break;
      case 'connection.established':
      case 'connection.acknowledged':
        debugPrint('WebSocket connected successfully');
        break;
      case 'error':
        debugPrint('WebSocket error: ${event.data['message']}');
        break;
    }
  }

  void _handleNotificationCreated(Map<String, dynamic> data) {
    try {
      final notification = Notification.fromJson(data['notification'] ?? data);
      
      _notifications.insert(0, notification);
      if (!notification.isRead) {
        _unreadCount++;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error handling notification created: $e');
    }
  }

  void _handleNotificationUpdated(Map<String, dynamic> data) {
    try {
      final updatedNotification = Notification.fromJson(data['notification'] ?? data);
      final index = _notifications.indexWhere((n) => n.id == updatedNotification.id);
      
      if (index != -1) {
        final oldNotification = _notifications[index];
        _notifications[index] = updatedNotification;
        
        if (oldNotification.isRead != updatedNotification.isRead) {
          _unreadCount += updatedNotification.isRead ? -1 : 1;
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error handling notification updated: $e');
    }
  }

  void _handleHealthRecordStatusChanged(Map<String, dynamic> data) {
    try {
      final recordId = data['health_record_id'] ?? data['record_id'];
      final status = data['status'] ?? data['approval_status'];
      
      for (var i = 0; i < _notifications.length; i++) {
        final notification = _notifications[i];
        if ((notification.targetType == 'health_record' && notification.targetId == recordId) ||
            (notification.type == NotificationType.healthRecordAssignment && notification.targetId == recordId)) {
          
          final metadata = Map<String, dynamic>.from(notification.toJson());
          metadata['approval_status'] = status;
          metadata['metadata'] = {
            ...?notification.toJson()['metadata'],
            'approval_status': status,
          };
          
          notifyListeners();
          break;
        }
      }
    } catch (e) {
      debugPrint('Error handling health record status changed: $e');
    }
  }

  void _handleHealthRecordAssigned(Map<String, dynamic> data) {
    loadNotifications(refresh: true);
  }

  void _handleHealthRecordApproved(Map<String, dynamic> data) {
    _handleHealthRecordStatusChanged({
      ...data,
      'status': 'approved',
      'approval_status': 'approved',
    });
  }

  void _handleHealthRecordRejected(Map<String, dynamic> data) {
    _handleHealthRecordStatusChanged({
      ...data,
      'status': 'rejected',
      'approval_status': 'rejected',
    });
  }

  Future<void> loadNotifications({int page = 1, bool refresh = false}) async {
    if (_isLoading && !refresh) return;

    try {
      if (refresh) {
        _currentPage = 1;
        _hasMore = true;
      }
      
      _isLoading = true;
      _error = null;
      notifyListeners();

      final data = await _notificationsService.getNotifications(
        page: refresh ? 1 : page,
        limit: 20,
      );

      final List<dynamic> notificationsList = data['notifications'] ?? [];
      final notifications = notificationsList
          .map((json) => Notification.fromJson(json))
          .toList();

      if (refresh || page == 1) {
        _notifications = notifications;
      } else {
        _notifications.addAll(notifications);
      }

      _unreadCount = data['unread_count'] ?? 0;
      _currentPage = page;
      _hasMore = notifications.length >= 20;

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationsService.markAsRead(notificationId);

      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _notificationsService.markAllAsRead();

      _notifications = _notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  Future<void> loadMore() async {
    if (_hasMore && !_isLoading) {
      await loadNotifications(page: _currentPage + 1);
    }
  }

  Future<void> refresh() async {
    await loadNotifications(refresh: true);
  }

  void reconnectWebSocket() {
    _wsService.disconnect();
    _wsService.connect();
  }

  @override
  void dispose() {
    _wsEventSubscription?.cancel();
    _wsStateSubscription?.cancel();
    _wsService.disconnect();
    super.dispose();
  }
}

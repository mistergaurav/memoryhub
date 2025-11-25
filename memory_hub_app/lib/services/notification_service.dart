import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging? _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Firebase
      // We try to initialize it, but if it fails (e.g. no config), we catch it
      // so the app doesn't crash completely
      try {
        await Firebase.initializeApp();
        _firebaseMessaging = FirebaseMessaging.instance;
      } catch (e) {
        debugPrint('Warning: Firebase initialization failed: $e');
        debugPrint('Push notifications will not be available.');
        return;
      }

      if (_firebaseMessaging == null) return;

      // Request permissions
      await _requestPermissions();

      // Initialize Local Notifications
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
      );

      // Foreground handler
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Get Token
      try {
        final token = await _firebaseMessaging!.getToken();
        debugPrint('FCM Token: $token');
        // TODO: Send token to backend
      } catch (e) {
        debugPrint('Error getting FCM token: $e');
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  Future<void> _requestPermissions() async {
    if (_firebaseMessaging == null) return;
    
    try {
      await _firebaseMessaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');
      
      // Show local notification
      await _showLocalNotification(
        id: message.hashCode,
        title: message.notification?.title ?? 'Notification',
        body: message.notification?.body ?? '',
        payload: message.data['type'],
      );
    }
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);
    
    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap
    debugPrint('Notification tapped with payload: ${response.payload}');
    // Navigate based on payload
  }
}

// Top-level function for background handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint("Handling a background message: ${message.messageId}");
}

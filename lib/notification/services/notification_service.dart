import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('>>> Background message received: ${message.messageId}');
  debugPrint('>>> Title: ${message.notification?.title}');
  debugPrint('>>> Body: ${message.notification?.body}');
  debugPrint('>>> Data: ${message.data}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  late final FlutterLocalNotificationsPlugin _localNotifications;
  late final FirebaseMessaging _firebaseMessaging;
  final GetStorage _storage = GetStorage();

  String? _currentFCMToken;
  bool _isInitialized = false;

  NotificationService._internal() {
    _localNotifications = FlutterLocalNotificationsPlugin();
    _firebaseMessaging = FirebaseMessaging.instance;
  }

  /// Get current FCM token
  String? get fcmToken => _currentFCMToken;

  /// Check if notifications are initialized
  bool get isInitialized => _isInitialized;

  Future<void> initializeNotifications() async {
    try {
      print('>>> ============================================');
      print('>>> INITIALIZING NOTIFICATION SERVICE');
      print('>>> ============================================');

      // Only initialize FCM on mobile platforms
      if (!kIsWeb) {
        print('>>> Platform: Mobile - Initializing FCM');
        await _initializeFCM();
      } else {
        print('>>> Platform: Web - Skipping FCM initialization');
        print('>>> Web users will only see in-app notifications');
      }

      // Initialize local notifications (works on both mobile and web)
      await _initializeLocalNotifications();

      _isInitialized = true;
      print('>>> Notification service initialized successfully');
      print('>>> ============================================');
    } catch (e) {
      print('>>> ERROR initializing notifications: $e');
      print('>>> ============================================');
    }
  }

  Future<void> _initializeFCM() async {
    try {
      // Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request permissions (iOS)
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      print('>>> FCM Permission status: ${settings.authorizationStatus}');

      if (settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional) {
        // Get FCM token
        _currentFCMToken = await _firebaseMessaging.getToken();
        print('>>> FCM Token obtained: ${_currentFCMToken?.substring(0, 20)}...');

        // Store token locally
        if (_currentFCMToken != null) {
          _storage.write('fcm_token', _currentFCMToken);
        }

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          print('>>> FCM Token refreshed');
          _currentFCMToken = newToken;
          _storage.write('fcm_token', newToken);
          // TODO: Update token in Appwrite when user is logged in
        });

        // Set up message handlers
        _setupMessageHandlers();
      } else {
        print('>>> FCM Permission denied by user');
      }
    } catch (e) {
      print('>>> Error initializing FCM: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
      onDidReceiveNotificationResponse: _handleNotificationTap,
    );

    print('>>> Local notifications initialized');
  }

  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTapFromBackground);

    // Check for initial notification (app opened from terminated state)
    _checkInitialMessage();
  }

  Future<void> _checkInitialMessage() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('>>> App opened from terminated state via notification');
      _handleNotificationData(initialMessage.data);
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    print('>>> Notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      // Parse payload and navigate
      try {
        // Payload format: "type:value" (e.g., "appointment:abc123")
        final parts = response.payload!.split(':');
        if (parts.length >= 2) {
          final type = parts[0];
          final id = parts[1];
          _navigateToScreen(type, id);
        }
      } catch (e) {
        print('>>> Error parsing notification payload: $e');
      }
    }
  }

  void _handleNotificationTapFromBackground(RemoteMessage message) {
    print('>>> Background notification tapped');
    _handleNotificationData(message.data);
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('>>> ============================================');
    print('>>> FOREGROUND MESSAGE RECEIVED');
    print('>>> Title: ${message.notification?.title}');
    print('>>> Body: ${message.notification?.body}');
    print('>>> Data: ${message.data}');
    print('>>> ============================================');

    // Show local notification when app is in foreground
    await _showLocalNotification(
      title: message.notification?.title ?? 'PAWrtal',
      body: message.notification?.body ?? 'You have a new notification',
      payload: _createPayloadFromData(message.data),
      data: message.data,
    );
  }

  String _createPayloadFromData(Map<String, dynamic> data) {
    // Create simple payload format: "type:id"
    final type = data['type'] ?? 'unknown';
    final id = data['appointmentId'] ?? data['messageId'] ?? '';
    return '$type:$id';
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    Map<String, dynamic>? data,
  }) async {
    // Determine notification importance based on type
    var importance = Importance.high;
    var priority = Priority.high;

    if (data != null) {
      final type = data['type'];
      if (type == 'new_appointment' || type == 'appointment') {
        importance = Importance.max;
        priority = Priority.max;
      }
    }

    final androidDetails = AndroidNotificationDetails(
      'pawrtal_channel',
      'PAWrtal Notifications',
      channelDescription: 'Notifications for appointments and messages',
      importance: importance,
      priority: priority,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: payload,
    );

    print('>>> Local notification displayed');
  }

  void _handleNotificationData(Map<String, dynamic> data) {
    print('>>> Handling notification data: $data');
    
    final type = data['type'];
    
    if (type == 'appointment' || type == 'new_appointment') {
      final appointmentId = data['appointmentId'];
      if (appointmentId != null) {
        _navigateToScreen('appointment', appointmentId);
      }
    } else if (type == 'message') {
      final conversationId = data['conversationId'];
      if (conversationId != null) {
        _navigateToScreen('message', conversationId);
      }
    }
  }

  void _navigateToScreen(String type, String id) {
    print('>>> Navigating to: $type with ID: $id');
    
    // Use GetX navigation
    switch (type) {
      case 'appointment':
      case 'new_appointment':
        // Navigate to appointments screen
        // Get.toNamed('/appointments', arguments: {'appointmentId': id});
        print('>>> TODO: Navigate to appointment: $id');
        break;
      case 'message':
        // Navigate to messages screen
        // Get.toNamed('/messages', arguments: {'conversationId': id});
        print('>>> TODO: Navigate to message: $id');
        break;
      default:
        print('>>> Unknown notification type: $type');
    }
  }

  /// Request notification permissions (call after login)
  Future<bool> requestPermissions() async {
    if (kIsWeb) {
      print('>>> Web platform: No FCM permissions needed');
      return true;
    }

    try {
      final settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      print('>>> Permission status: ${settings.authorizationStatus}');
      
      return settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
    } catch (e) {
      print('>>> Error requesting permissions: $e');
      return false;
    }
  }

  /// Get fresh FCM token (call after login)
  Future<String?> getFreshToken() async {
    if (kIsWeb) {
      print('>>> Web platform: No FCM token available');
      return null;
    }

    try {
      _currentFCMToken = await _firebaseMessaging.getToken();
      if (_currentFCMToken != null) {
        _storage.write('fcm_token', _currentFCMToken);
      }
      return _currentFCMToken;
    } catch (e) {
      print('>>> Error getting FCM token: $e');
      return null;
    }
  }

  /// Clear notification token (call on logout)
  Future<void> clearToken() async {
    try {
      if (!kIsWeb) {
        await _firebaseMessaging.deleteToken();
      }
      _currentFCMToken = null;
      _storage.remove('fcm_token');
      print('>>> FCM token cleared');
    } catch (e) {
      print('>>> Error clearing token: $e');
    }
  }

  /// Manual notification for testing
  Future<void> showTestNotification() async {
    await _showLocalNotification(
      title: 'Test Notification',
      body: 'This is a test notification from PAWrtal',
      payload: 'test:123',
    );
  }
}
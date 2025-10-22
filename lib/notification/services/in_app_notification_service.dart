import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/models/notification_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class InAppNotificationService extends GetxService {
  final AuthRepository authRepository;
  final UserSessionService session;

  InAppNotificationService({
    required this.authRepository,
    required this.session,
  });

  // Observable variables
  var notifications = <AppNotification>[].obs;
  var unreadCount = 0.obs;
  var isLoading = false.obs;

  // Track current user to detect account changes
  String _currentUserId = '';

  // Track processed notification IDs to prevent duplicates
  final Set<String> _processedNotificationIds = {};

  // Real-time subscription
  StreamSubscription<RealtimeMessage>? _notificationSubscription;

  @override
  void onInit() {
    super.onInit();
    initialize();
    // Don't auto-initialize - wait for explicit call
  }

  @override
  void onClose() {
    _notificationSubscription?.cancel();
    _processedNotificationIds.clear();
    super.onClose();
  }

  /// Initialize or reinitialize the service for current user
  /// Call this after login or when switching accounts
  Future<void> initialize() async {
    try {
      final userId = session.userId;

      if (userId.isEmpty) {
        print('>>> No user logged in, skipping notification initialization');
        _clearService();
        return;
      }

      // If user changed, clear everything and reinitialize
      if (_currentUserId != userId) {
        print(
            '>>> User changed from $_currentUserId to $userId, reinitializing...');
        _clearService();
        _currentUserId = userId;
      }

      print('>>> Initializing notification service for user: $userId');

      // Load initial notifications
      await fetchNotifications();

      // Setup real-time subscription
      _setupRealtimeSubscription();

      print('>>> Notification service initialized successfully');
    } catch (e) {
      print('>>> Error initializing notification service: $e');
    }
  }

  /// Clear all service data (for logout or account switch)
  void _clearService() {
    print('>>> Clearing notification service data');

    // Cancel subscription
    _notificationSubscription?.cancel();
    _notificationSubscription = null;

    // Clear data
    notifications.clear();
    unreadCount.value = 0;
    _processedNotificationIds.clear();
    _currentUserId = '';
  }

  /// Public method to clear service (call on logout)
  void clearOnLogout() {
    print('>>> Clearing notification service on logout');
    _clearService();
  }

  void _setupRealtimeSubscription() {
    try {
      final userId = session.userId;
      if (userId.isEmpty) return;

      // Cancel existing subscription if any
      _notificationSubscription?.cancel();

      print(
          '>>> Setting up notification real-time subscription for user: $userId');

      _notificationSubscription =
          authRepository.subscribeToUserNotifications(userId).listen(
        (message) {
          _handleRealtimeUpdate(message);
        },
        onError: (error) {
          print('>>> Real-time subscription error: $error');
        },
        cancelOnError: false,
      );

      print('>>> Notification subscription active');
    } catch (e) {
      print('>>> Error setting up notification subscription: $e');
    }
  }

  void _handleRealtimeUpdate(RealtimeMessage message) {
    try {
      print('>>> Notification real-time update: ${message.events}');

      final payload = message.payload;
      final notificationId = payload['\$id'] as String?;

      // CRITICAL FIX: Check if we already processed this notification
      if (message.events.any((e) => e.contains('.create')) &&
          _processedNotificationIds.contains(notificationId)) {
        print('>>> Duplicate CREATE skipped: $notificationId');
        return;
      }

      final notification = AppNotification.fromMap(payload);

      // Verify this notification is for current user
      if (notification.userId != _currentUserId) {
        print('>>> Notification not for current user, skipping');
        return;
      }

      for (String event in message.events) {
        if (event.contains('.create')) {
          _handleNewNotification(notification);
        } else if (event.contains('.update')) {
          _handleUpdatedNotification(notification);
        } else if (event.contains('.delete')) {
          _handleDeletedNotification(notification);
        }
      }
    } catch (e) {
      print('>>> Error handling notification real-time update: $e');
    }
  }

  void _handleNewNotification(AppNotification notification) {
    print('>>> New notification received: ${notification.title}');

    // CRITICAL FIX: Mark as processed to prevent duplicates
    if (notification.documentId != null) {
      _processedNotificationIds.add(notification.documentId!);
    }

    // Check if notification already exists (prevent duplicates)
    final exists =
        notifications.any((n) => n.documentId == notification.documentId);
    if (exists) {
      print('>>> Notification already exists in list, skipping duplicate');
      return;
    }

    // Add to list (insert at beginning)
    notifications.insert(0, notification);

    // Update unread count
    if (notification.isUnread) {
      unreadCount.value++;
    }

    // Show in-app notification banner
    _showNotificationBanner(notification);
  }

  void _handleUpdatedNotification(AppNotification notification) {
    print('>>> Notification updated: ${notification.documentId}');

    final index = notifications.indexWhere(
      (n) => n.documentId == notification.documentId,
    );

    if (index != -1) {
      final oldNotification = notifications[index];
      notifications[index] = notification;

      // Update unread count if read status changed
      if (oldNotification.isUnread && notification.isRead) {
        unreadCount.value = (unreadCount.value - 1).clamp(0, 999);
      } else if (oldNotification.isRead && notification.isUnread) {
        unreadCount.value++;
      }
    }

    notifications.refresh();
  }

  void _handleDeletedNotification(AppNotification notification) {
    print('>>> Notification deleted: ${notification.documentId}');

    final wasUnread = notification.isUnread;
    notifications.removeWhere((n) => n.documentId == notification.documentId);

    if (wasUnread) {
      unreadCount.value = (unreadCount.value - 1).clamp(0, 999);
    }

    // Remove from processed IDs
    if (notification.documentId != null) {
      _processedNotificationIds.remove(notification.documentId!);
    }
  }

  void _showNotificationBanner(AppNotification notification) {
    // Only show banner if Get context is available
    if (!Get.isRegistered<GetMaterialController>()) {
      print('>>> Get not ready, skipping banner');
      return;
    }

    try {
      Get.snackbar(
        notification.title,
        notification.message,
        duration: const Duration(seconds: 4),
        backgroundColor: const Color.fromARGB(255, 81, 115, 153),
        colorText: Colors.white,
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: Icon(
          _getNotificationIcon(notification.type),
          color: Colors.white,
        ),
        onTap: (_) {
          handleNotificationTap(notification);
        },
      );
    } catch (e) {
      print('>>> Error showing notification banner: $e');
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.appointmentBooked:
        return Icons.calendar_today;
      case NotificationType.appointmentAccepted:
        return Icons.check_circle;
      case NotificationType.appointmentDeclined:
        return Icons.cancel;
      case NotificationType.appointmentCancelled:
        return Icons.event_busy;
      case NotificationType.appointmentCompleted:
        return Icons.done_all;
      case NotificationType.message:
        return Icons.message;
      default:
        return Icons.notifications;
    }
  }

  // Public methods

  /// Fetch all notifications for current user
  Future<void> fetchNotifications() async {
    try {
      isLoading.value = true;
      final userId = session.userId;

      if (userId.isEmpty) {
        print('>>> No user logged in');
        _clearService();
        return;
      }

      // Verify we're fetching for the correct user
      if (_currentUserId.isNotEmpty && _currentUserId != userId) {
        print('>>> User mismatch detected, reinitializing...');
        await initialize();
        return;
      }

      print('>>> Fetching notifications for user: $userId');

      final docs = await authRepository.getUserNotifications(userId);

      // Clear existing data first
      notifications.clear();
      _processedNotificationIds.clear();

      // Add fetched notifications
      final fetchedNotifications = docs.map((doc) {
        final notification = AppNotification.fromMap(doc.data);
        // Track all fetched notifications to prevent duplicates
        if (notification.documentId != null) {
          _processedNotificationIds.add(notification.documentId!);
        }
        return notification;
      }).toList();

      notifications.assignAll(fetchedNotifications);

      // Update unread count
      unreadCount.value = notifications.where((n) => n.isUnread).length;

      print(
          '>>> Fetched ${notifications.length} notifications (${unreadCount.value} unread)');
    } catch (e) {
      print('>>> Error fetching notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      await authRepository.markNotificationAsRead(notificationId);
      print('>>> Marked notification as read: $notificationId');
    } catch (e) {
      print('>>> Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final userId = session.userId;
      if (userId.isEmpty) return;

      await authRepository.markAllNotificationsAsRead(userId);
      print('>>> Marked all notifications as read');
    } catch (e) {
      print('>>> Error marking all as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      await authRepository.deleteNotification(notificationId);
      print('>>> Deleted notification: $notificationId');
    } catch (e) {
      print('>>> Error deleting notification: $e');
    }
  }

  /// Delete all notifications
  Future<void> deleteAll() async {
    try {
      final userId = session.userId;
      if (userId.isEmpty) return;

      await authRepository.deleteAllNotifications(userId);
      print('>>> Deleted all notifications');
    } catch (e) {
      print('>>> Error deleting all notifications: $e');
    }
  }

  /// Handle notification tap - FIXED: No navigation, just mark as read
  void handleNotificationTap(AppNotification notification) {
    print('>>> Notification tapped: ${notification.title}');

    // Mark as read
    if (notification.isUnread && notification.documentId != null) {
      markAsRead(notification.documentId!);
    }

    // REMOVED: Navigation code
    // You can add custom logic here if needed without navigation
    print('>>> Notification marked as read (navigation disabled)');
  }

  // Getters
  List<AppNotification> get unreadNotifications {
    return notifications.where((n) => n.isUnread).toList();
  }

  List<AppNotification> get todayNotifications {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    return notifications.where((n) {
      return n.createdAt.isAfter(startOfDay);
    }).toList();
  }

  bool get hasUnread => unreadCount.value > 0;
}

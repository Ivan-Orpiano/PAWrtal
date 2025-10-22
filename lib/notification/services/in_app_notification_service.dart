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

  // Real-time subscription
  StreamSubscription<RealtimeMessage>? _notificationSubscription;

  @override
  void onInit() {
    super.onInit();
    _initializeService();
  }

  @override
  void onClose() {
    _notificationSubscription?.cancel();
    super.onClose();
  }

  Future<void> _initializeService() async {
    try {
      final userId = session.userId;
      if (userId.isEmpty) {
        print('>>> No user logged in, skipping notification initialization');
        return;
      }

      print('>>> Initializing notification service for user: $userId');

      // Load initial notifications
      await fetchNotifications();

      // Setup real-time subscription
      _setupRealtimeSubscription();

      print('>>> Notification service initialized');
    } catch (e) {
      print('>>> Error initializing notification service: $e');
    }
  }

  void _setupRealtimeSubscription() {
    try {
      final userId = session.userId;
      if (userId.isEmpty) return;

      print('>>> Setting up notification real-time subscription');

      _notificationSubscription = authRepository
          .subscribeToUserNotifications(userId)
          .listen((message) {
        _handleRealtimeUpdate(message);
      });

      print('>>> Notification subscription active');
    } catch (e) {
      print('>>> Error setting up notification subscription: $e');
    }
  }

  void _handleRealtimeUpdate(RealtimeMessage message) {
    try {
      print('>>> Notification real-time update: ${message.events}');

      final payload = message.payload;
      final notification = AppNotification.fromMap(payload);

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

    // Add to list (insert at beginning)
    notifications.insert(0, notification);

    // Update unread count
    if (notification.isUnread) {
      unreadCount.value++;
    }

    // Show in-app notification banner (optional - can customize)
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
  }

  void _showNotificationBanner(AppNotification notification) {
    // Only show banner if not already on notification page
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
        // Navigate to notification details or related screen
        handleNotificationTap(notification);
      },
    );
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
        return;
      }

      final docs = await authRepository.getUserNotifications(userId);
      notifications.assignAll(
        docs.map((doc) => AppNotification.fromMap(doc.data)).toList(),
      );

      // Update unread count
      unreadCount.value = notifications.where((n) => n.isUnread).length;

      print('>>> Fetched ${notifications.length} notifications');
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

  /// Handle notification tap
  void handleNotificationTap(AppNotification notification) {
    print('>>> Notification tapped: ${notification.title}');

    // Mark as read
    if (notification.isUnread && notification.documentId != null) {
      markAsRead(notification.documentId!);
    }

    // Navigate based on notification type
    // switch (notification.type) {
    //   case NotificationType.appointmentBooked:
    //   case NotificationType.appointmentAccepted:
    //   case NotificationType.appointmentDeclined:
    //   case NotificationType.appointmentCancelled:
    //   case NotificationType.appointmentCompleted:
    //     // Navigate to appointments page
    //     // You can customize this based on your routing
    //     Get.toNamed('/appointments');
    //     break;

    //   case NotificationType.message:
    //     // Navigate to messages
    //     Get.toNamed('/messages');
    //     break;

    //   default:
    //     // Default action
    //     break;
    // }
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
import 'dart:async';
import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/models/notification_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class NotificationController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService session;

  NotificationController({
    required this.authRepository,
    required this.session,
  });

  // Observable variables
  var notifications = <NotificationModel>[].obs;
  var unreadCount = 0.obs;
  var isLoading = false.obs;
  var isLoadingMore = false.obs;
  var hasMoreNotifications = true.obs;
  
  // Filtering and sorting
  var selectedFilter = 'all'.obs; // all, unread, appointments, messages
  var showArchived = false.obs;
  
  // Real-time subscription
  StreamSubscription<RealtimeMessage>? _notificationSubscription;
  
  // Pagination
  int _currentPage = 0;
  final int _pageSize = 20;
  String? _lastDocumentId;

  @override
  void onInit() {
    super.onInit();
    _initializeNotifications();
  }

  @override
  void onClose() {
    _notificationSubscription?.cancel();
    super.onClose();
  }

  Future<void> _initializeNotifications() async {
    try {
      await loadNotifications();
      _subscribeToNotifications();
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  /// Load notifications for the current user/clinic
  Future<void> loadNotifications({bool refresh = false}) async {
    if (refresh) {
      _resetPagination();
    }

    if (isLoading.value || (!hasMoreNotifications.value && !refresh)) return;

    try {
      isLoading.value = refresh;
      isLoadingMore.value = !refresh;

      final recipientId = _getRecipientId();
      final recipientType = _getRecipientType();

      if (recipientId == null || recipientType == null) {
        print('Cannot load notifications: invalid recipient data');
        return;
      }

      final result = await authRepository.getNotifications(
        recipientId: recipientId,
        recipientType: recipientType,
        filter: selectedFilter.value,
        showArchived: showArchived.value,
        limit: _pageSize,
        lastDocumentId: _lastDocumentId,
      );

      if (refresh) {
        notifications.assignAll(result);
      } else {
        notifications.addAll(result);
      }

      // Update pagination state
      hasMoreNotifications.value = result.length == _pageSize;
      if (result.isNotEmpty) {
        _lastDocumentId = result.last.documentId;
        _currentPage++;
      }

      _updateUnreadCount();

    } catch (e) {
      print('Error loading notifications: $e');
      _showErrorSnackbar('Failed to load notifications');
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  /// Subscribe to real-time notification updates
  void _subscribeToNotifications() {
    try {
      final recipientId = _getRecipientId();
      if (recipientId == null) return;

      final realtime = Realtime(authRepository.client);
      
      _notificationSubscription = realtime.subscribe([
        'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.notificationsCollectionID}.documents'
      ]).stream.listen(
        (response) => _handleRealtimeNotification(response),
        onError: (error) => print('Notification subscription error: $error'),
      );

      print('Notification real-time subscription established');
    } catch (e) {
      print('Error setting up notification subscription: $e');
    }
  }

  /// Handle real-time notification updates
  void _handleRealtimeNotification(RealtimeMessage response) {
    try {
      final payload = response.payload;
      final recipientId = _getRecipientId();
      
      // Only process notifications for current user/clinic
      if (payload['recipientId'] != recipientId) return;

      final notification = NotificationModel.fromMap(payload);

      for (String event in response.events) {
        if (event.contains('.create')) {
          _handleNewNotification(notification);
        } else if (event.contains('.update')) {
          _handleUpdatedNotification(notification);
        } else if (event.contains('.delete')) {
          _handleDeletedNotification(notification);
        }
      }
    } catch (e) {
      print('Error handling real-time notification: $e');
    }
  }

  void _handleNewNotification(NotificationModel notification) {
    // Add to beginning of list
    notifications.insert(0, notification);
    _updateUnreadCount();
    
    // Show notification popup
    _showNotificationPopup(notification);
    
    print('New notification received: ${notification.title}');
  }

  void _handleUpdatedNotification(NotificationModel notification) {
    final index = notifications.indexWhere((n) => n.documentId == notification.documentId);
    if (index != -1) {
      notifications[index] = notification;
      _updateUnreadCount();
    }
  }

  void _handleDeletedNotification(NotificationModel notification) {
    notifications.removeWhere((n) => n.documentId == notification.documentId);
    _updateUnreadCount();
  }

  /// Mark notification as read
  Future<void> markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      await authRepository.markNotificationAsRead(notification.documentId!);
      
      // Update locally
      final index = notifications.indexWhere((n) => n.documentId == notification.documentId);
      if (index != -1) {
        notifications[index] = notification.copyWith(
          isRead: true,
          readAt: DateTime.now(),
        );
        _updateUnreadCount();
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final recipientId = _getRecipientId();
      final recipientType = _getRecipientType();
      
      if (recipientId == null || recipientType == null) return;

      await authRepository.markAllNotificationsAsRead(
        recipientId: recipientId,
        recipientType: recipientType,
      );

      // Update locally
      for (int i = 0; i < notifications.length; i++) {
        if (!notifications[i].isRead) {
          notifications[i] = notifications[i].copyWith(
            isRead: true,
            readAt: DateTime.now(),
          );
        }
      }
      
      notifications.refresh();
      _updateUnreadCount();
      
      _showSuccessSnackbar('All notifications marked as read');
    } catch (e) {
      print('Error marking all as read: $e');
      _showErrorSnackbar('Failed to mark all as read');
    }
  }

  /// Archive notification
  Future<void> archiveNotification(NotificationModel notification) async {
    try {
      await authRepository.archiveNotification(notification.documentId!);
      
      if (!showArchived.value) {
        notifications.removeWhere((n) => n.documentId == notification.documentId);
      } else {
        final index = notifications.indexWhere((n) => n.documentId == notification.documentId);
        if (index != -1) {
          notifications[index] = notification.copyWith(
            isArchived: true,
            archivedAt: DateTime.now(),
          );
        }
      }
      
      _updateUnreadCount();
      _showSuccessSnackbar('Notification archived');
    } catch (e) {
      print('Error archiving notification: $e');
      _showErrorSnackbar('Failed to archive notification');
    }
  }

  /// Delete notification
  Future<void> deleteNotification(NotificationModel notification) async {
    try {
      await authRepository.deleteNotification(notification.documentId!);
      notifications.removeWhere((n) => n.documentId == notification.documentId);
      _updateUnreadCount();
      _showSuccessSnackbar('Notification deleted');
    } catch (e) {
      print('Error deleting notification: $e');
      _showErrorSnackbar('Failed to delete notification');
    }
  }

  /// Handle notification tap - navigate and mark as read
  Future<void> handleNotificationTap(NotificationModel notification) async {
    await markAsRead(notification);
    
    if (notification.actionUrl != null) {
      _navigateToAction(notification.actionUrl!);
    }
  }

  /// Set filter for notifications
  void setFilter(String filter) {
    selectedFilter.value = filter;
    loadNotifications(refresh: true);
  }

  /// Toggle archived notifications visibility
  void toggleArchived() {
    showArchived.value = !showArchived.value;
    loadNotifications(refresh: true);
  }

  /// Create notification (used by other controllers)
  Future<void> createNotification(NotificationModel notification) async {
    try {
      await authRepository.createNotification(notification);
      print('Notification created: ${notification.title}');
    } catch (e) {
      print('Error creating notification: $e');
    }
  }

  // Helper methods
  String? _getRecipientId() {
    try {
      final storage = GetStorage();
      final userRole = storage.read('role') as String?;
      
      if (userRole == 'admin' || userRole == 'staff') {
        return storage.read('clinicId') as String?;
      } else {
        return session.userId;
      }
    } catch (e) {
      print('Error getting recipient ID: $e');
      return null;
    }
  }

  String? _getRecipientType() {
    try {
      final storage = GetStorage();
      final userRole = storage.read('role') as String?;
      
      if (userRole == 'admin' || userRole == 'staff') {
        return 'admin';
      } else {
        return 'user';
      }
    } catch (e) {
      print('Error getting recipient type: $e');
      return null;
    }
  }

  void _updateUnreadCount() {
    unreadCount.value = notifications.where((n) => !n.isRead && !n.isArchived).length;
  }

  void _resetPagination() {
    _currentPage = 0;
    _lastDocumentId = null;
    hasMoreNotifications.value = true;
  }

  void _navigateToAction(String actionUrl) {
    try {
      // Handle different action URLs
      if (actionUrl.startsWith('/appointments')) {
        // Navigate to appointments with optional filter
        final uri = Uri.parse(actionUrl);
        final filter = uri.queryParameters['filter'];
        
        // Use your existing navigation logic
        // Example: Get.toNamed('/appointments', parameters: {'filter': filter});
        
      } else if (actionUrl.startsWith('/messages')) {
        // Navigate to messages with optional conversation
        final uri = Uri.parse(actionUrl);
        final conversationId = uri.queryParameters['conversation'];
        
        // Navigate to messages
        // Example: Get.toNamed('/messages', parameters: {'conversation': conversationId});
        
      }
      // Add more navigation cases as needed
    } catch (e) {
      print('Error navigating to action: $e');
    }
  }

  void _showNotificationPopup(NotificationModel notification) {
    // Create elegant notification popup instead of snackbar
    _showCustomNotificationPopup(notification);
  }

  void _showCustomNotificationPopup(NotificationModel notification) {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      notification.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                notification.message,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Dismiss'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Get.back();
                      handleNotificationTap(notification);
                    },
                    child: const Text('View'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: true,
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
      case NotificationType.newMessage:
        return Icons.message;
      case NotificationType.paymentReceived:
        return Icons.payment;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.appointmentBooked:
        return Colors.blue;
      case NotificationType.appointmentAccepted:
        return Colors.green;
      case NotificationType.appointmentDeclined:
        return Colors.red;
      case NotificationType.newMessage:
        return Colors.purple;
      case NotificationType.paymentReceived:
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Success',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Error',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  // Getters for filtered notifications
  List<NotificationModel> get unreadNotifications => 
      notifications.where((n) => !n.isRead && !n.isArchived).toList();

  List<NotificationModel> get appointmentNotifications =>
      notifications.where((n) => n.type.toString().contains('appointment')).toList();

  List<NotificationModel> get messageNotifications =>
      notifications.where((n) => n.type == NotificationType.newMessage).toList();

  List<NotificationModel> get urgentNotifications =>
      notifications.where((n) => n.priority == NotificationPriority.urgent).toList();

  bool get hasUnreadNotifications => unreadCount.value > 0;
}
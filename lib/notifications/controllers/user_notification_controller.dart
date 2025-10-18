// import 'dart:async';
// import 'package:appwrite/appwrite.dart';
// import 'package:capstone_app/data/models/notification_model.dart';
// import 'package:capstone_app/data/repository/auth.repository.dart';
// import 'package:capstone_app/notifications/components/toast_notification_system.dart';
// import 'package:capstone_app/utils/appwrite_constant.dart';
// import 'package:capstone_app/utils/user_session_service.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class UserNotificationController extends GetxController {
//   final AuthRepository authRepository;
//   final UserSessionService session;
//   final Set<String> _processedNotificationIds = <String>{};
//   Timer? _countUpdateDebouncer;

//   UserNotificationController({
//     required this.authRepository,
//     required this.session,
//   });

//   // Observable variables
//   var notifications = <NotificationModel>[].obs;
//   var unreadCount = 0.obs;
//   var isLoading = false.obs;
//   var isLoadingMore = false.obs;
//   var hasMoreNotifications = true.obs;

//   // Filtering and sorting
//   var selectedFilter = 'all'.obs;
//   var showArchived = false.obs;

//   // Real-time subscription
//   StreamSubscription<RealtimeMessage>? _notificationSubscription;

//   // Pagination
//   int _currentPage = 0;
//   final int _pageSize = 20;
//   String? _lastDocumentId;

//   @override
//   void onInit() {
//     super.onInit();
//     print('>>> UserNotificationController onInit - Starting initialization');
//     _initializeNotifications();
//   }

//   @override
//   void onReady() {
//     super.onReady();
//     print('>>> UserNotificationController onReady');
//     if (notifications.isEmpty && !isLoading.value) {
//       print('>>> No notifications loaded yet, loading now...');
//       loadNotifications(refresh: true);
//     }
//   }

//   @override
//   void onClose() {
//     _countUpdateDebouncer?.cancel();
//     ToastNotificationService.hideCurrentToast();
//     _notificationSubscription?.cancel();
//     super.onClose();
//   }

//   Future<void> _initializeNotifications() async {
//     try {
//       print('>>> Initializing user notifications...');
//       await loadNotifications(refresh: true);
//       print('>>> Initial notifications loaded: ${notifications.length}');
      
//       _subscribeToNotifications();
//       print('>>> Real-time subscription established');
//     } catch (e) {
//       print('>>> Error initializing user notifications: $e');
//     }
//   }

//   /// Load notifications for the current user
//   Future<void> loadNotifications({bool refresh = false}) async {
//     if (refresh) {
//       _resetPagination();
//       _processedNotificationIds.clear();
//     }

//     if (isLoading.value || (!hasMoreNotifications.value && !refresh)) return;

//     try {
//       isLoading.value = refresh;
//       isLoadingMore.value = !refresh;

//       final userId = session.userId;
//       if (userId.isEmpty) {
//         print('>>> Cannot load user notifications: invalid user ID');
//         return;
//       }

//       print('>>> Loading notifications for user: $userId');

//       final result = await authRepository.getNotifications(
//         recipientId: userId,
//         recipientType: 'user',
//         filter: selectedFilter.value,
//         showArchived: showArchived.value,
//         limit: _pageSize,
//         lastDocumentId: _lastDocumentId,
//       );

//       print('>>> Loaded ${result.length} notifications from database');

//       if (refresh) {
//         notifications.assignAll(result);
//         print('>>> Replaced notification list (refresh)');
//       } else {
//         final existingIds = notifications.map((n) => n.documentId).toSet();
//         final newNotifications =
//             result.where((n) => !existingIds.contains(n.documentId)).toList();
//         notifications.addAll(newNotifications);
//         print('>>> Added ${newNotifications.length} new notifications');
//       }

//       hasMoreNotifications.value = result.length == _pageSize;
//       if (result.isNotEmpty) {
//         _lastDocumentId = result.last.documentId;
//         _currentPage++;
//       }

//       _updateUnreadCount();
//       print('>>> Notification loading complete. Total: ${notifications.length}, Unread: ${unreadCount.value}');
//     } catch (e) {
//       print('>>> Error loading user notifications: $e');
//       _showErrorSnackbar('Failed to load notifications');
//     } finally {
//       isLoading.value = false;
//       isLoadingMore.value = false;
//     }
//   }

//   /// Subscribe to real-time notification updates for user
//   void _subscribeToNotifications() {
//     try {
//       final userId = session.userId;
//       if (userId.isEmpty) return;

//       final realtime = Realtime(authRepository.client);

//       _notificationSubscription = realtime
//           .subscribe([
//             'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.notificationsCollectionID}.documents'
//           ])
//           .stream
//           .listen(
//             (response) => _handleRealtimeNotification(response),
//             onError: (error) =>
//                 print('User notification subscription error: $error'),
//           );

//       print('>>> User notification real-time subscription established');
//     } catch (e) {
//       print('>>> Error setting up user notification subscription: $e');
//     }
//   }

//   /// Handle real-time notification updates
//   void _handleRealtimeNotification(RealtimeMessage response) {
//     try {
//       final payload = response.payload;
//       final userId = session.userId;

//       if (payload['recipientId'] != userId || payload['recipientType'] != 'user') return;

//       final notificationId = payload['\$id'] as String?;
//       if (notificationId == null) return;

//       // CRITICAL FIX: Check if already processed BEFORE any processing
//       if (_processedNotificationIds.contains(notificationId)) {
//         print('>>> Already processed notification: $notificationId - SKIPPING');
//         return;
//       }

//       // Mark as processed IMMEDIATELY
//       _processedNotificationIds.add(notificationId);

//       final notification = NotificationModel.fromMap(payload);

//       for (String event in response.events) {
//         if (event.contains('.create')) {
//           _handleNewNotification(notification);
//         } else if (event.contains('.update')) {
//           _handleUpdatedNotification(notification);
//         } else if (event.contains('.delete')) {
//           _handleDeletedNotification(notification);
//         }
//       }

//       _cleanupProcessedIds();
//     } catch (e) {
//       print('>>> Error handling real-time user notification: $e');
//     }
//   }

//   void _handleNewNotification(NotificationModel notification) {
//     final existingIndex = notifications
//         .indexWhere((n) => n.documentId == notification.documentId);

//     if (existingIndex != -1) {
//       print('>>> User notification already exists: ${notification.documentId} - SKIPPING');
//       return;
//     }

//     print('>>> NEW user notification received: ${notification.title}');

//     notifications.insert(0, notification);
//     _debouncedUpdateUnreadCount();

//     if (notification.isUnread) {
//       print('>>> Showing toast for notification: ${notification.documentId}');
//       _showNotificationPopup(notification);
//     }
//   }

//   void _handleUpdatedNotification(NotificationModel notification) {
//     final index = notifications
//         .indexWhere((n) => n.documentId == notification.documentId);
//     if (index != -1) {
//       notifications[index] = notification;
//       _debouncedUpdateUnreadCount();
//     }
//   }

//   void _handleDeletedNotification(NotificationModel notification) {
//     notifications.removeWhere((n) => n.documentId == notification.documentId);
//     _debouncedUpdateUnreadCount();
//   }

//   void _debouncedUpdateUnreadCount() {
//     _countUpdateDebouncer?.cancel();
//     _countUpdateDebouncer = Timer(const Duration(milliseconds: 300), () {
//       _updateUnreadCount();
//     });
//   }

//   /// Mark notification as read
//   Future<void> markAsRead(NotificationModel notification) async {
//     if (notification.isRead) return;

//     try {
//       await authRepository.markNotificationAsRead(notification.documentId!);

//       final index = notifications
//           .indexWhere((n) => n.documentId == notification.documentId);
//       if (index != -1) {
//         notifications[index] = notification.copyWith(
//           isRead: true,
//           readAt: DateTime.now(),
//         );
//         _updateUnreadCount();
//       }
//     } catch (e) {
//       print('>>> Error marking user notification as read: $e');
//     }
//   }

//   /// Mark all notifications as read
//   Future<void> markAllAsRead() async {
//     try {
//       await authRepository.markAllNotificationsAsRead(
//         recipientId: session.userId,
//         recipientType: 'user',
//       );

//       for (int i = 0; i < notifications.length; i++) {
//         if (!notifications[i].isRead) {
//           notifications[i] = notifications[i].copyWith(
//             isRead: true,
//             readAt: DateTime.now(),
//           );
//         }
//       }

//       notifications.refresh();
//       _updateUnreadCount();

//       _showSuccessSnackbar('All notifications marked as read');
//     } catch (e) {
//       print('>>> Error marking all user notifications as read: $e');
//       _showErrorSnackbar('Failed to mark all as read');
//     }
//   }

//   /// Archive notification
//   Future<void> archiveNotification(NotificationModel notification) async {
//     try {
//       await authRepository.archiveNotification(notification.documentId!);

//       if (!showArchived.value) {
//         notifications.removeWhere((n) => n.documentId == notification.documentId);
//       } else {
//         final index = notifications
//             .indexWhere((n) => n.documentId == notification.documentId);
//         if (index != -1) {
//           notifications[index] = notification.copyWith(
//             isArchived: true,
//             archivedAt: DateTime.now(),
//           );
//         }
//       }

//       _updateUnreadCount();
//       _showSuccessSnackbar('Notification archived');
//     } catch (e) {
//       print('>>> Error archiving user notification: $e');
//       _showErrorSnackbar('Failed to archive notification');
//     }
//   }

//   /// Delete notification
//   Future<void> deleteNotification(NotificationModel notification) async {
//     try {
//       await authRepository.deleteNotification(notification.documentId!);
//       notifications.removeWhere((n) => n.documentId == notification.documentId);
//       _updateUnreadCount();
//       _showSuccessSnackbar('Notification deleted');
//     } catch (e) {
//       print('>>> Error deleting user notification: $e');
//       _showErrorSnackbar('Failed to delete notification');
//     }
//   }

//   /// Handle notification tap
//   Future<void> handleNotificationTap(NotificationModel notification) async {
//     await markAsRead(notification);

//     if (notification.actionUrl != null) {
//       _navigateToAction(notification.actionUrl!);
//     }
//   }

//   /// Set filter
//   void setFilter(String filter) {
//     selectedFilter.value = filter;
//     loadNotifications(refresh: true);
//   }

//   /// Toggle archived
//   void toggleArchived() {
//     showArchived.value = !showArchived.value;
//     loadNotifications(refresh: true);
//   }

//   // Helper methods
//   void _updateUnreadCount() {
//     final uniqueNotifications = <String, NotificationModel>{};

//     for (var notification in notifications) {
//       if (notification.documentId != null) {
//         uniqueNotifications[notification.documentId!] = notification;
//       }
//     }

//     if (uniqueNotifications.length != notifications.length) {
//       notifications.assignAll(uniqueNotifications.values.toList());
//     }

//     final newUnreadCount =
//         notifications.where((n) => !n.isRead && !n.isArchived).length;

//     if (unreadCount.value != newUnreadCount) {
//       unreadCount.value = newUnreadCount;
//       print('>>> Updated user unread count: ${unreadCount.value}');
//     }
//   }

//   void _cleanupProcessedIds() {
//     if (_processedNotificationIds.length > 100) {
//       final recentIds = _processedNotificationIds.skip(50).toSet();
//       _processedNotificationIds.clear();
//       _processedNotificationIds.addAll(recentIds);
//     }
//   }

//   void _resetPagination() {
//     _currentPage = 0;
//     _lastDocumentId = null;
//     hasMoreNotifications.value = true;
//   }

//   void _navigateToAction(String actionUrl) {
//     try {
//       if (actionUrl.startsWith('/appointments')) {
//         Get.toNamed('/appointments');
//       } else if (actionUrl.startsWith('/messages')) {
//         Get.toNamed('/messages');
//       }
//     } catch (e) {
//       print('>>> Error navigating to action: $e');
//     }
//   }

//   void _showNotificationPopup(NotificationModel notification) {
//     ToastNotificationService.showToastNotification(notification);
//   }

//   void _showSuccessSnackbar(String message) {
//     Get.snackbar(
//       'Success',
//       message,
//       backgroundColor: Colors.green,
//       colorText: Colors.white,
//       duration: const Duration(seconds: 2),
//     );
//   }

//   void _showErrorSnackbar(String message) {
//     Get.snackbar(
//       'Error',
//       message,
//       backgroundColor: Colors.red,
//       colorText: Colors.white,
//       duration: const Duration(seconds: 3),
//     );
//   }

//   // Getters
//   bool get hasUnreadNotifications => unreadCount.value > 0;
// }
// import 'dart:async';
// import 'package:appwrite/appwrite.dart';
// import 'package:capstone_app/data/models/notification_model.dart';
// import 'package:capstone_app/data/repository/auth.repository.dart';
// import 'package:capstone_app/notifications/components/toast_notification_system.dart';
// import 'package:capstone_app/utils/appwrite_constant.dart';
// import 'package:capstone_app/utils/user_session_service.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:get_storage/get_storage.dart';

// class NotificationController extends GetxController {
//   final AuthRepository authRepository;
//   final UserSessionService session;
//   final Set<String> _processedNotificationIds = <String>{};
//   Timer? _countUpdateDebouncer;

//   NotificationController({
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
//     print('>>> NotificationController onInit - Starting initialization');
//     // Load notifications immediately on init
//     _initializeNotifications();
//   }

//   @override
//   void onReady() {
//     super.onReady();
//     print('>>> NotificationController onReady');
//     // Ensure notifications are loaded if they weren't in onInit
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
//       print('>>> Initializing admin notifications...');
//       // CRITICAL: Load notifications FIRST before subscribing
//       await loadNotifications(refresh: true);
//       print('>>> Initial notifications loaded: ${notifications.length}');
      
//       // Then subscribe to real-time updates
//       _subscribeToNotifications();
//       print('>>> Real-time subscription established');
//     } catch (e) {
//       print('>>> Error initializing notifications: $e');
//     }
//   }

//   /// Load notifications for the current user/clinic
//   Future<void> loadNotifications({bool refresh = false}) async {
//     if (refresh) {
//       _resetPagination();
//       _processedNotificationIds.clear();
//     }

//     if (isLoading.value || (!hasMoreNotifications.value && !refresh)) return;

//     try {
//       isLoading.value = refresh;
//       isLoadingMore.value = !refresh;

//       final recipientId = _getRecipientId();
//       final recipientType = _getRecipientType();

//       if (recipientId == null || recipientType == null) {
//         print('>>> Cannot load notifications: invalid recipient data');
//         print('>>> Recipient ID: $recipientId, Type: $recipientType');
//         return;
//       }

//       print('>>> Loading notifications for: $recipientId ($recipientType)');

//       final result = await authRepository.getNotifications(
//         recipientId: recipientId,
//         recipientType: recipientType,
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

//       // Update pagination state
//       hasMoreNotifications.value = result.length == _pageSize;
//       if (result.isNotEmpty) {
//         _lastDocumentId = result.last.documentId;
//         _currentPage++;
//       }

//       _updateUnreadCount();
//       print('>>> Notification loading complete. Total: ${notifications.length}, Unread: ${unreadCount.value}');
//     } catch (e) {
//       print('>>> Error loading notifications: $e');
//       _showErrorSnackbar('Failed to load notifications');
//     } finally {
//       isLoading.value = false;
//       isLoadingMore.value = false;
//     }
//   }

//   /// Subscribe to real-time notification updates
//   void _subscribeToNotifications() {
//     try {
//       final recipientId = _getRecipientId();
//       if (recipientId == null) return;

//       final realtime = Realtime(authRepository.client);

//       _notificationSubscription = realtime
//           .subscribe([
//             'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.notificationsCollectionID}.documents'
//           ])
//           .stream
//           .listen(
//             (response) => _handleRealtimeNotification(response),
//             onError: (error) =>
//                 print('Notification subscription error: $error'),
//           );

//       print('>>> Notification real-time subscription established');
//     } catch (e) {
//       print('>>> Error setting up notification subscription: $e');
//     }
//   }

//   /// Handle real-time notification updates
//   void _handleRealtimeNotification(RealtimeMessage response) {
//     try {
//       final payload = response.payload;
//       final recipientId = _getRecipientId();

//       // Only process notifications for current user/clinic
//       if (payload['recipientId'] != recipientId) return;

//       final notificationId = payload['\$id'] as String?;
//       if (notificationId == null) return;

//       // CRITICAL FIX: Check if already processed BEFORE any processing
//       if (_processedNotificationIds.contains(notificationId)) {
//         print('>>> Already processed notification: $notificationId - SKIPPING');
//         return;
//       }

//       // Mark as processed IMMEDIATELY to prevent duplicates
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
//       print('>>> Error handling real-time notification: $e');
//     }
//   }

//   void _handleNewNotification(NotificationModel notification) {
//     // Check if notification already exists in list
//     final existingIndex = notifications
//         .indexWhere((n) => n.documentId == notification.documentId);

//     if (existingIndex != -1) {
//       print('>>> Notification already exists in list: ${notification.documentId} - SKIPPING');
//       return;
//     }

//     print('>>> NEW notification received: ${notification.title}');

//     // Add to beginning of list
//     notifications.insert(0, notification);

//     // Debounced count update
//     _debouncedUpdateUnreadCount();

//     // Show toast ONLY ONCE for new unread notifications
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
//       print('>>> Notification updated: ${notification.documentId}');
//     }
//   }

//   void _handleDeletedNotification(NotificationModel notification) {
//     notifications.removeWhere((n) => n.documentId == notification.documentId);
//     _debouncedUpdateUnreadCount();
//     print('>>> Notification deleted: ${notification.documentId}');
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
//       print('>>> Error marking notification as read: $e');
//     }
//   }

//   /// Mark all notifications as read
//   Future<void> markAllAsRead() async {
//     try {
//       final recipientId = _getRecipientId();
//       final recipientType = _getRecipientType();

//       if (recipientId == null || recipientType == null) return;

//       await authRepository.markAllNotificationsAsRead(
//         recipientId: recipientId,
//         recipientType: recipientType,
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
//       print('>>> Error marking all as read: $e');
//       _showErrorSnackbar('Failed to mark all as read');
//     }
//   }

//   /// Archive notification
//   Future<void> archiveNotification(NotificationModel notification) async {
//     try {
//       await authRepository.archiveNotification(notification.documentId!);

//       if (!showArchived.value) {
//         notifications
//             .removeWhere((n) => n.documentId == notification.documentId);
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
//       print('>>> Error archiving notification: $e');
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
//       print('>>> Error deleting notification: $e');
//       _showErrorSnackbar('Failed to delete notification');
//     }
//   }

//   /// Handle notification tap - navigate and mark as read
//   Future<void> handleNotificationTap(NotificationModel notification) async {
//     await markAsRead(notification);

//     if (notification.actionUrl != null) {
//       _navigateToAction(notification.actionUrl!);
//     }
//   }

//   /// Set filter for notifications
//   void setFilter(String filter) {
//     selectedFilter.value = filter;
//     loadNotifications(refresh: true);
//   }

//   /// Toggle archived notifications visibility
//   void toggleArchived() {
//     showArchived.value = !showArchived.value;
//     loadNotifications(refresh: true);
//   }

//   /// Create notification (used by other controllers)
//   Future<void> createNotification(NotificationModel notification) async {
//     try {
//       await authRepository.createNotification(notification);
//       print('>>> Notification created: ${notification.title}');
//     } catch (e) {
//       print('>>> Error creating notification: $e');
//     }
//   }

//   // Helper methods
//   String? _getRecipientId() {
//     try {
//       final storage = GetStorage();
//       final userRole = storage.read('role') as String?;

//       if (userRole == 'admin' || userRole == 'staff') {
//         return storage.read('clinicId') as String?;
//       } else {
//         return session.userId;
//       }
//     } catch (e) {
//       print('>>> Error getting recipient ID: $e');
//       return null;
//     }
//   }

//   String? _getRecipientType() {
//     try {
//       final storage = GetStorage();
//       final userRole = storage.read('role') as String?;

//       if (userRole == 'admin' || userRole == 'staff') {
//         return 'admin';
//       } else {
//         return 'user';
//       }
//     } catch (e) {
//       print('>>> Error getting recipient type: $e');
//       return null;
//     }
//   }

//   void _updateUnreadCount() {
//     final uniqueNotifications = <String, NotificationModel>{};

//     for (var notification in notifications) {
//       if (notification.documentId != null) {
//         uniqueNotifications[notification.documentId!] = notification;
//       }
//     }

//     if (uniqueNotifications.length != notifications.length) {
//       notifications.assignAll(uniqueNotifications.values.toList());
//       print('>>> Removed ${notifications.length - uniqueNotifications.length} duplicate notifications');
//     }

//     final newUnreadCount =
//         notifications.where((n) => !n.isRead && !n.isArchived).length;

//     if (unreadCount.value != newUnreadCount) {
//       unreadCount.value = newUnreadCount;
//       print('>>> Updated unread count: ${unreadCount.value}');
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
//         final uri = Uri.parse(actionUrl);
//         final filter = uri.queryParameters['filter'];
//         // Navigate to appointments
//       } else if (actionUrl.startsWith('/messages')) {
//         final uri = Uri.parse(actionUrl);
//         final conversationId = uri.queryParameters['conversation'];
//         // Navigate to messages
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
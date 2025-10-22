import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/conversation_model.dart';
import 'package:capstone_app/data/models/message_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/models/user_model.dart';
import 'package:capstone_app/data/models/user_status_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/web/admin_web/components/appointments/web_appointment_controller.dart';
import 'package:capstone_app/web/pages/web_admin_home/web_admin_home_controller.dart';
import 'package:appwrite/appwrite.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get_storage/get_storage.dart';

class AdminDashboardController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService session;

  AdminDashboardController({
    required this.authRepository,
    required this.session,
  });

  RealtimeSubscription? _conversationSubscription;
  RealtimeSubscription? _messageSubscription;

  var isLoading = false.obs;
  var clinicData = Rxn<Clinic>();
  var appointments = <Appointment>[].obs;
  var appointmentStats = <String, int>{}.obs;
  var todayAppointments = <Appointment>[].obs;
  var upcomingAppointments = <Appointment>[].obs;
  var recentMessages = <Map<String, dynamic>>[].obs;
  var monthlyStats = <String, int>{}.obs;
  var petsCache = <String, Pet>{}.obs;
  var ownersCache = <String, Map<String, dynamic>>{}.obs;

  var selectedDate = DateTime.now().obs;
  var calendarAppointments = <DateTime, List<Appointment>>{}.obs;

  RealtimeSubscription? _appointmentSubscription;
  Timer? _fallbackTimer;
  var lastUpdateTime = DateTime.now().obs;
  var isRealTimeConnected = false.obs;

  var currentMessages = <Message>[].obs;
  var isLoadingConversation = false.obs;
  var isSendingMessage = false.obs;
  final messageController = TextEditingController();
  final scrollController = ScrollController();

  /// Enhanced onInit to ensure real-time setup
  @override
  void onInit() {
    super.onInit();
    print('>>> ============================================');
    print('>>> DASHBOARD CONTROLLER: onInit()');
    print('>>> ============================================');
    initializeDashboard();

    ever(selectedDate, (_) => fetchAppointmentsForDate(selectedDate.value));
  }

  /// Enhanced onClose to properly clean up subscriptions
  @override
  void onClose() {
    print('>>> ============================================');
    print('>>> DASHBOARD CONTROLLER: onClose()');
    print('>>> Cleaning up resources...');
    print('>>> ============================================');

    // Cancel all subscriptions
    try {
      _appointmentSubscription?.close();
      print('>>> Appointment subscription closed');
    } catch (e) {
      print('>>> Error closing appointment subscription: $e');
    }

    try {
      _conversationSubscription?.close();
      print('>>> Conversation subscription closed');
    } catch (e) {
      print('>>> Error closing conversation subscription: $e');
    }

    try {
      _messageSubscription?.close();
      print('>>> Message subscription closed');
    } catch (e) {
      print('>>> Error closing message subscription: $e');
    }

    try {
      _fallbackTimer?.cancel();
      print('>>> Fallback timer cancelled');
    } catch (e) {
      print('>>> Error cancelling fallback timer: $e');
    }

    // Clear all data to prevent memory leaks
    clinicData.value = null;
    appointments.clear();
    appointmentStats.clear();
    todayAppointments.clear();
    upcomingAppointments.clear();
    recentMessages.clear();
    monthlyStats.clear();
    petsCache.clear();
    ownersCache.clear();
    calendarAppointments.clear();
    _userNamesCache.clear();

    print('>>> All resources cleaned up');
    print('>>> ============================================');

    super.onClose();
  }

  @override
  Future<void> initializeDashboard() async {
    try {
      isLoading.value = true;

      print('>>> ============================================');
      print('>>> INITIALIZING DASHBOARD');
      print('>>> ============================================');

      // Step 1: Fetch clinic data FIRST (required for all other operations)
      print('>>> Step 1: Fetching clinic data...');
      await fetchClinicData();

      // Verify clinic data is available
      if (clinicData.value?.documentId == null) {
        print('>>> ERROR: No clinic data loaded!');
        throw Exception('Clinic data not available');
      }

      print('>>> ✓ Clinic loaded: ${clinicData.value!.clinicName}');
      print('>>> ✓ Clinic ID: ${clinicData.value!.documentId}');

      // Step 2: Fetch appointments data
      print('>>> Step 2: Fetching appointments...');
      await Future.wait([
        fetchAllAppointments(),
        fetchAppointmentStats(),
      ]);
      print('>>> ✓ Appointments loaded: ${appointments.length}');

      // Step 3: Fetch recent messages (MUST be after clinic data)
      print('>>> Step 3: Fetching recent messages...');
      await fetchRecentMessages();
      print('>>> ✓ Messages loaded: ${recentMessages.length}');

      // Step 4: Generate calendar data
      print('>>> Step 4: Generating calendar data...');
      await generateCalendarData();
      print('>>> ✓ Calendar generated');

      // Step 5: Initialize real-time updates LAST
      print('>>> Step 5: Initializing real-time updates...');
      await _initializeRealTimeUpdates();
      print('>>> ✓ Real-time subscriptions active');

      print('>>> ============================================');
      print('>>> DASHBOARD INITIALIZATION COMPLETE');
      print('>>> - Clinic: ${clinicData.value!.clinicName}');
      print('>>> - Appointments: ${appointments.length}');
      print('>>> - Recent Messages: ${recentMessages.length}');
      print('>>> - Real-time Connected: ${isRealTimeConnected.value}');
      print('>>> ============================================');
    } catch (e) {
      print('>>> ERROR: Failed to load dashboard data: $e');
      print('>>> Stack trace: ${StackTrace.current}');
      Get.snackbar("Error", "Failed to load dashboard data: $e");
    } finally {
      isLoading.value = false;
    }
  }

// Add this method to refresh messages separately if needed
  Future<void> refreshMessages() async {
    try {
      await fetchRecentMessages();
      print('>>> Messages refreshed: ${recentMessages.length} recent messages');
    } catch (e) {
      print('>>> Error refreshing messages: $e');
    }
  }

  Future<void> _subscribeToAppointmentUpdates() async {
    try {
      await _appointmentSubscription?.close();

      final realtime = Realtime(authRepository.client);

      _appointmentSubscription = realtime.subscribe([
        'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.appointmentCollectionID}.documents'
      ]);

      _appointmentSubscription!.stream.listen(
        (response) {
          _handleAppointmentRealTimeUpdate(response);
        },
        onError: (error) {
          print("Real-time subscription error: $error");
          isRealTimeConnected.value = false;
          _setupFallbackPolling(interval: 10);
        },
      );
    } catch (e) {
      print("Error setting up appointment subscription: $e");
      rethrow;
    }
  }

  void _handleAppointmentRealTimeUpdate(RealtimeMessage response) {
    try {
      print("Real-time update received: ${response.events}");

      final payload = response.payload;

      final appointmentClinicId = payload['clinicId'];
      if (appointmentClinicId != clinicData.value?.documentId) return;

      final appointment = Appointment.fromMap(payload);

      for (String event in response.events) {
        if (event.contains('.create')) {
          _handleNewAppointment(appointment);
        } else if (event.contains('.update')) {
          _handleUpdatedAppointment(appointment);
        } else if (event.contains('.delete')) {
          _handleDeletedAppointment(appointment);
        }
      }

      lastUpdateTime.value = DateTime.now();

      if (response.events.any((event) => event.contains('.create'))) {
        _showNewAppointmentNotification(appointment);
      }
    } catch (e) {
      print("Error handling real-time update: $e");
    }
  }

  void _handleNewAppointment(Appointment appointment) {
    final existingIndex =
        appointments.indexWhere((a) => a.documentId == appointment.documentId);

    if (existingIndex == -1) {
      appointments.add(appointment);
      print("New appointment added: ${appointment.documentId}");
    } else {
      appointments[existingIndex] = appointment;
      appointments.refresh();
      print("Appointment already exists, updated: ${appointment.documentId}");
    }

    _processTodayAppointments();
    _processUpcomingAppointments();
    _updateAppointmentStats();
    _updateCalendarData(appointment, isNew: true);
  }

  void _handleUpdatedAppointment(Appointment appointment) {
    final index =
        appointments.indexWhere((a) => a.documentId == appointment.documentId);
    if (index != -1) {
      appointments[index] = appointment;
      appointments.refresh();

      _processTodayAppointments();
      _processUpcomingAppointments();
      _updateAppointmentStats();
      _updateCalendarData(appointment, isUpdate: true);

      print("Appointment updated: ${appointment.documentId}");
    } else {
      appointments.add(appointment);
      _processTodayAppointments();
      _processUpcomingAppointments();
      _updateAppointmentStats();
      _updateCalendarData(appointment, isNew: true);
      print(
          "Appointment not found for update, added as new: ${appointment.documentId}");
    }
  }

  void _handleDeletedAppointment(Appointment appointment) {
    appointments.removeWhere((a) => a.documentId == appointment.documentId);

    _processTodayAppointments();
    _processUpcomingAppointments();
    _updateAppointmentStats();
    _removeFromCalendarData(appointment);

    print("Appointment deleted: ${appointment.documentId}");
  }

  void _updateCalendarData(Appointment appointment,
      {bool isNew = false, bool isUpdate = false}) {
    final date = DateTime(
      appointment.dateTime.year,
      appointment.dateTime.month,
      appointment.dateTime.day,
    );

    if (isNew || isUpdate) {
      if (calendarAppointments[date] == null) {
        calendarAppointments[date] = [];
      }

      if (isUpdate) {
        calendarAppointments[date]!
            .removeWhere((a) => a.documentId == appointment.documentId);
      }

      calendarAppointments[date]!.add(appointment);
    }

    calendarAppointments.refresh();
  }

  void _removeFromCalendarData(Appointment appointment) {
    final date = DateTime(
      appointment.dateTime.year,
      appointment.dateTime.month,
      appointment.dateTime.day,
    );

    calendarAppointments[date]
        ?.removeWhere((a) => a.documentId == appointment.documentId);
    if (calendarAppointments[date]?.isEmpty ?? false) {
      calendarAppointments.remove(date);
    }
    calendarAppointments.refresh();
  }

  void _updateAppointmentStats() {
    final stats = <String, int>{
      'total': appointments.length,
      'pending': appointments.where((a) => a.status == 'pending').length,
      'accepted': appointments.where((a) => a.status == 'accepted').length,
      'completed': appointments.where((a) => a.status == 'completed').length,
      'cancelled': appointments.where((a) => a.status == 'cancelled').length,
      'declined': appointments.where((a) => a.status == 'declined').length,
      'today': todayAppointments.length,
    };

    appointmentStats.assignAll(stats);
  }

  void _showNewAppointmentNotification(Appointment appointment) {
    Get.snackbar(
      "New Appointment",
      "New appointment from ${getOwnerName(appointment.userId)} for ${getPetName(appointment.petId)}",
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
      snackPosition: SnackPosition.TOP,
      mainButton: TextButton(
        onPressed: () {
          navigateToAppointments('pending');
        },
        child: const Text("View", style: TextStyle(color: Colors.white)),
      ),
    );
  }

  /// Setup more aggressive fallback polling for messages
  void _setupFallbackPolling({int interval = 30}) {
    _fallbackTimer?.cancel();

    print('>>> Setting up fallback polling with ${interval}s interval');

    _fallbackTimer = Timer.periodic(Duration(seconds: interval), (timer) {
      if (!isRealTimeConnected.value) {
        print(">>> Fallback polling: refreshing data...");
        // Refresh both appointments and messages
        Future.wait([
          fetchAllAppointments(),
          fetchRecentMessages(),
        ]);
      }
    });
  }

  @override
  Future<void> refreshDashboard() async {
    await refreshDashboardData();

    if (!isRealTimeConnected.value) {
      try {
        await _initializeRealTimeUpdates();
      } catch (e) {
        print("Failed to reconnect real-time updates: $e");
      }
    }
  }

  Future<void> refreshDashboardData() async {
    try {
      await Future.wait([
        fetchAllAppointments(),
        fetchAppointmentStats(),
        fetchRecentMessages(), // Add this
      ]);

      await generateCalendarData();
      lastUpdateTime.value = DateTime.now();

      _removeDuplicateAppointments();

      print('>>> Dashboard data refreshed successfully');
      print('>>> - Recent messages: ${recentMessages.length}');
    } catch (e) {
      print("Error refreshing dashboard data: $e");
    }
  }

  /// Enhanced _initializeRealTimeUpdates to include conversation updates
  Future<void> _initializeRealTimeUpdates() async {
    try {
      if (clinicData.value?.documentId == null) return;

      print('>>> ============================================');
      print('>>> INITIALIZING REAL-TIME UPDATES');
      print('>>> Clinic ID: ${clinicData.value!.documentId}');
      print('>>> ============================================');

      // Subscribe to appointments
      await _subscribeToAppointmentUpdates();

      // Subscribe to conversations (for message updates)
      await _subscribeToConversationUpdates();

      // Setup fallback polling
      _setupFallbackPolling();

      isRealTimeConnected.value = true;
      print(">>> Real-time updates initialized successfully");
      print('>>> ============================================');
    } catch (e) {
      print(">>> Failed to initialize real-time updates: $e");
      print('>>> ============================================');
      _setupFallbackPolling(interval: 15);
    }
  }

  /// Send a message in the current conversation
  Future<void> sendMessageInConversation({
    required String conversationId,
    required String messageText,
    bool isStarterMessage = false,
  }) async {
    try {
      if (messageText.trim().isEmpty) {
        print('>>> ERROR: Empty message text');
        return;
      }

      isSendingMessage.value = true;

      print('>>> ============================================');
      print('>>> SENDING MESSAGE');
      print('>>> Conversation: $conversationId');
      print('>>> Sender: ${session.userId}');
      print('>>> Message: $messageText');
      print('>>> ============================================');

      // Send the message using the updated repository method
      final message = await authRepository.sendMessage(
        conversationId: conversationId,
        senderId: session.userId,
        messageText: messageText,
      );

      print('>>> Message sent successfully: ${message.documentId}');
      print('>>> Sent at: ${message.detailedTimeFormatted}');

      // Add to current messages list
      currentMessages.add(message);
      currentMessages.refresh();

      // Clear input
      messageController.clear();

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });

      print('>>> ============================================');
    } catch (e) {
      print('>>> ERROR sending message: $e');
      print('>>> Stack trace: ${StackTrace.current}');
      Get.snackbar(
        'Error',
        'Failed to send message: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isSendingMessage.value = false;
    }
  }

  /// Mark all messages in a conversation as read
  Future<void> markConversationAsRead(String conversationId) async {
    try {
      print('>>> Marking conversation as read: $conversationId');

      await authRepository.markMessagesAsRead(conversationId, session.userId);

      print('>>> Conversation marked as read');
    } catch (e) {
      print('>>> Error marking conversation as read: $e');
    }
  }

  /// Open a specific conversation and load its messages
  Future<void> openConversation(
    Conversation conversation,
    String userId,
    String userType,
  ) async {
    try {
      print('>>> ============================================');
      print('>>> OPENING CONVERSATION');
      print('>>> Conversation ID: ${conversation.documentId}');
      print('>>> User ID: $userId');
      print('>>> User Type: $userType');
      print('>>> ============================================');

      isLoadingConversation.value = true;

      // Load messages for this conversation
      final messages = await authRepository.getConversationMessages(
        conversation.documentId!,
        limit: 50,
      );

      print('>>> Loaded ${messages.length} messages');

      currentMessages.assignAll(messages);
      currentMessages.refresh();

      // Mark as read
      await markConversationAsRead(conversation.documentId!);

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          scrollController.jumpTo(scrollController.position.maxScrollExtent);
        }
      });

      print('>>> ============================================');
    } catch (e) {
      print('>>> ERROR opening conversation: $e');
      Get.snackbar('Error', 'Failed to open conversation');
    } finally {
      isLoadingConversation.value = false;
    }
  }

  /// Check if a user ID belongs to current admin
  bool isCurrentUser(String userId) {
    return userId == session.userId;
  }

  /// Get user status by user ID
  UserStatus? getUserStatus(String userId) {
    try {
      // This would typically fetch from a cache or provider
      // For now, return offline status
      return UserStatus.offline(userId);
    } catch (e) {
      print('Error getting user status: $e');
      return null;
    }
  }

  /// Handle incoming real-time message
  void _handleIncomingMessage(Message message) {
    try {
      print('>>> ============================================');
      print('>>> INCOMING MESSAGE RECEIVED');
      print('>>> Message ID: ${message.documentId}');
      print('>>> From: ${message.senderId}');
      print('>>> Text: ${message.messageText}');
      print('>>> ============================================');

      // Check if message already exists
      final exists =
          currentMessages.any((m) => m.documentId == message.documentId);

      if (!exists) {
        currentMessages.add(message);
        currentMessages.refresh();

        // Auto-scroll to bottom
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (scrollController.hasClients) {
            scrollController.animateTo(
              scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });

        // Mark as read
        markConversationAsRead(message.conversationId);
      }

      // Refresh recent messages if needed
      Future.delayed(const Duration(milliseconds: 500), () {
        refreshMessages();
      });

      print('>>> ============================================');
    } catch (e) {
      print('>>> Error handling incoming message: $e');
    }
  }

  /// Subscribe to conversation updates for real-time message refreshes
  Future<void> _subscribeToConversationUpdates() async {
    try {
      await _conversationSubscription?.close();

      if (clinicData.value?.documentId == null) {
        print('>>> ERROR: Cannot subscribe - no clinic ID');
        return;
      }

      final realtime = Realtime(authRepository.client);

      _conversationSubscription = realtime.subscribe([
        'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.conversationsCollectionID}.documents'
      ]);

      _conversationSubscription!.stream.listen(
        (response) {
          _handleConversationRealTimeUpdate(response);
        },
        onError: (error) {
          print(">>> Conversation subscription error: $error");
          print(">>> Attempting to resubscribe in 3 seconds...");
          Future.delayed(const Duration(seconds: 3), () {
            if (clinicData.value?.documentId != null) {
              _subscribeToConversationUpdates();
            }
          });
        },
        onDone: () {
          print(">>> Conversation subscription stream closed");
        },
      );

      print(
          ">>> Subscribed to conversation updates for clinic: ${clinicData.value!.documentId}");
    } catch (e) {
      print(">>> Error setting up conversation subscription: $e");
    }
  }

  void _handleConversationRealTimeUpdate(RealtimeMessage response) {
    try {
      final payload = response.payload;

      // Only process if this is for our clinic
      final conversationClinicId = payload['clinicId'];
      if (conversationClinicId != clinicData.value?.documentId) {
        print('>>> Conversation not for this clinic - skipping');
        return;
      }

      print('>>> ============================================');
      print('>>> CONVERSATION UPDATE RECEIVED');
      print('>>> Events: ${response.events}');
      print('>>> Conversation ID: ${payload['\$id']}');
      print('>>> Last Message: ${payload['lastMessageText']}');
      print('>>> ============================================');

      // Check if this is a create or update event (new or updated message)
      final isCreateEvent = response.events.any(
        (event) =>
            event.contains('databases.*.collections.*.documents.*.create'),
      );

      final isUpdateEvent = response.events.any(
        (event) =>
            event.contains('databases.*.collections.*.documents.*.update'),
      );

      if (isCreateEvent || isUpdateEvent) {
        print(
            '>>> Message event detected - updating recent messages immediately');

        // Update immediately with the new conversation data
        _updateRecentMessagesFromPayload(payload);

        // Also refresh from database after a delay for consistency
        Future.delayed(const Duration(milliseconds: 500), () {
          print('>>> Performing full refresh from database');
          fetchRecentMessages();
        });
      }

      print('>>> ============================================');
    } catch (e) {
      print('>>> Error handling conversation update: $e');
    }
  }

  /// Helper method to fetch user profile picture
  Future<Map<String, dynamic>> _fetchUserProfilePicture(String userId) async {
    try {
      if (userId.isEmpty) {
        return {
          'url': '',
          'hasProfilePicture': false,
        };
      }

      final userDoc = await authRepository.getUserById(userId);
      if (userDoc != null) {
        final user = User.fromMap(userDoc.data);
        if (user.hasProfilePicture && user.profilePictureId != null) {
          try {
            final profilePictureUrl =
                authRepository.getUserProfilePictureUrl(user.profilePictureId!);
            return {
              'url': profilePictureUrl,
              'hasProfilePicture': true,
            };
          } catch (e) {
            print('>>> Error generating profile picture URL: $e');
            return {
              'url': '',
              'hasProfilePicture': false,
            };
          }
        }
      }
      return {
        'url': '',
        'hasProfilePicture': false,
      };
    } catch (e) {
      print('>>> Error fetching profile picture for $userId: $e');
      return {
        'url': '',
        'hasProfilePicture': false,
      };
    }
  }

  /// Update recent messages immediately from payload without waiting for database
  void _updateRecentMessagesFromPayload(Map<String, dynamic> payload) {
    try {
      print('>>> Updating recent messages from real-time payload');

      // Validate payload has required fields
      if (payload['lastMessageText'] == null ||
          payload['lastMessageTime'] == null ||
          payload['\$id'] == null ||
          payload['userId'] == null) {
        print('>>> Missing required fields in payload - skipping');
        return;
      }

      final conversationId = payload['\$id'] as String;
      final userId = payload['userId'] as String;
      final lastMessageText = payload['lastMessageText'] as String;
      final lastMessageTime =
          DateTime.parse(payload['lastMessageTime'] as String);
      final clinicUnreadCount = payload['clinicUnreadCount'] as int? ?? 0;

      print('>>> Looking up user data for: $userId');

      // Fetch user data for name and profile picture
      String senderName = 'Unknown User';
      String profilePictureUrl = '';
      bool hasProfilePicture = false;

      if (_userNamesCache.containsKey(userId)) {
        senderName = _userNamesCache[userId]!;
        print('>>> Using cached user name: $senderName');
      } else {
        // Fetch user name asynchronously
        _getUserName(userId).then((name) {
          print('>>> Fetched user name: $name');
          // Update the message with fetched name
          final index = recentMessages.indexWhere(
            (m) => m['senderId'] == userId,
          );
          if (index != -1) {
            recentMessages[index]['senderName'] = name;
            recentMessages.refresh();
          }
        }).catchError((e) {
          print('>>> Error fetching user name: $e');
        });
        senderName = userId.length > 6
            ? 'User #${userId.substring(0, 6)}'
            : 'Unknown User';
      }

      // Fetch profile picture asynchronously
      _fetchUserProfilePicture(userId).then((profileData) {
        print('>>> Fetched profile picture for user: $userId');
        final index = recentMessages.indexWhere(
          (m) => m['senderId'] == userId,
        );
        if (index != -1) {
          recentMessages[index]['profilePictureUrl'] = profileData['url'] ?? '';
          recentMessages[index]['hasProfilePicture'] =
              profileData['hasProfilePicture'] ?? false;
          recentMessages.refresh();
        }
      }).catchError((e) {
        print('>>> Error fetching profile picture: $e');
      });

      final newMessage = {
        'id': conversationId,
        'senderName': senderName,
        'senderId': userId,
        'message': lastMessageText,
        'time': lastMessageTime,
        'isRead': clinicUnreadCount == 0,
        'unreadCount': clinicUnreadCount,
        'conversationId': conversationId,
        'profilePictureUrl': profilePictureUrl,
        'hasProfilePicture': hasProfilePicture,
      };

      print('>>> New message data created');

      // Find if this conversation already exists in recent messages
      final existingIndex = recentMessages.indexWhere(
        (m) => m['conversationId'] == conversationId,
      );

      if (existingIndex != -1) {
        print('>>> Updating existing message at index $existingIndex');
        recentMessages[existingIndex] = newMessage;
      } else {
        print('>>> Adding as new message');
        recentMessages.insert(0, newMessage);
      }

      // Keep only the 3 most recent
      if (recentMessages.length > 3) {
        print('>>> Trimming to 3 most recent messages');
        recentMessages.value = recentMessages.take(3).toList();
      }

      // Sort by time to ensure most recent is first
      recentMessages.sort((a, b) {
        final timeA = a['time'] as DateTime;
        final timeB = b['time'] as DateTime;
        return timeB.compareTo(timeA);
      });

      print('>>> Recent messages updated. Total: ${recentMessages.length}');
      recentMessages.refresh();
    } catch (e, stackTrace) {
      print('>>> Error updating recent messages from payload: $e');
      print('>>> Stack trace: $stackTrace');
    }
  }

  void _removeDuplicateAppointments() {
    final uniqueAppointments = <Appointment>[];
    final seenIds = <String>{};

    for (var appointment in appointments) {
      if (appointment.documentId != null &&
          !seenIds.contains(appointment.documentId)) {
        seenIds.add(appointment.documentId!);
        uniqueAppointments.add(appointment);
      }
    }

    if (uniqueAppointments.length != appointments.length) {
      appointments.assignAll(uniqueAppointments);
      print(
          "Removed ${appointments.length - uniqueAppointments.length} duplicate appointments");
    }
  }

  Future<void> fetchClinicData() async {
    try {
      final user = await authRepository.getUser();
      if (user == null) {
        print('>>> ERROR: No user found');
        return;
      }

      // Get user role from storage
      final storage = GetStorage();
      final userRole = storage.read('role') as String?;

      print('>>> Fetching clinic data for role: $userRole');

      String? clinicId;

      if (userRole == 'staff') {
        // Staff: Get clinicId from storage
        clinicId = storage.read('clinicId') as String?;
        print('>>> DASHBOARD: Staff mode - using stored clinicId: $clinicId');
      } else {
        // Admin: Get clinic by admin ID
        print('>>> DASHBOARD: Admin mode - looking up clinic');
        final clinicDoc = await authRepository.getClinicByAdminId(user.$id);
        if (clinicDoc != null) {
          clinicId = clinicDoc.$id;
        }
      }

      if (clinicId != null) {
        final clinicDoc = await authRepository.getClinicById(clinicId);
        if (clinicDoc != null) {
          clinicData.value = Clinic.fromMap(clinicDoc.data);
          clinicData.value!.documentId = clinicDoc.$id;
          print(
              '>>> DASHBOARD: Clinic loaded: ${clinicData.value!.clinicName}');
          print('>>> DASHBOARD: Clinic ID: ${clinicData.value!.documentId}');
        } else {
          print('>>> ERROR: Clinic document not found for ID: $clinicId');
        }
      } else {
        print('>>> ERROR: No clinicId available');
      }
    } catch (e) {
      print(">>> ERROR fetching clinic data: $e");
    }
  }

  Future<void> fetchAllAppointments() async {
    if (clinicData.value?.documentId == null) {
      print('>>> ERROR: Cannot fetch appointments - no clinic ID');
      return;
    }

    try {
      print(
          '>>> Fetching appointments for clinic: ${clinicData.value!.documentId}');
      final result = await authRepository
          .getClinicAppointments(clinicData.value!.documentId!);
      print('>>> Found ${result.length} appointments');

      appointments.assignAll(result);
      await _fetchRelatedData();
      _processTodayAppointments();
      _processUpcomingAppointments();
    } catch (e) {
      print(">>> ERROR fetching appointments: $e");
    }
  }

  Future<void> fetchAppointmentStats() async {
    if (clinicData.value?.documentId == null) return;

    try {
      final stats = await authRepository
          .getClinicAppointmentStats(clinicData.value!.documentId!);
      appointmentStats.assignAll(stats);

      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 1);
      final nextMonth = DateTime(now.year, now.month + 1, 1);

      final monthlyAppointments = appointments.where((appointment) {
        return appointment.dateTime.isAfter(thisMonth) &&
            appointment.dateTime.isBefore(nextMonth);
      }).toList();

      monthlyStats.assignAll({
        'thisMonth': monthlyAppointments.length,
        'completed':
            monthlyAppointments.where((a) => a.status == 'completed').length,
        'pending':
            monthlyAppointments.where((a) => a.status == 'pending').length,
      });
    } catch (e) {
      print("Error fetching appointment stats: $e");
    }
  }

  Future<void> _fetchOwnerData(String userId) async {
    if (!ownersCache.containsKey(userId)) {
      try {
        final ownerDoc = await authRepository.getUserById(userId);
        if (ownerDoc != null) {
          // Create a proper User object
          final user = User.fromMap(ownerDoc.data);
          ownersCache[userId] = {
            'name': user.name,
            'email': user.email,
            'phone': user.phone,
          };
        } else {
          // Add fallback data to prevent repeated fetching
          ownersCache[userId] = {
            'name': 'User #${userId.substring(0, 6)}',
            'email': 'N/A',
            'phone': 'N/A',
          };
        }
      } catch (e) {
        print("Error fetching owner $userId: $e");
        // Add fallback data
        ownersCache[userId] = {
          'name': 'User #${userId.substring(0, 6)}',
          'email': 'N/A',
          'phone': 'N/A',
        };
      }
    }
  }

  Future<void> _fetchRelatedData() async {
    for (var appointment in appointments) {
      // Skip if pet is already cached
      if (petsCache.containsKey(appointment.petId)) {
        continue;
      }

      // Skip empty petId
      if (appointment.petId.isEmpty) {
        print(
            ">>> Skipping empty petId for appointment ${appointment.documentId}");
        continue;
      }

      try {
        print(">>> Fetching pet data for: ${appointment.petId}");

        // Try to get pet by ID if it looks like a valid document ID
        Pet? pet;

        if (_isValidDocumentId(appointment.petId)) {
          print(">>>   Trying to fetch by document ID...");
          try {
            final petDoc = await authRepository.getPetById(appointment.petId);
            if (petDoc != null) {
              pet = Pet.fromMap(petDoc.data);
              pet.documentId = petDoc.$id;
              print(">>>   ✓ Found pet by ID: ${pet.name}");
            }
          } catch (e) {
            print(">>>   ✗ Pet not found by ID: $e");
          }
        }

        // If not found by ID, try by name
        if (pet == null) {
          print(">>>   Trying to fetch by name...");
          try {
            final petByName =
                await authRepository.getPetByName(appointment.petId);
            if (petByName != null) {
              pet = Pet.fromMap(petByName.data);
              pet.documentId = petByName.$id;
              print(">>>   ✓ Found pet by name: ${pet.name}");
            }
          } catch (e) {
            print(">>>   ✗ Pet not found by name: $e");
          }
        }

        // If still not found, create fallback
        if (pet == null) {
          print(">>>   Creating fallback pet data");
          pet = Pet(
            petId: appointment.petId,
            userId: appointment.userId,
            name: _formatPetName(appointment.petId),
            type: 'Unknown',
            breed: 'Unknown',
          );
        }

        // Cache the pet
        petsCache[appointment.petId] = pet;
        print(">>>   ✓ Pet cached successfully");
      } catch (e) {
        print(">>> Error fetching pet ${appointment.petId}: $e");
        // Create fallback pet
        petsCache[appointment.petId] = Pet(
          petId: appointment.petId,
          userId: appointment.userId,
          name: _formatPetName(appointment.petId),
          type: 'Unknown',
          breed: 'Unknown',
        );
      }

      // Fetch owner data
      if (!ownersCache.containsKey(appointment.userId)) {
        await _fetchOwnerData(appointment.userId);
      }
    }
  }

  String _formatPetName(String rawName) {
    if (rawName.isEmpty) return 'Unknown Pet';

    // If it looks like a document ID, create a generic name
    if (_isValidDocumentId(rawName) && !rawName.contains(' ')) {
      return 'Pet #${rawName.substring(0, 6)}';
    }

    // Remove any special characters except spaces
    final cleaned = rawName.replaceAll(RegExp(r'[^\w\s]'), ' ');

    // Split by camelCase, underscores, dashes, or multiple spaces
    final words = cleaned.split(RegExp(r'(?=[A-Z])|[_\-\s]+'));

    // Capitalize each word and join with spaces
    final formatted = words
        .where((word) => word.isNotEmpty)
        .map((word) {
          if (word.length == 1) return word.toUpperCase();
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ')
        .trim();

    return formatted.isEmpty ? 'Unknown Pet' : formatted;
  }

  bool _isValidDocumentId(String id) {
    // Basic checks
    if (id.isEmpty) return false;

    // Appwrite document IDs are typically 20-36 characters
    if (id.length < 20 || id.length > 36) return false;

    // Check if it contains only valid characters
    // Appwrite IDs use alphanumeric characters and may include underscore, dot, dash
    final validIdRegex = RegExp(r'^[a-zA-Z0-9_.-]+$');
    if (!validIdRegex.hasMatch(id)) return false;

    // Check if it doesn't look like a pet name (no spaces, not too many special chars)
    if (id.contains(' ')) return false;

    // If it has more than 2 consecutive special characters, it's likely not a valid ID
    if (RegExp(r'[_.-]{3,}').hasMatch(id)) return false;

    return true;
  }

  void _processTodayAppointments() {
    final today = DateTime.now();
    final todayAppts = appointments.where((appointment) {
      final appointmentDate = appointment.dateTime;
      return appointmentDate.year == today.year &&
          appointmentDate.month == today.month &&
          appointmentDate.day == today.day;
    }).toList();

    todayAppts.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    todayAppointments.assignAll(todayAppts);
  }

  void _processUpcomingAppointments() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final upcoming = appointments.where((appointment) {
      final appointmentDate = DateTime(
        appointment.dateTime.year,
        appointment.dateTime.month,
        appointment.dateTime.day,
      );

      // exclude today's appointments and only show accepted ones
      return appointmentDate.isAfter(today) && appointment.status == 'accepted';
    }).toList();

    upcoming.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    upcomingAppointments.assignAll(upcoming.take(5).toList());
  }

  Future<void> generateCalendarData() async {
    Map<DateTime, List<Appointment>> calendarData = {};

    for (var appointment in appointments) {
      final date = DateTime(
        appointment.dateTime.year,
        appointment.dateTime.month,
        appointment.dateTime.day,
      );

      if (calendarData[date] == null) {
        calendarData[date] = [];
      }
      calendarData[date]!.add(appointment);
    }

    calendarAppointments.assignAll(calendarData);
  }

  Future<void> fetchAppointmentsForDate(DateTime date) async {
    // Placeholder for future implementation
  }

  /// Enhanced fetchRecentMessages with logging

  Future<void> fetchRecentMessages() async {
    if (clinicData.value?.documentId == null) {
      print('>>> ERROR: Cannot fetch messages - no clinic ID');
      recentMessages.clear();
      return;
    }

    try {
      print('>>> ============================================');
      print('>>> FETCHING RECENT MESSAGES WITH PROFILE PICTURES');
      print('>>> Clinic: ${clinicData.value!.documentId}');
      print('>>> ============================================');

      // Get all conversations for this clinic
      final conversations = await authRepository
          .getClinicConversations(clinicData.value!.documentId!);

      print('>>> Found ${conversations.length} total conversations');

      if (conversations.isEmpty) {
        print('>>> No conversations found');
        recentMessages.clear();
        recentMessages.refresh();
        print('>>> ============================================');
        return;
      }

      // Filter out conversations with null or invalid data
      final validConversations = conversations.where((conversation) {
        return conversation.documentId != null &&
            conversation.lastMessageText != null &&
            conversation.lastMessageText!.isNotEmpty &&
            conversation.lastMessageTime != null &&
            conversation.userId.isNotEmpty;
      }).toList();

      print('>>> Valid conversations: ${validConversations.length}');

      if (validConversations.isEmpty) {
        print('>>> No valid conversations with messages');
        recentMessages.clear();
        recentMessages.refresh();
        print('>>> ============================================');
        return;
      }

      // Sort conversations by lastMessageTime (most recent first)
      validConversations.sort((a, b) {
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });

      // Take only the 3 most recent conversations
      final recentConversations = validConversations.take(3).toList();
      print(
          '>>> Taking ${recentConversations.length} most recent conversations');

      // Build the recent messages list
      final List<Map<String, dynamic>> messages = [];

      // Process each conversation and WAIT for profile pictures
      for (var conversation in recentConversations) {
        print('>>> Processing conversation ${conversation.documentId}...');

        // Fetch user data
        String senderName = 'Unknown User';
        String profilePictureUrl = '';
        bool hasProfilePicture = false;

        try {
          print('>>>   Fetching user data for: ${conversation.userId}');
          final userDoc = await authRepository.getUserById(conversation.userId);

          if (userDoc != null) {
            final user = User.fromMap(userDoc.data);
            senderName = user.name.isNotEmpty ? user.name : 'Unknown User';
            print('>>>   ✓ Got user name: $senderName');

            // IMPORTANT: Check and fetch profile picture
            if (user.hasProfilePicture && user.profilePictureId != null) {
              print('>>>   ✓ User has profile picture, generating URL...');
              try {
                profilePictureUrl = authRepository
                    .getUserProfilePictureUrl(user.profilePictureId!);
                hasProfilePicture = true;
                print(
                    '>>>   ✓ Generated profile picture URL: ${profilePictureUrl.substring(0, 50)}...');
              } catch (e) {
                print('>>>   ✗ Error generating profile picture URL: $e');
                hasProfilePicture = false;
              }
            } else {
              print('>>>   - User has no profile picture');
              hasProfilePicture = false;
            }
          } else {
            print('>>>   ✗ User document not found');
            senderName = conversation.userId.length > 6
                ? 'User #${conversation.userId.substring(0, 6)}'
                : 'Unknown User';
          }
        } catch (e) {
          print('>>> Error fetching user ${conversation.userId}: $e');
          senderName = conversation.userId.length > 6
              ? 'User #${conversation.userId.substring(0, 6)}'
              : 'Unknown User';
          hasProfilePicture = false;
        }

        final messageData = {
          'id': conversation.documentId ?? '',
          'senderName': senderName,
          'senderId': conversation.userId,
          'message': conversation.lastMessageText ?? '',
          'time': conversation.lastMessageTime!,
          'isRead': (conversation.clinicUnreadCount ?? 0) == 0,
          'unreadCount': conversation.clinicUnreadCount ?? 0,
          'conversationId': conversation.documentId ?? '',
          'profilePictureUrl': profilePictureUrl,
          'hasProfilePicture': hasProfilePicture,
        };

        messages.add(messageData);

        print('>>> ✓ Added message from $senderName');
        print('>>>   - Conversation ID: ${conversation.documentId}');
        print('>>>   - Has Profile Picture: $hasProfilePicture');
        print('>>>   - Profile URL available: ${profilePictureUrl.isNotEmpty}');
        print('>>>   - Unread: ${conversation.clinicUnreadCount ?? 0}');
      }

      print('>>> Total messages processed: ${messages.length}');

      // Update the observable
      recentMessages.assignAll(messages);
      recentMessages.refresh();

      print('>>> ============================================');
      print('>>> RECENT MESSAGES FETCHED SUCCESSFULLY');
      print('>>> Total messages: ${recentMessages.length}');
      for (int i = 0; i < recentMessages.length; i++) {
        final msg = recentMessages[i];
        print(
            '>>> Message $i: ${msg['senderName']} - HasPic: ${msg['hasProfilePicture']}');
      }
      print('>>> ============================================');
    } catch (e, stackTrace) {
      print('>>> ERROR fetching recent messages: $e');
      print('>>> Stack trace: $stackTrace');
      // Clear messages on error instead of showing snackbar during initialization
      recentMessages.clear();
      recentMessages.refresh();
      print('>>> ============================================');
    }
  }

// Add this helper method to cache user data
  final Map<String, String> _userNamesCache = {};

  Future<String> _getUserName(String userId) async {
    if (userId.isEmpty) {
      return 'Unknown User';
    }

    if (_userNamesCache.containsKey(userId)) {
      return _userNamesCache[userId]!;
    }

    try {
      final userDoc = await authRepository.getUserById(userId);
      if (userDoc != null) {
        final user = User.fromMap(userDoc.data);
        final name = user.name.isNotEmpty ? user.name : 'Unknown User';
        _userNamesCache[userId] = name;
        return name;
      }
    } catch (e) {
      print('Error fetching user name for $userId: $e');
    }

    final fallback =
        userId.length > 6 ? 'User #${userId.substring(0, 6)}' : 'Unknown User';
    _userNamesCache[userId] = fallback;
    return fallback;
  }

  String getOwnerName(String userId) {
    if (!ownersCache.containsKey(userId)) {
      // Trigger a fetch if we don't have the data
      _fetchOwnerData(userId);
      return 'Loading...';
    }
    return ownersCache[userId]?['name'] ?? 'User #${userId.substring(0, 6)}';
  }

  String getPetName(String petId) {
    if (petId.isEmpty) return 'Unknown Pet';

    final pet = petsCache[petId];
    if (pet != null) {
      if (pet.name.isNotEmpty && pet.name != 'Unknown') {
        return pet.name;
      }
    }

    // If pet not in cache or has no name, format the ID
    return _formatPetName(petId);
  }

  String getPetType(String petId) {
    if (petId.isEmpty) return 'Unknown';

    final pet = petsCache[petId];
    if (pet != null && pet.type.isNotEmpty && pet.type != 'Unknown') {
      return pet.type;
    }

    return 'Not Available';
  }

  Pet? getPetForAppointment(String petId) {
    if (petId.isEmpty) return null;
    return petsCache[petId];
  }

  /// Force refresh pet data for a specific appointment
  Future<void> refreshPetData(String petId) async {
    if (petId.isEmpty) return;

    try {
      print(">>> Force refreshing pet data for: $petId");

      Pet? pet;

      // Try by ID first
      if (_isValidDocumentId(petId)) {
        try {
          final petDoc = await authRepository.getPetById(petId);
          if (petDoc != null) {
            pet = Pet.fromMap(petDoc.data);
            pet.documentId = petDoc.$id;
          }
        } catch (e) {
          print(">>> Pet not found by ID: $e");
        }
      }

      // Try by name if not found
      if (pet == null) {
        try {
          final petByName = await authRepository.getPetByName(petId);
          if (petByName != null) {
            pet = Pet.fromMap(petByName.data);
            pet.documentId = petByName.$id;
          }
        } catch (e) {
          print(">>> Pet not found by name: $e");
        }
      }

      // Update cache
      if (pet != null) {
        petsCache[petId] = pet;
        petsCache.refresh();
        print(">>> ✓ Pet data refreshed and cached");
      } else {
        print(">>> Could not refresh pet data - creating fallback");
        petsCache[petId] = Pet(
          petId: petId,
          userId: '',
          name: _formatPetName(petId),
          type: 'Unknown',
          breed: 'Unknown',
        );
      }
    } catch (e) {
      print(">>> Error refreshing pet data: $e");
    }
  }

  int get pendingCount => appointmentStats['pending'] ?? 0;
  int get acceptedCount => appointmentStats['accepted'] ?? 0;
  int get completedCount => appointmentStats['completed'] ?? 0;
  int get cancelledCount => appointmentStats['cancelled'] ?? 0;
  int get declinedCount => appointmentStats['declined'] ?? 0;
  int get totalAppointments => appointmentStats['total'] ?? 0;

  Future<void> quickAcceptAppointment(Appointment appointment) async {
    try {
      await authRepository.updateAppointmentStatus(
          appointment.documentId!, 'accepted');
      Get.snackbar("Success", "Appointment accepted!");
    } catch (e) {
      Get.snackbar("Error", "Failed to accept appointment: $e");
    }
  }

  // ✅ FIXED: Dynamic index lookup for Appointments
  void navigateToAppointments([String? filter]) {
    try {
      final homeController = Get.find<WebAdminHomeController>();

      // Find the correct index dynamically
      final appointmentsIndex =
          homeController.navigationLabels.indexOf('Appointments');

      if (appointmentsIndex != -1) {
        print('>>> Navigating to Appointments at index $appointmentsIndex');
        homeController.setSelectedIndex(appointmentsIndex);

        if (filter != null) {
          Future.delayed(const Duration(milliseconds: 100), () {
            try {
              final appointmentController =
                  Get.find<WebAppointmentController>();
              appointmentController.setSelectedTab(filter);
            } catch (e) {
              print("Appointment controller not ready for filter: $filter");
            }
          });
        }
      } else {
        print('>>> ERROR: Appointments page not available in navigation');
      }
    } catch (e) {
      print("Navigation error: $e");
    }
  }

  // ✅ FIXED: Dynamic index lookup for Messages
  void navigateToMessages() {
    try {
      final homeController = Get.find<WebAdminHomeController>();

      // Find the correct index dynamically
      final messagesIndex = homeController.navigationLabels.indexOf('Messages');

      if (messagesIndex != -1) {
        print('>>> Navigating to Messages at index $messagesIndex');
        homeController.setSelectedIndex(messagesIndex);
      } else {
        print('>>> ERROR: Messages page not available in navigation');
      }
    } catch (e) {
      print("Navigation error: $e");
    }
  }

  // ✅ FIXED: Dynamic index lookup for Clinic
  void navigateToClinic() {
    try {
      final homeController = Get.find<WebAdminHomeController>();

      // Find the correct index dynamically
      final clinicIndex = homeController.navigationLabels.indexOf('Clinic');

      if (clinicIndex != -1) {
        print('>>> Navigating to Clinic at index $clinicIndex');
        homeController.setSelectedIndex(clinicIndex);
      } else {
        print('>>> ERROR: Clinic page not available in navigation');
      }
    } catch (e) {
      print("Navigation error: $e");
    }
  }

  void setSelectedDate(DateTime date) {
    selectedDate.value = date;
  }

  String get connectionStatus =>
      isRealTimeConnected.value ? "Connected" : "Polling";
  String get lastUpdateDisplay =>
      "Last update: ${DateFormat('hh:mm:ss a').format(lastUpdateTime.value)}";

  /// Check if user can view appointments widget
  bool canViewAppointmentsWidget() {
    try {
      final homeController = Get.find<WebAdminHomeController>();
      return homeController.canAccessFeature('appointments');
    } catch (e) {
      print('Error checking appointments permission: $e');
      return false;
    }
  }

  /// Check if user can view messages widget
  bool canViewMessagesWidget() {
    try {
      final homeController = Get.find<WebAdminHomeController>();
      return homeController.canAccessFeature('messages');
    } catch (e) {
      print('Error checking messages permission: $e');
      return false;
    }
  }

  /// Check if user can view clinic widget
  bool canViewClinicWidget() {
    try {
      final homeController = Get.find<WebAdminHomeController>();
      return homeController.canAccessFeature('clinic_info');
    } catch (e) {
      print('Error checking clinic permission: $e');
      return false;
    }
  }

  /// NEW: Get only visible stats based on permissions
  List<Map<String, dynamic>> getVisibleStats() {
    final allStats = [
      {
        'title': 'Today\'s Appointments',
        'value': todayAppointments.length.toString(),
        'subtitle': 'Scheduled today',
        'icon': Icons.event_available,
        'color': Colors.blue,
        'permission': 'appointments',
      },
      {
        'title': 'Pending Appointments',
        'value': pendingCount.toString(),
        'subtitle': 'Need approval',
        'icon': Icons.pending_actions,
        'color': Colors.orange,
        'permission': 'appointments',
      },
      {
        'title': 'Today\'s In Progress',
        'value': todayAppointments
            .where((a) => a.status == 'in_progress')
            .length
            .toString(),
        'subtitle': 'Currently being treated',
        'icon': Icons.medical_services,
        'color': Colors.purple,
        'permission': 'appointments',
      },
      {
        'title': 'Today\'s Completed',
        'value': todayAppointments
            .where((a) => a.status == 'completed')
            .length
            .toString(),
        'subtitle': 'Finished appointments today',
        'icon': Icons.check_circle,
        'color': Colors.green,
        'permission': 'appointments',
      },
    ];

    try {
      final homeController = Get.find<WebAdminHomeController>();
      return allStats
          .where((stat) =>
              homeController.canAccessFeature(stat['permission'] as String))
          .toList();
    } catch (e) {
      print('Error filtering stats: $e');
      return allStats;
    }
  }

  /// NEW: Get count of visible widgets for layout purposes
  Map<String, bool> getVisibleWidgets() {
    try {
      final homeController = Get.find<WebAdminHomeController>();
      return {
        'appointments': homeController.canAccessFeature('appointments'),
        'messages': homeController.canAccessFeature('messages'),
        'clinic': homeController.canAccessFeature('clinic_info'),
      };
    } catch (e) {
      print('Error getting visible widgets: $e');
      return {
        'appointments': true,
        'messages': true,
        'clinic': true,
      };
    }
  }
  // Add these methods to AdminDashboardController class

  /// Confirm before accepting appointment from dashboard
  Future<void> confirmQuickAcceptAppointment(Appointment appointment) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Accept Appointment?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to accept this appointment.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${getPetName(appointment.petId)} • ${appointment.service}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Owner: ${getOwnerName(appointment.userId)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('MMM dd, yyyy • hh:mm a')
                        .format(appointment.dateTime),
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'The time slot will be reserved and the client will be notified.',
              style: TextStyle(fontSize: 12, color: Colors.orange[700]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: const Text('Accept', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      await quickAcceptAppointment(appointment);
    }
  }

  /// Confirm before declining appointment from dashboard
  Future<void> confirmQuickDeclineAppointment(Appointment appointment) async {
    String selectedReason = '';
    final customReasonController = TextEditingController();
    bool hasChanges = false;

    final predefinedReasons = [
      'Time slot already booked',
      'Clinic at full capacity',
      'Service not available',
      'Emergency override needed',
      'Insufficient information provided',
      'Other (specify below)',
    ];

    final result = await Get.dialog<Map<String, String>?>(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: StatefulBuilder(
            builder: (context, setState) {
              return WillPopScope(
                onWillPop: () async {
                  customReasonController.dispose();
                  return true;
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.cancel,
                              color: Colors.red, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Decline Appointment',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Please select or provide a reason for declining:',
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 16),
                    ...predefinedReasons.map((reason) {
                      return RadioListTile<String>(
                        title:
                            Text(reason, style: const TextStyle(fontSize: 14)),
                        value: reason,
                        groupValue: selectedReason,
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value!;
                            hasChanges = true;
                          });
                        },
                        activeColor: const Color.fromARGB(255, 81, 115, 153),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      );
                    }),
                    const SizedBox(height: 16),
                    TextField(
                      controller: customReasonController,
                      decoration: InputDecoration(
                        labelText: 'Custom reason (optional)',
                        hintText: 'Enter additional details...',
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      maxLength: 200,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          hasChanges = true;
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            customReasonController.dispose();
                            Get.back();
                          },
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: selectedReason.isEmpty
                              ? null
                              : () {
                                  String finalReason = selectedReason;
                                  if (customReasonController.text.isNotEmpty) {
                                    finalReason = selectedReason ==
                                            'Other (specify below)'
                                        ? customReasonController.text
                                        : '$selectedReason - ${customReasonController.text}';
                                  }

                                  Get.back(result: {
                                    'reason': finalReason,
                                  });
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          child: const Text('Decline Appointment',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );

    if (result != null && result['reason'] != null) {
      await quickDeclineAppointment(appointment, result['reason']!);
      customReasonController.dispose();
    } else {
      customReasonController.dispose();
    }
  }

  /// Quick decline appointment
  Future<void> quickDeclineAppointment(
      Appointment appointment, String reason) async {
    try {
      await authRepository.updateAppointmentStatus(
        appointment.documentId!,
        'declined',
      );

      // Update the appointment in the local list if needed
      final index = appointments
          .indexWhere((a) => a.documentId == appointment.documentId);
      if (index != -1) {
        appointments[index] = appointment.copyWith(
          status: 'declined',
          updatedAt: DateTime.now(),
        );
        appointments.refresh();
      }

      Get.snackbar(
        "Success",
        "Appointment declined. Patient will be notified.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );

      // Refresh dashboard data
      await refreshDashboardData();
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to decline appointment: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}

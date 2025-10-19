import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/models/user_model.dart';
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

  @override
  void onInit() {
    super.onInit();
    print('>>> ============================================');
    print('>>> DASHBOARD CONTROLLER: onInit()');
    print('>>> ============================================');
    initializeDashboard();

    ever(selectedDate, (_) => fetchAppointmentsForDate(selectedDate.value));
  }

  @override
  void onClose() {
    print('>>> ============================================');
    print('>>> DASHBOARD CONTROLLER: onClose()');
    print('>>> Cleaning up resources...');
    print('>>> ============================================');

    _appointmentSubscription?.close();
    _conversationSubscription?.close();
    _messageSubscription?.close();
    _fallbackTimer?.cancel();

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

    super.onClose();
  }

  Future<void> initializeDashboard() async {
    try {
      isLoading.value = true;

      print('>>> ============================================');
      print('>>> INITIALIZING DASHBOARD');
      print('>>> ============================================');

      await fetchClinicData();

      // Only continue if we have valid clinic data
      if (clinicData.value?.documentId != null) {
        print('>>> Clinic loaded: ${clinicData.value!.clinicName}');
        print('>>> Clinic ID: ${clinicData.value!.documentId}');

        // Fetch data in parallel for better performance
        await Future.wait([
          fetchAllAppointments(),
          fetchAppointmentStats(),
          fetchRecentMessages(), // Now fetches REAL messages
        ]);

        // Generate calendar data after appointments are loaded
        await generateCalendarData();

        // Initialize real-time updates last
        await _initializeRealTimeUpdates();

        print('>>> ============================================');
        print('>>> DASHBOARD INITIALIZATION COMPLETE');
        print('>>> - Appointments: ${appointments.length}');
        print('>>> - Recent Messages: ${recentMessages.length}');
        print('>>> - Today\'s Appointments: ${todayAppointments.length}');
        print('>>> ============================================');
      } else {
        print('>>> ERROR: No clinic data loaded!');
      }
    } catch (e) {
      print('>>> ERROR: Failed to load dashboard data: $e');
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

  void _setupFallbackPolling({int interval = 30}) {
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(Duration(seconds: interval), (timer) {
      if (!isRealTimeConnected.value) {
        print("Fallback polling: refreshing data...");
        refreshDashboardData(); // This now includes messages
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

  // Add these methods to AdminDashboardController

  Future<void> _initializeRealTimeUpdates() async {
    try {
      if (clinicData.value?.documentId == null) return;

      // Subscribe to appointments
      await _subscribeToAppointmentUpdates();

      // Subscribe to conversations (for message updates)
      await _subscribeToConversationUpdates();

      _setupFallbackPolling();

      isRealTimeConnected.value = true;
      print("Real-time updates initialized successfully");
    } catch (e) {
      print("Failed to initialize real-time updates: $e");
      _setupFallbackPolling(interval: 15);
    }
  }

// Add this new method for conversation updates
  Future<void> _subscribeToConversationUpdates() async {
    try {
      await _conversationSubscription?.close();

      final realtime = Realtime(authRepository.client);

      _conversationSubscription = realtime.subscribe([
        'databases.${AppwriteConstants.dbID}.collections.${AppwriteConstants.conversationsCollectionID}.documents'
      ]);

      _conversationSubscription!.stream.listen(
        (response) {
          _handleConversationRealTimeUpdate(response);
        },
        onError: (error) {
          print("Conversation subscription error: $error");
        },
      );

      print(">>> Subscribed to conversation updates");
    } catch (e) {
      print("Error setting up conversation subscription: $e");
    }
  }

// Add this handler for conversation updates
  void _handleConversationRealTimeUpdate(RealtimeMessage response) {
    try {
      final payload = response.payload;

      // Only process if this is for our clinic
      final conversationClinicId = payload['clinicId'];
      if (conversationClinicId != clinicData.value?.documentId) return;

      print(">>> Conversation update received: ${response.events}");

      // Check if this is a message-related update
      final hasMessageUpdate = response.events.any(
          (event) => event.contains('.update') || event.contains('.create'));

      if (hasMessageUpdate) {
        // Refresh messages after a short delay to ensure data is consistent
        Future.delayed(const Duration(milliseconds: 500), () {
          fetchRecentMessages();
        });
      }
    } catch (e) {
      print("Error handling conversation update: $e");
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
      if (!petsCache.containsKey(appointment.petId) &&
          appointment.petId.isNotEmpty) {
        try {
          // First try to fetch by name
          final petByName =
              await authRepository.getPetByName(appointment.petId);
          if (petByName != null) {
            final pet = Pet.fromMap(petByName.data);
            pet.documentId = petByName.$id;
            petsCache[appointment.petId] = pet;
            continue;
          }

          // If name lookup failed and ID is valid, try by ID
          if (_isValidDocumentId(appointment.petId)) {
            final petDoc = await authRepository.getPetById(appointment.petId);
            if (petDoc != null) {
              final pet = Pet.fromMap(petDoc.data);
              pet.documentId = petDoc.$id;
              petsCache[appointment.petId] = pet;
              continue;
            }
          }

          // If both lookups failed, create a fallback pet with the ID/name as the pet name
          print("Creating fallback pet data for ID/Name: ${appointment.petId}");
          petsCache[appointment.petId] = Pet(
            petId: appointment.petId,
            userId: appointment.userId,
            name: appointment.petId, // Use the ID/name as the pet name
            type: 'Unknown',
            breed: 'Unknown',
          );
        } catch (e) {
          print("Error fetching pet ${appointment.petId}: $e");
          // Create a more user-friendly fallback entry
          petsCache[appointment.petId] = Pet(
            petId: appointment.petId,
            userId: appointment.userId,
            name: _formatPetName(appointment.petId), // Format the name nicely
            type: 'Unknown',
            breed: 'Unknown',
          );
        }
      }

      if (!ownersCache.containsKey(appointment.userId)) {
        await _fetchOwnerData(appointment.userId);
      }
    }
  }

  String _formatPetName(String rawName) {
    // Remove any special characters except spaces
    final cleaned = rawName.replaceAll(RegExp(r'[^\w\s]'), '');

    // Split by camelCase, underscores, or dashes
    final words = cleaned.split(RegExp(r'(?=[A-Z])|[_-]'));

    // Capitalize each word and join with spaces
    return words
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  bool _isValidDocumentId(String id) {
    if (id.isEmpty || id.length > 36) return false;
    final validIdRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.-]*$');
    return validIdRegex.hasMatch(id);
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

  Future<void> fetchRecentMessages() async {
    if (clinicData.value?.documentId == null) {
      print('>>> ERROR: Cannot fetch messages - no clinic ID');
      return;
    }

    try {
      print(
          '>>> Fetching recent messages for clinic: ${clinicData.value!.documentId}');

      // Get all conversations for this clinic
      final conversations = await authRepository
          .getClinicConversations(clinicData.value!.documentId!);

      print('>>> Found ${conversations.length} conversations');

      if (conversations.isEmpty) {
        recentMessages.clear();
        return;
      }

      // Sort conversations by lastMessageTime (most recent first)
      conversations.sort((a, b) {
        if (a.lastMessageTime == null && b.lastMessageTime == null) return 0;
        if (a.lastMessageTime == null) return 1;
        if (b.lastMessageTime == null) return -1;
        return b.lastMessageTime!.compareTo(a.lastMessageTime!);
      });

      // Take only the 3 most recent conversations
      final recentConversations = conversations.take(3).toList();

      // Build the recent messages list
      final List<Map<String, dynamic>> messages = [];

      for (var conversation in recentConversations) {
        if (conversation.lastMessageText == null ||
            conversation.lastMessageTime == null) {
          continue;
        }

        // Fetch user data for the sender
        String senderName = 'Unknown User';
        try {
          final userDoc = await authRepository.getUserById(conversation.userId);
          if (userDoc != null) {
            final user = User.fromMap(userDoc.data);
            senderName = user.name;
          }
        } catch (e) {
          print('>>> Error fetching user ${conversation.userId}: $e');
          senderName = 'User #${conversation.userId.substring(0, 6)}';
        }

        messages.add({
          'id': conversation.documentId ?? '',
          'senderName': senderName,
          'senderId': conversation.userId,
          'message': conversation.lastMessageText ?? '',
          'time': conversation.lastMessageTime!,
          'isRead': conversation.clinicUnreadCount == 0,
          'unreadCount': conversation.clinicUnreadCount,
          'conversationId': conversation.documentId,
        });
      }

      print('>>> Processed ${messages.length} recent messages');
      recentMessages.assignAll(messages);
    } catch (e) {
      print('>>> ERROR fetching recent messages: $e');
      recentMessages.clear();
    }
  }

// Add this helper method to cache user data
  final Map<String, String> _userNamesCache = {};

  Future<String> _getUserName(String userId) async {
    if (_userNamesCache.containsKey(userId)) {
      return _userNamesCache[userId]!;
    }

    try {
      final userDoc = await authRepository.getUserById(userId);
      if (userDoc != null) {
        final user = User.fromMap(userDoc.data);
        _userNamesCache[userId] = user.name;
        return user.name;
      }
    } catch (e) {
      print('Error fetching user name for $userId: $e');
    }

    final fallback = 'User #${userId.substring(0, 6)}';
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
    final pet = petsCache[petId];
    if (pet != null) {
      if (pet.name.isNotEmpty) {
        return pet.name;
      }
      return _formatPetName(petId);
    }
    return _formatPetName(petId);
  }

  String getPetType(String petId) {
    return petsCache[petId]?.type ?? 'Not Available';
  }

  Pet? getPetForAppointment(String petId) => petsCache[petId];

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

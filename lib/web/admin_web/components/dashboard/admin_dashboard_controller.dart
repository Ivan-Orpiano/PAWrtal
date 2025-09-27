import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
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

class AdminDashboardController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService session;

  AdminDashboardController({
    required this.authRepository,
    required this.session,
  });

  // Observable variables
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

  // Calendar related
  var selectedDate = DateTime.now().obs;
  var calendarAppointments = <DateTime, List<Appointment>>{}.obs;

  // Real-time related
  RealtimeSubscription? _appointmentSubscription;
  Timer? _fallbackTimer;
  var lastUpdateTime = DateTime.now().obs;
  var isRealTimeConnected = false.obs;

  @override
  void onInit() {
    super.onInit();
    initializeDashboard();
    
    // Refresh data every 5 minutes
    ever(selectedDate, (_) => fetchAppointmentsForDate(selectedDate.value));
  }

  @override
  void onClose() {
    // Clean up subscriptions and timers
    _appointmentSubscription?.close();
    _fallbackTimer?.cancel();
    super.onClose();
  }

  Future<void> initializeDashboard() async {
    try {
      isLoading.value = true;
      await fetchClinicData();
      await fetchAllAppointments();
      await fetchAppointmentStats();
      await generateCalendarData();
      await fetchRecentMessages();
      
      // Initialize real-time updates
      await _initializeRealTimeUpdates();
      
    } catch (e) {
      Get.snackbar("Error", "Failed to load dashboard data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _initializeRealTimeUpdates() async {
    try {
      if (clinicData.value?.documentId == null) return;

      // Set up real-time subscription for appointments
      await _subscribeToAppointmentUpdates();
      
      // Set up fallback polling as backup (every 30 seconds)
      _setupFallbackPolling();
      
      isRealTimeConnected.value = true;
      print("Real-time updates initialized successfully");
      
    } catch (e) {
      print("Failed to initialize real-time updates: $e");
      // Fall back to polling if real-time fails
      _setupFallbackPolling(interval: 15); // More frequent polling as fallback
    }
  }

  Future<void> _subscribeToAppointmentUpdates() async {
    try {
      // Close existing subscription if any
      await _appointmentSubscription?.close();

      final realtime = Realtime(authRepository.client);
      
      // Subscribe to appointment collection changes for this clinic
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
          // Increase fallback polling frequency on error
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

      // Check if this appointment belongs to our clinic
      final appointmentClinicId = payload['clinicId'];
      if (appointmentClinicId != clinicData.value?.documentId) return;

      final appointment = Appointment.fromMap(payload);
      
      // Handle different types of events
      for (String event in response.events) {
        if (event.contains('.create')) {
          _handleNewAppointment(appointment);
        } else if (event.contains('.update')) {
          _handleUpdatedAppointment(appointment);
        } else if (event.contains('.delete')) {
          _handleDeletedAppointment(appointment);
        }
      }

      // Update last update time
      lastUpdateTime.value = DateTime.now();
      
      // Show notification for new appointments
      if (response.events.any((event) => event.contains('.create'))) {
        _showNewAppointmentNotification(appointment);
      }

    } catch (e) {
      print("Error handling real-time update: $e");
    }
  }

  void _handleNewAppointment(Appointment appointment) {
    // Check if appointment already exists to prevent duplicates
    final existingIndex = appointments.indexWhere((a) => a.documentId == appointment.documentId);
    
    if (existingIndex == -1) {
      // Only add if it doesn't already exist
      appointments.add(appointment);
      print("New appointment added: ${appointment.documentId}");
    } else {
      // Update existing appointment if it already exists (shouldn't happen for new, but safety check)
      appointments[existingIndex] = appointment;
      appointments.refresh();
      print("Appointment already exists, updated: ${appointment.documentId}");
    }
    
    // Refresh all related data
    _processTodayAppointments();
    _processUpcomingAppointments();
    _updateAppointmentStats();
    _updateCalendarData(appointment, isNew: true);
  }

  void _handleUpdatedAppointment(Appointment appointment) {
    // Find and update existing appointment
    final index = appointments.indexWhere((a) => a.documentId == appointment.documentId);
    if (index != -1) {
      appointments[index] = appointment;
      appointments.refresh();
      
      // Refresh related data
      _processTodayAppointments();
      _processUpcomingAppointments();
      _updateAppointmentStats();
      _updateCalendarData(appointment, isUpdate: true);
      
      print("Appointment updated: ${appointment.documentId}");
    } else {
      // If appointment doesn't exist, add it (edge case)
      appointments.add(appointment);
      _processTodayAppointments();
      _processUpcomingAppointments();
      _updateAppointmentStats();
      _updateCalendarData(appointment, isNew: true);
      print("Appointment not found for update, added as new: ${appointment.documentId}");
    }
  }

  void _handleDeletedAppointment(Appointment appointment) {
    // Remove from appointments list
    appointments.removeWhere((a) => a.documentId == appointment.documentId);
    
    // Refresh related data
    _processTodayAppointments();
    _processUpcomingAppointments();
    _updateAppointmentStats();
    _removeFromCalendarData(appointment);
    
    print("Appointment deleted: ${appointment.documentId}");
  }

  void _updateCalendarData(Appointment appointment, {bool isNew = false, bool isUpdate = false}) {
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
        // Remove old version and add updated version
        calendarAppointments[date]!.removeWhere((a) => a.documentId == appointment.documentId);
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
    
    calendarAppointments[date]?.removeWhere((a) => a.documentId == appointment.documentId);
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
        refreshDashboardData();
      }
    });
  }

  // Manual refresh method (for pull-to-refresh)
  Future<void> refreshDashboard() async {
    await refreshDashboardData();
    
    // Try to reconnect real-time if disconnected
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
      await fetchAllAppointments();
      await fetchAppointmentStats();
      await generateCalendarData();
      await fetchRecentMessages();
      lastUpdateTime.value = DateTime.now();
      
      // Clean up any potential duplicates after fetch
      _removeDuplicateAppointments();
    } catch (e) {
      print("Error refreshing dashboard data: $e");
    }
  }

  void _removeDuplicateAppointments() {
    // Remove any duplicate appointments based on documentId
    final uniqueAppointments = <Appointment>[];
    final seenIds = <String>{};
    
    for (var appointment in appointments) {
      if (appointment.documentId != null && !seenIds.contains(appointment.documentId)) {
        seenIds.add(appointment.documentId!);
        uniqueAppointments.add(appointment);
      }
    }
    
    if (uniqueAppointments.length != appointments.length) {
      appointments.assignAll(uniqueAppointments);
      print("Removed ${appointments.length - uniqueAppointments.length} duplicate appointments");
    }
  }

  // Rest of your existing methods remain the same...
  Future<void> fetchClinicData() async {
    try {
      final user = await authRepository.getUser();
      if (user == null) return;

      final clinicDoc = await authRepository.getClinicByAdminId(user.$id);
      if (clinicDoc != null) {
        clinicData.value = Clinic.fromMap(clinicDoc.data);
        clinicData.value!.documentId = clinicDoc.$id;
      }
    } catch (e) {
      print("Error fetching clinic data: $e");
    }
  }

  Future<void> fetchAllAppointments() async {
    if (clinicData.value?.documentId == null) return;

    try {
      final result = await authRepository.getClinicAppointments(clinicData.value!.documentId!);
      appointments.assignAll(result);
      await _fetchRelatedData();
      _processTodayAppointments();
      _processUpcomingAppointments();
    } catch (e) {
      print("Error fetching appointments: $e");
    }
  }

  Future<void> fetchAppointmentStats() async {
    if (clinicData.value?.documentId == null) return;

    try {
      final stats = await authRepository.getClinicAppointmentStats(clinicData.value!.documentId!);
      appointmentStats.assignAll(stats);
      
      // Calculate monthly stats
      final now = DateTime.now();
      final thisMonth = DateTime(now.year, now.month, 1);
      final nextMonth = DateTime(now.year, now.month + 1, 1);
      
      final monthlyAppointments = appointments.where((appointment) {
        return appointment.dateTime.isAfter(thisMonth) && appointment.dateTime.isBefore(nextMonth);
      }).toList();

      monthlyStats.assignAll({
        'thisMonth': monthlyAppointments.length,
        'completed': monthlyAppointments.where((a) => a.status == 'completed').length,
        'pending': monthlyAppointments.where((a) => a.status == 'pending').length,
        'revenue': monthlyAppointments
            .where((a) => a.isPaid && a.totalCost != null)
            .fold(0.0, (sum, a) => sum + (a.totalCost ?? 0.0))
            .round(),
      });
    } catch (e) {
      print("Error fetching appointment stats: $e");
    }
  }

  Future<void> _fetchRelatedData() async {
    for (var appointment in appointments) {
      // Cache pet data
      if (!petsCache.containsKey(appointment.petId)) {
        try {
          final petDoc = await authRepository.getPetById(appointment.petId);
          if (petDoc != null) {
            final pet = Pet.fromMap(petDoc.data);
            pet.documentId = petDoc.$id;
            petsCache[appointment.petId] = pet;
          }
        } catch (e) {
          print("Error fetching pet ${appointment.petId}: $e");
        }
      }

      // Cache owner data
      if (!ownersCache.containsKey(appointment.userId)) {
        try {
          final ownerDoc = await authRepository.getUserById(appointment.userId);
          if (ownerDoc != null) {
            ownersCache[appointment.userId] = ownerDoc.data;
          }
        } catch (e) {
          print("Error fetching owner ${appointment.userId}: $e");
        }
      }
    }
  }

  void _processTodayAppointments() {
    final today = DateTime.now();
    final todayAppts = appointments.where((appointment) {
      final appointmentDate = appointment.dateTime;
      return appointmentDate.year == today.year &&
             appointmentDate.month == today.month &&
             appointmentDate.day == today.day;
    }).toList();

    // Sort by time
    todayAppts.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    todayAppointments.assignAll(todayAppts);
  }

  void _processUpcomingAppointments() {
    final now = DateTime.now();
    final upcoming = appointments.where((appointment) {
      return appointment.dateTime.isAfter(now) && 
             (appointment.status == 'accepted' || appointment.status == 'pending');
    }).toList();

    // Sort by date and take next 5
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
    // This method can be used to fetch appointments for a specific date
    // when calendar date is selected
  }

  Future<void> fetchRecentMessages() async {
    // TODO: Implement when messaging system is ready
    // For now, add some mock data
    recentMessages.assignAll([
      {
        'id': '1',
        'senderName': 'Sarah Johnson',
        'message': 'Thank you for taking care of Buddy. When should we schedule the next checkup?',
        'time': DateTime.now().subtract(const Duration(hours: 2)),
        'isRead': false,
        'petName': 'Buddy',
      },
      {
        'id': '2',
        'senderName': 'Mike Chen',
        'message': 'Luna seems to be feeling much better after the treatment. Thank you!',
        'time': DateTime.now().subtract(const Duration(hours: 5)),
        'isRead': true,
        'petName': 'Luna',
      },
      {
        'id': '3',
        'senderName': 'Jennifer Davis',
        'message': 'Can we reschedule Max\'s appointment to next week?',
        'time': DateTime.now().subtract(const Duration(days: 1)),
        'isRead': false,
        'petName': 'Max',
      },
    ]);
  }

  // Helper methods
  String getOwnerName(String userId) => ownersCache[userId]?['name'] ?? 'Unknown Owner';
  String getPetName(String petId) => petsCache[petId]?.name ?? petId;
  String getPetType(String petId) => petsCache[petId]?.type ?? 'Unknown Type';
  Pet? getPetForAppointment(String petId) => petsCache[petId];

  // Statistics getters
  double get todayRevenue {
    return todayAppointments
        .where((a) => a.isPaid && a.totalCost != null)
        .fold(0.0, (sum, appointment) => sum + (appointment.totalCost ?? 0.0));
  }

  int get pendingCount => appointmentStats['pending'] ?? 0;
  int get acceptedCount => appointmentStats['accepted'] ?? 0;
  int get completedCount => appointmentStats['completed'] ?? 0;
  int get declinedCount => appointmentStats['declined'] ?? 0;
  int get totalAppointments => appointmentStats['total'] ?? 0;

  // Quick actions
  Future<void> quickAcceptAppointment(Appointment appointment) async {
    try {
      await authRepository.updateAppointmentStatus(appointment.documentId!, 'accepted');
      // Don't need to manually refresh - real-time will handle it
      Get.snackbar("Success", "Appointment accepted!");
    } catch (e) {
      Get.snackbar("Error", "Failed to accept appointment: $e");
    }
  }

  // Navigation methods using your existing WebAdminHomeController
  void navigateToAppointments([String? filter]) {
    try {
      final homeController = Get.find<WebAdminHomeController>();
      homeController.setSelectedIndex(2); // Appointments page
      
      // Set filter if provided
      if (filter != null) {
        Future.delayed(const Duration(milliseconds: 100), () {
          try {
            final appointmentController = Get.find<WebAppointmentController>();
            appointmentController.setSelectedTab(filter);
          } catch (e) {
            print("Appointment controller not ready for filter: $filter");
          }
        });
      }
    } catch (e) {
      print("Navigation error: $e");
    }
  }

  void navigateToMessages() {
    try {
      final homeController = Get.find<WebAdminHomeController>();
      homeController.setSelectedIndex(3); // Messages page
    } catch (e) {
      print("Navigation error: $e");
    }
  }

  void navigateToClinic() {
    try {
      final homeController = Get.find<WebAdminHomeController>();
      homeController.setSelectedIndex(1); // Clinic page
    } catch (e) {
      print("Navigation error: $e");
    }
  }

  void setSelectedDate(DateTime date) {
    selectedDate.value = date;
  }

  // Connection status helpers
  String get connectionStatus => isRealTimeConnected.value ? "Connected" : "Polling";
  String get lastUpdateDisplay => "Last update: ${DateFormat('hh:mm:ss a').format(lastUpdateTime.value)}";
}
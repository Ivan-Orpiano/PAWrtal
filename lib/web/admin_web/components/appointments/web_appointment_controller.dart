import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/medical_record_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';

class WebAppointmentController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService session;

  WebAppointmentController({
    required this.authRepository,
    required this.session,
  });

  // Observable variables
  var isLoading = false.obs;
  var appointments = <Appointment>[].obs;
  var filteredAppointments = <Appointment>[].obs;
  var clinicData = Rxn<Clinic>();
  var petsCache = <String, Pet>{}.obs;
  var ownersCache = <String, Map<String, dynamic>>{}.obs;

  // Filter and search
  var selectedTab = 'today'.obs;
  var searchQuery = ''.obs;
  var selectedDateFilter = DateTime.now().obs;

  // Real-time related
  RealtimeSubscription? _appointmentSubscription;
  Timer? _fallbackTimer;
  var lastUpdateTime = DateTime.now().obs;
  var isRealTimeConnected = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchClinicData();
    
    // Listen to changes
    ever(selectedTab, (_) => updateFilteredAppointments());
    ever(searchQuery, (_) => updateFilteredAppointments());
    ever(selectedDateFilter, (_) => updateFilteredAppointments());
  }

  @override
  void onClose() {
    _appointmentSubscription?.close();
    _fallbackTimer?.cancel();
    super.onClose();
  }

  Future<void> fetchClinicData() async {
    try {
      isLoading.value = true;
      
      final user = await authRepository.getUser();
      if (user == null) return;

      final clinicDoc = await authRepository.getClinicByAdminId(user.$id);
      if (clinicDoc != null) {
        clinicData.value = Clinic.fromMap(clinicDoc.data);
        clinicData.value!.documentId = clinicDoc.$id;
        await fetchClinicAppointments();
        await _initializeRealTimeUpdates();
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load clinic data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _initializeRealTimeUpdates() async {
    try {
      if (clinicData.value?.documentId == null) return;

      await _subscribeToAppointmentUpdates();
      _setupFallbackPolling();
      
      isRealTimeConnected.value = true;
      print("Real-time updates initialized for appointments");
      
    } catch (e) {
      print("Failed to initialize real-time updates: $e");
      _setupFallbackPolling(interval: 15);
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
    final existingIndex = appointments.indexWhere((a) => a.documentId == appointment.documentId);
    
    if (existingIndex == -1) {
      appointments.add(appointment);
      print("New appointment added: ${appointment.documentId}");
    } else {
      appointments[existingIndex] = appointment;
      appointments.refresh();
    }
    
    updateFilteredAppointments();
  }

  void _handleUpdatedAppointment(Appointment appointment) {
    final index = appointments.indexWhere((a) => a.documentId == appointment.documentId);
    if (index != -1) {
      appointments[index] = appointment;
      appointments.refresh();
      updateFilteredAppointments();
      print("Appointment updated: ${appointment.documentId}");
    } else {
      appointments.add(appointment);
      updateFilteredAppointments();
    }
  }

  void _handleDeletedAppointment(Appointment appointment) {
    appointments.removeWhere((a) => a.documentId == appointment.documentId);
    updateFilteredAppointments();
    print("Appointment deleted: ${appointment.documentId}");
  }

  void _showNewAppointmentNotification(Appointment appointment) {
    Get.snackbar(
      "New Appointment",
      "New appointment from ${getOwnerName(appointment.userId)} for ${getPetName(appointment.petId)}",
      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
      snackPosition: SnackPosition.TOP,
    );
  }

  void _setupFallbackPolling({int interval = 30}) {
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer.periodic(Duration(seconds: interval), (timer) {
      if (!isRealTimeConnected.value) {
        print("Fallback polling: refreshing appointments...");
        fetchClinicAppointments();
      }
    });
  }

  Future<void> fetchClinicAppointments() async {
    if (clinicData.value?.documentId == null) return;

    try {
      final result = await authRepository.getClinicAppointments(clinicData.value!.documentId!);
      appointments.assignAll(result);
      await _fetchRelatedData();
      updateFilteredAppointments();
    } catch (e) {
      Get.snackbar("Error", "Failed to load appointments: $e");
    }
  }

  Future<void> _fetchRelatedData() async {
    for (var appointment in appointments) {
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

  void updateFilteredAppointments() {
    List<Appointment> filtered = appointments.toList();

    // Filter by tab/status
    switch (selectedTab.value) {
      case 'today':
        // Show all appointments for today (pending, accepted, in_progress)
        filtered = filtered.where((appointment) => appointment.isToday).toList();
        break;
      case 'pending':
        filtered = filtered.where((a) => a.status == 'pending').toList();
        break;
      case 'scheduled':
        // Only show accepted appointments that are NOT today
        filtered = filtered.where((a) => a.status == 'accepted' && !a.isToday).toList();
        break;
      case 'in_progress':
        filtered = filtered.where((a) => a.status == 'in_progress').toList();
        break;
      case 'completed':
        filtered = filtered.where((a) => a.status == 'completed').toList();
        break;
      case 'cancelled':
        filtered = filtered.where((a) => a.status == 'cancelled').toList();
        break;
      case 'declined':
        filtered = filtered.where((a) => a.status == 'declined').toList();
        break;
    }

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((appointment) {
        final petName = getPetName(appointment.petId).toLowerCase();
        final ownerName = getOwnerName(appointment.userId).toLowerCase();
        final service = appointment.service.toLowerCase();
        final query = searchQuery.value.toLowerCase();
        
        return petName.contains(query) || 
               ownerName.contains(query) || 
               service.contains(query);
      }).toList();
    }

    // Sort by date (most recent first)
    filtered.sort((a, b) => b.dateTime.compareTo(a.dateTime));

    filteredAppointments.assignAll(filtered);
  }

  // Helper methods
  String getOwnerName(String userId) => ownersCache[userId]?['name'] ?? 'Unknown Owner';
  String getPetName(String petId) => petsCache[petId]?.name ?? petId;
  String getPetBreed(String petId) => petsCache[petId]?.breed ?? 'Unknown Breed';
  String getPetType(String petId) => petsCache[petId]?.type ?? 'Unknown Type';
  Pet? getPetForAppointment(String petId) => petsCache[petId];

  // Status-based getters
  List<Appointment> get todayAppointments {
    return appointments.where((appointment) => appointment.isToday).toList();
  }

  List<Appointment> get pending => appointments.where((a) => a.status == 'pending').toList();
  List<Appointment> get scheduled => appointments.where((a) => a.status == 'accepted' && !a.isToday).toList();
  List<Appointment> get inProgress => appointments.where((a) => a.status == 'in_progress').toList();
  List<Appointment> get completed => appointments.where((a) => a.status == 'completed').toList();
  List<Appointment> get cancelled => appointments.where((a) => a.status == 'cancelled').toList();
  List<Appointment> get declined => appointments.where((a) => a.status == 'declined').toList();

  // Statistics
  Map<String, int> get appointmentStats {
    return {
      'total': appointments.length,
      'today': todayAppointments.length,
      'pending': pending.length,
      'scheduled': scheduled.length,
      'in_progress': inProgress.length,
      'completed': completed.length,
      'cancelled': cancelled.length,
      'declined': declined.length,
    };
  }

  // Appointment actions
  Future<void> acceptAppointment(Appointment appointment) async {
    // Check if time slot is available before accepting
    final isAvailable = await checkTimeSlotAvailability(
      appointment.clinicId,
      appointment.dateTime,
      excludeAppointmentId: appointment.documentId,
    );

    if (!isAvailable) {
      Get.snackbar(
        "Time Slot Unavailable",
        "This time slot is already booked. Please ask the client to choose a different time.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    await _updateAppointmentStatus(appointment, 'accepted');
    Get.snackbar("Success", "Appointment accepted! Time slot has been reserved.");
  }

  Future<void> declineAppointment(Appointment appointment) async {
    await _updateAppointmentStatus(appointment, 'declined');
    Get.snackbar("Success", "Appointment declined. Patient will be notified.");
  }

  Future<void> checkInPatient(Appointment appointment) async {
    if (!appointment.isToday) {
      Get.snackbar("Error", "Cannot check in patient for future appointments");
      return;
    }

    final updatedAppointment = appointment.copyWith(
      status: 'in_progress',
      checkedInAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await updateFullAppointment(updatedAppointment);
    Get.snackbar("Success", "${getPetName(appointment.petId)} has been checked in!");
  }

  Future<void> startService(Appointment appointment) async {
    final updatedAppointment = appointment.copyWith(
      serviceStartedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    await updateFullAppointment(updatedAppointment);
    Get.snackbar("Info", "Service started for ${getPetName(appointment.petId)}");
  }

  Future<void> completeServiceWithRecord({
    required Appointment appointment,
    String? diagnosis,
    String? treatment,
    String? prescription,
    String? vetNotes,
    Map<String, dynamic>? vitals,
    String? followUpInstructions,
    DateTime? nextAppointmentDate,
  }) async {
    final updatedAppointment = appointment.copyWith(
      status: 'completed',
      serviceCompletedAt: DateTime.now(),
      diagnosis: diagnosis ?? 'N/A',
      treatment: treatment ?? 'N/A',
      prescription: prescription ?? 'N/A',
      vetNotes: vetNotes ?? 'N/A',
      vitals: vitals,
      followUpInstructions: followUpInstructions,
      nextAppointmentDate: nextAppointmentDate,
      updatedAt: DateTime.now(),
    );

    await updateFullAppointment(updatedAppointment);

    // Create medical record
    final user = await authRepository.getUser();
    if (user != null) {
      final medicalRecord = MedicalRecord.fromAppointment(updatedAppointment, user.$id);
      await authRepository.createMedicalRecord(medicalRecord);
    }

    Get.snackbar("Success", "Service completed and medical record created!");
  }

  Future<void> markNoShow(Appointment appointment) async {
    if (!appointment.isToday) {
      Get.snackbar("Error", "Cannot mark as no-show for future appointments");
      return;
    }

    await _updateAppointmentStatus(appointment, 'no_show');
    Get.snackbar("Info", "Appointment marked as No Show");
  }

  // Check if a time slot is available
  Future<bool> checkTimeSlotAvailability(
    String clinicId,
    DateTime dateTime, {
    String? excludeAppointmentId,
  }) async {
    try {
      final allAppointments = await authRepository.getClinicAppointments(clinicId);
      
      // Check for accepted appointments at the same date/time
      final conflictingAppointments = allAppointments.where((apt) {
        // Exclude the current appointment if checking for update
        if (excludeAppointmentId != null && apt.documentId == excludeAppointmentId) {
          return false;
        }
        
        // Only check accepted appointments
        if (apt.status != 'accepted') return false;
        
        // Check if same date and time (within 30-minute window)
        final timeDifference = apt.dateTime.difference(dateTime).inMinutes.abs();
        return timeDifference < 30; // 30-minute slots
      }).toList();

      return conflictingAppointments.isEmpty;
    } catch (e) {
      print("Error checking time slot availability: $e");
      return true; // Default to available if error
    }
  }

  Future<void> updateFullAppointment(Appointment appointment) async {
    if (appointment.documentId == null) {
      Get.snackbar("Error", "Cannot update appointment: Missing document ID");
      return;
    }

    try {
      await authRepository.updateFullAppointment(appointment.documentId!, appointment.toMap());
      
      final index = appointments.indexWhere((a) => a.documentId == appointment.documentId);
      if (index != -1) {
        appointments[index] = appointment;
        appointments.refresh();
        updateFilteredAppointments();
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to update appointment: $e");
    }
  }

  Future<void> _updateAppointmentStatus(Appointment appointment, String status) async {
    if (appointment.documentId == null) {
      Get.snackbar("Error", "Cannot update appointment: Missing document ID");
      return;
    }

    try {
      await authRepository.updateAppointmentStatus(appointment.documentId!, status);
      
      final index = appointments.indexWhere((a) => a.documentId == appointment.documentId);
      if (index != -1) {
        appointments[index] = appointment.copyWith(
          status: status,
          updatedAt: DateTime.now(),
        );
        appointments.refresh();
        updateFilteredAppointments();
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to update appointment: $e");
    }
  }

  Future<void> refreshAppointments() async {
    await fetchClinicAppointments();
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  void setSelectedTab(String tab) {
    selectedTab.value = tab;
  }

  void setDateFilter(DateTime date) {
    selectedDateFilter.value = date;
  }

  String get connectionStatus => isRealTimeConnected.value ? "Live" : "Polling";
}
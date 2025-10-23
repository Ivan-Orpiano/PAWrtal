import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/medical_record_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/models/user_model.dart';
import 'package:capstone_app/data/models/vaccination_model.dart';
import 'package:capstone_app/data/models/notification_model.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

import 'appointment_view_mode.dart';

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

  var viewMode = AppointmentViewMode.today.obs;
  var selectedCalendarDate = Rxn<DateTime>();

  var pendingVitals = <String, Map<String, dynamic>>{}.obs;

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

      // Get user role from storage
      final storage = GetStorage();
      final userRole = storage.read('role') as String?;

      String? clinicId;

      if (userRole == 'staff') {
        // Staff: Get clinicId from storage
        clinicId = storage.read('clinicId') as String?;
        print(
            '>>> APPOINTMENTS: Staff mode - using stored clinicId: $clinicId');
      } else {
        // Admin: Get clinic by admin ID
        print('>>> APPOINTMENTS: Admin mode - looking up clinic');
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
          await fetchClinicAppointments();
          await _initializeRealTimeUpdates();
          print(
              '>>> APPOINTMENTS: Clinic loaded: ${clinicData.value!.clinicName}');
        }
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
    final existingIndex =
        appointments.indexWhere((a) => a.documentId == appointment.documentId);

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
    final index =
        appointments.indexWhere((a) => a.documentId == appointment.documentId);
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
      final result = await authRepository
          .getClinicAppointments(clinicData.value!.documentId!);
      appointments.assignAll(result);
      await _fetchRelatedData();
      updateFilteredAppointments();
    } catch (e) {
      Get.snackbar("Error", "Failed to load appointments: $e");
    }
  }

  Future<void> _fetchOwnerData(String userId) async {
    if (!ownersCache.containsKey(userId)) {
      try {
        final ownerDoc = await authRepository.getUserById(userId);
        if (ownerDoc != null) {
          // Store the raw data instead of trying to create a User object
          ownersCache[userId] = {
            'name': ownerDoc.data['name'] ?? 'User #${userId.substring(0, 6)}',
            'email': ownerDoc.data['email'] ?? 'N/A',
            'phone': ownerDoc.data['phone'] ?? 'N/A',
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
      // Fetch pet data
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

          // If not found by name and ID is valid, try fetching by ID
          if (_isValidDocumentId(appointment.petId)) {
            final petDoc = await authRepository.getPetById(appointment.petId);
            if (petDoc != null) {
              final pet = Pet.fromMap(petDoc.data);
              pet.documentId = petDoc.$id;
              petsCache[appointment.petId] = pet;
              continue;
            }
          }

          // If pet not found, add fallback data
          print("Creating fallback pet data for ID/Name: ${appointment.petId}");
          petsCache[appointment.petId] = Pet(
            petId: appointment.petId,
            userId: appointment.userId,
            name: appointment.petId.length <= 10
                ? appointment.petId
                : 'Unknown Pet',
            type: 'Unknown',
            breed: 'Unknown',
          );
        } catch (e) {
          print("Error fetching pet ${appointment.petId}: $e");
          petsCache[appointment.petId] = Pet(
            petId: appointment.petId,
            userId: appointment.userId,
            name: appointment.petId.length <= 10
                ? appointment.petId
                : 'Unknown Pet',
            type: 'Unknown',
            breed: 'Unknown',
          );
        }
      }

      // Fetch owner data
      if (!ownersCache.containsKey(appointment.userId)) {
        await _fetchOwnerData(appointment.userId);
      }
    }
  }

  bool _isValidDocumentId(String id) {
    if (id.isEmpty || id.length > 36) return false;
    // Updated regex to handle more ID formats while still being secure
    final validIdRegex = RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_.-]*$');
    return validIdRegex.hasMatch(id);
  }

  void updateFilteredAppointments() {
    List<Appointment> filtered = appointments.toList();

    // If a calendar date is selected, filter by that date first
    if (selectedCalendarDate.value != null) {
      final selectedDate = selectedCalendarDate.value!;
      filtered = filtered.where((appointment) {
        final appointmentDate = appointment.dateTime;
        return appointmentDate.year == selectedDate.year &&
            appointmentDate.month == selectedDate.month &&
            appointmentDate.day == selectedDate.day;
      }).toList();
    } else {
      // Otherwise filter by view mode for tabs that should respect it
      // Pending and Scheduled always show all
      if (selectedTab.value != 'pending' && selectedTab.value != 'scheduled') {
        filtered = _getFilteredAppointmentsForStats();
      }
    }

    switch (selectedTab.value) {
      case 'today':
        filtered =
            filtered.where((appointment) => appointment.isToday).toList();
        break;
      case 'pending':
        filtered = filtered.where((a) => a.status == 'pending').toList();
        break;
      case 'scheduled':
        filtered = filtered
            .where((a) => a.status == 'accepted' && !a.isToday)
            .toList();
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

    filtered.sort((a, b) => b.dateTime.compareTo(a.dateTime));
    filteredAppointments.assignAll(filtered);
  }

  // Helper methods
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
    if (pet != null && pet.name.isNotEmpty) {
      return pet.name;
    }
    // Use the ID as name if it's short enough, otherwise show Unknown Pet
    return petId.length <= 10 ? petId : 'Unknown Pet';
  }

  String getPetBreed(String petId) {
    return petsCache[petId]?.breed ?? 'Not Available';
  }

  String getPetType(String petId) {
    return petsCache[petId]?.type ?? 'Not Available';
  }

  Pet? getPetForAppointment(String petId) => petsCache[petId];

  // Status-based getters
  List<Appointment> get todayAppointments {
    return appointments.where((appointment) => appointment.isToday).toList();
  }

  List<Appointment> get pending =>
      appointments.where((a) => a.status == 'pending').toList();
  List<Appointment> get scheduled =>
      appointments.where((a) => a.status == 'accepted' && !a.isToday).toList();
  List<Appointment> get inProgress =>
      appointments.where((a) => a.status == 'in_progress').toList();
  List<Appointment> get completed =>
      appointments.where((a) => a.status == 'completed').toList();
  List<Appointment> get cancelled =>
      appointments.where((a) => a.status == 'cancelled').toList();
  List<Appointment> get declined =>
      appointments.where((a) => a.status == 'declined').toList();

  // Statistics
  Map<String, int> get appointmentStats {
    List<Appointment> filteredForStats = _getFilteredAppointmentsForStats();

    return {
      'total': filteredForStats.length,
      'today': todayAppointments.length,
      'pending': filteredForStats.where((a) => a.status == 'pending').length,
      'scheduled': filteredForStats
          .where((a) => a.status == 'accepted' && !a.isToday)
          .length,
      'in_progress':
          filteredForStats.where((a) => a.status == 'in_progress').length,
      'completed':
          filteredForStats.where((a) => a.status == 'completed').length,
      'cancelled':
          filteredForStats.where((a) => a.status == 'cancelled').length,
      'declined': filteredForStats.where((a) => a.status == 'declined').length,
    };
  }

  List<Appointment> _getFilteredAppointmentsForStats() {
    final now = DateTime.now();
    // Get all pending appointments first
    final pendingAppointments =
        appointments.where((a) => a.status == 'pending').toList();

    // Get time-filtered non-pending appointments
    List<Appointment> timeFilteredAppointments;
    switch (viewMode.value) {
      case AppointmentViewMode.today:
        timeFilteredAppointments = appointments
            .where((a) => a.isToday && a.status != 'pending')
            .toList();

      case AppointmentViewMode.thisWeek:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));
        timeFilteredAppointments = appointments.where((a) {
          if (a.status == 'pending') return false;
          final date =
              DateTime(a.dateTime.year, a.dateTime.month, a.dateTime.day);
          return date.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
              date.isBefore(endOfWeek.add(const Duration(days: 1)));
        }).toList();

      case AppointmentViewMode.thisMonth:
        final startOfMonth = DateTime(now.year, now.month, 1);
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        timeFilteredAppointments = appointments.where((a) {
          if (a.status == 'pending') return false;
          final date =
              DateTime(a.dateTime.year, a.dateTime.month, a.dateTime.day);
          return date.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
              date.isBefore(endOfMonth.add(const Duration(days: 1)));
        }).toList();

      case AppointmentViewMode.allTime:
        timeFilteredAppointments =
            appointments.where((a) => a.status != 'pending').toList();
    }

    // Combine pending appointments with time-filtered appointments
    return [...pendingAppointments, ...timeFilteredAppointments];
  }

  void setViewMode(AppointmentViewMode mode) {
    viewMode.value = mode;
    selectedCalendarDate.value =
        null; // Clear calendar selection when changing view mode
    updateFilteredAppointments();
  }

  void setCalendarDate(DateTime? date) {
    selectedCalendarDate.value = date;
    if (date != null) {
      viewMode.value = AppointmentViewMode
          .today; // Switch to daily view when selecting from calendar
    }
    updateFilteredAppointments();
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

    try {
      final notification = AppNotification.appointmentAccepted(
        userId: appointment.userId,
        appointmentId: appointment.documentId!,
        clinicId: appointment.clinicId,
        clinicName: clinicData.value?.clinicName ?? 'Clinic',
        petName: getPetName(appointment.petId),
        service: appointment.service,
        appointmentDateTime: appointment.dateTime,
      );

      await authRepository.createNotification(notification);
      print('>>> Acceptance notification sent to user');
    } catch (e) {
      print('>>> Error creating notification: $e');
    }

    await _sendAppointmentStatusNotification(appointment, 'accepted');

    Get.snackbar(
      "Success",
      "Appointment accepted! Time slot has been reserved.",
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  }

  Future<void> declineAppointment(Appointment appointment, String notes) async {
    if (appointment.documentId == null) return;

    try {
      final updatedAppointment = appointment.copyWith(
        status: 'declined',
        notes: notes,
        updatedAt: DateTime.now(),
      );

      await updateFullAppointment(updatedAppointment);

      try {
        final notification = AppNotification.appointmentDeclined(
          userId: appointment.userId,
          appointmentId: appointment.documentId!,
          clinicId: appointment.clinicId,
          clinicName: clinicData.value?.clinicName ?? 'Clinic',
          petName: getPetName(appointment.petId),
          declineReason: notes,
        );

        await authRepository.createNotification(notification);
        print('>>> Decline notification sent to user');
      } catch (e) {
        print('>>> Error creating notification: $e');
      }

      await _sendAppointmentStatusNotification(
        updatedAppointment,
        'declined',
        declineReason: notes,
      );

      Get.snackbar(
        "Success",
        "Appointment declined. Patient will be notified.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar("Error", "Failed to decline appointment: $e");
    }
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

    await _sendAppointmentStatusNotification(updatedAppointment, 'in_progress');

    Get.snackbar(
      "Success",
      "${getPetName(appointment.petId)} has been checked in!",
      backgroundColor: Colors.blue,
      colorText: Colors.white,
    );
  }

  Future<void> startService(Appointment appointment) async {
    final updatedAppointment = appointment.copyWith(
      serviceStartedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await updateFullAppointment(updatedAppointment);
    Get.snackbar(
        "Info", "Service started for ${getPetName(appointment.petId)}");
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
    try {
      print('>>> ============================================');
      print('>>> CONTROLLER: Starting service completion');
      print('>>> ============================================');
      print('>>> Appointment ID: ${appointment.documentId}');
      print('>>> Pet ID: ${appointment.petId}');
      print('>>> Service: ${appointment.service}');

      // CRITICAL: Check if we have pending vitals stored locally
      Map<String, dynamic>? finalVitals = vitals;
      if (pendingVitals.containsKey(appointment.documentId)) {
        print('>>> Found pending vitals in local storage!');
        finalVitals = pendingVitals[appointment.documentId];
        print('>>> Using locally stored vitals: $finalVitals');
      } else if (vitals != null) {
        print('>>> Using vitals passed as parameter: $vitals');
      } else {
        print('>>> No vitals data available');
      }

      print('>>> Final vitals to be saved: $finalVitals');
      print('>>> ============================================');

      // Ensure we have minimum required data
      final finalDiagnosis = diagnosis?.trim().isNotEmpty == true
          ? diagnosis!.trim()
          : 'Service completed - ${appointment.service}';

      final finalTreatment = treatment?.trim().isNotEmpty == true
          ? treatment!.trim()
          : appointment.service;

      // CRITICAL: Extract and validate individual vital values
      double? temperature;
      double? weight;
      String? bloodPressure;
      int? heartRate;

      if (finalVitals != null && finalVitals.isNotEmpty) {
        print('>>> Processing vitals data...');

        // Extract temperature
        if (finalVitals.containsKey('temperature') &&
            finalVitals['temperature'] != null) {
          try {
            final tempValue = finalVitals['temperature'];
            temperature = tempValue is double
                ? tempValue
                : double.parse(tempValue.toString());
            print('>>> ✓ Temperature: $temperature°C');
          } catch (e) {
            print('>>> ✗ Error parsing temperature: $e');
          }
        }

        // Extract weight
        if (finalVitals.containsKey('weight') &&
            finalVitals['weight'] != null) {
          try {
            final weightValue = finalVitals['weight'];
            weight = weightValue is double
                ? weightValue
                : double.parse(weightValue.toString());
            print('>>> ✓ Weight: ${weight}kg');
          } catch (e) {
            print('>>> ✗ Error parsing weight: $e');
          }
        }

        // Extract blood pressure
        if (finalVitals.containsKey('bloodPressure') &&
            finalVitals['bloodPressure'] != null) {
          bloodPressure = finalVitals['bloodPressure'].toString();
          print('>>> ✓ Blood Pressure: $bloodPressure');
        }

        // Extract heart rate
        if (finalVitals.containsKey('heartRate') &&
            finalVitals['heartRate'] != null) {
          try {
            final hrValue = finalVitals['heartRate'];
            heartRate =
                hrValue is int ? hrValue : int.parse(hrValue.toString());
            print('>>> ✓ Heart Rate: $heartRate bpm');
          } catch (e) {
            print('>>> ✗ Error parsing heart rate: $e');
          }
        }

        print('>>> ============================================');
        print('>>> EXTRACTED VITALS SUMMARY:');
        print('>>>   Temperature: $temperature');
        print('>>>   Weight: $weight');
        print('>>>   Blood Pressure: $bloodPressure');
        print('>>>   Heart Rate: $heartRate');
        print('>>> ============================================');
      } else {
        print('>>> ⚠️ No vitals data provided');
      }

      // STEP 1: Update appointment with ALL data including vitals
      print('>>> STEP 1: Updating appointment...');
      final updatedAppointment = appointment.copyWith(
        status: 'completed',
        serviceCompletedAt: DateTime.now(),
        diagnosis: finalDiagnosis,
        treatment: finalTreatment,
        prescription:
            prescription?.trim().isNotEmpty == true ? prescription : null,
        vetNotes: vetNotes?.trim().isNotEmpty == true ? vetNotes : null,
        vitals: finalVitals, // Store the complete vitals map
        followUpInstructions: followUpInstructions,
        nextAppointmentDate: nextAppointmentDate,
        updatedAt: DateTime.now(),
      );

      print(
          '>>> Appointment vitals before update: ${updatedAppointment.vitals}');
      await updateFullAppointment(updatedAppointment);
      print('>>> ✓ Appointment updated successfully');
      print('>>> ============================================');

      // STEP 2: Create medical record with individual vital fields
      print('>>> STEP 2: Creating medical record...');
      final user = await authRepository.getUser();
      if (user != null) {
        try {
          final medicalRecord = MedicalRecord(
            petId: appointment.petId,
            clinicId: appointment.clinicId,
            vetId: user.$id,
            appointmentId: appointment.documentId!,
            visitDate: appointment.serviceCompletedAt ?? DateTime.now(),
            service: appointment.service,
            diagnosis: finalDiagnosis,
            treatment: finalTreatment,
            prescription:
                prescription?.trim().isNotEmpty == true ? prescription : null,
            notes: vetNotes?.trim().isNotEmpty == true ? vetNotes : null,
            // CRITICAL: Pass individual vital fields
            temperature: temperature,
            weight: weight,
            bloodPressure: bloodPressure,
            heartRate: heartRate,
            vitals: finalVitals, // Also keep the full vitals map
            attachments: appointment.attachments,
          );

          print('>>> Medical record vitals before creation:');
          print('>>>   - temperature: ${medicalRecord.temperature}');
          print('>>>   - weight: ${medicalRecord.weight}');
          print('>>>   - bloodPressure: ${medicalRecord.bloodPressure}');
          print('>>>   - heartRate: ${medicalRecord.heartRate}');
          print('>>>   - vitals map: ${medicalRecord.vitals}');
          print('>>> ============================================');

          await authRepository.createMedicalRecord(medicalRecord);
          print('>>> ✓ Medical record created successfully');

          // CRITICAL: Clear pending vitals after successful save
          if (pendingVitals.containsKey(appointment.documentId)) {
            pendingVitals.remove(appointment.documentId);
            print('>>> ✓ Cleared pending vitals from local storage');
          }

          print('>>> ============================================');
        } catch (e) {
          print('>>> ✗ ERROR: Failed to create medical record: $e');
          print('>>> ============================================');
          Get.snackbar(
            "Warning",
            "Appointment completed but medical record creation failed: $e",
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            duration: const Duration(seconds: 5),
          );
          return;
        }
      } else {
        print('>>> ✗ ERROR: Cannot create medical record - user not found');
        Get.snackbar(
          "Warning",
          "Appointment completed but medical record requires authentication.",
          backgroundColor: Colors.orange,
          colorText: Colors.white,
        );
        return;
      }

      // STEP 3: Create notification
      print('>>> STEP 3: Creating notification...');
      try {
        final notification = AppNotification.appointmentCompleted(
          userId: appointment.userId,
          appointmentId: appointment.documentId!,
          clinicId: appointment.clinicId,
          clinicName: clinicData.value?.clinicName ?? 'Clinic',
          petName: getPetName(appointment.petId),
        );

        await authRepository.createNotification(notification);
        print('>>> ✓ Completion notification sent to user');
      } catch (e) {
        print('>>> ⚠️ Error creating notification: $e');
      }

      await _sendAppointmentStatusNotification(updatedAppointment, 'completed');

      print('>>> ============================================');
      print('>>> SERVICE COMPLETION SUCCESSFUL');
      print('>>> ============================================');

      Get.snackbar(
        "Success",
        finalVitals != null
            ? "Service completed and medical record created with vitals!"
            : "Service completed and medical record created!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      print('>>> ============================================');
      print('>>> ✗ ERROR in completeServiceWithRecord: $e');
      print('>>> Stack trace: ${StackTrace.current}');
      print('>>> ============================================');
      Get.snackbar("Error", "Failed to complete service: $e");
      rethrow;
    }
  }

  // NEW: Check if appointment has pending vitals
  bool hasPendingVitals(String appointmentId) {
    return pendingVitals.containsKey(appointmentId);
  }

  // NEW: Get pending vitals for display
  Map<String, dynamic>? getPendingVitals(String appointmentId) {
    return pendingVitals[appointmentId];
  }

  // NEW: Clear pending vitals (if user cancels)
  void clearPendingVitals(String appointmentId) {
    pendingVitals.remove(appointmentId);
    print('>>> Cleared pending vitals for appointment: $appointmentId');
  }

  Future<void> recordVitalsLocally(
    Appointment appointment,
    Map<String, dynamic> vitals,
  ) async {
    try {
      print('>>> ============================================');
      print('>>> RECORDING VITALS LOCALLY (NOT SAVED YET)');
      print('>>> Appointment ID: ${appointment.documentId}');
      print('>>> Vitals: $vitals');
      print('>>> ============================================');

      // Store vitals in memory with appointment ID as key
      pendingVitals[appointment.documentId!] = vitals;

      print(
          '>>> Vitals stored locally for appointment: ${appointment.documentId}');
      print('>>> Will be saved when service is completed');
      print('>>> ============================================');

      Get.snackbar(
        "Vitals Recorded",
        "Vital signs recorded. They will be saved when you complete the service.",
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      print('>>> Error recording vitals locally: $e');
      Get.snackbar("Error", "Failed to record vitals: $e");
    }
  }

  Future<void> markNoShow(Appointment appointment) async {
    // Check if appointment is in the past
    if (appointment.dateTime.isAfter(DateTime.now())) {
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
      final allAppointments =
          await authRepository.getClinicAppointments(clinicId);

      // Check for accepted appointments at the same date/time
      final conflictingAppointments = allAppointments.where((apt) {
        // Exclude the current appointment if checking for update
        if (excludeAppointmentId != null &&
            apt.documentId == excludeAppointmentId) {
          return false;
        }

        // Only check accepted appointments
        if (apt.status != 'accepted') return false;

        // Check if same date and time (within 30-minute window)
        final timeDifference =
            apt.dateTime.difference(dateTime).inMinutes.abs();
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
      await authRepository.updateFullAppointment(
          appointment.documentId!, appointment.toMap());

      final index = appointments
          .indexWhere((a) => a.documentId == appointment.documentId);
      if (index != -1) {
        appointments[index] = appointment;
        appointments.refresh();
        updateFilteredAppointments();
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to update appointment: $e");
    }
  }

  Future<void> _updateAppointmentStatus(
      Appointment appointment, String status) async {
    if (appointment.documentId == null) {
      Get.snackbar("Error", "Cannot update appointment: Missing document ID");
      return;
    }

    try {
      await authRepository.updateAppointmentStatus(
          appointment.documentId!, status);

      final index = appointments
          .indexWhere((a) => a.documentId == appointment.documentId);
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

  // ============= VACCINATION-SPECIFIC METHODS =============

  /// Check if a service is a vaccination service
  bool isVaccinationService(String serviceName) {
    final vaccinationKeywords = [
      'vaccination',
      'vaccine',
      'immunization',
      'rabies',
      'dhpp',
      'bordetella',
      'lepto',
      'lyme',
      'influenza',
      'shot',
    ];

    final lowerService = serviceName.toLowerCase();
    return vaccinationKeywords.any((keyword) => lowerService.contains(keyword));
  }

  /// Get veterinarian name from current user
  String getVeterinarianName() {
    try {
      final storage = GetStorage();
      final userName = storage.read('userName') as String?;
      return userName ?? 'Dr. Veterinarian';
    } catch (e) {
      print('Error getting vet name: $e');
      return 'Dr. Veterinarian';
    }
  }

  /// Complete a vaccination service with both vaccination and medical records
  Future<void> completeVaccinationService({
    required Appointment appointment,
    required Map<String, dynamic> vaccinationData,
    String? vetNotes,
  }) async {
    try {
      print('>>> Starting vaccination service completion...');

      // Step 1: Update appointment status
      final updatedAppointment = appointment.copyWith(
        status: 'completed',
        serviceCompletedAt: DateTime.now(),
        diagnosis: 'Vaccination: ${vaccinationData['vaccineType']}',
        treatment: 'Administered ${vaccinationData['vaccineName']}',
        prescription: vaccinationData['batchNumber'] != null
            ? 'Batch: ${vaccinationData['batchNumber']}'
            : null,
        vetNotes: vetNotes ?? 'Vaccination completed successfully',
        updatedAt: DateTime.now(),
      );

      await updateFullAppointment(updatedAppointment);
      print('>>> Appointment updated to completed');

      // Step 2: Create medical record
      final user = await authRepository.getUser();
      if (user != null) {
        final medicalRecord =
            MedicalRecord.fromAppointment(updatedAppointment, user.$id);
        await authRepository.createMedicalRecord(medicalRecord);
        print('>>> Medical record created');
      }

      // Step 3: Create vaccination record
      final vaccination = Vaccination(
        petId: appointment.petId,
        clinicId: appointment.clinicId,
        vaccineType: vaccinationData['vaccineType'],
        vaccineName: vaccinationData['vaccineName'],
        dateGiven: appointment.serviceCompletedAt ?? DateTime.now(),
        nextDueDate: vaccinationData['nextDueDate'],
        veterinarianName: vaccinationData['veterinarianName'],
        veterinarianId: user?.$id,
        batchNumber: vaccinationData['batchNumber'],
        manufacturer: vaccinationData['manufacturer'],
        notes: vaccinationData['notes'],
        isBooster: vaccinationData['isBooster'] ?? false,
      );

      await authRepository.createVaccination(vaccination);
      print('>>> Vaccination record created');

      Get.snackbar(
        "Success",
        "Vaccination completed! Records created for ${getPetName(appointment.petId)}",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      print('>>> Error completing vaccination service: $e');
      Get.snackbar(
        "Error",
        "Failed to complete vaccination: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      rethrow;
    }
  }

  // ============= DIAGNOSTIC METHOD =============

  /// Check for appointments with missing medical records
  Future<void> diagnoseMissingMedicalRecords() async {
    try {
      print('>>> ============================================');
      print('>>> DIAGNOSING MISSING MEDICAL RECORDS');
      print('>>> ============================================');

      final completedAppointments =
          appointments.where((apt) => apt.status == 'completed').toList();

      print(
          '>>> Total completed appointments: ${completedAppointments.length}');

      int missingRecords = 0;
      int emptyDiagnosis = 0;
      int emptyTreatment = 0;

      for (var apt in completedAppointments) {
        bool hasMissingData = false;

        if (apt.diagnosis == null || apt.diagnosis!.isEmpty) {
          emptyDiagnosis++;
          hasMissingData = true;
        }

        if (apt.treatment == null || apt.treatment!.isEmpty) {
          emptyTreatment++;
          hasMissingData = true;
        }

        if (hasMissingData) {
          missingRecords++;
          print('>>> Missing data in appointment: ${apt.documentId}');
          print('>>>   - Pet: ${getPetName(apt.petId)}');
          print('>>>   - Service: ${apt.service}');
          print('>>>   - Completed: ${apt.serviceCompletedAt}');
          print('>>>   - Diagnosis: ${apt.diagnosis ?? "EMPTY"}');
          print('>>>   - Treatment: ${apt.treatment ?? "EMPTY"}');
        }
      }

      print('>>> ============================================');
      print('>>> DIAGNOSIS COMPLETE');
      print('>>> Appointments with missing data: $missingRecords');
      print('>>> Missing diagnosis: $emptyDiagnosis');
      print('>>> Missing treatment: $emptyTreatment');
      print('>>> ============================================');

      if (missingRecords > 0) {
        Get.dialog(
          AlertDialog(
            title: const Text('Missing Medical Records Detected'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Found $missingRecords completed appointments with missing or incomplete medical data.'),
                const SizedBox(height: 16),
                Text('• $emptyDiagnosis appointments missing diagnosis'),
                Text('• $emptyTreatment appointments missing treatment'),
                const SizedBox(height: 16),
                const Text(
                  'These appointments were marked as completed but may not have proper medical records.',
                  style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      } else {
        Get.snackbar(
          "Diagnosis Complete",
          "All completed appointments have proper medical data",
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      print('>>> Error diagnosing medical records: $e');
    }
  }

  // Add these methods to WebAppointmentController class

  /// Confirm before accepting appointment (pending -> accepted)
  Future<void> confirmAcceptAppointment(Appointment appointment) async {
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
      await acceptAppointment(appointment);
    }
  }

  /// Confirm before checking in patient (accepted/today -> in_progress)
  Future<void> confirmCheckInPatient(Appointment appointment) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Check In Patient?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are checking in ${getPetName(appointment.petId)}.',
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
                    '${getPetName(appointment.petId)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Service: ${appointment.service}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Owner: ${getOwnerName(appointment.userId)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'The appointment status will change to "In Progress".',
              style: TextStyle(fontSize: 12, color: Colors.blue[700]),
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
              backgroundColor: Colors.blue,
            ),
            child:
                const Text('Check In', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      await checkInPatient(appointment);
    }
  }

  /// Confirm before starting service (in_progress -> service started)
  Future<void> confirmStartService(Appointment appointment) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Start Service?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.purple,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to begin the service.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple[200]!),
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
                    'Time: ${DateFormat('hh:mm a').format(appointment.dateTime)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Service start time will be recorded.',
              style: TextStyle(fontSize: 12, color: Colors.purple[700]),
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
              backgroundColor: Colors.purple,
            ),
            child: const Text('Start Service',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      await startService(appointment);
    }
  }

  /// Confirm before completing service (in_progress -> completed)
  Future<void> confirmCompleteService(Appointment appointment) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Complete Service?',
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
              'You are about to complete this service.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green[200]!),
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
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Medical records will be created.',
                    style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                  ),
                ),
              ],
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
            child:
                const Text('Complete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      // Return true to signal that completion dialog should be shown
      Get.back(result: true);
    }
  }

  /// Confirm before marking as no-show (accepted/today -> no_show)
  Future<void> confirmMarkNoShow(Appointment appointment) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Mark as No Show?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are marking this appointment as No Show.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
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
            Row(
              children: [
                Icon(Icons.warning_outlined, size: 16, color: Colors.red[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This marks the appointment as uncompleted.',
                    style: TextStyle(fontSize: 12, color: Colors.red[700]),
                  ),
                ),
              ],
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
              backgroundColor: Colors.red,
            ),
            child: const Text('Mark No Show',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true) {
      await markNoShow(appointment);
    }
  }

  Future<void> _sendAppointmentStatusNotification(
    Appointment appointment,
    String status, {
    String? declineReason,
  }) async {
    try {
      print('>>> Sending appointment notification');

      // Get user details
      final userDoc = await authRepository.getUserById(appointment.userId);
      if (userDoc == null) {
        print('>>> User not found, skipping notification');
        return;
      }

      final userName = userDoc.data['name'] ?? 'User';
      final userEmail = userDoc.data['email'] ?? '';

      // Get pet name
      final petName = getPetName(appointment.petId);

      // Get clinic name
      final clinicName = clinicData.value?.clinicName ?? 'Unknown Clinic';

      // Check if AppwriteProvider is registered
      if (!Get.isRegistered<AppWriteProvider>()) {
        print('>>> AppwriteProvider not registered, skipping notification');
        return;
      }

      // Use AppwriteProvider to send notifications
      final appwriteProvider = Get.find<AppWriteProvider>();

      await appwriteProvider.notifyAppointmentStatusChange(
        userId: appointment.userId,
        userEmail: userEmail,
        userName: userName,
        status: status,
        petName: petName,
        clinicName: clinicName,
        service: appointment.service,
        appointmentDateTime: appointment.dateTime,
        appointmentId: appointment.documentId!,
        declineReason: declineReason,
      );

      print('>>> Notification sent successfully');
    } catch (e) {
      print('>>> Error sending notification: $e');
      // Don't fail the operation if notification fails
    }
  }
}

import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/medical_record_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/models/conversation_model.dart';
import 'package:capstone_app/data/models/message_model.dart';
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

  // CRITICAL: Store pending vitals locally (in memory, not in appointment)
  var pendingVitals = <String, Map<String, dynamic>>{}.obs;

  var petProfilePictures = <String, String?>{}.obs;

  final RxMap<String, String> petImagesCache = <String, String>{}.obs;

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

      final storage = GetStorage();
      final userRole = storage.read('role') as String?;

      String? clinicId;

      if (userRole == 'staff') {
        clinicId = storage.read('clinicId') as String?;
        print(
            '>>> APPOINTMENTS: Staff mode - using stored clinicId: $clinicId');
      } else {
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
          ownersCache[userId] = {
            'name': ownerDoc.data['name'] ?? 'User #${userId.substring(0, 6)}',
            'email': ownerDoc.data['email'] ?? 'N/A',
            'phone': ownerDoc.data['phone'] ?? 'N/A',
          };
        } else {
          ownersCache[userId] = {
            'name': 'User #${userId.substring(0, 6)}',
            'email': 'N/A',
            'phone': 'N/A',
          };
        }
      } catch (e) {
        print("Error fetching owner $userId: $e");
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
      final petIdentifier = appointment.petId;
      final userId = appointment.userId;

      // CRITICAL: Use composite key to avoid conflicts between different users with same pet names
      final petCacheKey = '${userId}_$petIdentifier';
      final imageCacheKey = '${userId}_$petIdentifier';

      // Only fetch if not already cached
      if (!petsCache.containsKey(petCacheKey) && petIdentifier.isNotEmpty) {
        try {
          print('>>> Fetching pet data for: $petIdentifier (User: $userId)');

          // Fetch pet using the new method that includes userId
          final fetchedPet = await _fetchPetByUserAndId(userId, petIdentifier);

          if (fetchedPet != null) {
            // Cache the pet with composite key
            petsCache[petCacheKey] = fetchedPet;
            print(
                '>>> Pet cached with composite key: $petCacheKey -> ${fetchedPet.name}');

            // Cache profile picture with composite key
            if (fetchedPet.image != null && fetchedPet.image!.isNotEmpty) {
              petProfilePictures[imageCacheKey] = fetchedPet.image;
              print(
                  '>>> Pet profile picture cached: $imageCacheKey -> ${fetchedPet.image}');
            } else {
              petProfilePictures[imageCacheKey] = null;
              print('>>> No profile picture for pet: $imageCacheKey');
            }
          } else {
            // Create fallback pet if not found
            print('>>> Creating fallback pet for: $petIdentifier');
            petsCache[petCacheKey] = Pet(
              petId: petIdentifier,
              userId: userId,
              name: petIdentifier,
              type: 'Unknown',
              breed: 'Unknown',
            );
            petProfilePictures[imageCacheKey] = null;
          }
        } catch (e) {
          print('>>> Error fetching pet $petIdentifier: $e');
          // Create fallback pet on error
          petsCache[petCacheKey] = Pet(
            petId: petIdentifier,
            userId: userId,
            name: petIdentifier,
            type: 'Unknown',
            breed: 'Unknown',
          );
          petProfilePictures[imageCacheKey] = null;
        }
      }

      // Fetch owner data if not cached
      if (!ownersCache.containsKey(userId)) {
        await _fetchOwnerData(userId);
      }
    }

    print('>>> ============================================');
    print('>>> Pets cache summary:');
    print('>>> Total cached pets: ${petsCache.length}');
    for (var entry in petsCache.entries) {
      print('>>>   ${entry.key} -> ${entry.value.name}');
    }
    print('>>> Profile pictures cache: ${petProfilePictures.length}');
    print('>>> ============================================');
  }

  /// NEW HELPER METHOD: Fetch pet by both userId and petId
  Future<Pet?> _fetchPetByUserAndId(String userId, String petIdentifier) async {
    try {
      // Get all pets for this specific user
      final userPets = await authRepository.getUserPets(userId);

      if (userPets.isEmpty) {
        print('>>> No pets found for user: $userId');
        return null;
      }

      // Find the specific pet by petId (document ID, petId field, or name)
      for (var petDoc in userPets) {
        final pet = Pet.fromMap(petDoc.data);
        pet.documentId = petDoc.$id;

        // Match by document ID, petId field, or name (in that order of priority)
        if (petDoc.$id == petIdentifier ||
            pet.petId == petIdentifier ||
            pet.name == petIdentifier) {
          print(
              '>>> ✅ Found pet: ${pet.name} (ID: ${pet.petId}) for user: $userId');
          return pet;
        }
      }

      print('>>> ⚠️ Pet not found in user\'s pets: $petIdentifier');
      return null;
    } catch (e) {
      print('>>> Error fetching pet by user and ID: $e');
      return null;
    }
  }

  void updateFilteredAppointments() {
    List<Appointment> filtered = appointments.toList();

    // Safety check
    if (filtered == null) {
      filtered = [];
    }

    if (selectedCalendarDate.value != null) {
      final selectedDate = selectedCalendarDate.value!;
      filtered = filtered.where((appointment) {
        final appointmentDate = appointment.dateTime;
        return appointmentDate.year == selectedDate.year &&
            appointmentDate.month == selectedDate.month &&
            appointmentDate.day == selectedDate.day;
      }).toList();
    } else {
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

  String getOwnerName(String userId) {
    if (!ownersCache.containsKey(userId)) {
      _fetchOwnerData(userId);
      return 'Loading...';
    }
    return ownersCache[userId]?['name'] ?? 'User #${userId.substring(0, 6)}';
  }

  /// Get pet name using composite key (userId + petId)
  String getPetName(String petId) {
    // Find the appointment to get userId
    final appointment = appointments.firstWhereOrNull(
      (a) => a.petId == petId,
    );

    if (appointment != null) {
      final cacheKey = '${appointment.userId}_$petId';
      final pet = petsCache[cacheKey];

      if (pet != null && pet.name.isNotEmpty) {
        return pet.name;
      }
    }

    // Fallback: trigger fetch if not cached
    if (appointment != null) {
      _fetchRelatedData();
    }

    return petId.isEmpty ? 'Unknown Pet' : petId;
  }

  /// Get pet breed using composite key
  String getPetBreed(String petId) {
    final appointment = appointments.firstWhereOrNull(
      (a) => a.petId == petId,
    );

    if (appointment != null) {
      final cacheKey = '${appointment.userId}_$petId';
      final pet = petsCache[cacheKey];

      if (pet != null) {
        return pet.breed.isNotEmpty ? pet.breed : 'Not Available';
      }
    }

    if (appointment != null) {
      _fetchRelatedData();
    }

    return 'Loading...';
  }

  /// Get pet type using composite key
  String getPetType(String petId) {
    final appointment = appointments.firstWhereOrNull(
      (a) => a.petId == petId,
    );

    if (appointment != null) {
      final cacheKey = '${appointment.userId}_$petId';
      final pet = petsCache[cacheKey];

      if (pet != null) {
        return pet.type.isNotEmpty ? pet.type : 'Not Available';
      }
    }

    if (appointment != null) {
      _fetchRelatedData();
    }

    return 'Loading...';
  }

  Pet? getPetForAppointment(String petId) => petsCache[petId];

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
    final pendingAppointments =
        appointments.where((a) => a.status == 'pending').toList();

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

    return [...pendingAppointments, ...timeFilteredAppointments];
  }

  void setViewMode(AppointmentViewMode mode) {
    viewMode.value = mode;
    selectedCalendarDate.value = null;
    updateFilteredAppointments();
  }

  void setCalendarDate(DateTime? date) {
    selectedCalendarDate.value = date;
    if (date != null) {
      viewMode.value = AppointmentViewMode.today;
    }
    updateFilteredAppointments();
  }

  Future<void> acceptAppointment(Appointment appointment) async {
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

    await _sendAutomatedAppointmentMessage(
      appointment: appointment,
      messageType: 'accepted',
    );

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

      await _sendAutomatedAppointmentMessage(
        appointment: updatedAppointment,
        messageType: 'declined',
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
    required String diagnosis,
    required String treatment,
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

      // Step 1: Update appointment status
      print('>>> Step 1: Updating appointment to completed...');
      final updatedAppointment = appointment.copyWith(
        status: 'completed',
        serviceCompletedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        followUpInstructions: followUpInstructions,
        nextAppointmentDate: nextAppointmentDate,
      );

      await updateFullAppointment(updatedAppointment);
      print('>>> ✅ Appointment updated to completed');

      // Step 2: Create medical record with vitals
      print('>>> Step 2: Creating medical record...');
      final user = await authRepository.getUser();
      if (user != null) {
        // Parse vitals into individual fields
        double? temperature;
        double? weight;
        String? bloodPressure;
        int? heartRate;

        if (finalVitals != null && finalVitals.isNotEmpty) {
          print('>>> Processing vitals data...');

          if (finalVitals.containsKey('temperature') &&
              finalVitals['temperature'] != null) {
            try {
              final tempValue = finalVitals['temperature'];
              temperature = tempValue is double
                  ? tempValue
                  : double.parse(tempValue.toString());
              print('>>> ✓ Temperature: ${temperature}°C');
            } catch (e) {
              print('>>> ✗ Error parsing temperature: $e');
            }
          }

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

          if (finalVitals.containsKey('bloodPressure') &&
              finalVitals['bloodPressure'] != null) {
            bloodPressure = finalVitals['bloodPressure'].toString();
            print('>>> ✓ Blood Pressure: $bloodPressure');
          }

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
        }

        final medicalRecord = MedicalRecord(
          petId: appointment.petId,
          clinicId: appointment.clinicId,
          vetId: user.$id,
          appointmentId: appointment.documentId!,
          visitDate: appointment.serviceCompletedAt ?? DateTime.now(),
          service: appointment.service,
          diagnosis: diagnosis,
          treatment: treatment,
          prescription: prescription,
          notes: vetNotes,
          temperature: temperature,
          weight: weight,
          bloodPressure: bloodPressure,
          heartRate: heartRate,
          attachments: appointment.attachments,
        );

        print('>>> Medical record vitals:');
        print('>>>   - temperature: ${medicalRecord.temperature}');
        print('>>>   - weight: ${medicalRecord.weight}');
        print('>>>   - bloodPressure: ${medicalRecord.bloodPressure}');
        print('>>>   - heartRate: ${medicalRecord.heartRate}');

        await authRepository.createMedicalRecord(medicalRecord);
        print('>>> ✅ Medical record created');

        // Clear pending vitals after successful save
        if (pendingVitals.containsKey(appointment.documentId)) {
          pendingVitals.remove(appointment.documentId);
          print('>>> ✅ Cleared pending vitals from local storage');
        }
      }

      // Step 3: Create notification
      print('>>> Step 3: Creating notification...');
      try {
        final notification = AppNotification.appointmentCompleted(
          userId: appointment.userId,
          appointmentId: appointment.documentId!,
          clinicId: appointment.clinicId,
          clinicName: clinicData.value?.clinicName ?? 'Clinic',
          petName: getPetName(appointment.petId),
        );

        await authRepository.createNotification(notification);
        print('>>> ✅ Completion notification sent to user');
      } catch (e) {
        print('>>> ⚠️ Error creating notification: $e');
      }

      // Step 4: Send status notification
      await _sendAppointmentStatusNotification(updatedAppointment, 'completed');

      // Step 5: Send automated message
      await _sendAutomatedAppointmentMessage(
        appointment: updatedAppointment,
        messageType: 'completed',
      );

      print('>>> ============================================');
      print('>>> SERVICE COMPLETION SUCCESSFUL');
      print('>>> ============================================');

      // Use Future.microtask to ensure we're not in the middle of a build
      Future.microtask(() {
        if (Get.isRegistered<WebAppointmentController>()) {
          Get.snackbar(
            "Success",
            finalVitals != null
                ? "Service completed! Medical record created with vitals for ${getPetName(appointment.petId)}"
                : "Service completed! Medical record created for ${getPetName(appointment.petId)}",
            backgroundColor: Colors.green,
            colorText: Colors.white,
            duration: const Duration(seconds: 4),
          );
        }
      });
    } catch (e) {
      print('>>> ============================================');
      print('>>> ✗ ERROR in completeServiceWithRecord: $e');
      print('>>> Stack trace: ${StackTrace.current}');
      print('>>> ============================================');

      // Use Future.microtask for error snackbar
      Future.microtask(() {
        if (Get.isRegistered<WebAppointmentController>()) {
          Get.snackbar(
            "Error",
            "Failed to complete service: $e",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
        }
      });
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

      // CRITICAL FIX: Check if we're still registered and in valid state
      if (!Get.isRegistered<WebAppointmentController>()) {
        print('>>> Controller not registered, aborting');
        return;
      }

      // Store vitals in memory with appointment ID as key
      pendingVitals[appointment.documentId!] =
          Map<String, dynamic>.from(vitals);

      print(
          '>>> Vitals stored locally for appointment: ${appointment.documentId}');
      print('>>> Will be saved when service is completed');
      print('>>> ============================================');

      // CRITICAL FIX: Schedule snackbar for next frame to avoid state conflicts
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          if (Get.isRegistered<WebAppointmentController>() &&
              Get.context != null) {
            Get.snackbar(
              "Vitals Recorded",
              "Vital signs recorded. They will be saved when you complete the service.",
              backgroundColor: Colors.blue,
              colorText: Colors.white,
              duration: const Duration(seconds: 3),
              snackPosition: SnackPosition.TOP,
              margin: const EdgeInsets.all(16),
            );
          }
        } catch (e) {
          print('>>> Error showing snackbar: $e');
        }
      });
    } catch (e) {
      print('>>> Error recording vitals locally: $e');
      print('>>> Stack trace: ${StackTrace.current}');
    }
  }

  Future<void> markNoShow(Appointment appointment) async {
    // Check if appointment is in the past
    if (appointment.dateTime.isBefore(DateTime.now())) {
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

        //   // Check if same date and time (within 30-minute window)
        //   final timeDifference =
        //       apt.dateTime.difference(dateTime).inMinutes.abs();
        //   return timeDifference != 0;
        // }).toList();

        // Check if appointment time is exactly the same
        return apt.dateTime.isAtSameMomentAs(dateTime);
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

      // Step 1: Update appointment status - ONLY workflow fields
      final updatedAppointment = appointment.copyWith(
        status: 'completed',
        serviceCompletedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await updateFullAppointment(updatedAppointment);
      print('>>> Appointment updated to completed');

      // Step 2: Create medical record with vaccination details
      final user = await authRepository.getUser();
      if (user != null) {
        final medicalRecord = MedicalRecord(
          petId: appointment.petId,
          clinicId: appointment.clinicId,
          vetId: user.$id,
          appointmentId: appointment.documentId!,
          visitDate: appointment.serviceCompletedAt ?? DateTime.now(),
          service: appointment.service,
          diagnosis: 'Vaccination: ${vaccinationData['vaccineType']}',
          treatment: 'Administered ${vaccinationData['vaccineName']}',
          prescription: vaccinationData['batchNumber'] != null
              ? 'Batch: ${vaccinationData['batchNumber']}'
              : null,
          notes: vetNotes ?? 'Vaccination completed successfully',
          temperature: null,
          weight: null,
          bloodPressure: null,
          heartRate: null,
          attachments: appointment.attachments,
        );

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

  // ============= CONFIRMATION METHODS =============

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

  /// Complete a vaccination service with both vaccination and medical records INCLUDING VITALS
  Future<void> completeVaccinationServiceWithVitals({
    required Appointment appointment,
    required Map<String, dynamic> vaccinationData,
    String? vetNotes,
    Map<String, dynamic>? vitals, // ADDED: Vitals parameter
  }) async {
    try {
      print('>>> ============================================');
      print('>>> Starting vaccination service completion WITH VITALS');
      print('>>> Appointment ID: ${appointment.documentId}');
      print('>>> Vitals provided: ${vitals != null}');
      if (vitals != null) {
        print('>>> Vitals data: $vitals');
      }
      print('>>> ============================================');

      // CRITICAL: Extract individual vital values
      double? temperature;
      double? weight;
      String? bloodPressure;
      int? heartRate;

      if (vitals != null && vitals.isNotEmpty) {
        print('>>> Processing vitals data...');

        if (vitals.containsKey('temperature') &&
            vitals['temperature'] != null) {
          try {
            final tempValue = vitals['temperature'];
            temperature = tempValue is double
                ? tempValue
                : double.parse(tempValue.toString());
            print('>>> ✓ Temperature: $temperature°C');
          } catch (e) {
            print('>>> ✗ Error parsing temperature: $e');
          }
        }

        if (vitals.containsKey('weight') && vitals['weight'] != null) {
          try {
            final weightValue = vitals['weight'];
            weight = weightValue is double
                ? weightValue
                : double.parse(weightValue.toString());
            print('>>> ✓ Weight: ${weight}kg');
          } catch (e) {
            print('>>> ✗ Error parsing weight: $e');
          }
        }

        if (vitals.containsKey('bloodPressure') &&
            vitals['bloodPressure'] != null) {
          bloodPressure = vitals['bloodPressure'].toString();
          print('>>> ✓ Blood Pressure: $bloodPressure');
        }

        if (vitals.containsKey('heartRate') && vitals['heartRate'] != null) {
          try {
            final hrValue = vitals['heartRate'];
            heartRate =
                hrValue is int ? hrValue : int.parse(hrValue.toString());
            print('>>> ✓ Heart Rate: $heartRate bpm');
          } catch (e) {
            print('>>> ✗ Error parsing heart rate: $e');
          }
        }
      }

      // Step 1: Update appointment status - ONLY workflow fields
      print('>>> Step 1: Updating appointment to completed...');
      final updatedAppointment = appointment.copyWith(
        status: 'completed',
        serviceCompletedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await updateFullAppointment(updatedAppointment);
      print('>>> ✓ Appointment updated to completed');

      // Step 2: Create medical record with vaccination details AND vitals
      print('>>> Step 2: Creating medical record with vitals...');
      final user = await authRepository.getUser();
      if (user != null) {
        final medicalRecord = MedicalRecord(
          petId: appointment.petId,
          clinicId: appointment.clinicId,
          vetId: user.$id,
          appointmentId: appointment.documentId!,
          visitDate: appointment.serviceCompletedAt ?? DateTime.now(),
          service: appointment.service,
          diagnosis: 'Vaccination: ${vaccinationData['vaccineType']}',
          treatment: 'Administered ${vaccinationData['vaccineName']}',
          prescription: vaccinationData['batchNumber'] != null
              ? 'Batch: ${vaccinationData['batchNumber']}'
              : null,
          notes: vetNotes ?? 'Vaccination completed successfully',
          // CRITICAL: Include individual vital fields
          temperature: temperature,
          weight: weight,
          bloodPressure: bloodPressure,
          heartRate: heartRate,
          attachments: appointment.attachments,
        );

        print('>>> Medical record vitals:');
        print('>>>   - temperature: ${medicalRecord.temperature}');
        print('>>>   - weight: ${medicalRecord.weight}');
        print('>>>   - bloodPressure: ${medicalRecord.bloodPressure}');
        print('>>>   - heartRate: ${medicalRecord.heartRate}');

        await authRepository.createMedicalRecord(medicalRecord);
        print('>>> ✓ Medical record created with vitals');

        // CRITICAL: Clear pending vitals after successful save
        if (pendingVitals.containsKey(appointment.documentId)) {
          pendingVitals.remove(appointment.documentId);
          print('>>> ✓ Cleared pending vitals from local storage');
        }
      }

      // Step 3: Create vaccination record
      print('>>> Step 3: Creating vaccination record...');
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
      print('>>> ✓ Vaccination record created');

      // Step 4: Create notification
      print('>>> Step 4: Creating notification...');
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

      await _sendAutomatedAppointmentMessage(
        appointment: updatedAppointment,
        messageType: 'completed',
      );

      print('>>> ============================================');
      print('>>> VACCINATION COMPLETION SUCCESSFUL');
      print('>>> ============================================');

      Get.snackbar(
        "Success",
        vitals != null
            ? "Vaccination completed! Records created with vitals for ${getPetName(appointment.petId)}"
            : "Vaccination completed! Records created for ${getPetName(appointment.petId)}",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      print('>>> ============================================');
      print('>>> ✗ ERROR completing vaccination service: $e');
      print('>>> Stack trace: ${StackTrace.current}');
      print('>>> ============================================');
      Get.snackbar(
        "Error",
        "Failed to complete vaccination: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      rethrow;
    }
  }

  /// Check if a service is a medical service (requires vitals)
  bool isMedicalService(String serviceName) {
    final medicalKeywords = [
      'checkup',
      'check-up',
      'examination',
      'exam',
      'consultation',
      'diagnosis',
      'treatment',
      'surgery',
      'vaccination',
      'vaccine',
      'immunization',
      'dental',
      'xray',
      'x-ray',
      'ultrasound',
      'blood test',
      'lab test',
      'emergency',
      'medical',
      'health check',
      'wellness',
      'sick visit',
      'follow-up',
      'follow up',
    ];

    final lowerService = serviceName.toLowerCase();
    return medicalKeywords.any((keyword) => lowerService.contains(keyword));
  }

  /// Check if a service is a basic service (grooming, etc.)
  bool isBasicService(String serviceName) {
    final basicKeywords = [
      'grooming',
      'bath',
      'nail trim',
      'nail clipping',
      'haircut',
      'shampoo',
      'brush',
      'ear cleaning',
      'teeth cleaning',
      'boarding',
      'daycare',
    ];

    final lowerService = serviceName.toLowerCase();
    return basicKeywords.any((keyword) => lowerService.contains(keyword));
  }

  /// Get service type for display
  String getServiceType(String serviceName) {
    if (isMedicalService(serviceName)) {
      return 'Medical Service';
    } else if (isBasicService(serviceName)) {
      return 'Basic Service';
    } else {
      return 'General Service';
    }
  }

  /// Get service type icon
  IconData getServiceTypeIcon(String serviceName) {
    if (isMedicalService(serviceName)) {
      return Icons.medical_services;
    } else if (isBasicService(serviceName)) {
      return Icons.content_cut;
    } else {
      return Icons.pets;
    }
  }

  /// Get service type color
  Color getServiceTypeColor(String serviceName) {
    if (isMedicalService(serviceName)) {
      return Colors.red; // Medical = Red
    } else if (isBasicService(serviceName)) {
      return Colors.blue; // Basic = Blue
    } else {
      return Colors.grey; // General = Grey
    }
  }

  /// Check if service should show vitals button
  bool shouldShowVitalsButton(String serviceName) {
    // Only medical services need vitals
    return isMedicalService(serviceName);
  }

  /// Debug method to verify pet fetching
  Future<void> debugPetFetching() async {
    print('>>> ============================================');
    print('>>> DEBUGGING PET FETCHING');
    print('>>> ============================================');

    for (var appointment in appointments.take(5)) {
      print('>>> Appointment: ${appointment.documentId}');
      print('>>>   petId field: ${appointment.petId}');
      print(
          '>>>   Cached pet: ${petsCache[appointment.petId]?.name ?? 'Not cached'}');

      // Try to fetch directly
      try {
        final petDoc = await authRepository.getPetById(appointment.petId);
        if (petDoc != null) {
          print('>>>   ✅ Direct fetch succeeded: ${petDoc.data['name']}');
        } else {
          print('>>>   ❌ Direct fetch returned null');
        }
      } catch (e) {
        print('>>>   ❌ Direct fetch error: $e');
      }

      print('>>> ---');
    }

    print('>>> ============================================');
  }

  /// Get pet profile picture URL using composite key (userId + petId)
  Future<String?> getPetProfilePictureUrl(String petId,
      {String? userId}) async {
    // If userId is provided, use it directly
    if (userId != null) {
      final cacheKey = '${userId}_$petId';

      // Check cache first
      if (petProfilePictures.containsKey(cacheKey)) {
        return petProfilePictures[cacheKey];
      }

      // Fetch and cache
      return await _fetchAndCachePetImage(userId, petId);
    }

    // If userId not provided, find it from appointments
    final appointment = appointments.firstWhereOrNull(
      (a) => a.petId == petId,
    );

    if (appointment != null) {
      final cacheKey = '${appointment.userId}_$petId';

      // Check cache first
      if (petProfilePictures.containsKey(cacheKey)) {
        return petProfilePictures[cacheKey];
      }

      // Fetch and cache
      return await _fetchAndCachePetImage(appointment.userId, petId);
    }

    return null;
  }

  /// HELPER: Fetch and cache pet image
  Future<String?> _fetchAndCachePetImage(String userId, String petId) async {
    try {
      final cacheKey = '${userId}_$petId';

      print('>>> Fetching pet image for: $petId (User: $userId)');

      // Fetch pet using the user-specific method
      final pet = await _fetchPetByUserAndId(userId, petId);

      if (pet != null && pet.image != null && pet.image!.isNotEmpty) {
        // Cache the image URL
        petProfilePictures[cacheKey] = pet.image;
        print('>>> Pet image cached: $cacheKey -> ${pet.image}');
        return pet.image;
      }

      // Cache null result
      petProfilePictures[cacheKey] = null;
      print('>>> No image for pet: $cacheKey');
      return null;
    } catch (e) {
      print('>>> Error fetching pet image: $e');
      final cacheKey = '${userId}_$petId';
      petProfilePictures[cacheKey] = null;
      return null;
    }
  }

  /// Get pet image by userId (already implemented correctly)
  Future<String?> getPetImageByUserId(String petId, String userId) async {
    try {
      // CRITICAL: Use composite key (userId + petId)
      final cacheKey = '${userId}_$petId';

      // Check cache FIRST - return immediately if already cached
      if (petProfilePictures.containsKey(cacheKey)) {
        print('>>> Using cached pet image for: $cacheKey');
        return petProfilePictures[cacheKey];
      }

      print('>>> Fetching pet image for petId: $petId, userId: $userId');

      // Use the new helper method
      final pet = await _fetchPetByUserAndId(userId, petId);

      if (pet == null) {
        print('>>> ⚠️ Pet not found for this user');
        petProfilePictures[cacheKey] = null;
        return null;
      }

      // Cache the pet with composite key
      final petCacheKey = '${userId}_${pet.petId}';
      petsCache[petCacheKey] = pet;

      // Return and cache the image URL
      if (pet.image != null && pet.image!.isNotEmpty) {
        petProfilePictures[cacheKey] = pet.image;
        print('>>> Pet image URL cached with key: $cacheKey -> ${pet.image}');
        return pet.image;
      }

      petProfilePictures[cacheKey] = null;
      return null;
    } catch (e) {
      print('>>> Error fetching pet image by userId: $e');
      final cacheKey = '${userId}_$petId';
      petProfilePictures[cacheKey] = null;
      return null;
    }
  }

  /// Preload pet images for visible appointments
  Future<void> preloadPetImages() async {
    print('>>> Preloading pet images for visible appointments...');

    final visibleAppointments = filteredAppointments.take(20).toList();

    for (var appointment in visibleAppointments) {
      final cacheKey = '${appointment.userId}_${appointment.petId}';

      // Skip if already cached
      if (petProfilePictures.containsKey(cacheKey)) {
        continue;
      }

      // Fetch in background (don't await)
      getPetImageByUserId(appointment.petId, appointment.userId)
          .catchError((e) {
        print('>>> Error preloading image for ${appointment.petId}: $e');
      });
    }

    print(
        '>>> Preload initiated for ${visibleAppointments.length} appointments');
  }

  Future<void> _sendAutomatedAppointmentMessage({
    required Appointment appointment,
    required String messageType, // 'accepted', 'declined', 'completed'
    String? declineReason,
  }) async {
    try {
      print('>>> ============================================');
      print('>>> SENDING AUTOMATED APPOINTMENT MESSAGE');
      print('>>> Type: $messageType');
      print('>>> User ID: ${appointment.userId}');
      print('>>> Clinic ID: ${appointment.clinicId}');
      print('>>> ============================================');

      // Step 1: Get or create conversation
      print('>>> Step 1: Getting or creating conversation...');
      final conversation = await authRepository.getOrCreateConversation(
        appointment.userId,
        appointment.clinicId,
      );

      if (conversation == null) {
        print('>>> ERROR: Failed to get/create conversation');
        // Don't throw error - just log and continue
        // The appointment action already succeeded
        return;
      }

      print('>>> Conversation ready: ${conversation.documentId}');

      // Step 2: Build the automated message based on type
      print('>>> Step 2: Building message text...');
      String messageText;
      final petName = getPetName(appointment.petId);
      final clinicName = clinicData.value?.clinicName ?? 'Our clinic';
      final formattedDate =
          DateFormat('MMMM dd, yyyy').format(appointment.dateTime);
      final formattedTime = DateFormat('hh:mm a').format(appointment.dateTime);

      switch (messageType) {
        case 'accepted':
          messageText = '''
Hello! 🎉

Your appointment for $petName has been ACCEPTED!

📅 Date: $formattedDate
🕐 Time: $formattedTime
🏥 Service: ${appointment.service}

Please arrive 10 minutes early. We look forward to seeing you and $petName!

If you need to make any changes, please let us know as soon as possible.

- $clinicName Team
''';
          break;

        case 'declined':
          messageText = '''
Hello,

We regret to inform you that your appointment for $petName on $formattedDate at $formattedTime could not be confirmed.

${declineReason != null && declineReason.isNotEmpty ? '📝 Reason: $declineReason\n\n' : ''}Please contact us to reschedule or discuss alternative time slots.

We apologize for any inconvenience.

- $clinicName Team
''';
          break;

        case 'completed':
          messageText = '''
Hello! ✅

$petName's appointment has been completed.

📋 Service: ${appointment.service}
📅 Date: $formattedDate

${appointment.followUpInstructions != null && appointment.followUpInstructions!.isNotEmpty ? '💡 Follow-up instructions: ${appointment.followUpInstructions}\n\n' : ''}Thank you for choosing $clinicName. If you have any questions about the visit, please don't hesitate to reach out!

- $clinicName Team
''';
          break;

        default:
          messageText = '''
Hello,

Your appointment for $petName has been updated.

📅 Date: $formattedDate
🕐 Time: $formattedTime
🏥 Service: ${appointment.service}

For more details, please check your appointments.

- $clinicName Team
''';
      }

      print('>>> Message text prepared (${messageText.length} characters)');

      // Step 3: Send the automated message
      // CRITICAL: Use clinic ID as sender (not admin user ID)
      print('>>> Step 3: Sending message...');
      print('>>>   Sender (Clinic) ID: ${appointment.clinicId}');
      print('>>>   Receiver (User) ID: ${appointment.userId}');
      print('>>>   Conversation ID: ${conversation.documentId}');

      final messageData = {
        'conversationId': conversation.documentId!,
        'senderId': appointment.clinicId, // IMPORTANT: Use clinic ID as sender
        'senderType': 'clinic',
        'receiverId': appointment.userId,
        'messageText': messageText,
        'messageType': 'text',
        'timestamp': DateTime.now().toIso8601String(),
        'isRead': false,
        'isDeleted': false,
        'sentAt': DateTime.now().toIso8601String(),
      };

      await authRepository.appWriteProvider.createMessage(messageData);

      print('>>> ✅ Automated message sent successfully!');
      print('>>> ============================================');
    } catch (e) {
      print('>>> ============================================');
      print('>>> ⚠️ ERROR sending automated message: $e');
      print('>>> Stack trace: ${StackTrace.current}');
      print('>>> ============================================');
      // Don't rethrow - the appointment action already succeeded
      // Just log the error
    }
  }

  /// Clear pet profile pictures cache
  void clearPetProfilePicturesCache() {
    petProfilePictures.clear();
  }

  Future<void> refreshPetImages() async {
    print('>>> Refreshing pet images cache...');
    petProfilePictures.clear();
    await _fetchRelatedData();
    print('>>> Pet images cache refreshed');
  }

  Future<void> debugPetData(String appointmentId) async {
    try {
      print('>>> ============================================');
      print('>>> DEBUG: Pet data for appointment: $appointmentId');
      print('>>> ============================================');

      final appointment = appointments.firstWhere(
        (a) => a.documentId == appointmentId,
        orElse: () => throw Exception('Appointment not found'),
      );

      print('>>> Appointment petId: ${appointment.petId}');
      print('>>> Appointment userId: ${appointment.userId}');

      // Fetch user's pets
      final userPets = await authRepository.getUserPets(appointment.userId);
      print('>>> User has ${userPets.length} pets');

      for (var petDoc in userPets) {
        final pet = Pet.fromMap(petDoc.data);
        print('>>> Pet:');
        print('>>>   Document ID: ${petDoc.$id}');
        print('>>>   Pet ID field: ${pet.petId}');
        print('>>>   Name: ${pet.name}');
        print('>>>   Image: ${pet.image}');
        print(
            '>>>   Matches appointment: ${petDoc.$id == appointment.petId || pet.petId == appointment.petId || pet.name == appointment.petId}');
        print('>>> ---');
      }

      // Check cache
      print('>>> Cache status:');
      print(
          '>>>   Pet in petsCache: ${petsCache.containsKey(appointment.petId)}');
      print(
          '>>>   Image in petProfilePictures: ${petProfilePictures.containsKey(appointment.petId)}');
      if (petProfilePictures.containsKey(appointment.petId)) {
        print(
            '>>>   Cached image URL: ${petProfilePictures[appointment.petId]}');
      }

      print('>>> ============================================');
    } catch (e) {
      print('>>> ERROR in debugPetData: $e');
      print('>>> Stack trace: ${StackTrace.current}');
    }
  }

  /// Get medical record by appointment ID
  Future<MedicalRecord?> getMedicalRecordByAppointmentId(
      String appointmentId) async {
    try {
      print('>>> ============================================');
      print(
          '>>> CONTROLLER: Getting medical record for appointment: $appointmentId');
      print('>>> ============================================');

      // Get all medical records for the clinic
      final allRecords = await authRepository
          .getClinicMedicalRecords(clinicData.value!.documentId!);

      // Find the record that matches this appointment ID
      final matchingRecord = allRecords.firstWhereOrNull(
        (record) => record.appointmentId == appointmentId,
      );

      if (matchingRecord != null) {
        print('>>> ✅ Medical record found!');
        print('>>> Record ID: ${matchingRecord.id}');
        print('>>> Service: ${matchingRecord.service}');
        print('>>> Diagnosis: ${matchingRecord.diagnosis}');
        print('>>> Has vitals: ${matchingRecord.hasVitals}');
      } else {
        print('>>> ⚠️ No medical record found for this appointment');
      }

      print('>>> ============================================');
      return matchingRecord;
    } catch (e) {
      print('>>> ============================================');
      print('>>> ❌ ERROR getting medical record: $e');
      print('>>> Stack trace: ${StackTrace.current}');
      print('>>> ============================================');
      return null;
    }
  }

  Future<void> completeNonMedicalService({
    required Appointment appointment,
    String? notes,
  }) async {
    try {
      print('>>> ============================================');
      print('>>> COMPLETING NON-MEDICAL SERVICE');
      print('>>> Appointment ID: ${appointment.documentId}');
      print('>>> Service: ${appointment.service}');
      print('>>> ============================================');

      // Update appointment to completed
      final updatedAppointment = appointment.copyWith(
        status: 'completed',
        serviceCompletedAt: DateTime.now(),
        updatedAt: DateTime.now(),
        notes: notes,
      );

      await updateFullAppointment(updatedAppointment);
      print('>>> ✅ Non-medical service completed');

      // Create notification
      try {
        final notification = AppNotification.appointmentCompleted(
          userId: appointment.userId,
          appointmentId: appointment.documentId!,
          clinicId: appointment.clinicId,
          clinicName: clinicData.value?.clinicName ?? 'Clinic',
          petName: getPetName(appointment.petId),
        );

        await authRepository.createNotification(notification);
        print('>>> ✅ Completion notification sent');
      } catch (e) {
        print('>>> ⚠️ Error creating notification: $e');
      }

      // Send status notification
      await _sendAppointmentStatusNotification(updatedAppointment, 'completed');

      // Send automated message
      await _sendAutomatedAppointmentMessage(
        appointment: updatedAppointment,
        messageType: 'completed',
      );

      print('>>> ============================================');
      print('>>> NON-MEDICAL SERVICE COMPLETION SUCCESSFUL');
      print('>>> ============================================');

      Get.snackbar(
        "Success",
        "Service completed for ${getPetName(appointment.petId)}!",
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } catch (e) {
      print('>>> ============================================');
      print('>>> ❌ ERROR completing non-medical service: $e');
      print('>>> ============================================');
      Get.snackbar(
        "Error",
        "Failed to complete service: $e",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      rethrow;
    }
  }

  Future<bool> isCurrentStaffDoctor() async {
    try {
      final storage = GetStorage();
      final userRole = storage.read('role') as String?;

      if (userRole != 'staff') {
        // Admins can complete all appointments
        return true;
      }

      final staffId = storage.read('staffId') as String?;
      if (staffId == null) return false;

      final staffDoc = await authRepository.getStaffByDocumentId(staffId);
      return staffDoc?.isDoctor ?? false;
    } catch (e) {
      print('>>> Error checking if staff is doctor: $e');
      return false;
    }
  }

  Future<String?> getPetImageUrl(String petId) async {
    try {
      // Check cache first
      if (petImagesCache.containsKey(petId)) {
        return petImagesCache[petId];
      }

      print('>>> Fetching pet image for: $petId');

      final petData = await authRepository.getPetWithImage(petId);

      if (petData != null) {
        final imageUrl = petData['imageUrl'] as String?;

        if (imageUrl != null && imageUrl.isNotEmpty) {
          // Cache the URL
          petImagesCache[petId] = imageUrl;
          print('>>> Pet image cached: $imageUrl');
          return imageUrl;
        }
      }

      return null;
    } catch (e) {
      print('>>> Error getting pet image: $e');
      return null;
    }
  }

  /// Clear pet images cache
  void clearPetImagesCache() {
    petImagesCache.clear();
  }
}

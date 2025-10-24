import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/medical_record_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:get/get.dart';

class EnhancedClinicAppointmentController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService session;

  EnhancedClinicAppointmentController({
    required this.authRepository,
    required this.session,
  });

  var isLoading = false.obs;
  var appointments = <Appointment>[].obs;
  var clinicData = Rxn<Clinic>();
  var petsCache = <String, Pet>{}.obs;
  var ownersCache = <String, Map<String, dynamic>>{}.obs;
  var medicalRecords = <MedicalRecord>[].obs;

  // Current selected appointment for detailed workflow
  var selectedAppointment = Rxn<Appointment>();

  // CRITICAL: In-memory storage for vitals (NOT saved to appointment)
  // This holds vitals temporarily until service is completed
  final Map<String, Map<String, dynamic>> _pendingVitals = {};

  @override
  void onInit() {
    super.onInit();
    fetchClinicData();
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
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to load clinic data: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchClinicAppointments() async {
    if (clinicData.value?.documentId == null) return;

    try {
      isLoading.value = true;
      final result = await authRepository
          .getClinicAppointments(clinicData.value!.documentId!);
      appointments.assignAll(result);
      await _fetchRelatedData();
    } catch (e) {
      Get.snackbar("Error", "Failed to load appointments: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchRelatedData() async {
    for (var appointment in appointments) {
      // Cache pet data
      if (!petsCache.containsKey(appointment.petId)) {
        try {
          final petDoc = await authRepository.getPetByName(appointment.petId);
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

  // Enhanced status-based filtering with proper getters
  List<Appointment> get pending =>
      appointments.where((a) => a.status == 'pending').toList();
  List<Appointment> get accepted =>
      appointments.where((a) => a.status == 'accepted').toList();
  List<Appointment> get scheduled =>
      appointments.where((a) => a.status == 'accepted').toList();
  List<Appointment> get declined =>
      appointments.where((a) => a.status == 'declined').toList();
  List<Appointment> get inProgress =>
      appointments.where((a) => a.status == 'in_progress').toList();
  List<Appointment> get completed =>
      appointments.where((a) => a.status == 'completed').toList();
  List<Appointment> get noShow =>
      appointments.where((a) => a.status == 'no_show').toList();

  // Today's appointments
  List<Appointment> get todayAppointments {
    final today = DateTime.now();
    return appointments.where((appointment) {
      final appointmentDate = appointment.dateTime;
      return appointmentDate.year == today.year &&
          appointmentDate.month == today.month &&
          appointmentDate.day == today.day;
    }).toList();
  }

  // Helper methods
  String getOwnerName(String userId) =>
      ownersCache[userId]?['name'] ?? 'Unknown Owner';
  String getPetName(String petId) => petsCache[petId]?.name ?? petId;
  String getPetBreed(String petId) =>
      petsCache[petId]?.breed ?? 'Unknown Breed';
  String getPetType(String petId) => petsCache[petId]?.type ?? 'Unknown Type';
  Pet? getPetForAppointment(String petId) => petsCache[petId];

  // === VITALS MANAGEMENT (IN-MEMORY ONLY) ===

  /// Record vitals in memory (NOT saved to appointment)
  void recordVitalsLocally({
    required String appointmentId,
    double? temperature,
    double? weight,
    String? bloodPressure,
    int? heartRate,
  }) {
    print(
        '>>> CONTROLLER: Recording vitals locally for appointment: $appointmentId');
    print('>>>   - temperature: $temperature');
    print('>>>   - weight: $weight');
    print('>>>   - bloodPressure: $bloodPressure');
    print('>>>   - heartRate: $heartRate');

    _pendingVitals[appointmentId] = {
      'temperature': temperature,
      'weight': weight,
      'bloodPressure': bloodPressure,
      'heartRate': heartRate,
      'recordedAt': DateTime.now().toIso8601String(),
    };

    print('>>> âœ" Vitals stored in memory (not saved yet)');
  }

  /// Check if appointment has pending vitals
  bool hasPendingVitals(String appointmentId) {
    return _pendingVitals.containsKey(appointmentId);
  }

  /// Get pending vitals for appointment
  Map<String, dynamic>? getPendingVitals(String appointmentId) {
    return _pendingVitals[appointmentId];
  }

  /// Clear pending vitals (called after successful completion)
  void clearPendingVitals(String appointmentId) {
    _pendingVitals.remove(appointmentId);
    print('>>> Pending vitals cleared for appointment: $appointmentId');
  }

  // === APPOINTMENT WORKFLOW METHODS ===

  // 1. Accept Appointment
  Future<void> acceptAppointment(Appointment appointment) async {
    print('>>> ============================================');
    print('>>> ACCEPTING APPOINTMENT');
    print('>>> ID: ${appointment.documentId}');
    print('>>> ============================================');

    await _updateAppointmentStatus(appointment, 'accepted');
    Get.snackbar("Success", "Appointment accepted! Patient will be notified.");
  }

  // 2. Decline Appointment
  Future<void> declineAppointment(Appointment appointment) async {
    print('>>> ============================================');
    print('>>> DECLINING APPOINTMENT');
    print('>>> ID: ${appointment.documentId}');
    print('>>> ============================================');

    await _updateAppointmentStatus(appointment, 'declined');
    Get.snackbar("Success", "Appointment declined. Patient will be notified.");
  }

  // 3. Mark Patient as Checked In (Arrived)
  Future<void> checkInPatient(Appointment appointment) async {
    print('>>> ============================================');
    print('>>> CHECKING IN PATIENT');
    print('>>> ID: ${appointment.documentId}');
    print('>>> ============================================');

    final updatedAppointment = appointment.copyWith(
      status: 'in_progress',
      checkedInAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _updateFullAppointment(updatedAppointment);
    Get.snackbar(
        "Success", "${getPetName(appointment.petId)} has been checked in!");
  }

  // 4. Start Service/Treatment
  Future<void> startService(Appointment appointment) async {
    print('>>> ============================================');
    print('>>> STARTING SERVICE');
    print('>>> ID: ${appointment.documentId}');
    print('>>> ============================================');

    final updatedAppointment = appointment.copyWith(
      serviceStartedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _updateFullAppointment(updatedAppointment);
    Get.snackbar(
        "Info", "Service started for ${getPetName(appointment.petId)}");
  }

  // 5. Complete Service with Medical Record
  Future<void> completeServiceWithRecord({
    required Appointment appointment,
    required String diagnosis,
    required String treatment,
    String? prescription,
    String? vetNotes,
    double? totalCost,
    String? followUpInstructions,
    DateTime? nextAppointmentDate, Map<String, dynamic>? vitals,
  }) async {
    print('>>> ============================================');
    print('>>> COMPLETING SERVICE');
    print('>>> ID: ${appointment.documentId}');
    print('>>> ============================================');

    try {
      // CRITICAL: Get pending vitals from memory
      final pendingVitals = getPendingVitals(appointment.documentId!);

      print('>>> Step 1: Updating appointment (workflow only)...');
      // Update appointment with workflow and billing data ONLY
      final updatedAppointment = appointment.copyWith(
        status: 'completed',
        serviceCompletedAt: DateTime.now(),
        totalCost: totalCost,
        followUpInstructions: followUpInstructions,
        nextAppointmentDate: nextAppointmentDate,
        updatedAt: DateTime.now(),
      );

      await _updateFullAppointment(updatedAppointment);
      print('>>> âœ" Appointment updated');

      // Create medical record with all medical data
      print('>>> Step 2: Creating medical record...');
      final user = await authRepository.getUser();
      if (user != null) {
        // CRITICAL: Create medical record with individual vital fields
        final medicalRecord = MedicalRecord(
          petId: appointment.petId,
          clinicId: appointment.clinicId,
          vetId: user.$id,
          appointmentId: appointment.documentId!,
          visitDate: appointment.dateTime,
          service: appointment.service,
          diagnosis: diagnosis,
          treatment: treatment,
          prescription: prescription,
          notes: vetNotes,
          // Individual vital fields from pendingVitals
          temperature: pendingVitals?['temperature'],
          weight: pendingVitals?['weight'],
          bloodPressure: pendingVitals?['bloodPressure'],
          heartRate: pendingVitals?['heartRate'],
        );

        print('>>> Medical record data:');
        print('>>>   - diagnosis: $diagnosis');
        print('>>>   - treatment: $treatment');
        print('>>>   - prescription: $prescription');
        print('>>>   - temperature: ${medicalRecord.temperature}');
        print('>>>   - weight: ${medicalRecord.weight}');
        print('>>>   - bloodPressure: ${medicalRecord.bloodPressure}');
        print('>>>   - heartRate: ${medicalRecord.heartRate}');

        await authRepository.createMedicalRecord(medicalRecord);
        print('>>> âœ" Medical record created');

        // Clear pending vitals after successful save
        clearPendingVitals(appointment.documentId!);
      }

      print('>>> ============================================');
      print('>>> SERVICE COMPLETED SUCCESSFULLY');
      print('>>> ============================================');

      Get.snackbar("Success", "Service completed and medical record created!");
    } catch (e) {
      print('>>> ============================================');
      print('>>> ERROR COMPLETING SERVICE: $e');
      print('>>> ============================================');
      Get.snackbar("Error", "Failed to complete service: $e");
      rethrow;
    }
  }

  // 6. Mark as No Show
  Future<void> markNoShow(Appointment appointment) async {
    print('>>> ============================================');
    print('>>> MARKING NO SHOW');
    print('>>> ID: ${appointment.documentId}');
    print('>>> ============================================');

    await _updateAppointmentStatus(appointment, 'no_show');

    // Clear any pending vitals
    if (appointment.documentId != null) {
      clearPendingVitals(appointment.documentId!);
    }

    Get.snackbar("Info", "Appointment marked as No Show");
  }

  // 7. Process Payment
  Future<void> processPayment(
      Appointment appointment, double amount, String method) async {
    print('>>> ============================================');
    print('>>> PROCESSING PAYMENT');
    print('>>> Amount: â‚±$amount');
    print('>>> Method: $method');
    print('>>> ============================================');

    final updatedAppointment = appointment.copyWith(
      totalCost: amount,
      isPaid: true,
      paymentMethod: method,
      updatedAt: DateTime.now(),
    );

    await _updateFullAppointment(updatedAppointment);
    Get.snackbar("Success", "Payment processed successfully!");
  }

  // === MEDICAL RECORD METHODS ===

  Future<List<MedicalRecord>> getPetMedicalHistory(String petId) async {
    try {
      print('>>> Getting medical history for pet: $petId');
      final records = await authRepository.getPetMedicalRecords(petId);
      print('>>> Found ${records.length} medical records');
      return records;
    } catch (e) {
      print('>>> Error getting medical history: $e');
      Get.snackbar("Error", "Failed to load medical history: $e");
      return [];
    }
  }

  // === PRIVATE HELPER METHODS ===

  Future<void> _updateAppointmentStatus(
      Appointment appointment, String status) async {
    if (appointment.documentId == null) {
      Get.snackbar("Error", "Cannot update appointment: Missing document ID");
      return;
    }

    print('>>> Updating appointment status to: $status');

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
      }

      print('>>> âœ" Status updated successfully');
    } catch (e) {
      print('>>> âœ— Error updating status: $e');
      Get.snackbar("Error", "Failed to update appointment: $e");
    }
  }

  Future<void> _updateFullAppointment(Appointment appointment) async {
    if (appointment.documentId == null) {
      Get.snackbar("Error", "Cannot update appointment: Missing document ID");
      return;
    }

    print('>>> Updating full appointment data');
    print('>>> Document ID: ${appointment.documentId}');

    try {
      final appointmentMap = appointment.toMap();

      // CRITICAL: Ensure no medical data in appointment
      final medicalFields = [
        'diagnosis',
        'treatment',
        'prescription',
        'vetNotes',
        'vitals'
      ];
      for (var field in medicalFields) {
        if (appointmentMap.containsKey(field)) {
          print(
              '>>> âš ï¸ WARNING: Removing medical field from appointment: $field');
          appointmentMap.remove(field);
        }
      }

      print('>>> Final data keys: ${appointmentMap.keys.toList()}');

      await authRepository.updateFullAppointment(
          appointment.documentId!, appointmentMap);

      final index = appointments
          .indexWhere((a) => a.documentId == appointment.documentId);
      if (index != -1) {
        appointments[index] = appointment;
        appointments.refresh();
      }

      print('>>> âœ" Full appointment updated successfully');
    } catch (e) {
      print('>>> âœ— Error updating full appointment: $e');
      Get.snackbar("Error", "Failed to update appointment: $e");
    }
  }

  // === STATISTICS & ANALYTICS ===

  Map<String, int> get appointmentStats {
    return {
      'total': appointments.length,
      'pending': pending.length,
      'scheduled': scheduled.length,
      'accepted': accepted.length,
      'declined': declined.length,
      'in_progress': inProgress.length,
      'completed': completed.length,
      'no_show': noShow.length,
      'today': todayAppointments.length,
    };
  }

  double get todayRevenue {
    return todayAppointments
        .where((a) => a.isPaid && a.totalCost != null)
        .fold(0.0, (sum, appointment) => sum + (appointment.totalCost ?? 0.0));
  }

  Future<void> refreshAppointments() async {
    print('>>> Refreshing appointments...');
    await fetchClinicAppointments();
  }

  @override
  void onClose() {
    // Clear pending vitals on controller disposal
    _pendingVitals.clear();
    super.onClose();
  }
}

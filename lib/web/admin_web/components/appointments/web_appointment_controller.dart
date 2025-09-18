import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/medical_record_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:get/get.dart';

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

  @override
  void onInit() {
    super.onInit();
    fetchClinicData();
    
    // Listen to tab changes and update filtered appointments
    ever(selectedTab, (_) => updateFilteredAppointments());
    ever(searchQuery, (_) => updateFilteredAppointments());
    ever(selectedDateFilter, (_) => updateFilteredAppointments());
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

  void updateFilteredAppointments() {
    List<Appointment> filtered = appointments.toList();

    // Filter by tab/status
    switch (selectedTab.value) {
      case 'today':
        final today = DateTime.now();
        filtered = filtered.where((appointment) {
          final appointmentDate = appointment.dateTime;
          return appointmentDate.year == today.year &&
                 appointmentDate.month == today.month &&
                 appointmentDate.day == today.day;
        }).toList();
        break;
      case 'pending':
        filtered = filtered.where((a) => a.status == 'pending').toList();
        break;
      case 'scheduled':
        filtered = filtered.where((a) => a.status == 'accepted').toList();
        break;
      case 'in_progress':
        filtered = filtered.where((a) => a.status == 'in_progress').toList();
        break;
      case 'completed':
        filtered = filtered.where((a) => a.status == 'completed').toList();
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
    final today = DateTime.now();
    return appointments.where((appointment) {
      final appointmentDate = appointment.dateTime;
      return appointmentDate.year == today.year &&
             appointmentDate.month == today.month &&
             appointmentDate.day == today.day;
    }).toList();
  }

  List<Appointment> get pending => appointments.where((a) => a.status == 'pending').toList();
  List<Appointment> get scheduled => appointments.where((a) => a.status == 'accepted').toList();
  List<Appointment> get inProgress => appointments.where((a) => a.status == 'in_progress').toList();
  List<Appointment> get completed => appointments.where((a) => a.status == 'completed').toList();
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
      'declined': declined.length,
    };
  }

  double get todayRevenue {
    return todayAppointments
        .where((a) => a.isPaid && a.totalCost != null)
        .fold(0.0, (sum, appointment) => sum + (appointment.totalCost ?? 0.0));
  }

  // Appointment actions
  Future<void> acceptAppointment(Appointment appointment) async {
    await _updateAppointmentStatus(appointment, 'accepted');
    Get.snackbar("Success", "Appointment accepted! Patient will be notified.");
  }

  Future<void> declineAppointment(Appointment appointment) async {
    await _updateAppointmentStatus(appointment, 'declined');
    Get.snackbar("Success", "Appointment declined. Patient will be notified.");
  }

  Future<void> checkInPatient(Appointment appointment) async {
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
    required String diagnosis,
    required String treatment,
    String? prescription,
    String? vetNotes,
    Map<String, dynamic>? vitals,
    double? totalCost,
    String? followUpInstructions,
    DateTime? nextAppointmentDate,
  }) async {
    final updatedAppointment = appointment.copyWith(
      status: 'completed',
      serviceCompletedAt: DateTime.now(),
      diagnosis: diagnosis,
      treatment: treatment,
      prescription: prescription,
      vetNotes: vetNotes,
      vitals: vitals,
      totalCost: totalCost,
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
    await _updateAppointmentStatus(appointment, 'no_show');
    Get.snackbar("Info", "Appointment marked as No Show");
  }

  Future<void> processPayment(Appointment appointment, double amount, String method) async {
    final updatedAppointment = appointment.copyWith(
      totalCost: amount,
      isPaid: true,
      paymentMethod: method,
      updatedAt: DateTime.now(),
    );

    await updateFullAppointment(updatedAppointment);
    Get.snackbar("Success", "Payment processed successfully!");
  }

  // Public method for updating appointments (was private)
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

  // Private helper methods
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

  // Search and filter methods
  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  void setSelectedTab(String tab) {
    selectedTab.value = tab;
  }

  void setDateFilter(DateTime date) {
    selectedDateFilter.value = date;
  }
}
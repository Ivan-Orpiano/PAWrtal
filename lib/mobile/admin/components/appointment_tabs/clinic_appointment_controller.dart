import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:get/get.dart';

class ClinicAppointmentController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService session;

  ClinicAppointmentController({
    required this.authRepository,
    required this.session,
  });

  var isLoading = false.obs;
  var appointments = <Appointment>[].obs;
  var clinicData = Rxn<Clinic>();
  var petsCache = <String, Pet>{}.obs;
  var ownersCache = <String, Map<String, dynamic>>{}.obs;

  @override
  void onInit() {
    super.onInit();
    fetchClinicData();
  }

  Future<void> fetchClinicData() async {
    try {
      isLoading.value = true;
      
      // Get current user (admin)
      final user = await authRepository.getUser();
      if (user == null) return;

      // Get clinic data for this admin
      final clinicDoc = await authRepository.getClinicByAdminId(user.$id);
      if (clinicDoc != null) {
        clinicData.value = Clinic.fromMap(clinicDoc.data);
        // Now fetch appointments for this clinic
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
      final result = await authRepository.getClinicAppointments(clinicData.value!.documentId!);
      appointments.assignAll(result);
      
      // Fetch related data for each appointment
      await _fetchRelatedData();
      
    } catch (e) {
      Get.snackbar("Error", "Failed to load appointments: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchRelatedData() async {
    for (var appointment in appointments) {
      // Fetch pet data if not cached
      if (!petsCache.containsKey(appointment.petId)) {
        try {
          final pet = await authRepository.getPetByName(appointment.petId);
          if (pet != null) {
            petsCache[appointment.petId] = pet as Pet;
          }
        } catch (e) {
          print("Error fetching pet ${appointment.petId}: $e");
        }
      }

      // Fetch owner data if not cached
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

  // Filtered lists by status
  List<Appointment> get pending =>
      appointments.where((a) => a.status == 'pending').toList();

  List<Appointment> get accepted =>
      appointments.where((a) => a.status == 'accepted').toList();

  List<Appointment> get declined =>
      appointments.where((a) => a.status == 'declined').toList();

  // Helper methods to get related data
  Pet? getPetForAppointment(String petId) {
    return petsCache[petId];
  }

  Map<String, dynamic>? getOwnerForAppointment(String userId) {
    return ownersCache[userId];
  }

  String getOwnerName(String userId) {
    final owner = ownersCache[userId];
    return owner?['name'] ?? 'Unknown Owner';
  }

  String getPetName(String petId) {
    final pet = petsCache[petId];
    return pet?.name ?? petId; // fallback to petId if not found
  }

  String getPetBreed(String petId) {
    final pet = petsCache[petId];
    return pet?.breed ?? 'Unknown Breed';
  }

  String getPetType(String petId) {
    final pet = petsCache[petId];
    return pet?.type ?? 'Unknown Type';
  }

  // Appointment status management
  Future<void> acceptAppointment(Appointment appointment) async {
    if (appointment.documentId == null) {
      Get.snackbar("Error", "Cannot update appointment: Missing document ID");
      return;
    }

    try {
      await authRepository.updateAppointmentStatus(
        appointment.documentId!,
        'accepted'
      );
      
      // Update local state
      final index = appointments.indexWhere((a) => 
        a.documentId == appointment.documentId
      );
      
      if (index != -1) {
        appointments[index] = appointment.copyWith(
          status: 'accepted',
          updatedAt: DateTime.now(),
        );
        appointments.refresh();
      }
      
      Get.snackbar("Success", "Appointment accepted successfully!");
    } catch (e) {
      Get.snackbar("Error", "Failed to accept appointment: $e");
    }
  }

  Future<void> declineAppointment(Appointment appointment) async {
    if (appointment.documentId == null) {
      Get.snackbar("Error", "Cannot update appointment: Missing document ID");
      return;
    }

    try {
      await authRepository.updateAppointmentStatus(
        appointment.documentId!,
        'declined'
      );
      
      // Update local state
      final index = appointments.indexWhere((a) => 
        a.documentId == appointment.documentId
      );
      
      if (index != -1) {
        appointments[index] = appointment.copyWith(
          status: 'declined',
          updatedAt: DateTime.now(),
        );
        appointments.refresh();
      }
      
      Get.snackbar("Success", "Appointment declined.");
    } catch (e) {
      Get.snackbar("Error", "Failed to decline appointment: $e");
    }
  }

  // Refresh functionality
  Future<void> refreshAppointments() async {
    await fetchClinicAppointments();
  }
}
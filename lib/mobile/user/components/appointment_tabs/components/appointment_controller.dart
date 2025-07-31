import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:get/get.dart';

class AppointmentController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService session;

  AppointmentController({
    required this.authRepository,
    required this.session,
  });

  var isLoading = false.obs;
  var appointments = <Appointment>[].obs;
  var clinics = <String, Clinic>{}.obs; // Cache clinics by ID
  var pets = <String, Pet>{}.obs; // Cache pets by ID

  @override
  void onInit() {
    super.onInit();
    fetchAppointments();
  }

  Future<void> fetchAppointments() async {
    try {
      isLoading.value = true;
      final userId = session.userId;

      if (userId.isEmpty) {
        Get.snackbar("Error", "User not logged in.");
        return;
      }

      // Fetch appointments
      final result = await authRepository.getUserAppointments(userId);
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
    // Get unique clinic and pet IDs
    final clinicIds = appointments.map((a) => a.clinicId).toSet();
    final petIds = appointments.map((a) => a.petId).toSet();

    // Fetch clinics
    for (final clinicId in clinicIds) {
      if (!clinics.containsKey(clinicId)) {
        try {
          final clinicDoc = await authRepository.getClinicByAdminId(clinicId);
          if (clinicDoc != null) {
            final clinic = Clinic.fromMap(clinicDoc.data);
            clinic.documentId = clinicDoc.$id;
            clinics[clinicId] = clinic;
          }
        } catch (e) {
          print('Error fetching clinic $clinicId: $e');
        }
      }
    }

    // Fetch pets
    final userId = session.userId;
    if (userId.isNotEmpty) {
      try {
        final userPets = await authRepository.getUserPets(userId);
        for (final petDoc in userPets) {
          final pet = Pet.fromMap(petDoc.data);
          pet.documentId = petDoc.$id;
          pets[pet.name] = pet; // Using name as key since that's what's stored in appointment
        }
      } catch (e) {
        print('Error fetching pets: $e');
      }
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    try {
      isLoading.value = true;
      
      // TODO: Implement cancel appointment in your AppWrite provider and repository
      // await authRepository.cancelAppointment(appointmentId);
      
      // For now, just refresh the appointments
      await fetchAppointments();
      
      Get.snackbar(
        "Success", 
        "Appointment cancelled successfully",
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        "Error", 
        "Failed to cancel appointment: $e",
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Getters for filtered appointments
  List<Appointment> get pending =>
      appointments.where((a) => a.status == 'pending').toList();

  List<Appointment> get accepted =>
      appointments.where((a) => a.status == 'accepted').toList();

  List<Appointment> get declined =>
      appointments.where((a) => a.status == 'declined').toList();

  // Helper methods to get related data
  Clinic? getClinicForAppointment(Appointment appointment) {
    return clinics[appointment.clinicId];
  }

  Pet? getPetForAppointment(Appointment appointment) {
    return pets[appointment.petId];
  }

  String getPetNameForAppointment(Appointment appointment) {
    final pet = pets[appointment.petId];
    return pet?.name ?? appointment.petId; // Fallback to stored petId
  }
}
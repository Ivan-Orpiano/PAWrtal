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
  var pets = <String, Pet>{}.obs; // Cache pets by name (current system)

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
    final userId = session.userId;
    
    // Get unique clinic IDs and pet names
    final clinicIds = appointments.map((a) => a.clinicId).toSet();
    final petNames = appointments.map((a) => a.petId).toSet(); // petId currently stores pet names

    // Fetch clinics
    for (final clinicId in clinicIds) {
      if (!clinics.containsKey(clinicId) && clinicId.isNotEmpty) {
        try {
          final clinic = await authRepository.getClinicById(clinicId);
          if (clinic != null) {
            clinics[clinicId] = clinic as Clinic;
          }
        } catch (e) {
          print('Error fetching clinic $clinicId: $e');
        }
      }
    }

    // Fetch pets by name (since your current system stores pet names in appointments)
    for (final petName in petNames) {
      if (!pets.containsKey(petName) && petName.isNotEmpty) {
        try {
          final pet = await authRepository.getPetByName(petName);
          if (pet != null) {
            pets[petName] = pet as Pet;
          }
        } catch (e) {
          print('Error fetching pet $petName: $e');
        }
      }
    }
  }

  Future<void> cancelAppointment(String appointmentId) async {
    try {
      isLoading.value = true;
      
      // TODO: Implement cancel appointment method in your repository
      // await authRepository.updateAppointmentStatus(appointmentId, 'cancelled');
      
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
    return pets[appointment.petId]; // petId currently stores pet name
  }

  String getPetNameForAppointment(Appointment appointment) {
    final pet = pets[appointment.petId];
    return pet?.name ?? appointment.petId; // Fallback to stored petId (which is the name)
  }

  String getClinicNameForAppointment(Appointment appointment) {
    final clinic = clinics[appointment.clinicId];
    return clinic?.clinicName ?? 'Unknown Clinic';
  }
}
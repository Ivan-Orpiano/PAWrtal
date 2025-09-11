import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

class EnhancedUserAppointmentController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService session;

  EnhancedUserAppointmentController({
    required this.authRepository,
    required this.session,
  });

  var isLoading = false.obs;
  var appointments = <Appointment>[].obs;
  var clinics = <String, Clinic>{}.obs;
  var pets = <String, Pet>{}.obs;

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

      final result = await authRepository.getUserAppointments(userId);
      appointments.assignAll(result);
      await _fetchRelatedData();

    } catch (e) {
      Get.snackbar("Error", "Failed to load appointments: $e");
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _fetchRelatedData() async {
    final clinicIds = appointments.map((a) => a.clinicId).toSet();
    final petNames = appointments.map((a) => a.petId).toSet();

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

  // Enhanced status-based filtering for user side
  List<Appointment> get pending => appointments.where((a) => a.status == 'pending').toList();
  
  List<Appointment> get accepted => appointments.where((a) => 
    a.status == 'accepted' || a.status == 'in_progress' || a.status == 'completed').toList();
  
  List<Appointment> get declined => appointments.where((a) => 
    a.status == 'declined' || a.status == 'no_show').toList();

  // More specific filtering for better user experience
  List<Appointment> get upcoming => appointments.where((a) => 
    a.status == 'accepted' && a.dateTime.isAfter(DateTime.now())).toList();
  
  List<Appointment> get inProgress => appointments.where((a) => 
    a.status == 'in_progress').toList();
  
  List<Appointment> get completed => appointments.where((a) => 
    a.status == 'completed').toList();
  
  List<Appointment> get noShow => appointments.where((a) => 
    a.status == 'no_show').toList();

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

  Future<void> cancelAppointment(String appointmentId) async {
    try {
      isLoading.value = true;
      await authRepository.updateAppointmentStatus(appointmentId, 'cancelled');
      await fetchAppointments();
      
      Get.snackbar(
        "Success", 
        "Appointment cancelled successfully",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error", 
        "Failed to cancel appointment: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Helper methods
  Clinic? getClinicForAppointment(Appointment appointment) {
    return clinics[appointment.clinicId];
  }

  Pet? getPetForAppointment(Appointment appointment) {
    return pets[appointment.petId];
  }

  String getPetNameForAppointment(Appointment appointment) {
    final pet = pets[appointment.petId];
    return pet?.name ?? appointment.petId;
  }

  String getClinicNameForAppointment(Appointment appointment) {
    final clinic = clinics[appointment.clinicId];
    return clinic?.clinicName ?? 'Unknown Clinic';
  }

  // Get appointment workflow stage for user display
  String getAppointmentStage(Appointment appointment) {
    switch (appointment.status) {
      case 'pending':
        return 'Waiting for clinic approval';
      case 'accepted':
        return 'Confirmed - Please arrive on time';
      case 'in_progress':
        if (appointment.checkedInAt != null && appointment.serviceStartedAt == null) {
          return 'Checked in - Waiting for treatment';
        } else if (appointment.serviceStartedAt != null) {
          return 'Currently receiving treatment';
        }
        return 'Treatment in progress';
      case 'completed':
        return 'Treatment completed';
      case 'no_show':
        return 'Missed appointment';
      case 'declined':
        return 'Not approved by clinic';
      default:
        return appointment.status;
    }
  }

  // Get user-friendly status
  String getUserFriendlyStatus(Appointment appointment) {
    switch (appointment.status) {
      case 'pending':
        return 'Pending Review';
      case 'accepted':
        return 'Confirmed';
      case 'in_progress':
        return 'In Treatment';
      case 'completed':
        return 'Completed';
      case 'no_show':
        return 'Missed';
      case 'declined':
        return 'Declined';
      default:
        return appointment.status.toUpperCase();
    }
  }

  // Check if appointment can be cancelled
  bool canCancelAppointment(Appointment appointment) {
    return appointment.status == 'pending' || 
           (appointment.status == 'accepted' && 
            appointment.dateTime.isAfter(DateTime.now().add(const Duration(hours: 2))));
  }

  // Get appointment progress for user
  double getAppointmentProgress(Appointment appointment) {
    switch (appointment.status) {
      case 'pending':
        return 0.2;
      case 'accepted':
        return 0.4;
      case 'in_progress':
        if (appointment.serviceStartedAt != null) return 0.8;
        return 0.6;
      case 'completed':
        return 1.0;
      default:
        return 0.0;
    }
  }

  // Statistics for user dashboard
  Map<String, int> get userStats {
    return {
      'total': appointments.length,
      'pending': pending.length,
      'upcoming': upcoming.length,
      'completed': completed.length,
      'today': todayAppointments.length,
    };
  }
}

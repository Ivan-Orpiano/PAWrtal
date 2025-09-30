import 'dart:async';
import 'package:appwrite/appwrite.dart';
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
  
  // Real-time subscription
  StreamSubscription<RealtimeMessage>? _appointmentSubscription;

  @override
  void onInit() {
    super.onInit();
    fetchAppointments();
    _setupRealtimeSubscription();
  }

  @override
  void onClose() {
    _appointmentSubscription?.cancel();
    super.onClose();
  }

  // Setup real-time subscription for appointment updates
  void _setupRealtimeSubscription() {
    try {
      final userId = session.userId;
      if (userId.isEmpty) return;

      _appointmentSubscription = authRepository
          .subscribeToUserAppointments(userId)
          .listen((message) {
        _handleRealtimeUpdate(message);
      });
    } catch (e) {
      print('Error setting up realtime subscription: $e');
    }
  }

  void _handleRealtimeUpdate(RealtimeMessage message) {
    final payload = message.payload;
    final eventType = message.events.first;

    if (eventType.contains('create')) {
      // New appointment created
      _addOrUpdateAppointment(payload);
    } else if (eventType.contains('update')) {
      // Appointment updated
      _addOrUpdateAppointment(payload);
    } else if (eventType.contains('delete')) {
      // Appointment deleted
      appointments.removeWhere((a) => a.documentId == payload['\$id']);
    }
  }

  void _addOrUpdateAppointment(Map<String, dynamic> payload) {
    final appointment = Appointment.fromMap(payload);
    final index = appointments.indexWhere((a) => a.documentId == appointment.documentId);
    
    if (index != -1) {
      appointments[index] = appointment;
    } else {
      appointments.add(appointment);
    }
    
    // Fetch related data if not cached
    _fetchRelatedDataForAppointment(appointment);
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
          final clinicDoc = await authRepository.getClinicById(clinicId);
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

  Future<void> _fetchRelatedDataForAppointment(Appointment appointment) async {
    // Fetch clinic if not cached
    if (!clinics.containsKey(appointment.clinicId) && appointment.clinicId.isNotEmpty) {
      try {
        final clinicDoc = await authRepository.getClinicById(appointment.clinicId);
        if (clinicDoc != null) {
          final clinic = Clinic.fromMap(clinicDoc.data);
          clinic.documentId = clinicDoc.$id;
          clinics[appointment.clinicId] = clinic;
        }
      } catch (e) {
        print('Error fetching clinic: $e');
      }
    }

    // Fetch pet if not cached
    if (!pets.containsKey(appointment.petId) && appointment.petId.isNotEmpty) {
      try {
        final pet = await authRepository.getPetByName(appointment.petId);
        if (pet != null) {
          pets[appointment.petId] = pet as Pet;
        }
      } catch (e) {
        print('Error fetching pet: $e');
      }
    }
  }

  // Enhanced filtering with new tab structure
  List<Appointment> get upcoming {
    final now = DateTime.now();
    return appointments.where((a) => 
      a.status == 'accepted' && 
      a.dateTime.isAfter(now)).toList()
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  }
  
  List<Appointment> get pending {
    return appointments.where((a) => a.status == 'pending').toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  
  List<Appointment> get completed {
    return appointments.where((a) => a.status == 'completed').toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
  }
  
  List<Appointment> get history {
    return appointments.where((a) => 
      a.status == 'cancelled' || 
      a.status == 'declined' || 
      a.status == 'no_show').toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  // Additional filters
  List<Appointment> get inProgress {
    return appointments.where((a) => a.status == 'in_progress').toList();
  }
  
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
      // Real-time will handle the update
      
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
      case 'cancelled':
        return 'Appointment cancelled';
      default:
        return appointment.status;
    }
  }

  String getUserFriendlyStatus(Appointment appointment) {
    switch (appointment.status) {
      case 'pending':
        return 'Pending Approval';
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
      case 'cancelled':
        return 'Cancelled';
      default:
        return appointment.status.toUpperCase();
    }
  }

  bool canCancelAppointment(Appointment appointment) {
    return (appointment.status == 'pending' || appointment.status == 'accepted') && 
           appointment.dateTime.isAfter(DateTime.now().add(const Duration(hours: 2)));
  }

  double getAppointmentProgress(Appointment appointment) {
    switch (appointment.status) {
      case 'pending':
        return 0.25;
      case 'accepted':
        return 0.5;
      case 'in_progress':
        if (appointment.serviceStartedAt != null) return 0.85;
        return 0.7;
      case 'completed':
        return 1.0;
      default:
        return 0.0;
    }
  }

  // Enhanced statistics
  Map<String, int> get userStats {
    return {
      'total': appointments.length,
      'pending': pending.length,
      'upcoming': upcoming.length,
      'completed': completed.length,
      'today': todayAppointments.length,
      'history': history.length,
    };
  }
}
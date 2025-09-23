import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebAppointmentController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService session;
  final Clinic clinic;

  WebAppointmentController({
    required this.authRepository,
    required this.session,
    required this.clinic,
  });

  var isLoading = false.obs;
  var isBooking = false.obs;
  var selectedDateTime = Rx<DateTime?>(null);
  var selectedTime = Rx<String?>(null);
  var selectedService = Rx<String?>(null);
  var selectedPet = Rx<Pet?>(null);
  var clinicSettings = Rx<ClinicSettings?>(null);
  var pets = <Pet>[].obs;
  var availableTimes = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _loadClinicSettings();
    _loadUserPets();
  }

  Future<void> _loadClinicSettings() async {
    try {
      final settings = await authRepository.getClinicSettingsByClinicId(clinic.documentId ?? '');
      clinicSettings.value = settings;
    } catch (e) {
      print("Error loading clinic settings: $e");
    }
  }

  Future<void> _loadUserPets() async {
    try {
      isLoading.value = true;
      final userId = session.userId;
      
      if (userId.isNotEmpty) {
        final petDocs = await authRepository.getUserPets(userId);
        pets.assignAll(petDocs.map((doc) => Pet.fromMap(doc.data)).toList());
      }
    } catch (e) {
      print("Error loading pets: $e");
    } finally {
      isLoading.value = false;
    }
  }

  List<String> get services {
    if (clinicSettings.value != null && clinicSettings.value!.services.isNotEmpty) {
      return clinicSettings.value!.services;
    }
    
    if (clinic.services.isEmpty) {
      return ['General Consultation', 'Vaccination', 'Check-up', 'Grooming'];
    }
    return clinic.services.split(',').map((s) => s.trim()).toList();
  }

  bool isDateSelectable(DateTime day) {
    // Check if date is in the past
    if (day.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return false;
    }

    // Check if clinic settings allow this date
    if (clinicSettings.value != null) {
      // Check if clinic is open
      if (!clinicSettings.value!.isOpen) {
        return false;
      }

      // Check max advance booking
      final maxAdvanceDate = DateTime.now().add(
        Duration(days: clinicSettings.value!.maxAdvanceBooking)
      );
      if (day.isAfter(maxAdvanceDate)) {
        return false;
      }

      // Check if clinic is open on this day
      final dayName = _getDayName(day.weekday);
      final daySchedule = clinicSettings.value!.operatingHours[dayName];
      if (daySchedule?['isOpen'] != true) {
        return false;
      }
    }

    return true;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'monday';
      case 2: return 'tuesday';
      case 3: return 'wednesday';
      case 4: return 'thursday';
      case 5: return 'friday';
      case 6: return 'saturday';
      case 7: return 'sunday';
      default: return 'monday';
    }
  }

  void onDateSelected(DateTime date) {
    selectedDateTime.value = date;
    selectedTime.value = null; // Reset selected time when date changes
    _updateAvailableTimeSlots();
  }

  void _updateAvailableTimeSlots() {
    if (selectedDateTime.value == null) {
      availableTimes.clear();
      return;
    }

    List<String> slots = [];
    
    if (clinicSettings.value != null) {
      slots = clinicSettings.value!.getAvailableTimeSlotsFiltered(selectedDateTime.value!);
    } else {
      // Fallback to default time slots
      slots = [
        '09:00',
        '10:00',
        '11:00',
        '13:00',
        '14:00',
        '15:00',
        '16:00',
      ];
      
      // Filter out past time slots if the selected date is today
      if (_isToday(selectedDateTime.value!)) {
        slots = _filterPastTimeSlots(slots);
      }
    }

    availableTimes.assignAll(slots);
    
    // Reset selected time if it's no longer available
    if (selectedTime.value != null && !slots.contains(selectedTime.value)) {
      selectedTime.value = null;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && 
           date.month == now.month && 
           date.day == now.day;
  }

  List<String> _filterPastTimeSlots(List<String> timeSlots) {
    final now = DateTime.now();
    
    return timeSlots.where((timeSlot) {
      try {
        final timeParts = timeSlot.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        
        final slotDateTime = DateTime(
          selectedDateTime.value!.year, 
          selectedDateTime.value!.month, 
          selectedDateTime.value!.day, 
          hour, 
          minute
        );
        // Add a 30-minute buffer - don't allow booking slots that start within 30 minutes
        return slotDateTime.isAfter(now.add(const Duration(minutes: 30)));
      } catch (e) {
        // If parsing fails, include the slot (better to be permissive)
        return true;
      }
    }).toList();
  }

  void onTimeSelected(String? time) {
    selectedTime.value = time;
  }

  void onServiceSelected(String? service) {
    selectedService.value = service;
  }

  void onPetSelected(Pet? pet) {
    selectedPet.value = pet;
  }

  bool get canBookAppointment {
    return selectedDateTime.value != null &&
           selectedTime.value != null &&
           selectedService.value != null &&
           selectedPet.value != null &&
           !isBooking.value &&
           (clinicSettings.value?.isOpen ?? true);
  }

  String? get bookingValidationMessage {
    if (clinicSettings.value != null && !clinicSettings.value!.isOpen) {
      return 'This clinic is currently not accepting appointments';
    }
    
    if (selectedDateTime.value == null) {
      return 'Please select a date';
    }
    
    if (availableTimes.isEmpty) {
      return 'No available times for this date';
    }
    
    if (selectedTime.value == null) {
      return 'Please select a time';
    }
    
    if (selectedService.value == null) {
      return 'Please select a service';
    }
    
    if (selectedPet.value == null) {
      return 'Please select a pet';
    }
    
    return null;
  }

  Future<void> bookAppointment() async {
    if (!canBookAppointment) return;

    final userId = session.userId;
    if (userId.isEmpty) {
      Get.snackbar(
        "Error", 
        "User not logged in",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isBooking.value = true;

      // Parse time and create DateTime
      final timeParts = selectedTime.value!.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      final appointmentDateTime = DateTime(
        selectedDateTime.value!.year,
        selectedDateTime.value!.month,
        selectedDateTime.value!.day,
        hour,
        minute,
      );

      final appointment = Appointment(
        userId: userId,
        clinicId: clinic.documentId ?? '',
        petId: selectedPet.value!.name, // Using pet name as ID for now
        service: selectedService.value!,
        dateTime: appointmentDateTime,
        status: clinicSettings.value?.autoAcceptAppointments == true ? 'accepted' : 'pending',
      );

      await authRepository.createAppointment(appointment);

      // Show success message
      Get.snackbar(
        "Success", 
        clinicSettings.value?.autoAcceptAppointments == true
          ? "Appointment automatically confirmed!"
          : "Appointment booked successfully! You will receive confirmation once the clinic reviews your request.",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );

      // Reset form
      selectedDateTime.value = null;
      selectedTime.value = null;
      selectedService.value = null;
      selectedPet.value = null;
      availableTimes.clear();

    } catch (e) {
      Get.snackbar(
        "Error", 
        "Failed to book appointment: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isBooking.value = false;
    }
  }
}
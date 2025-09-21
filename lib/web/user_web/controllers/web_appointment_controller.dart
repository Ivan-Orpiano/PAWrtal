import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

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
  var pets = <Pet>[].obs;
  var selectedDateTime = Rx<DateTime?>(null);
  var selectedTime = Rx<String?>(null);
  var selectedService = Rx<String?>(null);
  var selectedPet = Rx<Pet?>(null);
  var clinicSettings = Rxn<ClinicSettings>();
  var availableTimes = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchUserPets();
    loadClinicSettings();
    // Set default date to today
    selectedDateTime.value = DateTime.now();
  }

  Future<void> loadClinicSettings() async {
    try {
      final settings = await authRepository.getClinicSettingsByClinicId(clinic.documentId ?? '');
      clinicSettings.value = settings;
      
      // Update available times when date changes
      if (selectedDateTime.value != null) {
        updateAvailableTimes(selectedDateTime.value!);
      }
    } catch (e) {
      print("Error loading clinic settings: $e");
    }
  }

  Future<void> fetchUserPets() async {
    try {
      isLoading.value = true;
      final userId = session.userId;

      if (userId.isEmpty) {
        _showSnackBar("User not logged in", isError: true);
        return;
      }

      final petDocs = await authRepository.getUserPets(userId);
      pets.value = petDocs.map((doc) {
        final pet = Pet.fromMap(doc.data);
        pet.documentId = doc.$id;
        return pet;
      }).toList();

    } catch (e) {
      _showSnackBar("Failed to load pets: $e", isError: true);
    } finally {
      isLoading.value = false;
    }
  }

  List<String> get services {
    // First try clinic settings, then fall back to clinic.services
    if (clinicSettings.value != null && clinicSettings.value!.services.isNotEmpty) {
      return clinicSettings.value!.services;
    }
    
    if (clinic.services.isNotEmpty) {
      return clinic.services.split(',').map((s) => s.trim()).toList();
    }
    
    return ['General Consultation', 'Vaccination', 'Check-up', 'Grooming'];
  }

  bool isDateSelectable(DateTime day) {
    // Disable past dates
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDay = DateTime(day.year, day.month, day.day);
    
    if (checkDay.isBefore(today)) return false;
    
    // Check clinic settings for availability
    if (clinicSettings.value != null) {
      // Check if clinic is open
      if (!clinicSettings.value!.isOpen) return false;
      
      // Check max advance booking
      final maxAdvanceDays = clinicSettings.value!.maxAdvanceBooking;
      final maxDate = today.add(Duration(days: maxAdvanceDays));
      if (checkDay.isAfter(maxDate)) return false;
      
      // Check if clinic is open on this day
      final dayName = _getDayName(checkDay.weekday);
      final dayHours = clinicSettings.value!.operatingHours[dayName];
      if (dayHours == null || dayHours['isOpen'] != true) return false;
    }
    
    return true;
  }

  void onDateSelected(DateTime selectedDay) {
    selectedDateTime.value = selectedDay;
    selectedTime.value = null; // Reset selected time
    updateAvailableTimes(selectedDay);
  }

  void updateAvailableTimes(DateTime date) {
    if (clinicSettings.value != null) {
      availableTimes.value = clinicSettings.value!.getAvailableTimeSlots(date);
    } else {
      // Fallback to default time slots
      availableTimes.value = [
        '9:00 AM',
        '10:00 AM',
        '11:00 AM',
        '1:00 PM',
        '2:00 PM',
        '3:00 PM',
        '4:00 PM',
      ];
    }
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

  void onTimeSelected(String? time) {
    selectedTime.value = time;
  }

  void onServiceSelected(String? service) {
    selectedService.value = service;
  }

  void onPetSelected(Pet? pet) {
    selectedPet.value = pet;
  }

  DateTime parseTimeStringToDateTime(DateTime date, String timeString) {
    // Handle both formats: "9:00 AM" and "09:00"
    if (timeString.contains('AM') || timeString.contains('PM')) {
      final timeParts = timeString.split(" ");
      final hourMinute = timeParts[0].split(":");
      int hour = int.parse(hourMinute[0]);
      final int minute = int.parse(hourMinute[1]);
      final meridian = timeParts[1].toUpperCase();

      if (meridian == 'PM' && hour != 12) {
        hour += 12;
      } else if (meridian == 'AM' && hour == 12) {
        hour = 0;
      }

      return DateTime(date.year, date.month, date.day, hour, minute);
    } else {
      // Handle 24-hour format "09:00"
      final hourMinute = timeString.split(":");
      final hour = int.parse(hourMinute[0]);
      final minute = int.parse(hourMinute[1]);
      return DateTime(date.year, date.month, date.day, hour, minute);
    }
  }

  bool get canBookAppointment {
    if (isBooking.value) return false;
    
    // Check basic fields
    if (selectedDateTime.value == null ||
        selectedTime.value == null ||
        selectedService.value == null ||
        selectedPet.value == null) {
      return false;
    }
    
    // Check if clinic is open for appointments
    if (clinicSettings.value != null && !clinicSettings.value!.isOpen) {
      return false;
    }
    
    return true;
  }

  String? get bookingValidationMessage {
    if (clinicSettings.value != null && !clinicSettings.value!.isOpen) {
      return "This clinic is currently closed for appointments";
    }
    
    if (selectedDateTime.value == null) {
      return "Please select a date";
    }
    
    if (selectedTime.value == null) {
      return "Please select a time";
    }
    
    if (selectedService.value == null) {
      return "Please select a service";
    }
    
    if (selectedPet.value == null) {
      return "Please select a pet";
    }
    
    return null;
  }

  Future<void> bookAppointment() async {
    final validationMessage = bookingValidationMessage;
    if (validationMessage != null) {
      _showSnackBar(validationMessage, isError: true);
      return;
    }

    final userId = session.userId;
    if (userId.isEmpty) {
      _showSnackBar("User not logged in", isError: true);
      return;
    }

    try {
      isBooking.value = true;

      final appointmentDateTime = parseTimeStringToDateTime(
        selectedDateTime.value!, 
        selectedTime.value!
      );

      final appointment = Appointment(
        userId: userId,
        clinicId: clinic.documentId ?? '',
        petId: selectedPet.value!.documentId ?? selectedPet.value!.name,
        service: selectedService.value!,
        dateTime: appointmentDateTime,
        status: (clinicSettings.value?.autoAcceptAppointments ?? false) ? 'accepted' : 'pending',
      );

      await authRepository.createAppointment(appointment);

      _showSuccessDialog();
      _resetForm();

    } catch (e) {
      _showSnackBar("Failed to book appointment: $e", isError: true);
    } finally {
      isBooking.value = false;
    }
  }

  void _resetForm() {
    selectedTime.value = null;
    selectedService.value = null;
    selectedPet.value = null;
    selectedDateTime.value = DateTime.now();
    updateAvailableTimes(DateTime.now());
  }

  void _showSnackBar(String message, {bool isError = false}) {
    Get.snackbar(
      isError ? "Error" : "Success",
      message,
      snackPosition: SnackPosition.TOP,
      backgroundColor: isError ? Colors.red[600] : Colors.green[600],
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 8,
    );
  }

  void _showSuccessDialog() {
    final autoAccept = clinicSettings.value?.autoAcceptAppointments ?? false;
    final statusText = autoAccept ? "confirmed" : "received and pending review";
    
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Appointment Booked!'),
          ],
        ),
        content: Text(
          'Your appointment with ${clinic.clinicName} has been $statusText. '
          '${autoAccept ? "You're all set!" : "You will receive a confirmation once the clinic reviews your request."}'
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5173B8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)
              ),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }
}
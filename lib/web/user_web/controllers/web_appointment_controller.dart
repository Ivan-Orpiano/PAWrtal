import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
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

  // Available time slots for appointments
  final List<String> availableTimes = [
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '1:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
  ];

  @override
  void onInit() {
    super.onInit();
    fetchUserPets();
    // Set default date to today
    selectedDateTime.value = DateTime.now();
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
    if (clinic.services.isEmpty) {
      return ['General Consultation', 'Vaccination', 'Check-up', 'Grooming'];
    }
    return clinic.services.split(',').map((s) => s.trim()).toList();
  }

  bool isDateSelectable(DateTime day) {
    // Disable past dates
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final checkDay = DateTime(day.year, day.month, day.day);
    
    return !checkDay.isBefore(today);
  }

  void onDateSelected(DateTime selectedDay) {
    selectedDateTime.value = selectedDay;
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
  }

  bool get canBookAppointment {
    return selectedDateTime.value != null &&
           selectedTime.value != null &&
           selectedService.value != null &&
           selectedPet.value != null &&
           !isBooking.value;
  }

  Future<void> bookAppointment() async {
    if (!canBookAppointment) {
      _showSnackBar("Please complete all fields", isError: true);
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
        petId: selectedPet.value!.name, // Using pet name as identifier
        service: selectedService.value!,
        dateTime: appointmentDateTime,
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
          'Your appointment with ${clinic.clinicName} has been successfully booked. '
          'You will receive a confirmation once the clinic reviews your request.'
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
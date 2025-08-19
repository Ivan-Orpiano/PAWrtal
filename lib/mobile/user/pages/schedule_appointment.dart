import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:capstone_app/mobile/user/components/pets_components/pets_controller.dart';
import 'package:capstone_app/mobile/user/components/appointment_tabs/components/appointment_controller.dart';

import '../../../data/models/appointment_model.dart';

class ScheduleAppointment extends StatefulWidget {
  final Clinic clinic;

  const ScheduleAppointment({super.key, required this.clinic});

  @override
  State<ScheduleAppointment> createState() => _ScheduleAppointmentState();
}

class _ScheduleAppointmentState extends State<ScheduleAppointment> {
  DateTime today = DateTime.now();
  String? selectedTime;
  String? selectedService;
  String? selectedPet;
  bool isBooking = false;

  final List<String> availableTimes = [
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '1:00 PM',
    '2:00 PM',
    '3:00 PM',
    '4:00 PM',
  ];

  PetsController? petsController;

  @override
  void initState() {
    super.initState();
    _initializePetsController();

    // Add focus listener to refresh pets when page regains focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final focusNode = FocusNode();
      focusNode.addListener(() {
        if (focusNode.hasFocus) {
          petsController?.fetchUserPets();
        }
      });
      FocusScope.of(context).requestFocus(focusNode);
    });
  }

  void _initializePetsController() {
    if (!Get.isRegistered<PetsController>()) {
      petsController = Get.put(
        PetsController(
          authRepository: Get.find(),
          session: Get.find(),
        ),
      );
    } else {
      petsController = Get.find();
    }

    // Always refresh pets when page is initialized
    petsController?.fetchUserPets();
  }

  List<String> get services {
    if (widget.clinic.services.isEmpty) {
      return ['General Consultation', 'Vaccination', 'Check-up', 'Grooming'];
    }
    return widget.clinic.services.split(',').map((s) => s.trim()).toList();
  }

  void _onDaySelected(DateTime day, DateTime focusedDay) {
    setState(() {
      today = day;
    });
  }

  bool _isDateSelectable(DateTime day) {
    // Disable past dates and maybe weekends based on clinic settings
    if (day.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      return false;
    }
    return true;
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

  Future<void> _bookAppointment() async {
    if (selectedPet == null ||
        selectedService == null ||
        selectedTime == null) {
      _showSnackBar("Please complete all fields", isError: true);
      return;
    }

    final userId = Get.find<UserSessionService>().userId;
    if (userId.isEmpty) {
      _showSnackBar("User not logged in", isError: true);
      return;
    }

    setState(() {
      isBooking = true;
    });

    try {
      final selectedDateTime = parseTimeStringToDateTime(today, selectedTime!);

      final appointment = Appointment(
        userId: userId,
        clinicId: widget.clinic.documentId ?? '',
        petId: selectedPet!,
        service: selectedService!,
        dateTime: selectedDateTime,
      );

      await Get.find<AuthRepository>().createAppointment(appointment);

      // Refresh appointments if controller exists
      if (Get.isRegistered<EnhancedUserAppointmentController>()) {
        Get.find<EnhancedUserAppointmentController>().fetchAppointments();
      }

      _showSuccessDialog();
    } catch (e) {
      _showSnackBar("Failed to book appointment: $e", isError: true);
    } finally {
      setState(() {
        isBooking = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Success!'),
          ],
        ),
        content: const Text(
            'Your appointment has been booked successfully. You will receive a confirmation once the clinic reviews your request.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 81, 115, 153),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.grey[800],
        ),
      ),
    );
  }

  Widget _buildTimeSlot(String time) {
    final isSelected = selectedTime == time;
    return GestureDetector(
      onTap: () => setState(() => selectedTime = time),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color.fromARGB(255, 81, 115, 153)
              : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color.fromARGB(255, 81, 115, 153)
                : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          time,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
      body: Column(
        children: [
          // Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Book Appointment',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.clinic.clinicName,
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Calendar
                    _buildSectionTitle('Select Date'),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[200]!),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TableCalendar(
                        focusedDay: today,
                        firstDay: DateTime.now(),
                        lastDay: DateTime.now().add(const Duration(days: 90)),
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          titleTextStyle: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: const Color.fromARGB(255, 81, 115, 153)
                                .withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: const BoxDecoration(
                            color: Color.fromARGB(255, 81, 115, 153),
                            shape: BoxShape.circle,
                          ),
                          weekendTextStyle: TextStyle(color: Colors.grey[600]),
                          outsideDaysVisible: false,
                        ),
                        enabledDayPredicate: _isDateSelectable,
                        onDaySelected: _onDaySelected,
                        selectedDayPredicate: (day) => isSameDay(day, today),
                      ),
                    ),

                    // Time slots
                    _buildSectionTitle('Available Times'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Wrap(
                        children: availableTimes.map(_buildTimeSlot).toList(),
                      ),
                    ),

                    // Service selection
                    _buildSectionTitle('Select Service'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButtonFormField<String>(
                        value: selectedService,
                        decoration: InputDecoration(
                          hintText: 'Choose a service',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color.fromARGB(255, 81, 115, 153),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        items: services
                            .map((service) => DropdownMenuItem(
                                  value: service,
                                  child: Text(service),
                                ))
                            .toList(),
                        onChanged: (value) =>
                            setState(() => selectedService = value),
                      ),
                    ),

                    // Pet selection
                    _buildSectionTitle('Select Pet'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Obx(() {
                        if (petsController!.isLoading.value) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 12),
                                Text('Loading pets...'),
                              ],
                            ),
                          );
                        }

                        if (petsController!.pets.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                                'No pets found. Please add a pet first.'),
                          );
                        }

                        return DropdownButtonFormField<String>(
                          value: selectedPet,
                          decoration: InputDecoration(
                            hintText: 'Choose your pet',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color.fromARGB(255, 81, 115, 153),
                              ),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          items: petsController!.pets
                              .map((pet) => DropdownMenuItem(
                                    value: pet.name,
                                    child: Row(
                                      children: [
                                        Icon(Icons.pets,
                                            size: 20, color: Colors.grey[600]),
                                        const SizedBox(width: 8),
                                        Text(pet.name),
                                      ],
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) =>
                              setState(() => selectedPet = value),
                        );
                      }),
                    ),

                    // Book button
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isBooking ? null : _bookAppointment,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 81, 115, 153),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: isBooking
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                Colors.white),
                                      ),
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Booking...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Book Appointment',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

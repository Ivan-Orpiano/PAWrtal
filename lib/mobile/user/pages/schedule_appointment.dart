import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:get/get.dart';
import 'package:capstone_app/mobile/user/components/pets_components/pets_controller.dart';

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

// TODO: Replace with actual data later
  final List<String> availableTimes = [
    '9:00 AM',
    '10:00 AM',
    '11:00 AM',
    '1:00 PM',
    '2:00 PM',
  ];

  PetsController? petsController;

  @override
  void initState() {
    super.initState();

    if (!Get.isRegistered<PetsController>()) {
      petsController = Get.put(
        PetsController(
          authRepository: Get.find(),
          session: Get.find(),
        ),
      );
    } else {
      petsController = Get.find();
      // In case pets were not fetched yet due to a previous lazy load:
      if (petsController?.pets.isEmpty ?? true) {
        petsController?.fetchUserPets();
      }
    }
  }

  final List<String> services = [
    'Vaccination',
    'Check-up',
    'Grooming',
  ]; // Replace with clinic's services from database

  void _onDaySelected(DateTime day, DateTime focusedDay) {
    setState(() {
      today = day;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
      body: Column(
        children: [
          SizedBox(
            height: 100,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 35),
                  child: IconButton(
                    icon: const Icon(
                      Icons.keyboard_arrow_left_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color.fromARGB(255, 230, 230, 230),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.only(
                      bottom: 30), // Prevent clipping on bottom
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TableCalendar(
                          focusedDay: today,
                          firstDay: DateTime.utc(2025, 1, 1),
                          lastDay: DateTime.utc(2030, 12, 31),
                          headerStyle: const HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                          ),
                          availableGestures: AvailableGestures.all,
                          onDaySelected: _onDaySelected,
                          selectedDayPredicate: (day) => isSameDay(day, today),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: DropdownMenu(
                          width: double.infinity,
                          label: const Text("Select a Time"),
                          inputDecorationTheme: InputDecorationTheme(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onSelected: (value) =>
                              setState(() => selectedTime = value),
                          dropdownMenuEntries: availableTimes
                              .map((time) =>
                                  DropdownMenuEntry(value: time, label: time))
                              .toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: DropdownMenu(
                          width: double.infinity,
                          label: const Text("Service"),
                          inputDecorationTheme: InputDecorationTheme(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onSelected: (value) =>
                              setState(() => selectedService = value),
                          dropdownMenuEntries: services.isNotEmpty
                              ? services
                                  .map((service) => DropdownMenuEntry(
                                      value: service, label: service))
                                  .toList()
                              : [
                                  const DropdownMenuEntry(
                                      value: "none",
                                      label: "No services available")
                                ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Obx(() {
                                if (petsController!.isLoading.value) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }

                                if (petsController!.pets.isEmpty) {
                                  return const Center(
                                      child: Text("No pets found."));
                                }

                                return DropdownMenu(
                                  width: double.infinity,
                                  label: const Text("Pet"),
                                  inputDecorationTheme: InputDecorationTheme(
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                  ),
                                  onSelected: (value) =>
                                      setState(() => selectedPet = value),
                                  dropdownMenuEntries: petsController!.pets
                                      .map((pet) => DropdownMenuEntry(
                                          value: pet.name, label: pet.name))
                                      .toList(),
                                );
                              }),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 20),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 75, vertical: 15),
                              backgroundColor:
                                  const Color.fromARGB(255, 81, 115, 153),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20)),
                            ),
                            onPressed: () async {
                              if (selectedPet == null ||
                                  selectedService == null ||
                                  selectedTime == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                          Text("Please complete all fields")),
                                );
                                return;
                              }

                              final userId =
                                  Get.find<UserSessionService>().userId;
                              if (userId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("User not logged in")),
                                );
                                return;
                              }

                              final appointment = Appointment(
                                userId: userId,
                                clinicId: widget.clinic.documentId ?? '',
                                petName: selectedPet!,
                                service: selectedService!,
                                time: selectedTime!,
                                date: today,
                              );

                              try {
                                await Get.find<AuthRepository>()
                                    .createAppointment(appointment);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          "Appointment booked successfully!")),
                                );
                                Navigator.pop(
                                    context); // Return to previous page
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          "Failed to book appointment: $e")),
                                );
                              }
                            },
                            child: const Text(
                              "Continue",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

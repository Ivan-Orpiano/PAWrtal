import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:capstone_app/web/user_web/controllers/user_web_appointment_controller.dart';

class EnhancedWebAppointmentPanel extends StatefulWidget {
  final Clinic clinic;
  final double? maxHeight;
  final bool compact;

  const EnhancedWebAppointmentPanel({
    super.key,
    required this.clinic,
    this.maxHeight,
    this.compact = false,
  });

  @override
  State<EnhancedWebAppointmentPanel> createState() =>
      _EnhancedWebAppointmentPanelState();
}

class _EnhancedWebAppointmentPanelState
    extends State<EnhancedWebAppointmentPanel> {
  late WebAppointmentController controller;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<WebAppointmentController>(
        tag: widget.clinic.documentId)) {
      controller = Get.put(
        WebAppointmentController(
          authRepository: Get.find<AuthRepository>(),
          session: Get.find<UserSessionService>(),
          clinic: widget.clinic,
        ),
        tag: widget.clinic.documentId,
      );
    } else {
      controller =
          Get.find<WebAppointmentController>(tag: widget.clinic.documentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCalendarSection(),
        const SizedBox(height: 32),
        _buildDetailsSection(),
        const SizedBox(height: 32),
        _buildPetSection(),
        const SizedBox(height: 32),
        _buildBookButton(),
      ],
    );
  }

  Widget _buildCalendarSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Date',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Obx(() {
          // Get closed dates from controller
          final closedDates = controller.closedDates.toSet();

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[200]!),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TableCalendar(
                  focusedDay:
                      controller.selectedDateTime.value ?? DateTime.now(),
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(Duration(
                    days: controller.clinicSettings.value?.maxAdvanceBooking ??
                        30,
                  )),
                  headerStyle: HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                    titleTextStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                    leftChevronIcon: Icon(Icons.chevron_left,
                        color: Colors.grey[600], size: 24),
                    rightChevronIcon: Icon(Icons.chevron_right,
                        color: Colors.grey[600], size: 24),
                  ),
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(
                      color: const Color(0xFF5173B8).withOpacity(0.6),
                      border: Border.all(color: Color(0xFF5173B8)),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      color: Color(0xFF5173B8),
                      shape: BoxShape.circle,
                    ),
                    weekendTextStyle: TextStyle(color: Colors.grey[600]),
                    outsideDaysVisible: false,
                    cellMargin: const EdgeInsets.all(4),
                    disabledTextStyle: TextStyle(color: Colors.grey[400]),
                    defaultTextStyle: const TextStyle(fontSize: 14),
                  ),
                  calendarBuilders: CalendarBuilders(
                    defaultBuilder: (context, day, focusedDay) {
                      final dateStr =
                          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

                      if (closedDates.contains(dateStr)) {
                        // Show closed dates with red background
                        return Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            border: Border.all(color: Colors.red[200]!),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: Colors.red[400],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                    disabledBuilder: (context, day, focusedDay) {
                      final dateStr =
                          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

                      if (closedDates.contains(dateStr)) {
                        // Show closed dates with red background even if disabled
                        return Container(
                          margin: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red[50],
                            border: Border.all(color: Colors.red[200]!),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${day.day}',
                            style: TextStyle(
                              color: Colors.red[300],
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                  daysOfWeekStyle: const DaysOfWeekStyle(
                    weekdayStyle:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    weekendStyle:
                        TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  enabledDayPredicate: controller.isDateSelectable,
                  onDaySelected: (selectedDay, focusedDay) {
                    if (controller.isDateSelectable(selectedDay)) {
                      controller.onDateSelected(selectedDay);
                    } else {
                      // Check if it's a closed date
                      final dateStr =
                          '${selectedDay.year}-${selectedDay.month.toString().padLeft(2, '0')}-${selectedDay.day.toString().padLeft(2, '0')}';
                      if (closedDates.contains(dateStr)) {
                        _showClosedDateMessage();
                      }
                    }
                  },
                  selectedDayPredicate: (day) =>
                      isSameDay(day, controller.selectedDateTime.value),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDetailsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appointment Details',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTimeSelector()),
            const SizedBox(width: 16),
            Expanded(child: _buildServiceSelector()),
          ],
        ),
      ],
    );
  }

  Widget _buildTimeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: controller.selectedTime.value,
                  hint: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.access_time, size: 20),
                        SizedBox(width: 8),
                        Text('Select time', style: TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                  isExpanded: true,
                  items: controller.availableTimes.map((time) {
                    return DropdownMenuItem<String>(
                      value: time,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            const SizedBox(width: 8),
                            Text(time, style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: controller.availableTimes.isEmpty
                      ? null
                      : controller.onTimeSelected,
                ),
              ),
            )),
        Obx(() {
          if (controller.selectedDateTime.value != null &&
              controller.availableTimes.isEmpty &&
              controller.clinicSettings.value != null) {
            return Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'No available times for this date',
                style: TextStyle(fontSize: 12, color: Colors.red[600]),
              ),
            );
          }
          return const SizedBox.shrink();
        }),
      ],
    );
  }

  Widget _buildServiceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Service',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Obx(() => Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: controller.selectedService.value,
                  hint: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child:
                        Text('Choose service', style: TextStyle(fontSize: 14)),
                  ),
                  isExpanded: true,
                  items: controller.services.map((service) {
                    return DropdownMenuItem<String>(
                      value: service,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          service,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: controller.onServiceSelected,
                ),
              ),
            )),
      ],
    );
  }

  Widget _buildPetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Pet',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),
        Obx(() {
          if (controller.isLoading.value) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Loading pets...', style: TextStyle(fontSize: 14)),
                ],
              ),
            );
          }

          if (controller.pets.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange[300]!),
                borderRadius: BorderRadius.circular(8),
                color: Colors.orange[50],
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[600], size: 24),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'No pets found. Please add a pet to your profile first.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Pet>(
                value: controller.selectedPet.value,
                hint: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.pets, size: 20),
                      SizedBox(width: 12),
                      Text('Choose your pet', style: TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
                isExpanded: true,
                items: controller.pets.map((pet) {
                  return DropdownMenuItem<Pet>(
                    value: pet,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.grey[200],
                            backgroundImage:
                                pet.image != null && pet.image!.isNotEmpty
                                    ? NetworkImage(pet.image!)
                                    : null,
                            child: pet.image == null || pet.image!.isEmpty
                                ? const Icon(Icons.pets, size: 16)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  pet.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${pet.type} • ${pet.breed}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: controller.onPetSelected,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBookButton() {
    return Obx(() {
      final validationMessage = controller.bookingValidationMessage;
      final isEnabled = controller.canBookAppointment;

      return Column(
        children: [
          if (validationMessage != null && !controller.isBooking.value)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      validationMessage,
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: isEnabled ? controller.bookAppointment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isEnabled ? const Color(0xFF5173B8) : Colors.grey[300],
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: isEnabled ? 2 : 0,
              ),
              child: controller.isBooking.value
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
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
                        color: isEnabled ? Colors.white : Colors.grey[600],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      );
    });
  }

  void _showClosedDateMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.event_busy, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'This clinic is closed on the selected date. Please choose another day.',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

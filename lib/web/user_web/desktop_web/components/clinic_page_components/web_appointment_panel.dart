import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:capstone_app/web/user_web/controllers/web_appointment_controller.dart';

class EnhancedWebAppointmentPanel extends StatefulWidget {
  final Clinic clinic;

  const EnhancedWebAppointmentPanel({super.key, required this.clinic});

  @override
  State<EnhancedWebAppointmentPanel> createState() => _EnhancedWebAppointmentPanelState();
}

class _EnhancedWebAppointmentPanelState extends State<EnhancedWebAppointmentPanel> {
  late WebAppointmentController controller;

  @override
  void initState() {
    super.initState();
    // Initialize controller with dependencies
    controller = Get.put(
      WebAppointmentController(
        authRepository: Get.find<AuthRepository>(),
        session: Get.find<UserSessionService>(),
        clinic: widget.clinic,
      ),
      tag: widget.clinic.documentId, // Use unique tag for each clinic
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 420,
      constraints: const BoxConstraints(maxHeight: 800),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with clinic status
          Obx(() => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _getHeaderColor(),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(_getHeaderIcon(), color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book Appointment',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (controller.clinicSettings.value != null)
                        Text(
                          _getClinicStatusText(),
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          )),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Clinic status banner (if closed)
                  _buildStatusBanner(),
                  
                  // Calendar Section
                  _buildSectionHeader('Select Date'),
                  const SizedBox(height: 12),
                  _buildCalendar(),
                  
                  const SizedBox(height: 24),
                  
                  // Time & Service Selection
                  _buildSectionHeader('Appointment Details'),
                  const SizedBox(height: 12),
                  _buildTimeServiceRow(),
                  
                  const SizedBox(height: 20),
                  
                  // Pet Selection
                  _buildSectionHeader('Select Pet'),
                  const SizedBox(height: 12),
                  _buildPetSelection(),
                  
                  const SizedBox(height: 24),
                  
                  // Book Button
                  _buildBookButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getHeaderColor() {
    if (controller.clinicSettings.value == null) {
      return const Color(0xFF5173B8);
    }
    
    final settings = controller.clinicSettings.value!;
    if (!settings.isOpen) {
      return Colors.red;
    } else if (!settings.isOpenNow()) {
      return Colors.orange;
    } else {
      return const Color(0xFF5173B8);
    }
  }

  IconData _getHeaderIcon() {
    if (controller.clinicSettings.value == null) {
      return Icons.calendar_today;
    }
    
    final settings = controller.clinicSettings.value!;
    if (!settings.isOpen) {
      return Icons.cancel;
    } else if (!settings.isOpenNow()) {
      return Icons.schedule;
    } else {
      return Icons.calendar_today;
    }
  }

  String _getClinicStatusText() {
    if (controller.clinicSettings.value == null) {
      return '';
    }
    
    final settings = controller.clinicSettings.value!;
    if (!settings.isOpen) {
      return 'Currently closed';
    } else if (!settings.isOpenNow()) {
      return 'Closed Now';
    } else {
      return 'Open - ${settings.getTodayHours()}';
    }
  }

  Widget _buildStatusBanner() {
    return Obx(() {
      if (controller.clinicSettings.value == null) {
        return const SizedBox.shrink();
      }
      
      final settings = controller.clinicSettings.value!;
      if (settings.isOpen && settings.isOpenNow()) {
        return const SizedBox.shrink();
      }
      
      Color bannerColor;
      String bannerText;
      IconData bannerIcon;
      
      if (!settings.isOpen) {
        bannerColor = Colors.red;
        bannerText = 'This clinic is currently closed for appointments';
        bannerIcon = Icons.cancel;
      } else {
        bannerColor = Colors.orange;
        bannerText = 'This clinic is closed today';
        bannerIcon = Icons.schedule;
      }
      
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: bannerColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: bannerColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(bannerIcon, color: bannerColor, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                bannerText,
                style: TextStyle(
                  color: bannerColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.grey[800],
      ),
    );
  }

  Widget _buildCalendar() {
    return Obx(() => Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TableCalendar(
        focusedDay: controller.selectedDateTime.value ?? DateTime.now(),
        firstDay: DateTime.now(),
        lastDay: DateTime.now().add(Duration(
          days: controller.clinicSettings.value?.maxAdvanceBooking ?? 30,
        )),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.grey[800],
          ),
          leftChevronIcon: Icon(Icons.chevron_left, color: Colors.grey[600]),
          rightChevronIcon: Icon(Icons.chevron_right, color: Colors.grey[600]),
        ),
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: const Color(0xFF5173B8).withOpacity(0.3),
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
        ),
        enabledDayPredicate: controller.isDateSelectable,
        onDaySelected: (selectedDay, focusedDay) {
          if (controller.isDateSelectable(selectedDay)) {
            controller.onDateSelected(selectedDay);
          }
        },
        selectedDayPredicate: (day) =>
            isSameDay(day, controller.selectedDateTime.value),
      ),
    ));
  }

  Widget _buildTimeServiceRow() {
    return Row(
      children: [
        Expanded(
          child: Column(
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
              const SizedBox(height: 6),
              Obx(() => Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.selectedTime.value,
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Select time'),
                    ),
                    isExpanded: true,
                    items: controller.availableTimes.map((time) {
                      return DropdownMenuItem<String>(
                        value: time,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(time),
                        ),
                      );
                    }).toList(),
                    onChanged: controller.availableTimes.isEmpty 
                        ? null 
                        : controller.onTimeSelected,
                  ),
                ),
              )),
              // Show message if no times available
              Obx(() {
                if (controller.selectedDateTime.value != null && 
                    controller.availableTimes.isEmpty &&
                    controller.clinicSettings.value != null) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'No available times for this date',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[600],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
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
              const SizedBox(height: 6),
              Obx(() => Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.selectedService.value,
                    hint: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Choose service'),
                    ),
                    isExpanded: true,
                    items: controller.services.map((service) {
                      return DropdownMenuItem<String>(
                        value: service,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            service,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: controller.onServiceSelected,
                  ),
                ),
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPetSelection() {
    return Obx(() {
      if (controller.isLoading.value) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
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
              Text('Loading pets...'),
            ],
          ),
        );
      }

      if (controller.pets.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.orange[50],
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, color: Colors.orange[600]),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('No pets found. Please add a pet to your profile first.'),
              ),
            ],
          ),
        );
      }

      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<Pet>(
            value: controller.selectedPet.value,
            hint: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Icon(Icons.pets, size: 20),
                  SizedBox(width: 8),
                  Text('Choose your pet'),
                ],
              ),
            ),
            isExpanded: true,
            items: controller.pets.map((pet) {
              return DropdownMenuItem<Pet>(
                value: pet,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: pet.image != null && pet.image!.isNotEmpty
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
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '${pet.type} • ${pet.breed}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
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
    });
  }

  Widget _buildBookButton() {
    return Obx(() {
      final validationMessage = controller.bookingValidationMessage;
      final isEnabled = controller.canBookAppointment;
      
      return Column(
        children: [
          // Show validation message if any
          if (validationMessage != null && !controller.isBooking.value)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      validationMessage,
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: isEnabled ? controller.bookAppointment : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isEnabled ? const Color(0xFF5173B8) : Colors.grey[300],
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
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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

  @override
  void dispose() {
    // Clean up controller
    Get.delete<WebAppointmentController>(tag: widget.clinic.documentId);
    super.dispose();
  }
}
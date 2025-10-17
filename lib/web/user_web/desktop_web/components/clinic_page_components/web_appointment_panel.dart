import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/mobile/user/controllers/user_messaging_controller.dart';
import 'package:capstone_app/web/pages/web_user_home/web_user_home_controller.dart';
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
  State<EnhancedWebAppointmentPanel> createState() => _EnhancedWebAppointmentPanelState();
}

class _EnhancedWebAppointmentPanelState extends State<EnhancedWebAppointmentPanel> {
  late WebAppointmentController controller;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialize controller with dependencies only if not already created
    if (!Get.isRegistered<WebAppointmentController>(tag: widget.clinic.documentId)) {
      controller = Get.put(
        WebAppointmentController(
          authRepository: Get.find<AuthRepository>(),
          session: Get.find<UserSessionService>(),
          clinic: widget.clinic,
        ),
        tag: widget.clinic.documentId,
      );
    } else {
      controller = Get.find<WebAppointmentController>(tag: widget.clinic.documentId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final effectiveMaxHeight = widget.maxHeight ?? _calculateMaxHeight(screenHeight);
    
    return Container(
      width: 420,
      constraints: BoxConstraints(
        maxHeight: effectiveMaxHeight,
        minHeight: widget.compact ? 400 : 500,
      ),
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
          _buildHeader(),
          Flexible(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: false,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.all(widget.compact ? 16 : 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStatusBanner(),
                    _buildSectionHeader('Select Date'),
                    SizedBox(height: widget.compact ? 8 : 12),
                    _buildCalendar(),
                    SizedBox(height: widget.compact ? 16 : 24),
                    _buildSectionHeader('Appointment Details'),
                    SizedBox(height: widget.compact ? 8 : 12),
                    _buildTimeServiceRow(),
                    SizedBox(height: widget.compact ? 16 : 20),
                    _buildSectionHeader('Select Pet'),
                    SizedBox(height: widget.compact ? 8 : 12),
                    _buildPetSelection(),
                    SizedBox(height: widget.compact ? 16 : 24),
                    _buildBookButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateMaxHeight(double screenHeight) {
    if (screenHeight <= 768) {
      return screenHeight * 0.75;
    } else if (screenHeight <= 1080) {
      return screenHeight * 0.7;
    } else {
      return 800;
    }
  }

  Widget _buildHeader() {
    return Obx(() => Container(
          width: double.infinity,
          padding: EdgeInsets.all(widget.compact ? 16 : 20),
          decoration: BoxDecoration(
            color: _getHeaderColor(),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getHeaderIcon(),
                color: Colors.white,
                size: widget.compact ? 20 : 24,
              ),
              SizedBox(width: widget.compact ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Book Appointment',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: widget.compact ? 18 : 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (controller.clinicSettings.value != null)
                      Text(
                        _getClinicStatusText(),
                        style: GoogleFonts.inter(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: widget.compact ? 12 : 14,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: widget.compact ? 8 : 12),
              _buildMessageBtn(),
            ],
          ),
        ));
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
        padding: EdgeInsets.all(widget.compact ? 10 : 12),
        margin: EdgeInsets.only(bottom: widget.compact ? 16 : 20),
        decoration: BoxDecoration(
          color: bannerColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: bannerColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(bannerIcon, color: bannerColor, size: widget.compact ? 18 : 20),
            SizedBox(width: widget.compact ? 6 : 8),
            Expanded(
              child: Text(
                bannerText,
                style: TextStyle(
                  color: bannerColor,
                  fontWeight: FontWeight.w600,
                  fontSize: widget.compact ? 12 : 14,
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
        fontSize: widget.compact ? 14 : 16,
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
            fontSize: widget.compact ? 14 : 16,
            color: Colors.grey[800],
          ),
          leftChevronIcon: Icon(Icons.chevron_left, 
            color: Colors.grey[600], 
            size: widget.compact ? 20 : 24
          ),
          rightChevronIcon: Icon(Icons.chevron_right, 
            color: Colors.grey[600],
            size: widget.compact ? 20 : 24
          ),
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
          cellMargin: EdgeInsets.all(widget.compact ? 2 : 4),
          disabledTextStyle: TextStyle(color: Colors.grey[400]),
          defaultTextStyle: TextStyle(fontSize: widget.compact ? 12 : 14),
        ),
        daysOfWeekStyle: DaysOfWeekStyle(
          weekdayStyle: TextStyle(fontSize: widget.compact ? 11 : 13),
          weekendStyle: TextStyle(fontSize: widget.compact ? 11 : 13),
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
                  fontSize: widget.compact ? 12 : 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: widget.compact ? 4 : 6),
              Obx(() => Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.selectedTime.value,
                    hint: Padding(
                      padding: EdgeInsets.symmetric(horizontal: widget.compact ? 8 : 12),
                      child: Text(
                        'Select time',
                        style: TextStyle(fontSize: widget.compact ? 12 : 14),
                      ),
                    ),
                    isExpanded: true,
                    items: controller.availableTimes.map((time) {
                      return DropdownMenuItem<String>(
                        value: time,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: widget.compact ? 8 : 12),
                          child: Text(
                            time,
                            style: TextStyle(fontSize: widget.compact ? 12 : 14),
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
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'No available times',
                      style: TextStyle(
                        fontSize: widget.compact ? 10 : 12,
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
        SizedBox(width: widget.compact ? 12 : 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Service',
                style: GoogleFonts.inter(
                  fontSize: widget.compact ? 12 : 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: widget.compact ? 4 : 6),
              Obx(() => Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.selectedService.value,
                    hint: Padding(
                      padding: EdgeInsets.symmetric(horizontal: widget.compact ? 8 : 12),
                      child: Text(
                        'Choose service',
                        style: TextStyle(fontSize: widget.compact ? 12 : 14),
                      ),
                    ),
                    isExpanded: true,
                    items: controller.services.map((service) {
                      return DropdownMenuItem<String>(
                        value: service,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: widget.compact ? 8 : 12),
                          child: Text(
                            service,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: widget.compact ? 12 : 14),
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
          padding: EdgeInsets.all(widget.compact ? 12 : 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(
                width: widget.compact ? 16 : 20,
                height: widget.compact ? 16 : 20,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: widget.compact ? 8 : 12),
              Text(
                'Loading pets...',
                style: TextStyle(fontSize: widget.compact ? 12 : 14),
              ),
            ],
          ),
        );
      }

      if (controller.pets.isEmpty) {
        return Container(
          padding: EdgeInsets.all(widget.compact ? 12 : 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.orange[300]!),
            borderRadius: BorderRadius.circular(8),
            color: Colors.orange[50],
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline, 
                color: Colors.orange[600],
                size: widget.compact ? 16 : 20,
              ),
              SizedBox(width: widget.compact ? 8 : 12),
              Expanded(
                child: Text(
                  'No pets found. Please add a pet to your profile first.',
                  style: TextStyle(fontSize: widget.compact ? 12 : 14),
                ),
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
            hint: Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.compact ? 8 : 12),
              child: Row(
                children: [
                  Icon(Icons.pets, size: widget.compact ? 16 : 20),
                  SizedBox(width: widget.compact ? 6 : 8),
                  Text(
                    'Choose your pet',
                    style: TextStyle(fontSize: widget.compact ? 12 : 14),
                  ),
                ],
              ),
            ),
            isExpanded: true,
            items: controller.pets.map((pet) {
              return DropdownMenuItem<Pet>(
                value: pet,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: widget.compact ? 8 : 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: widget.compact ? 14 : 16,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: pet.image != null && pet.image!.isNotEmpty
                            ? NetworkImage(pet.image!)
                            : null,
                        child: pet.image == null || pet.image!.isEmpty
                            ? Icon(Icons.pets, size: widget.compact ? 12 : 16)
                            : null,
                      ),
                      SizedBox(width: widget.compact ? 8 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              pet.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: widget.compact ? 12 : 14,
                              ),
                            ),
                            Text(
                              '${pet.type} • ${pet.breed}',
                              style: TextStyle(
                                fontSize: widget.compact ? 10 : 12,
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
          if (validationMessage != null && !controller.isBooking.value)
            Container(
              padding: EdgeInsets.all(widget.compact ? 10 : 12),
              margin: EdgeInsets.only(bottom: widget.compact ? 10 : 12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline, 
                    color: Colors.orange[700], 
                    size: widget.compact ? 14 : 16
                  ),
                  SizedBox(width: widget.compact ? 6 : 8),
                  Expanded(
                    child: Text(
                      validationMessage,
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: widget.compact ? 11 : 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          SizedBox(
            width: double.infinity,
            height: widget.compact ? 44 : 48,
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
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: widget.compact ? 16 : 20,
                          height: widget.compact ? 16 : 20,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: widget.compact ? 8 : 12),
                        Text(
                          'Booking...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: widget.compact ? 14 : 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Book Appointment',
                      style: GoogleFonts.inter(
                        color: isEnabled ? Colors.white : Colors.grey[600],
                        fontSize: widget.compact ? 14 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildMessageBtn() {
    return IconButton(
      icon: const Icon(
        Icons.message_rounded,
        color: Colors.white,
      ),
      onPressed: () => _startConversationWithClinic(context),
      tooltip: 'Message Clinic',
    );
  }

  Future<void> _startConversationWithClinic(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF5173B8),
          ),
        ),
      );

      final MessagingController messagingController = Get.find<MessagingController>();
      final UserSessionService userSession = Get.find<UserSessionService>();

      if (userSession.userId.isEmpty) {
        Navigator.pop(context);
        _showLoginRequiredDialog(context);
        return;
      }

      final conversation = await messagingController.startConversationWithClinic(
          widget.clinic.documentId!);

      Navigator.pop(context);

      if (conversation != null && context.mounted) {
        // Open the conversation in MessagingController
        await messagingController.openConversation(
          conversation,
          widget.clinic.documentId!,
          'clinic',
        );
        
        // Get or create the WebUserHomeController
        final homeController = Get.isRegistered<WebUserHomeController>()
            ? Get.find<WebUserHomeController>()
            : Get.put(WebUserHomeController());
        
        // Navigate to Messages tab (index 2)
        homeController.onItemSelected(2);
        
        // Pop back to close the current page if needed
        Navigator.pop(context);
      } else {
        if (context.mounted) {
          _showErrorDialog(context, 'Failed to start conversation. Please try again.');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showErrorDialog(context, 'Error starting conversation: $e');
      }
    }
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Login Required'),
        content: const Text('Please log in to start a conversation with this clinic.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Navigate to login page
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5173B8),
            ),
            child: const Text(
              'Login',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
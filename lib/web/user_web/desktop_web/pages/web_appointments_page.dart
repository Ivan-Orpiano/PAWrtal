import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/models/ratings_and_review_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/mobile/user/components/appointment_tabs/components/user_appointment_controller.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/appointment_components/user_web_appointment_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:appwrite/appwrite.dart';

class EnhancedWebAppointmentsPage extends StatefulWidget {
  const EnhancedWebAppointmentsPage({super.key});

  @override
  State<EnhancedWebAppointmentsPage> createState() =>
      _EnhancedWebAppointmentsPageState();
}

class _EnhancedWebAppointmentsPageState
    extends State<EnhancedWebAppointmentsPage> {
  int selectedTabIndex = 0;
  final double tabletWidth = 1100;
  late EnhancedUserAppointmentController appointmentController;
  
  // Track reviewed appointments in memory
  final Set<String> _reviewedAppointments = {};

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void _initializeController() {
    if (!Get.isRegistered<EnhancedUserAppointmentController>()) {
      appointmentController = Get.put(EnhancedUserAppointmentController(
        authRepository: Get.find<AuthRepository>(),
        session: Get.find<UserSessionService>(),
      ));
    } else {
      appointmentController = Get.find<EnhancedUserAppointmentController>();
      appointmentController.fetchAppointments();
    }
  }

  // Method to check if appointment has been reviewed
  Future<bool> _checkIfReviewed(String appointmentId) async {
    // Check memory first
    if (_reviewedAppointments.contains(appointmentId)) {
      return true;
    }
    
    // Check database
    final hasReview = await Get.find<AuthRepository>()
        .hasUserReviewedAppointment(appointmentId);
    
    if (hasReview) {
      setState(() {
        _reviewedAppointments.add(appointmentId);
      });
    }
    
    return hasReview;
  }

  // Mark appointment as reviewed in memory
  void _markAsReviewed(String appointmentId) {
    setState(() {
      _reviewedAppointments.add(appointmentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isTablet = constraints.maxWidth < tabletWidth;

        return Scaffold(
          backgroundColor: const Color(0xFFEEEEEE),
          body: Container(
            padding: EdgeInsets.symmetric(
                horizontal: isTablet ? 20 : 65, vertical: 16),
            child: Column(
              children: [
                _buildEnhancedAppointmentBar(isTablet),
                const SizedBox(height: 16),
                if (isTablet) _buildTabletView() else _buildDesktopView(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopView() {
    return Expanded(
      child: Obx(() {
        if (appointmentController.isLoading.value) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                    color: Color.fromARGB(255, 81, 115, 153)),
                SizedBox(height: 16),
                Text('Loading appointments...',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return Row(
          children: [
            _buildAppointmentColumn("Pending", appointmentController.pending,
                Colors.orange, Icons.pending_actions),
            const SizedBox(width: 16),
            _buildAppointmentColumn("Upcoming", appointmentController.upcoming,
                Colors.blue, Icons.event_available),
            const SizedBox(width: 16),
            _buildAppointmentColumn(
                "Completed",
                appointmentController.completed,
                Colors.green,
                Icons.check_circle),
            const SizedBox(width: 16),
            _buildAppointmentColumn("History", appointmentController.history,
                Colors.grey, Icons.history),
          ],
        );
      }),
    );
  }

  Widget _buildTabletView() {
    return Expanded(
      child: Column(
        children: [
          _buildTabSelector(),
          const SizedBox(height: 16),
          Expanded(
            child: _buildSelectedTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Obx(() => Row(
            children: [
              _buildTabButton(0, Icons.event_available, "Upcoming", Colors.blue,
                  appointmentController.upcoming.length),
              _buildTabButton(1, Icons.pending_actions, "Pending",
                  Colors.orange, appointmentController.pending.length),
              _buildTabButton(2, Icons.check_circle, "Completed", Colors.green,
                  appointmentController.completed.length),
              _buildTabButton(3, Icons.history, "History", Colors.grey,
                  appointmentController.history.length),
            ],
          )),
    );
  }

  Widget _buildTabButton(
      int index, IconData icon, String text, Color color, int count) {
    bool isSelected = selectedTabIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedTabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: isSelected ? Border.all(color: color, width: 2) : null,
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.black : Colors.grey.shade600,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  text,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.black : Colors.grey.shade700,
                    fontSize: 16,
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTabContent() {
    return Obx(() {
      List<Appointment> appointments;
      String emptyTitle;
      String emptyMessage;
      IconData emptyIcon;
      Color emptyColor;

      switch (selectedTabIndex) {
        case 0:
          appointments = appointmentController.upcoming;
          emptyTitle = "No Upcoming Appointments";
          emptyMessage = "Your confirmed future appointments will appear here";
          emptyIcon = Icons.event_available;
          emptyColor = Colors.blue;
          break;
        case 1:
          appointments = appointmentController.pending;
          emptyTitle = "No Pending Appointments";
          emptyMessage =
              "Appointments awaiting clinic approval will appear here";
          emptyIcon = Icons.pending_actions;
          emptyColor = Colors.orange;
          break;
        case 2:
          appointments = appointmentController.completed;
          emptyTitle = "No Completed Appointments";
          emptyMessage = "Your finished appointments will appear here";
          emptyIcon = Icons.check_circle;
          emptyColor = Colors.green;
          break;
        case 3:
          appointments = appointmentController.history;
          emptyTitle = "No History";
          emptyMessage = "Cancelled or declined appointments will appear here";
          emptyIcon = Icons.history;
          emptyColor = Colors.grey;
          break;
        default:
          appointments = [];
          emptyTitle = "No Appointments";
          emptyMessage = "";
          emptyIcon = Icons.event;
          emptyColor = Colors.grey;
      }

      if (appointments.isEmpty) {
        return _buildEmptyState(
            emptyTitle, emptyMessage, emptyIcon, emptyColor);
      }

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildColumnHeader(_getTabTitle(selectedTabIndex),
                _getTabIcon(selectedTabIndex), _getTabColor(selectedTabIndex)),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: appointments.length,
                itemBuilder: (context, index) => WebAppointmentTile(
                  appointment: appointments[index],
                  onTap: () => _showAppointmentDialog(
                    appointments[index],
                    appointmentController
                        .getClinicForAppointment(appointments[index]),
                    appointmentController
                        .getPetForAppointment(appointments[index]),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAppointmentColumn(String title, List<Appointment> appointments,
      Color color, IconData icon) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildColumnHeader(title, icon, color),
            Expanded(
              child: appointments.isEmpty
                  ? _buildEmptyColumnState(title, icon, color)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: appointments.length,
                      itemBuilder: (context, index) => WebAppointmentTile(
                        appointment: appointments[index],
                        onTap: () => _showAppointmentDialog(
                          appointments[index],
                          appointmentController
                              .getClinicForAppointment(appointments[index]),
                          appointmentController
                              .getPetForAppointment(appointments[index]),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColumnHeader(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyColumnState(String title, IconData icon, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 48, color: color.withOpacity(0.6)),
          ),
          const SizedBox(height: 16),
          Text(
            "No ${title.toLowerCase()}\nappointments",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
      String title, String message, IconData icon, Color color) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, size: 64, color: color.withOpacity(0.6)),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedAppointmentBar(bool isCompact) {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('MMM dd, yyyy').format(now);

    return Obx(() {
      final stats = appointmentController.userStats;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color.fromARGB(255, 81, 115, 153),
              Colors.blue.shade400,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isCompact
            ? _buildCompactHeader(formattedDate, stats)
            : _buildFullHeader(formattedDate, stats),
      );
    });
  }

  Widget _buildCompactHeader(String formattedDate, Map<String, int> stats) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInfoCard(Icons.calendar_today, "Today", formattedDate,
                isWhite: true),
            _buildInfoCard(Icons.event_note, "Total", "${stats['total']}",
                isWhite: true),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatusChip("Upcoming", "${stats['upcoming']}", Colors.blue),
            _buildStatusChip("Pending", "${stats['pending']}", Colors.orange),
            _buildStatusChip(
                "Completed", "${stats['completed']}", Colors.green),
          ],
        ),
      ],
    );
  }

  Widget _buildFullHeader(String formattedDate, Map<String, int> stats) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "My Appointments",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${stats['total']} total • ${stats['today']} today • $formattedDate",
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
        Row(
          children: [
            _buildStatusChip("Upcoming", "${stats['upcoming']}", Colors.blue),
            const SizedBox(width: 12),
            _buildStatusChip("Pending", "${stats['pending']}", Colors.orange),
            const SizedBox(width: 12),
            _buildStatusChip(
                "Completed", "${stats['completed']}", Colors.green),
            const SizedBox(width: 12),
            _buildStatusChip("History", "${stats['history']}", Colors.grey),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value,
      {bool isWhite = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isWhite
                ? Colors.white.withOpacity(0.2)
                : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              Icon(icon, color: isWhite ? Colors.white : Colors.blue, size: 20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isWhite
                    ? Colors.white.withOpacity(0.8)
                    : Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isWhite ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            "$label: $count",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'declined':
      case 'no_show':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending_actions;
      case 'accepted':
        return Icons.event_available;
      case 'in_progress':
        return Icons.medical_services;
      case 'completed':
        return Icons.check_circle;
      case 'declined':
        return Icons.cancel;
      case 'no_show':
        return Icons.person_off;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0:
        return "Upcoming";
      case 1:
        return "Pending";
      case 2:
        return "Completed";
      case 3:
        return "History";
      default:
        return "Unknown";
    }
  }

  IconData _getTabIcon(int index) {
    switch (index) {
      case 0:
        return Icons.event_available;
      case 1:
        return Icons.pending_actions;
      case 2:
        return Icons.check_circle;
      case 3:
        return Icons.history;
      default:
        return Icons.event;
    }
  }

  Color _getTabColor(int index) {
    switch (index) {
      case 0:
        return Colors.blue;
      case 1:
        return Colors.orange;
      case 2:
        return Colors.green;
      case 3:
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  void _showAppointmentDialog(
      Appointment appointment, Clinic? clinic, Pet? pet) {
    showDialog(
      context: context,
      builder: (context) => _buildAppointmentDialog(appointment, clinic, pet),
    );
  }

  Widget _buildAppointmentDialog(
      Appointment appointment, Clinic? clinic, Pet? pet) {
    Color statusColor = _getStatusColor(appointment.status);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        height: 700,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withOpacity(0.1),
                    statusColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const Text(
                    'Appointment Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(appointment.status),
                          size: 16,
                          color: statusColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          appointmentController
                              .getUserFriendlyStatus(appointment),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDialogSection("Appointment Information", [
                      _buildDialogDetailRow(Icons.local_hospital, "Clinic",
                          clinic?.clinicName ?? 'Unknown Clinic'),
                      _buildDialogDetailRow(Icons.location_on, "Address",
                          clinic?.address ?? 'Address not available'),
                      _buildDialogDetailRow(Icons.medical_services, "Service",
                          appointment.service),
                      _buildDialogDetailRow(
                          Icons.pets, "Pet", pet?.name ?? appointment.petId),
                      if (pet != null)
                        _buildDialogDetailRow(Icons.category, "Pet Details",
                            '${pet.type} • ${pet.breed}'),
                      _buildDialogDetailRow(
                          Icons.calendar_today,
                          "Date",
                          DateFormat('EEEE, MMMM dd, yyyy')
                              .format(appointment.dateTime)),
                      _buildDialogDetailRow(Icons.access_time, "Time",
                          DateFormat('h:mm a').format(appointment.dateTime)),
                    ]),
                    if (appointment.status == 'completed' &&
                        appointment.hasMedicalRecord) ...[
                      const SizedBox(height: 20),
                      _buildDialogSection("Medical Record", [
                        if (appointment.diagnosis != null)
                          _buildDialogDetailRow(Icons.medical_information,
                              "Diagnosis", appointment.diagnosis!),
                        if (appointment.treatment != null)
                          _buildDialogDetailRow(Icons.healing, "Treatment",
                              appointment.treatment!),
                        if (appointment.prescription != null)
                          _buildDialogDetailRow(Icons.medication,
                              "Prescription", appointment.prescription!),
                        if (appointment.vetNotes != null)
                          _buildDialogDetailRow(Icons.note_alt,
                              "Veterinary Notes", appointment.vetNotes!),
                      ]),
                    ],
                    const SizedBox(height: 20),
                    _buildDialogSection("Booking Information", [
                      _buildDialogDetailRow(
                          Icons.event,
                          "Booked on",
                          DateFormat('MMM dd, yyyy • h:mm a')
                              .format(appointment.createdAt)),
                      if (appointment.updatedAt != appointment.createdAt)
                        _buildDialogDetailRow(
                            Icons.update,
                            "Last updated",
                            DateFormat('MMM dd, yyyy • h:mm a')
                                .format(appointment.updatedAt)),
                    ]),
                    if (appointment.notes != null &&
                        appointment.notes!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildDialogSection("Notes", [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Text(
                            appointment.notes!,
                            style: const TextStyle(fontSize: 14, height: 1.5),
                          ),
                        ),
                      ]),
                    ],
                    const SizedBox(height: 30),
                    _buildDialogActionButtons(appointment, clinic, pet),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDialogDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              color: const Color.fromARGB(255, 81, 115, 153),
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogActionButtons(
      Appointment appointment, Clinic? clinic, Pet? pet) {
    final controller = Get.find<EnhancedUserAppointmentController>();
    
    return FutureBuilder<bool>(
      future: _checkIfReviewed(appointment.documentId!),
      builder: (context, snapshot) {
        final hasReviewed = snapshot.data ?? false;
        
        return Column(
          children: [
            if (appointment.status == 'completed')
              SizedBox(
                width: double.infinity,
                child: hasReviewed
                    ? Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.green.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Rating & Review Submitted',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showRatingDialog(appointment, clinic, pet);
                        },
                        icon: const Icon(Icons.rate_review),
                        label: const Text('Rate & Review'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade50,
                          foregroundColor: Colors.amber.shade700,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.amber.shade200),
                          ),
                        ),
                      ),
              ),
            if (appointment.status == 'completed') const SizedBox(height: 12),
            if (controller.canCancelAppointment(appointment))
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showCancelDialog(appointment),
                  icon: const Icon(Icons.cancel_outlined),
                  label: Text(appointment.status == 'pending'
                      ? 'Cancel Request'
                      : 'Cancel Appointment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: appointment.status == 'pending'
                        ? Colors.orange.shade50
                        : Colors.red.shade50,
                    foregroundColor: appointment.status == 'pending'
                        ? Colors.orange.shade700
                        : Colors.red.shade700,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: appointment.status == 'pending'
                            ? Colors.orange.shade200
                            : Colors.red.shade200,
                      ),
                    ),
                  ),
                ),
              ),
            if (appointmentController.canCancelAppointment(appointment))
              const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  void _showCancelDialog(Appointment appointment) {
    final controller = Get.find<EnhancedUserAppointmentController>();

    if (appointment.status == 'pending') {
      _showPendingCancelDialog(appointment, controller);
      return;
    }

    _showAcceptedCancelDialog(appointment, controller);
  }

  void _showPendingCancelDialog(
    Appointment appointment,
    EnhancedUserAppointmentController controller,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cancel_outlined,
                  color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Cancel Request',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this appointment request?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This appointment hasn\'t been confirmed yet. You can cancel it without any reason.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Request'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              controller.cancelPendingAppointment(appointment.documentId!);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text(
              'Cancel Request',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showAcceptedCancelDialog(
    Appointment appointment,
    EnhancedUserAppointmentController controller,
  ) {
    String selectedReason = '';
    final customReasonController = TextEditingController();

    final predefinedReasons = [
      'Schedule conflict',
      'Pet condition improved',
      'Found another clinic closer',
      'Financial constraints',
      'Transportation issues',
      'Emergency situation changed plans',
      'Other (specify below)',
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 550,
              constraints: const BoxConstraints(maxHeight: 700),
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.cancel,
                              color: Colors.red, size: 24),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cancel Appointment',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'This appointment has been confirmed',
                                style:
                                    TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber,
                              color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'The clinic has already confirmed this appointment. Please provide a reason for cancellation.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.local_hospital,
                                  color: Colors.blue.shade600, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  controller
                                      .getClinicNameForAppointment(appointment),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${appointment.service} • ${controller.getPetNameForAppointment(appointment)}',
                            style: TextStyle(
                                color: Colors.grey.shade700, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('EEEE, MMM dd, yyyy • h:mm a')
                                .format(appointment.dateTime),
                            style: TextStyle(
                                color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'Please select a reason for cancellation:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    ...predefinedReasons.map((reason) {
                      return RadioListTile<String>(
                        title:
                            Text(reason, style: const TextStyle(fontSize: 14)),
                        value: reason,
                        groupValue: selectedReason,
                        onChanged: (value) {
                          setState(() {
                            selectedReason = value!;
                          });
                        },
                        activeColor: const Color.fromARGB(255, 81, 115, 153),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      );
                    }),

                    const SizedBox(height: 16),

                    TextField(
                      controller: customReasonController,
                      decoration: InputDecoration(
                        labelText: selectedReason == 'Other (specify below)'
                            ? 'Please specify your reason *'
                            : 'Additional details (optional)',
                        hintText: 'Enter additional information...',
                        border: const OutlineInputBorder(),
                        enabled: selectedReason.isNotEmpty,
                      ),
                      maxLines: 3,
                      maxLength: 200,
                    ),

                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Colors.blue.shade700, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You can cancel up to 2 hours before your appointment time.',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Keep Appointment'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            if (selectedReason.isEmpty) {
                              Get.snackbar(
                                'Required Field',
                                'Please select a reason for cancellation',
                                backgroundColor: Colors.orange,
                                colorText: Colors.white,
                                snackPosition: SnackPosition.BOTTOM,
                              );
                              return;
                            }

                            if (selectedReason == 'Other (specify below)' &&
                                customReasonController.text.trim().isEmpty) {
                              Get.snackbar(
                                'Required Field',
                                'Please specify your reason for cancellation',
                                backgroundColor: Colors.orange,
                                colorText: Colors.white,
                                snackPosition: SnackPosition.BOTTOM,
                              );
                              return;
                            }

                            String finalReason = selectedReason;
                            if (customReasonController.text.trim().isNotEmpty) {
                              finalReason = selectedReason ==
                                      'Other (specify below)'
                                  ? customReasonController.text.trim()
                                  : '$selectedReason - ${customReasonController.text.trim()}';
                            }

                            Navigator.pop(context);
                            Navigator.pop(context);
                            controller.cancelAcceptedAppointment(
                              appointment.documentId!,
                              finalReason,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                          child: const Text(
                            'Cancel Appointment',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showContactOptions(Appointment appointment) {
    final clinic = appointmentController.getClinicForAppointment(appointment);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Contact ${clinic?.clinicName ?? 'Clinic'}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.phone,
                    color: Color.fromARGB(255, 81, 115, 153)),
              ),
              title: const Text('Call Clinic'),
              subtitle: Text(clinic?.contact ?? 'Phone not available'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                Get.snackbar('Info', 'Phone call feature will be implemented');
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.email,
                    color: Color.fromARGB(255, 81, 115, 153)),
              ),
              title: const Text('Send Email'),
              subtitle: Text(clinic?.email ?? 'Email not available'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                Get.snackbar('Info', 'Email feature will be implemented');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showRatingDialog(Appointment appointment, Clinic? clinic, Pet? pet) {
    showDialog(
      context: context,
      builder: (context) => _buildRatingDialog(appointment, clinic, pet),
    );
  }

  Widget _buildRatingDialog(Appointment appointment, Clinic? clinic, Pet? pet) {
    double selectedRating = 0.0;
    final TextEditingController reviewController = TextEditingController();
    List<PlatformFile> selectedImages = [];

    return StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 500,
            constraints: const BoxConstraints(maxHeight: 700),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber.shade50,
                        Colors.orange.shade50,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      const Text(
                        'Rate & Review',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child:
                            const Icon(Icons.rate_review, color: Colors.amber),
                      ),
                    ],
                  ),
                ),

                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_hospital,
                                    color: Colors.blue.shade600,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      clinic?.clinicName ?? 'Unknown Clinic',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${appointment.service} • ${pet?.name ?? appointment.petId}',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('MMM dd, yyyy')
                                    .format(appointment.dateTime),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'How would you rate your experience?',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              final starValue = index + 1;
                              return MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedRating = starValue.toDouble();
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Stack(
                                      children: [
                                        Icon(
                                          selectedRating >= starValue
                                              ? Icons.star
                                              : (selectedRating >= starValue - 0.5
                                                  ? Icons.star_half
                                                  : Icons.star_border),
                                          color: selectedRating >= starValue - 0.5
                                              ? Colors.amber
                                              : Colors.grey.shade400,
                                          size: 40,
                                        ),
                                        Positioned(
                                          left: 0,
                                          top: 0,
                                          bottom: 0,
                                          width: 20,
                                          child: MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  selectedRating = starValue - 0.5;
                                                });
                                              },
                                              child: Container(
                                                color: Colors.transparent,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        const SizedBox(height: 16),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              Slider(
                                value: selectedRating,
                                min: 0.0,
                                max: 5.0,
                                divisions: 10,
                                activeColor: Colors.amber,
                                inactiveColor: Colors.grey.shade300,
                                label: selectedRating > 0
                                    ? selectedRating.toStringAsFixed(1)
                                    : null,
                                onChanged: (value) {
                                  setState(() {
                                    selectedRating = value;
                                  });
                                },
                              ),
                              if (selectedRating > 0)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${selectedRating.toStringAsFixed(1)} stars',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      _getRatingTextFromDouble(selectedRating),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _getRatingColorFromDouble(selectedRating),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'Share your experience (Optional)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: TextField(
                            controller: reviewController,
                            maxLines: 4,
                            maxLength: 500,
                            decoration: InputDecoration(
                              hintText:
                                  'Tell us about your visit, the service quality, staff friendliness, etc...',
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                              counterStyle:
                                  TextStyle(color: Colors.grey.shade500),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'Add Photos (Optional)',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),

                        InkWell(
                          onTap: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                              allowMultiple: true,
                              withData: true,
                            );

                            if (result != null && result.files.isNotEmpty) {
                              List<PlatformFile> validFiles = [];
                              List<String> rejectedFiles = [];
                              
                              for (var file in result.files) {
                                // Check 5MB limit (5 * 1024 * 1024 bytes)
                                if (file.size <= 5 * 1024 * 1024) {
                                  validFiles.add(file);
                                } else {
                                  rejectedFiles.add(file.name);
                                }
                              }
                              
                              if (rejectedFiles.isNotEmpty) {
                                Get.snackbar(
                                  'File Size Limit',
                                  'The following files exceed 5MB limit and were not added:\n${rejectedFiles.join(", ")}',
                                  backgroundColor: Colors.orange.shade50,
                                  colorText: Colors.orange.shade700,
                                  duration: const Duration(seconds: 4),
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                              }
                              
                              setState(() {
                                selectedImages.addAll(validFiles);
                                if (selectedImages.length > 5) {
                                  selectedImages =
                                      selectedImages.take(5).toList();
                                }
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 2,
                                  style: BorderStyle.solid),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.grey.shade50,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  color: Colors.grey.shade600,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  selectedImages.isEmpty
                                      ? 'Add photos (up to 5, max 5MB each)'
                                      : '${selectedImages.length} photo${selectedImages.length > 1 ? 's' : ''} selected',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        if (selectedImages.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: selectedImages.length,
                              itemBuilder: (context, index) {
                                final file = selectedImages[index];

                                return Stack(
                                  children: [
                                    Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: file.bytes != null
                                            ? Image.memory(
                                                file.bytes!,
                                                width: 100,
                                                height: 100,
                                                fit: BoxFit.cover,
                                              )
                                            : Container(
                                                width: 100,
                                                height: 100,
                                                color: Colors.grey.shade200,
                                                child: const Icon(Icons.image),
                                              ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 12,
                                      child: InkWell(
                                        onTap: () {
                                          setState(() {
                                            selectedImages.removeAt(index);
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: selectedRating > 0
                                ? () => _submitRating(
                                      appointment,
                                      selectedRating,
                                      reviewController.text,
                                      selectedImages,
                                      clinic,
                                    )
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedRating > 0
                                  ? Colors.amber
                                  : Colors.grey.shade300,
                              foregroundColor: selectedRating > 0
                                  ? Colors.white
                                  : Colors.grey.shade500,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: selectedRating > 0 ? 2 : 0,
                            ),
                            child: Text(
                              selectedRating > 0
                                  ? 'Submit Review'
                                  : 'Select a Rating',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getRatingTextFromDouble(double rating) {
    if (rating >= 4.5) return 'Excellent';
    if (rating >= 3.5) return 'Very Good';
    if (rating >= 2.5) return 'Good';
    if (rating >= 1.5) return 'Fair';
    if (rating > 0) return 'Poor';
    return '';
  }

  Color _getRatingColorFromDouble(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 3.5) return Colors.lightGreen;
    if (rating >= 2.5) return Colors.amber;
    if (rating >= 1.5) return Colors.orange;
    if (rating > 0) return Colors.red;
    return Colors.grey;
  }

  Future<void> _submitRating(
    Appointment appointment,
    double rating,
    String review,
    List<PlatformFile> images,
    Clinic? clinic,
  ) async {
    try {
      // Show loading
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(color: Colors.amber),
        ),
        barrierDismissible: false,
      );

      // Get user info
      final user = await Get.find<AuthRepository>().getUser();
      if (user == null) {
        Get.back();
        Get.snackbar('Error', 'User not found');
        return;
      }

      // Check if already reviewed
      final alreadyReviewed = await Get.find<AuthRepository>()
          .hasUserReviewedAppointment(appointment.documentId!);

      if (alreadyReviewed) {
        Get.back();
        Get.snackbar(
          'Already Reviewed',
          'You have already reviewed this appointment.',
          backgroundColor: Colors.orange.shade50,
          colorText: Colors.orange.shade700,
        );
        return;
      }

      // Upload images if any
      List<String> imageIds = [];
      if (images.isNotEmpty) {
        try {
          print('Uploading ${images.length} review images...');
          final uploadedFiles =
              await Get.find<AuthRepository>().uploadReviewImages(images);
          imageIds = uploadedFiles.map((file) => file.$id).toList();
          print('Successfully uploaded ${imageIds.length} images');
        } catch (e) {
          print('Error uploading images: $e');
        }
      }

      // Get pet name
      final pet = appointmentController.getPetForAppointment(appointment);

      // Create review
      final ratingReview = RatingAndReview(
        userId: appointment.userId,
        clinicId: appointment.clinicId,
        appointmentId: appointment.documentId!,
        rating: rating,
        reviewText: review.isNotEmpty ? review : null,
        images: imageIds,
        userName: user.name,
        petName: pet?.name,
        serviceName: appointment.service,
      );

      await Get.find<AuthRepository>().createRatingAndReview(ratingReview);

      // Mark as reviewed in memory
      _markAsReviewed(appointment.documentId!);

      // Close loading dialog
      Get.back();
      
      // Close rating dialog
      Navigator.pop(context);

      // Refresh appointments to update the UI
      await appointmentController.fetchAppointments();

      // Show success message
      Get.snackbar(
        'Review Submitted!',
        'Thank you for your feedback. Your ${rating.toStringAsFixed(1)}-star review helps other pet owners.',
        backgroundColor: Colors.green.shade50,
        colorText: Colors.green.shade700,
        icon: const Icon(Icons.check_circle, color: Colors.green),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
      );
    } catch (e) {
      Get.back();
      print('Error submitting review: $e');
      Get.snackbar(
        'Error',
        'Failed to submit review: ${e.toString()}',
        backgroundColor: Colors.red.shade50,
        colorText: Colors.red.shade700,
        icon: const Icon(Icons.error, color: Colors.red),
      );
    }
  }
}
import 'package:capstone_app/data/models/appointment_model.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/mobile/user/components/appointment_tabs/components/appointment_controller.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class EnhancedWebAppointmentsPage extends StatefulWidget {
  const EnhancedWebAppointmentsPage({super.key});

  @override
  State<EnhancedWebAppointmentsPage> createState() => _EnhancedWebAppointmentsPageState();
}

class _EnhancedWebAppointmentsPageState extends State<EnhancedWebAppointmentsPage> {
  int selectedTabIndex = 0; // 0: Pending, 1: Active, 2: Cancelled
  final double tabletWidth = 1100;
  late EnhancedUserAppointmentController appointmentController;

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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isTablet = constraints.maxWidth < tabletWidth;
        
        return Scaffold(
          backgroundColor: const Color(0xFFEEEEEE),
          body: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 20 : 65,
              vertical: 16
            ),
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
                CircularProgressIndicator(color: Color.fromARGB(255, 81, 115, 153)),
                SizedBox(height: 16),
                Text('Loading appointments...', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return Row(
          children: [
            _buildAppointmentColumn("Pending", appointmentController.pending, Colors.orange, Icons.pending_actions),
            const SizedBox(width: 16),
            _buildAppointmentColumn("Active", appointmentController.accepted, Colors.green, Icons.check_circle),
            const SizedBox(width: 16),
            _buildAppointmentColumn("Cancelled", appointmentController.declined, Colors.red, Icons.cancel),
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
          _buildTabButton(0, Icons.pending_actions, "Pending", Colors.orange, appointmentController.pending.length),
          _buildTabButton(1, Icons.check_circle, "Active", Colors.green, appointmentController.accepted.length),
          _buildTabButton(2, Icons.cancel, "Cancelled", Colors.red, appointmentController.declined.length),
        ],
      )),
    );
  }

  Widget _buildTabButton(int index, IconData icon, String text, Color color, int count) {
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
          appointments = appointmentController.pending;
          emptyTitle = "No Pending Appointments";
          emptyMessage = "Appointments waiting for clinic approval will appear here";
          emptyIcon = Icons.pending_actions;
          emptyColor = Colors.orange;
          break;
        case 1:
          appointments = appointmentController.accepted;
          emptyTitle = "No Active Appointments";
          emptyMessage = "Confirmed and ongoing appointments will appear here";
          emptyIcon = Icons.check_circle;
          emptyColor = Colors.green;
          break;
        case 2:
          appointments = appointmentController.declined;
          emptyTitle = "Great! No Cancelled Here";
          emptyMessage = "Declined or missed appointments will appear here";
          emptyIcon = Icons.sentiment_satisfied;
          emptyColor = Colors.red;
          break;
        default:
          appointments = [];
          emptyTitle = "No Appointments";
          emptyMessage = "";
          emptyIcon = Icons.event;
          emptyColor = Colors.grey;
      }

      if (appointments.isEmpty) {
        return _buildEmptyState(emptyTitle, emptyMessage, emptyIcon, emptyColor);
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
            _buildColumnHeader(_getTabTitle(selectedTabIndex), _getTabIcon(selectedTabIndex), _getTabColor(selectedTabIndex)),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: appointments.length,
                itemBuilder: (context, index) => _buildWebAppointmentTile(appointments[index]),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildAppointmentColumn(String title, List<Appointment> appointments, Color color, IconData icon) {
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
                    itemBuilder: (context, index) => _buildWebAppointmentTile(appointments[index]),
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

  Widget _buildEmptyState(String title, String message, IconData icon, Color color) {
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

  Widget _buildWebAppointmentTile(Appointment appointment) {
    final clinic = appointmentController.getClinicForAppointment(appointment);
    final pet = appointmentController.getPetForAppointment(appointment);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAppointmentDialog(appointment, clinic, pet),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(appointment.status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _getStatusColor(appointment.status).withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(appointment.status),
                            size: 16,
                            color: _getStatusColor(appointment.status),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            appointmentController.getUserFriendlyStatus(appointment),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: _getStatusColor(appointment.status),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Add Rate & Review button for completed appointments
                    if (appointment.status == 'completed') ...[
                      IconButton(
                        onPressed: () => _showRatingDialog(appointment, clinic, pet),
                        icon: const Icon(Icons.rate_review),
                        color: Colors.amber,
                        tooltip: 'Rate & Review',
                      ),
                      const SizedBox(width: 8),
                    ],
                    Icon(
                      Icons.keyboard_arrow_right_rounded,
                      color: Colors.grey.shade400,
                    ),
                  ],
                ),
                
                // Progress bar for non-declined appointments
                if (appointment.status != 'declined' && appointment.status != 'no_show') ...[
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: appointmentController.getAppointmentProgress(appointment),
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(_getStatusColor(appointment.status)),
                    minHeight: 3,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    appointmentController.getAppointmentStage(appointment),
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getStatusColor(appointment.status).withOpacity(0.1),
                            _getStatusColor(appointment.status).withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getStatusColor(appointment.status).withOpacity(0.2),
                        ),
                      ),
                      child: Icon(
                        Icons.local_hospital,
                        color: _getStatusColor(appointment.status),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            clinic?.clinicName ?? 'Unknown Clinic',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.medical_services_outlined,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  appointment.service,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.pets_rounded,
                                size: 16,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  pet?.name ?? appointment.petId,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('MMMM dd, yyyy').format(appointment.dateTime),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue.shade700,
                            ),
                          ),
                          Text(
                            DateFormat('h:mm a').format(appointment.dateTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
        child: isCompact ? _buildCompactHeader(formattedDate, stats) : _buildFullHeader(formattedDate, stats),
      );
    });
  }

  Widget _buildCompactHeader(String formattedDate, Map<String, int> stats) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInfoCard(Icons.calendar_today, "Today", formattedDate, isWhite: true),
            _buildInfoCard(Icons.event_note, "Total", "${stats['total']}", isWhite: true),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatusChip("Pending", "${stats['pending']}", Colors.orange),
            _buildStatusChip("Active", "${stats['upcoming']}", Colors.green),
            _buildStatusChip("Cancelled", "${appointmentController.declined.length}", Colors.red),
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
            _buildStatusChip("Pending", "${stats['pending']}", Colors.orange),
            const SizedBox(width: 12),
            _buildStatusChip("Active", "${stats['upcoming']}", Colors.green),
            const SizedBox(width: 12),
            _buildStatusChip("Cancelled", "${appointmentController.declined.length}", Colors.red),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value, {bool isWhite = false}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isWhite ? Colors.white.withOpacity(0.2) : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon, 
            color: isWhite ? Colors.white : Colors.blue, 
            size: 20
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isWhite ? Colors.white.withOpacity(0.8) : Colors.grey.shade600,
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
      default:
        return Icons.help_outline;
    }
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0: return "Pending";
      case 1: return "Active";
      case 2: return "Cancelled";
      default: return "Unknown";
    }
  }

  IconData _getTabIcon(int index) {
    switch (index) {
      case 0: return Icons.pending_actions;
      case 1: return Icons.check_circle;
      case 2: return Icons.cancel;
      default: return Icons.event;
    }
  }

  Color _getTabColor(int index) {
    switch (index) {
      case 0: return Colors.orange;
      case 1: return Colors.green;
      case 2: return Colors.red;
      default: return Colors.grey;
    }
  }

  void _showAppointmentDialog(Appointment appointment, Clinic? clinic, Pet? pet) {
    showDialog(
      context: context,
      builder: (context) => _buildAppointmentDialog(appointment, clinic, pet),
    );
  }

  Widget _buildAppointmentDialog(Appointment appointment, Clinic? clinic, Pet? pet) {
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
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _getStatusColor(appointment.status).withOpacity(0.1),
                    _getStatusColor(appointment.status).withOpacity(0.05),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment.status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(appointment.status),
                          size: 16,
                          color: _getStatusColor(appointment.status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          appointmentController.getUserFriendlyStatus(appointment),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(appointment.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Basic Information
                    _buildDialogSection("Appointment Information", [
                      _buildDialogDetailRow(Icons.local_hospital, "Clinic", clinic?.clinicName ?? 'Unknown Clinic'),
                      _buildDialogDetailRow(Icons.location_on, "Address", clinic?.address ?? 'Address not available'),
                      _buildDialogDetailRow(Icons.medical_services, "Service", appointment.service),
                      _buildDialogDetailRow(Icons.pets, "Pet", pet?.name ?? appointment.petId),
                      if (pet != null)
                        _buildDialogDetailRow(Icons.category, "Pet Details", '${pet.type} • ${pet.breed}'),
                      _buildDialogDetailRow(Icons.calendar_today, "Date", DateFormat('EEEE, MMMM dd, yyyy').format(appointment.dateTime)),
                      _buildDialogDetailRow(Icons.access_time, "Time", DateFormat('h:mm a').format(appointment.dateTime)),
                    ]),

                    // Medical Information (if completed)
                    if (appointment.status == 'completed' && appointment.hasMedicalRecord) ...[
                      const SizedBox(height: 20),
                      _buildDialogSection("Medical Record", [
                        if (appointment.diagnosis != null)
                          _buildDialogDetailRow(Icons.medical_information, "Diagnosis", appointment.diagnosis!),
                        if (appointment.treatment != null)
                          _buildDialogDetailRow(Icons.healing, "Treatment", appointment.treatment!),
                        if (appointment.prescription != null)
                          _buildDialogDetailRow(Icons.medication, "Prescription", appointment.prescription!),
                        if (appointment.vetNotes != null)
                          _buildDialogDetailRow(Icons.note_alt, "Veterinary Notes", appointment.vetNotes!),
                      ]),
                    ],

                    // Payment Information (if completed)
                    if (appointment.status == 'completed' && appointment.totalCost != null) ...[
                      const SizedBox(height: 20),
                      _buildDialogSection("Payment Information", [
                        _buildDialogDetailRow(Icons.attach_money, "Total Cost", '₱${appointment.totalCost!.toStringAsFixed(2)}'),
                        _buildDialogDetailRow(
                          appointment.isPaid ? Icons.check_circle : Icons.pending,
                          "Payment Status",
                          appointment.isPaid ? 'Paid' : 'Pending',
                        ),
                        if (appointment.paymentMethod != null)
                          _buildDialogDetailRow(Icons.payment, "Payment Method", appointment.paymentMethod!.toUpperCase()),
                      ]),
                    ],

                    // Booking Information
                    const SizedBox(height: 20),
                    _buildDialogSection("Booking Information", [
                      _buildDialogDetailRow(Icons.event, "Booked on", DateFormat('MMM dd, yyyy • h:mm a').format(appointment.createdAt)),
                      if (appointment.updatedAt != appointment.createdAt)
                        _buildDialogDetailRow(Icons.update, "Last updated", DateFormat('MMM dd, yyyy • h:mm a').format(appointment.updatedAt)),
                    ]),

                    // Notes (if available)
                    if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
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

                    // Action Buttons
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

  Widget _buildDialogActionButtons(Appointment appointment, Clinic? clinic, Pet? pet) {
    return Column(
      children: [
        // Rate & Review button for completed appointments
        if (appointment.status == 'completed')
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context); // Close current dialog
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

        if (appointment.status == 'completed')
          const SizedBox(height: 12),

        // Cancel button for eligible appointments
        if (appointmentController.canCancelAppointment(appointment))
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showCancelDialog(appointment),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancel Appointment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade50,
                foregroundColor: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red.shade200),
                ),
              ),
            ),
          ),
        
        if (appointmentController.canCancelAppointment(appointment))
          const SizedBox(height: 12),
        
        // Contact clinic button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _showContactOptions(appointment),
            icon: const Icon(Icons.phone),
            label: const Text('Contact Clinic'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 81, 115, 153),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

    void _showCancelDialog(Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Appointment'),
        content: const Text('Are you sure you want to cancel this appointment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Appointment'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Close appointment dialog too
              appointmentController.cancelAppointment(appointment.documentId!);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Appointment', style: TextStyle(color: Colors.white)),
          ),
        ],
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
                  color: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.phone, color: Color.fromARGB(255, 81, 115, 153)),
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
                  color: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.email, color: Color.fromARGB(255, 81, 115, 153)),
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
    int selectedRating = 0;
    final TextEditingController reviewController = TextEditingController();

    return StatefulBuilder(
      builder: (context, setState) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            width: 500,
            constraints: const BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
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
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.rate_review, color: Colors.amber),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Appointment Info Summary
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
                                DateFormat('MMM dd, yyyy').format(appointment.dateTime),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Rating Section
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
                              return GestureDetector(
                                onTap: () => setState(() => selectedRating = index + 1),
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    selectedRating > index ? Icons.star : Icons.star_border,
                                    color: selectedRating > index ? Colors.amber : Colors.grey.shade400,
                                    size: 40,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        if (selectedRating > 0) ...[
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              _getRatingText(selectedRating),
                              style: TextStyle(
                                color: _getRatingColor(selectedRating),
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Review Section
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
                              hintText: 'Tell us about your visit, the service quality, staff friendliness, etc...',
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                              counterStyle: TextStyle(color: Colors.grey.shade500),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: selectedRating > 0 
                              ? () => _submitRating(appointment, selectedRating, reviewController.text, clinic)
                              : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedRating > 0 ? Colors.amber : Colors.grey.shade300,
                              foregroundColor: selectedRating > 0 ? Colors.white : Colors.grey.shade500,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: selectedRating > 0 ? 2 : 0,
                            ),
                            child: Text(
                              selectedRating > 0 ? 'Submit Review' : 'Select a Rating',
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

  String _getRatingText(int rating) {
    switch (rating) {
      case 1: return 'Poor';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Very Good';
      case 5: return 'Excellent';
      default: return '';
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.amber;
      case 4: return Colors.lightGreen;
      case 5: return Colors.green;
      default: return Colors.grey;
    }
  }

  void _submitRating(Appointment appointment, int rating, String review, Clinic? clinic) {
    // Here you would typically send the rating and review to your backend
    // For now, we'll just show a success message
    Navigator.pop(context); // Close rating dialog
    
    Get.snackbar(
      'Review Submitted!',
      'Thank you for your feedback. Your $rating-star review helps other pet owners.',
      backgroundColor: Colors.green.shade50,
      colorText: Colors.green.shade700,
      icon: const Icon(Icons.check_circle, color: Colors.green),
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
    );

    // You can add additional logic here to:
    // 1. Save the rating to your database
    // 2. Update the appointment model to include rating info
    // 3. Send the review to the clinic
    // 4. Update any clinic rating averages
    
    print('Rating submitted: $rating stars');
    print('Review: $review');
    print('Appointment ID: ${appointment.documentId}');
    print('Clinic: ${clinic?.clinicName}');
  }
}
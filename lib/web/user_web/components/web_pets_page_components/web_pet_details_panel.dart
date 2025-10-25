import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/models/medical_record_model.dart';
import 'package:capstone_app/data/models/vaccination_model.dart';
import 'package:capstone_app/web/user_web/controllers/web_pets_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

enum CardView {
  front,
  back,
  medicalHistory,
  vaccinationHistory,
  medicalAppointmentsHistory
}

class WebPetDetailsPanel extends StatefulWidget {
  final Pet pet;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const WebPetDetailsPanel({
    super.key,
    required this.pet,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<WebPetDetailsPanel> createState() => _WebPetDetailsPanelState();
}

class _WebPetDetailsPanelState extends State<WebPetDetailsPanel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  CardView _currentView = CardView.front;
  CardView _previousView = CardView.front;
  bool _isGoingForward = true;

  // Selected record for detail view
  MedicalRecord? _selectedMedicalRecord;
  Vaccination? _selectedVaccination;
  Map<String, dynamic>? _selectedMedicalAppointment;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Fetch histories when panel opens
    _fetchHistories();
  }

  void _fetchHistories() {
    final controller = Get.find<WebPetsController>();
    controller.fetchPetMedicalHistory(widget.pet.petId);
    controller.fetchPetVaccinationHistory(widget.pet.petId);
    controller.fetchPetMedicalAppointmentsAllClinics(widget.pet.petId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _getViewLevel(CardView view) {
    switch (view) {
      case CardView.front:
        return 0;
      case CardView.back:
        return 1;
      case CardView.medicalHistory:
      case CardView.vaccinationHistory:
      case CardView.medicalAppointmentsHistory:
        return 2;
    }
  }

  void _flipToView(CardView newView) {
    setState(() {
      _previousView = _currentView;
      _isGoingForward = _getViewLevel(newView) > _getViewLevel(_currentView);
      _currentView = newView;
      // Clear selections when changing views
      _selectedMedicalRecord = null;
      _selectedVaccination = null;
      _selectedMedicalAppointment = null;
    });
    _controller.forward(from: 0);
  }

  void _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          "Delete Pet",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        content: Text(
          "Are you sure you want to delete ${widget.pet.name}? This action cannot be undone.",
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.grey[600]),
            ),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text("Delete"),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm ?? false) {
      widget.onDelete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final angle = _animation.value * math.pi * (_isGoingForward ? 1 : -1);
        final transform = Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle);

        return Transform(
          transform: transform,
          alignment: Alignment.center,
          child: angle.abs() >= math.pi / 2
              ? Transform(
                  transform: Matrix4.identity()
                    ..rotateY(_isGoingForward ? math.pi : -math.pi),
                  alignment: Alignment.center,
                  child: _buildCurrentView(),
                )
              : _buildPreviousView(),
        );
      },
    );
  }

  Widget _buildPreviousView() {
    switch (_previousView) {
      case CardView.front:
        return _buildFrontSide();
      case CardView.back:
        return _buildBackSide();
      case CardView.medicalHistory:
        return _buildMedicalHistoryView();
      case CardView.vaccinationHistory:
        return _buildVaccinationHistoryView();
      case CardView.medicalAppointmentsHistory:
        return _buildMedicalAppointmentsHistoryView();
    }
  }

  Widget _buildCurrentView() {
    switch (_currentView) {
      case CardView.front:
        return _buildFrontSide();
      case CardView.back:
        return _buildBackSide();
      case CardView.medicalHistory:
        return _buildMedicalHistoryView();
      case CardView.vaccinationHistory:
        return _buildVaccinationHistoryView();
      case CardView.medicalAppointmentsHistory:
        return _buildMedicalAppointmentsHistoryView();
    }
  }

  Widget _buildFrontSide() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with small image on top left
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF3498DB),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Small circular pet image
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.network(
                        widget.pet.image ??
                            'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=300&h=300&fit=crop',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.pets,
                            size: 50,
                            color: Colors.grey[400],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 20),

                  // Pet info next to image
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.pet.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.pet.type,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action buttons
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.more_horiz_rounded,
                            color: Colors.white),
                        onPressed: () => _flipToView(CardView.back),
                        tooltip: "More",
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white),
                        onPressed: widget.onEdit,
                        tooltip: "Edit Pet",
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.white),
                        onPressed: () => _confirmDelete(context),
                        tooltip: "Delete Pet",
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Body section with pet details
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ID-style information grid
                  _buildIDRow('Breed', widget.pet.breed),
                  const Divider(height: 24),
                  _buildIDRow('Color', widget.pet.color ?? 'Not specified'),
                  const Divider(height: 24),
                  _buildIDRow(
                      'Weight',
                      widget.pet.weight != null
                          ? '${widget.pet.weight} kg'
                          : 'Not specified'),
                  const Divider(height: 24),
                  _buildIDRow('Gender', widget.pet.gender ?? 'Not specified'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackSide() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header for back side
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF2C3E50),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => _flipToView(CardView.front),
                    tooltip: "Back",
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Health Records',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Back side content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medical Appointments History section (NEW - HIGHLIGHTED)
                  _buildHistoryButton(
                    'Medical Appointments History',
                    'View all medical appointments across clinics',
                    Icons.local_hospital_outlined,
                    () => _flipToView(CardView.medicalAppointmentsHistory),
                    _getMedicalAppointmentsCount(),
                    isPrimary: true,
                  ),

                  const SizedBox(height: 16),

                  // Medical History section
                  _buildHistoryButton(
                    'Medical Records',
                    'View complete medical records',
                    Icons.medical_services_outlined,
                    () => _flipToView(CardView.medicalHistory),
                    _getMedicalRecordCount(),
                  ),

                  const SizedBox(height: 16),

                  // Vaccination History section
                  _buildHistoryButton(
                    'Vaccination History',
                    'View vaccination records',
                    Icons.vaccines_outlined,
                    () => _flipToView(CardView.vaccinationHistory),
                    _getVaccinationCount(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getMedicalRecordCount() {
    final controller = Get.find<WebPetsController>();
    return controller.medicalRecords.length;
  }

  int _getVaccinationCount() {
    final controller = Get.find<WebPetsController>();
    return controller.vaccinations.length;
  }

  int _getMedicalAppointmentsCount() {
    final controller = Get.find<WebPetsController>();
    return controller.medicalAppointments.length;
  }

  // NEW: Medical Appointments History View
  Widget _buildMedicalAppointmentsHistoryView() {
    final controller = Get.find<WebPetsController>();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _selectedMedicalAppointment = null;
                    });
                    _flipToView(CardView.back);
                  },
                  tooltip: "Back",
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedMedicalAppointment != null
                            ? 'Appointment Details'
                            : 'Medical Appointments History',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      if (_selectedMedicalAppointment == null)
                        const SizedBox(height: 4),
                      if (_selectedMedicalAppointment == null)
                        const Text(
                          'All medical visits across clinics',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_selectedMedicalAppointment != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _selectedMedicalAppointment = null;
                      });
                    },
                    tooltip: "Close Details",
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Obx(() {
              if (controller.isLoadingMedicalAppointments.value) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Loading medical appointments...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              if (controller.medicalAppointments.isEmpty) {
                return _buildEmptyState(
                  'No Medical Appointments',
                  'No completed medical appointments found for ${widget.pet.name} yet.',
                  Icons.local_hospital_outlined,
                );
              }

              if (_selectedMedicalAppointment != null) {
                return _buildMedicalAppointmentDetails(
                    _selectedMedicalAppointment!);
              }

              return _buildMedicalAppointmentsList(
                  controller.medicalAppointments);
            }),
          ),
        ],
      ),
    );
  }

  // NEW: Build Medical Appointments List
  Widget _buildMedicalAppointmentsList(
      List<Map<String, dynamic>> appointments) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: appointments.length,
      itemBuilder: (context, index) {
        final appointment = appointments[index];
        return _buildMedicalAppointmentCard(appointment);
      },
    );
  }

  // NEW: Build Medical Appointment Card
  Widget _buildMedicalAppointmentCard(Map<String, dynamic> appointment) {
    final dateTime = DateTime.parse(appointment['dateTime']);
    final clinicName = appointment['clinicName'] ?? 'Unknown Clinic';
    final service = appointment['service'] ?? 'Medical Service';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMedicalAppointment = appointment;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon with gradient background
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.3),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_hospital,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Clinic Name (Bold)
                    Text(
                      clinicName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Service
                    Row(
                      children: [
                        Icon(
                          Icons.medical_services,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            service,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Date
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMMM dd, yyyy • hh:mm a')
                              .format(dateTime),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // NEW: Build Medical Appointment Details
  Widget _buildMedicalAppointmentDetails(Map<String, dynamic> appointment) {
    final dateTime = DateTime.parse(appointment['dateTime']);
    final completedAt = appointment['serviceCompletedAt'] != null
        ? DateTime.parse(appointment['serviceCompletedAt'])
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clinic Information Card
          _buildDetailCard(
            'Veterinary Clinic',
            [
              _buildDetailRow(
                  'Clinic Name', appointment['clinicName'] ?? 'N/A'),
              _buildDetailRow('Address', appointment['clinicAddress'] ?? 'N/A'),
              _buildDetailRow('Contact', appointment['clinicContact'] ?? 'N/A'),
            ],
            icon: Icons.local_hospital,
            iconColor: const Color(0xFF667eea),
          ),

          const SizedBox(height: 16),

          // Appointment Information Card
          _buildDetailCard(
            'Appointment Information',
            [
              _buildDetailRow('Service', appointment['service'] ?? 'N/A'),
              _buildDetailRow(
                'Date & Time',
                DateFormat('MMMM dd, yyyy').format(dateTime),
              ),
              _buildDetailRow(
                'Time',
                DateFormat('hh:mm a').format(dateTime),
              ),
              _buildDetailRow('Status', 'Completed'),
              if (completedAt != null)
                _buildDetailRow(
                  'Completed At',
                  DateFormat('MMMM dd, yyyy • hh:mm a').format(completedAt),
                ),
            ],
            icon: Icons.event_note,
            iconColor: const Color(0xFF3498DB),
          ),

          const SizedBox(height: 16),

          // Payment Information Card
          if (appointment['totalCost'] != null || appointment['isPaid'] != null)
            _buildDetailCard(
              'Payment Information',
              [
                if (appointment['totalCost'] != null)
                  _buildDetailRow(
                    'Total Cost',
                    '₱ ${appointment['totalCost'].toStringAsFixed(2)}',
                  ),
                _buildDetailRow(
                  'Payment Status',
                  appointment['isPaid'] == true ? 'Paid' : 'Unpaid',
                ),
                if (appointment['paymentMethod'] != null)
                  _buildDetailRow(
                    'Payment Method',
                    appointment['paymentMethod'] ?? 'N/A',
                  ),
              ],
              icon: Icons.payment,
              iconColor: const Color(0xFF27AE60),
            ),

          const SizedBox(height: 16),

          // Follow-up Information Card
          if (appointment['followUpInstructions'] != null ||
              appointment['nextAppointmentDate'] != null)
            _buildDetailCard(
              'Follow-up Information',
              [
                if (appointment['followUpInstructions'] != null &&
                    appointment['followUpInstructions'].toString().isNotEmpty)
                  _buildDetailRow(
                    'Instructions',
                    appointment['followUpInstructions'],
                  ),
                if (appointment['nextAppointmentDate'] != null)
                  _buildDetailRow(
                    'Next Appointment',
                    DateFormat('MMMM dd, yyyy').format(
                      DateTime.parse(appointment['nextAppointmentDate']),
                    ),
                  ),
              ],
              icon: Icons.event_available,
              iconColor: const Color(0xFFE67E22),
            ),

          const SizedBox(height: 16),

          // Additional Notes Card
          if (appointment['notes'] != null &&
              appointment['notes'].toString().isNotEmpty)
            _buildDetailCard(
              'Additional Notes',
              [
                _buildDetailRow('Notes', appointment['notes']),
              ],
              icon: Icons.note,
              iconColor: const Color(0xFF9B59B6),
            ),
        ],
      ),
    );
  }

  Widget _buildMedicalHistoryView() {
    final controller = Get.find<WebPetsController>();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF3498DB),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _selectedMedicalRecord = null;
                    });
                    _flipToView(CardView.back);
                  },
                  tooltip: "Back",
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedMedicalRecord != null
                        ? 'Medical Record Details'
                        : 'Medical History',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (_selectedMedicalRecord != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _selectedMedicalRecord = null;
                      });
                    },
                    tooltip: "Close Details",
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Obx(() {
              if (controller.isLoadingMedical.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.medicalRecords.isEmpty) {
                return _buildEmptyState(
                  'No Medical Records',
                  'No medical history available for this pet yet.',
                  Icons.medical_services_outlined,
                );
              }

              if (_selectedMedicalRecord != null) {
                return _buildMedicalRecordDetails(_selectedMedicalRecord!);
              }

              return _buildMedicalRecordsList(controller.medicalRecords);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildVaccinationHistoryView() {
    final controller = Get.find<WebPetsController>();

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF2C3E50),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () {
                    setState(() {
                      _selectedVaccination = null;
                    });
                    _flipToView(CardView.back);
                  },
                  tooltip: "Back",
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedVaccination != null
                        ? 'Vaccination Details'
                        : 'Vaccination History',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (_selectedVaccination != null)
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _selectedVaccination = null;
                      });
                    },
                    tooltip: "Close Details",
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Obx(() {
              if (controller.isLoadingVaccinations.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.vaccinations.isEmpty) {
                return _buildEmptyState(
                  'No Vaccination Records',
                  'No vaccination history available for this pet yet.',
                  Icons.vaccines_outlined,
                );
              }

              if (_selectedVaccination != null) {
                return _buildVaccinationDetails(_selectedVaccination!);
              }

              return _buildVaccinationsList(controller.vaccinations);
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalRecordsList(List<MedicalRecord> records) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        return _buildMedicalRecordCard(record);
      },
    );
  }

  Widget _buildMedicalRecordCard(MedicalRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMedicalRecord = record;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF3498DB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medical_services,
                  color: Color(0xFF3498DB),
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.service,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(record.visitDate),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (record.diagnosis.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        record.diagnosis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicalRecordDetails(MedicalRecord record) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailCard(
            'Visit Information',
            [
              _buildDetailRow(
                  'Date', DateFormat('MMMM dd, yyyy').format(record.visitDate)),
              _buildDetailRow('Service', record.service),
            ],
          ),

          const SizedBox(height: 16),

          _buildDetailCard(
            'Diagnosis & Treatment',
            [
              _buildDetailRow('Diagnosis', record.diagnosis),
              _buildDetailRow('Treatment', record.treatment),
              if (record.prescription != null &&
                  record.prescription!.isNotEmpty)
                _buildDetailRow('Prescription', record.prescription!),
            ],
          ),

          // UPDATED: Use individual vital fields instead of vitals map
          if (record.hasVitals) ...[
            const SizedBox(height: 16),
            _buildDetailCard(
              'Vital Signs',
              [
                if (record.temperature != null)
                  _buildDetailRow('Temperature',
                      '${record.temperature!.toStringAsFixed(1)}°C'),
                if (record.weight != null)
                  _buildDetailRow(
                      'Weight', '${record.weight!.toStringAsFixed(2)} kg'),
                if (record.bloodPressure != null)
                  _buildDetailRow('Blood Pressure', record.bloodPressure!),
                if (record.heartRate != null)
                  _buildDetailRow('Heart Rate', '${record.heartRate} bpm'),
              ],
            ),
          ],

          if (record.notes != null && record.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDetailCard(
              'Additional Notes',
              [_buildDetailRow('Notes', record.notes!)],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVaccinationsList(List<Vaccination> vaccinations) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: vaccinations.length,
      itemBuilder: (context, index) {
        final vaccination = vaccinations[index];
        return _buildVaccinationCard(vaccination);
      },
    );
  }

  Widget _buildVaccinationCard(Vaccination vaccination) {
    Color statusColor;
    if (vaccination.isOverdue) {
      statusColor = Colors.red;
    } else if (vaccination.isDueSoon) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.green;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedVaccination = vaccination;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.vaccines,
                  color: statusColor,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vaccination.vaccineName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            vaccination.statusText,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Given: ${DateFormat('MMM dd, yyyy').format(vaccination.dateGiven)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (vaccination.nextDueDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Next Due: ${DateFormat('MMM dd, yyyy').format(vaccination.nextDueDate!)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVaccinationDetails(Vaccination vaccination) {
    Color statusColor;
    if (vaccination.isOverdue) {
      statusColor = Colors.red;
    } else if (vaccination.isDueSoon) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.green;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: statusColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    vaccination.statusText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          _buildDetailCard(
            'Vaccine Information',
            [
              _buildDetailRow('Vaccine Name', vaccination.vaccineName),
              _buildDetailRow('Type', vaccination.vaccineType),
              _buildDetailRow('Booster', vaccination.isBooster ? 'Yes' : 'No'),
              if (vaccination.manufacturer != null &&
                  vaccination.manufacturer!.isNotEmpty)
                _buildDetailRow('Manufacturer', vaccination.manufacturer!),
              if (vaccination.batchNumber != null &&
                  vaccination.batchNumber!.isNotEmpty)
                _buildDetailRow('Batch Number', vaccination.batchNumber!),
            ],
          ),

          const SizedBox(height: 16),

          _buildDetailCard(
            'Vaccination Dates',
            [
              _buildDetailRow(
                'Date Given',
                DateFormat('MMMM dd, yyyy').format(vaccination.dateGiven),
              ),
              if (vaccination.nextDueDate != null)
                _buildDetailRow(
                  'Next Due Date',
                  DateFormat('MMMM dd, yyyy').format(vaccination.nextDueDate!),
                ),
            ],
          ),

          const SizedBox(height: 16),

          _buildDetailCard(
            'Administered By',
            [
              _buildDetailRow('Veterinarian', vaccination.veterinarianName),
            ],
          ),

          if (vaccination.notes != null && vaccination.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildDetailCard(
              'Additional Notes',
              [_buildDetailRow('Notes', vaccination.notes!)],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailCard(
    String title,
    List<Widget> children, {
    IconData? icon,
    Color? iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: iconColor ?? const Color(0xFF2C3E50),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2C3E50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String message, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIDRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF2C3E50),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryButton(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onPressed,
    int count, {
    bool isPrimary = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isPrimary ? const Color(0xFF667eea) : Colors.white,
              foregroundColor:
                  isPrimary ? Colors.white : const Color(0xFF2C3E50),
              padding: const EdgeInsets.all(20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color:
                      isPrimary ? const Color(0xFF667eea) : Colors.grey[300]!,
                  width: isPrimary ? 2 : 1,
                ),
              ),
              elevation: isPrimary ? 4 : 0,
            ),
            onPressed: onPressed,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isPrimary
                        ? Colors.white.withOpacity(0.2)
                        : const Color(0xFF3498DB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isPrimary ? Colors.white : const Color(0xFF3498DB),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isPrimary
                              ? Colors.white
                              : const Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: isPrimary ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isPrimary
                            ? Colors.white.withOpacity(0.2)
                            : const Color(0xFF3498DB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isPrimary
                              ? Colors.white
                              : const Color(0xFF3498DB),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'records',
                      style: TextStyle(
                        fontSize: 11,
                        color: isPrimary ? Colors.white60 : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: isPrimary ? Colors.white : Colors.grey[400],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

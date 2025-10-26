import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/models/medical_record_model.dart';
import 'package:capstone_app/data/models/vaccination_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:capstone_app/web/user_web/controllers/web_pets_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

enum CardView { front, back, vaccinationHistory, medicalAppointmentsHistory }

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchHistories();
    });
  }

  @override
  void didUpdateWidget(WebPetDetailsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Refetch if pet changed
    if (oldWidget.pet.petId != widget.pet.petId) {
      _fetchHistories();
    }
  }

  void _fetchHistories() {
    final controller = Get.find<WebPetsController>();
    print('>>> Fetching histories for pet: ${widget.pet.petId}');

    // Fetch all three: vaccinations, medical appointments, and medical records
    controller.fetchPetVaccinationHistory(widget.pet.petId);
    controller.fetchPetMedicalAppointmentsAllClinics(widget.pet.petId);
    controller.fetchPetMedicalRecordsForAppointments(
        widget.pet.petId); // ✅ ADDED THIS
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
      case CardView.vaccinationHistory:
        return 2;

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
      _selectedVaccination = null;
      _selectedMedicalAppointment = null;
      // REMOVED: _selectedMedicalRecord = null;
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

            // Back side content - REMOVED Medical Records section
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Medical Appointments History section (PRIMARY)
                  _buildHistoryButton(
                    'Medical Appointments History',
                    'View all medical appointments with records',
                    Icons.local_hospital_outlined,
                    () => _flipToView(CardView.medicalAppointmentsHistory),
                    _getMedicalAppointmentsCount(),
                    isPrimary: true,
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
    final clinicId = appointment['clinicId']; // Get clinicId

    final controller = Get.find<WebPetsController>();
    final appointmentId = appointment['\$id'];
    final petId = appointment['petId'];

    print('>>> ============================================');
    print('>>> Checking records for appointment card');
    print('>>> Appointment ID: $appointmentId');
    print('>>> Clinic ID: $clinicId');

    // Check medical records by appointmentId
    bool hasMedicalRecord = false;
    MedicalRecord? matchedRecord;

    for (var record in controller.medicalRecords) {
      if (record.appointmentId == appointmentId) {
        hasMedicalRecord = true;
        matchedRecord = record;
        print('>>> ✅ Medical record found!');
        break;
      }
    }

    if (!hasMedicalRecord) {
      print('>>> Trying fuzzy match...');
      for (var record in controller.medicalRecords) {
        final petMatches = record.petId == petId;
        final dateMatches = record.visitDate.year == dateTime.year &&
            record.visitDate.month == dateTime.month &&
            record.visitDate.day == dateTime.day;
        final serviceMatches =
            record.service.toLowerCase().contains(service.toLowerCase()) ||
                service.toLowerCase().contains(record.service.toLowerCase());

        if (petMatches && dateMatches && serviceMatches) {
          hasMedicalRecord = true;
          matchedRecord = record;
          print('>>> ✅ Fuzzy match found!');
          break;
        }
      }
    }

    // Check vaccination records
    final hasVaccinationRecord = controller.vaccinations.any((vaccination) {
      final isSameDay = vaccination.dateGiven.year == dateTime.year &&
          vaccination.dateGiven.month == dateTime.month &&
          vaccination.dateGiven.day == dateTime.day;
      final isVaccineService = service.toLowerCase().contains('vaccin') ||
          service.toLowerCase().contains('immuniz');
      return isSameDay && isVaccineService;
    });

    final hasAnyRecord = hasMedicalRecord || hasVaccinationRecord;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasAnyRecord
            ? BorderSide.none
            : BorderSide(color: Colors.orange[300]!, width: 2),
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
              // 🆕 CLINIC PROFILE PICTURE (replaces icon with gradient)
              FutureBuilder<String?>(
                future: _getClinicProfilePictureId(clinicId),
                builder: (context, snapshot) {
                  final profilePictureId = snapshot.data;

                  if (profilePictureId != null && profilePictureId.isNotEmpty) {
                    // Show clinic profile picture
                    return Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (hasAnyRecord
                                    ? const Color(0xFF667eea)
                                    : Colors.orange[400]!)
                                .withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          _getClinicProfilePictureUrl(profilePictureId),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // Fallback to icon if image fails to load
                            return _buildClinicIconFallback(
                                hasAnyRecord, hasVaccinationRecord);
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return _buildClinicIconFallback(
                                hasAnyRecord, hasVaccinationRecord);
                          },
                        ),
                      ),
                    );
                  }

                  // Fallback to icon if no profile picture
                  return _buildClinicIconFallback(
                      hasAnyRecord, hasVaccinationRecord);
                },
              ),

              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Clinic Name (Bold) and Badge
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            clinicName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2C3E50),
                            ),
                          ),
                        ),
                        // Record type indicator
                        if (hasVaccinationRecord)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.purple[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.vaccines,
                                  size: 12,
                                  color: Colors.purple[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Vaccine',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple[700],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else if (hasMedicalRecord)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: 12,
                                  color: Colors.green[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Record',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.warning_outlined,
                                  size: 12,
                                  color: Colors.orange[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'No Record',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
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

// 🆕 Helper method to build fallback icon
  Widget _buildClinicIconFallback(
      bool hasAnyRecord, bool hasVaccinationRecord) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasAnyRecord
              ? [const Color(0xFF667eea), const Color(0xFF764ba2)]
              : [Colors.orange[400]!, Colors.orange[300]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                (hasAnyRecord ? const Color(0xFF667eea) : Colors.orange[400]!)
                    .withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        hasAnyRecord
            ? (hasVaccinationRecord ? Icons.vaccines : Icons.local_hospital)
            : Icons.local_hospital_outlined,
        color: Colors.white,
        size: 24,
      ),
    );
  }

// 🆕 Helper method to get clinic profile picture ID
  Future<String?> _getClinicProfilePictureId(String clinicId) async {
    try {
      final authRepository = Get.find<AuthRepository>();
      final clinicDoc = await authRepository.getClinicById(clinicId);

      if (clinicDoc != null) {
        return clinicDoc.data['profilePictureId'] as String?;
      }
      return null;
    } catch (e) {
      print('>>> Error fetching clinic profile picture ID: $e');
      return null;
    }
  }

// 🆕 Helper method to get clinic profile picture URL
  String _getClinicProfilePictureUrl(String profilePictureId) {
    return '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.imageBucketID}/files/$profilePictureId/view?project=${AppwriteConstants.projectID}';
  }

  Widget _buildMedicalAppointmentDetails(Map<String, dynamic> appointment) {
    final dateTime = DateTime.parse(appointment['dateTime']);
    final completedAt = appointment['serviceCompletedAt'] != null
        ? DateTime.parse(appointment['serviceCompletedAt'])
        : null;

    final controller = Get.find<WebPetsController>();
    final appointmentId = appointment['\$id'];
    final service = appointment['service'] ?? '';
    final petId = appointment['petId'];

    print('>>> ============================================');
    print('>>> Looking for records for appointment: $appointmentId');
    print('>>> Service: $service');
    print('>>> Pet ID: $petId');
    print('>>> Appointment Date: $dateTime');

    // CRITICAL: Try MULTIPLE matching strategies
    MedicalRecord? medicalRecord;
    Vaccination? vaccinationRecord;

    // STRATEGY 1: Try exact appointmentId match
    try {
      medicalRecord = controller.medicalRecords.firstWhere(
        (record) => record.appointmentId == appointmentId,
        orElse: () => throw Exception('Not found'),
      );
      print('>>> ✅ Found medical record by appointmentId: ${medicalRecord.id}');
    } catch (e) {
      print('>>> ℹ️ No medical record found by appointmentId');
    }

    // STRATEGY 2: If not found, try matching by pet + date + service
    if (medicalRecord == null) {
      try {
        medicalRecord = controller.medicalRecords.firstWhere(
          (record) {
            // Match by pet
            final petMatches = record.petId == petId;

            // Match by date (same day)
            final recordDate = record.visitDate;
            final dateMatches = recordDate.year == dateTime.year &&
                recordDate.month == dateTime.month &&
                recordDate.day == dateTime.day;

            // Match by service (fuzzy match)
            final serviceMatches = record.service.toLowerCase() ==
                    service.toLowerCase() ||
                service.toLowerCase().contains(record.service.toLowerCase()) ||
                record.service.toLowerCase().contains(service.toLowerCase());

            final matches = petMatches && dateMatches && serviceMatches;

            if (matches) {
              print('>>> 🔍 Potential match found by pet+date+service:');
              print('>>>   Record ID: ${record.id}');
              print('>>>   Record appointmentId: ${record.appointmentId}');
              print('>>>   Record petId: ${record.petId}');
              print('>>>   Record date: ${record.visitDate}');
              print('>>>   Record service: ${record.service}');
            }

            return matches;
          },
          orElse: () => throw Exception('Not found'),
        );
        print('>>> ✅ Found medical record by pet+date+service match!');
      } catch (e) {
        print('>>> ℹ️ No medical record found by pet+date+service either');
      }
    }

    // STRATEGY 3: If not found, try matching by pet + completed time (within 1 hour)
    if (medicalRecord == null && completedAt != null) {
      try {
        medicalRecord = controller.medicalRecords.firstWhere(
          (record) {
            // Match by pet
            final petMatches = record.petId == petId;

            // Match by time (within 1 hour of completion)
            final timeDifference =
                record.visitDate.difference(completedAt).abs();
            final timeMatches = timeDifference.inHours < 1;

            final matches = petMatches && timeMatches;

            if (matches) {
              print('>>> 🔍 Potential match found by pet+time:');
              print('>>>   Record ID: ${record.id}');
              print(
                  '>>>   Time difference: ${timeDifference.inMinutes} minutes');
            }

            return matches;
          },
          orElse: () => throw Exception('Not found'),
        );
        print('>>> ✅ Found medical record by pet+time match!');
      } catch (e) {
        print('>>> ℹ️ No medical record found by pet+time either');
      }
    }

    // Try to find vaccination record (match by date and service)
    try {
      final isVaccineService = service.toLowerCase().contains('vaccin') ||
          service.toLowerCase().contains('immuniz');

      if (isVaccineService) {
        vaccinationRecord = controller.vaccinations.firstWhere(
          (vaccination) {
            final isSameDay = vaccination.dateGiven.year == dateTime.year &&
                vaccination.dateGiven.month == dateTime.month &&
                vaccination.dateGiven.day == dateTime.day;
            return isSameDay;
          },
          orElse: () => throw Exception('Not found'),
        );
        print(
            '>>> ✅ Found vaccination record: ${vaccinationRecord.vaccineName}');
      }
    } catch (e) {
      print('>>> ℹ️ No vaccination record found');
    }

    // FINAL CHECK: Print all medical records for this pet to help debug
    if (medicalRecord == null && vaccinationRecord == null) {
      print('>>> 📋 All medical records for this pet:');
      final petRecords =
          controller.medicalRecords.where((r) => r.petId == petId).toList();
      for (var record in petRecords) {
        print('>>>   Record: ${record.id}');
        print('>>>     appointmentId: ${record.appointmentId}');
        print('>>>     visitDate: ${record.visitDate}');
        print('>>>     service: ${record.service}');
        print('>>>     diagnosis: ${record.diagnosis.substring(0, 30)}...');
      }

      if (petRecords.isEmpty) {
        print('>>>   ❌ No medical records found for pet: $petId');
      }
    }

    print('>>> ============================================');

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

          // ✅✅✅ VACCINATION RECORD SECTION (PRIORITY) ✅✅✅
          if (vaccinationRecord != null) ...[
            const SizedBox(height: 16),

            // Vaccine Information Card
            _buildDetailCard(
              'Vaccine Information',
              [
                _buildDetailRow('Vaccine Name', vaccinationRecord.vaccineName),
                _buildDetailRow('Type', vaccinationRecord.vaccineType),
                _buildDetailRow(
                    'Booster', vaccinationRecord.isBooster ? 'Yes' : 'No'),
                if (vaccinationRecord.manufacturer != null &&
                    vaccinationRecord.manufacturer!.isNotEmpty)
                  _buildDetailRow(
                      'Manufacturer', vaccinationRecord.manufacturer!),
                if (vaccinationRecord.batchNumber != null &&
                    vaccinationRecord.batchNumber!.isNotEmpty)
                  _buildDetailRow(
                      'Batch Number', vaccinationRecord.batchNumber!),
              ],
              icon: Icons.vaccines,
              iconColor: const Color(0xFF9B59B6),
            ),

            const SizedBox(height: 16),

            // Vaccination Dates Card
            _buildDetailCard(
              'Vaccination Dates',
              [
                _buildDetailRow(
                  'Date Given',
                  DateFormat('MMMM dd, yyyy')
                      .format(vaccinationRecord.dateGiven),
                ),
                if (vaccinationRecord.nextDueDate != null)
                  _buildDetailRow(
                    'Next Due Date',
                    DateFormat('MMMM dd, yyyy')
                        .format(vaccinationRecord.nextDueDate!),
                  ),
              ],
              icon: Icons.event,
              iconColor: const Color(0xFF3498DB),
            ),

            const SizedBox(height: 16),

            // Veterinarian Card
            _buildDetailCard(
              'Administered By',
              [
                _buildDetailRow(
                    'Veterinarian', vaccinationRecord.veterinarianName),
              ],
              icon: Icons.person,
              iconColor: const Color(0xFF2ECC71),
            ),

            if (vaccinationRecord.notes != null &&
                vaccinationRecord.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDetailCard(
                'Additional Notes',
                [_buildDetailRow('Notes', vaccinationRecord.notes!)],
                icon: Icons.note,
                iconColor: const Color(0xFF95A5A6),
              ),
            ],
          ]
          // ✅✅✅ MEDICAL RECORD SECTION (IF NO VACCINATION RECORD) ✅✅✅
          else if (medicalRecord != null) ...[
            const SizedBox(height: 16),

            // Diagnosis & Treatment Card
            _buildDetailCard(
              'Diagnosis & Treatment',
              [
                _buildDetailRow('Diagnosis', medicalRecord.diagnosis),
                _buildDetailRow('Treatment', medicalRecord.treatment),
                if (medicalRecord.prescription != null &&
                    medicalRecord.prescription!.isNotEmpty)
                  _buildDetailRow('Prescription', medicalRecord.prescription!),
              ],
              icon: Icons.medical_services,
              iconColor: const Color(0xFFE74C3C),
            ),

            // Vital Signs Card (if available)
            if (medicalRecord.hasVitals) ...[
              const SizedBox(height: 16),
              _buildDetailCard(
                'Vital Signs',
                [
                  if (medicalRecord.temperature != null)
                    _buildDetailRow('Temperature',
                        '${medicalRecord.temperature!.toStringAsFixed(1)}°C'),
                  if (medicalRecord.weight != null)
                    _buildDetailRow('Weight',
                        '${medicalRecord.weight!.toStringAsFixed(2)} kg'),
                  if (medicalRecord.bloodPressure != null)
                    _buildDetailRow(
                        'Blood Pressure', medicalRecord.bloodPressure!),
                  if (medicalRecord.heartRate != null)
                    _buildDetailRow(
                        'Heart Rate', '${medicalRecord.heartRate} bpm'),
                ],
                icon: Icons.favorite,
                iconColor: const Color(0xFFE74C3C),
              ),
            ],

            // Veterinary Notes Card
            if (medicalRecord.notes != null &&
                medicalRecord.notes!.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildDetailCard(
                'Veterinary Notes',
                [
                  _buildDetailRow('Notes', medicalRecord.notes!),
                ],
                icon: Icons.note,
                iconColor: const Color(0xFF9B59B6),
              ),
            ],
          ] else ...[
            // No records found - Enhanced debug info
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.orange[700], size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No medical record available',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This appointment was completed, but no detailed medical record or vaccination record was created at the time.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Debug Information:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Appointment ID: $appointmentId',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                        Text(
                          'Pet ID: $petId',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                        Text(
                          'Completed: ${completedAt != null ? DateFormat('MMM dd, yyyy HH:mm').format(completedAt) : 'N/A'}',
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

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

          // Additional Notes Card (from appointment)
          if (appointment['notes'] != null &&
              appointment['notes'].toString().isNotEmpty)
            _buildDetailCard(
              'Additional Appointment Notes',
              [
                _buildDetailRow('Notes', appointment['notes']),
              ],
              icon: Icons.note_outlined,
              iconColor: const Color(0xFF95A5A6),
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

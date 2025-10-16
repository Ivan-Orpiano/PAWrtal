import 'package:capstone_app/data/models/pet_model.dart';
import 'package:capstone_app/data/models/medical_record_model.dart';
import 'package:capstone_app/data/models/vaccination_model.dart';
import 'package:capstone_app/mobile/user/pages/pet_card_creation.dart';
import 'package:capstone_app/utils/custom_snack_bar.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/web/user_web/controllers/web_pets_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PetsNextPage extends StatefulWidget {
  final Pet pet;
  const PetsNextPage({super.key, required this.pet});

  @override
  State<PetsNextPage> createState() => _PetsNextPageState();
}

class _PetsNextPageState extends State<PetsNextPage> with TickerProviderStateMixin {
  bool _isMedicalExpanded = false;
  bool _isVaccinationExpanded = false;
  late AnimationController _medicalController;
  late AnimationController _vaccinationController;
  late Animation<double> _medicalArrowAnimation;
  late Animation<double> _vaccinationArrowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _medicalController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _vaccinationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // Arrow rotation animations
    _medicalArrowAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _medicalController, curve: Curves.easeInOut),
    );
    _vaccinationArrowAnimation = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _vaccinationController, curve: Curves.easeInOut),
    );
    
    // Fetch histories when page opens
    _fetchHistories();
  }

  void _fetchHistories() {
    try {
      final controller = Get.find<WebPetsController>();
      controller.fetchPetMedicalHistory(widget.pet.petId);
      controller.fetchPetVaccinationHistory(widget.pet.petId);
    } catch (e) {
      // Controller might not be initialized yet
      debugPrint('Controller not found: $e');
    }
  }

  @override
  void dispose() {
    _medicalController.dispose();
    _vaccinationController.dispose();
    super.dispose();
  }

  void _toggleMedicalSection() {
    setState(() {
      _isMedicalExpanded = !_isMedicalExpanded;
      if (_isMedicalExpanded) {
        _medicalController.forward();
      } else {
        _medicalController.reverse();
      }
    });
  }

  void _toggleVaccinationSection() {
    setState(() {
      _isVaccinationExpanded = !_isVaccinationExpanded;
      if (_isVaccinationExpanded) {
        _vaccinationController.forward();
      } else {
        _vaccinationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF3498DB),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_ios_new, size: 18),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, size: 20),
                ),
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PetCardCreation(existingPet: widget.pet),
                    ),
                  );
                  if (result == true) {
                    Get.back(result: true);
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  final confirm = await showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text("Delete Pet"),
                      content: const Text(
                          "Are you sure you want to delete this pet?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text("Delete"),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      // Delete image if exists
                      if (widget.pet.image != null && widget.pet.image!.isNotEmpty) {
                        final imageId = widget.pet.image!.split('/files/')[1].split('/')[0];
                        await Get.find<AuthRepository>().deleteImage(imageId);
                      }

                      // Delete pet
                      await Get.find<AuthRepository>().deletePet(widget.pet.documentId!);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Pet deleted successfully")),
                      );

                      Get.back(result: true);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Failed to delete pet: $e")),
                      );
                    }
                  }
                },
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.pet.image ??
                        'https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=600&h=600&fit=crop',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.pets, size: 100),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.pet.name,
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3498DB),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.pet.type,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Information Card
                  _buildInfoCard(
                    title: "Basic Information",
                    icon: Icons.info_outline,
                    children: [
                      _buildInfoRow(Icons.pets, "Breed", widget.pet.breed),
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.palette,
                        "Color",
                        widget.pet.color ?? "Not specified",
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.monitor_weight,
                        "Weight",
                        widget.pet.weight != null
                            ? "${widget.pet.weight} kg"
                            : "Not specified",
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(
                        Icons.wc,
                        "Gender",
                        widget.pet.gender ?? "Not specified",
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Notes Card
                  if (widget.pet.notes != null && widget.pet.notes!.isNotEmpty)
                    _buildInfoCard(
                      title: "Notes",
                      icon: Icons.notes,
                      children: [
                        Text(
                          widget.pet.notes!,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: Colors.grey[700],
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),

                  const SizedBox(height: 16),

                  // Medical History Section
                  _buildExpandableSection(
                    title: "Medical History",
                    icon: Icons.medical_services_outlined,
                    isExpanded: _isMedicalExpanded,
                    arrowAnimation: _medicalArrowAnimation,
                    onTap: _toggleMedicalSection,
                    contentBuilder: () => _buildMedicalHistoryContent(),
                  ),

                  const SizedBox(height: 16),

                  // Vaccination History Section
                  _buildExpandableSection(
                    title: "Vaccination History",
                    icon: Icons.vaccines_outlined,
                    isExpanded: _isVaccinationExpanded,
                    arrowAnimation: _vaccinationArrowAnimation,
                    onTap: _toggleVaccinationSection,
                    contentBuilder: () => _buildVaccinationHistoryContent(),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3498DB).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: const Color(0xFF3498DB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2C3E50),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey[400], size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: const Color(0xFF2C3E50),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required Animation<double> arrowAnimation,
    required VoidCallback onTap,
    required Widget Function() contentBuilder,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF3498DB).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3498DB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFF3498DB),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2C3E50),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isExpanded ? "Tap to collapse" : "Tap to view records",
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  RotationTransition(
                    turns: arrowAnimation,
                    child: Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.grey[400],
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: contentBuilder(),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicalHistoryContent() {
    try {
      final controller = Get.find<WebPetsController>();
      
      return Obx(() {
        if (controller.isLoadingMedical.value) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (controller.medicalRecords.isEmpty) {
          return _buildEmptyState(
            'No medical records yet',
            Icons.medical_services_outlined,
          );
        }
        
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(
            children: controller.medicalRecords
                .map((record) => _buildMedicalRecordCard(record))
                .toList(),
          ),
        );
      });
    } catch (e) {
      return _buildEmptyState(
        'Unable to load medical records',
        Icons.error_outline,
      );
    }
  }

  Widget _buildVaccinationHistoryContent() {
    try {
      final controller = Get.find<WebPetsController>();
      
      return Obx(() {
        if (controller.isLoadingVaccinations.value) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        
        if (controller.vaccinations.isEmpty) {
          return _buildEmptyState(
            'No vaccination records yet',
            Icons.vaccines_outlined,
          );
        }
        
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(
            children: controller.vaccinations
                .map((vaccination) => _buildVaccinationCard(vaccination))
                .toList(),
          ),
        );
      });
    } catch (e) {
      return _buildEmptyState(
        'Unable to load vaccination records',
        Icons.error_outline,
      );
    }
  }

  Widget _buildMedicalRecordCard(MedicalRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showMedicalRecordDetails(record),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3498DB).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.medical_services,
                  color: Color(0xFF3498DB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.service,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(record.visitDate),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (record.diagnosis.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        record.diagnosis,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
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
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showVaccinationDetails(vaccination),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.vaccines,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vaccination.vaccineName,
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2C3E50),
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
                            style: GoogleFonts.inter(
                              fontSize: 11,
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
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (vaccination.nextDueDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Next Due: ${DateFormat('MMM dd, yyyy').format(vaccination.nextDueDate!)}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _showMedicalRecordDetails(MedicalRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Medical Record Details',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildDetailSection(
                      'Visit Information',
                      [
                        _buildDetailItem('Date', DateFormat('MMMM dd, yyyy').format(record.visitDate)),
                        _buildDetailItem('Service', record.service),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailSection(
                      'Diagnosis & Treatment',
                      [
                        _buildDetailItem('Diagnosis', record.diagnosis),
                        _buildDetailItem('Treatment', record.treatment),
                        if (record.prescription != null && record.prescription!.isNotEmpty)
                          _buildDetailItem('Prescription', record.prescription!),
                      ],
                    ),
                    if (record.notes != null && record.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDetailSection(
                        'Additional Notes',
                        [_buildDetailItem('Notes', record.notes!)],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVaccinationDetails(Vaccination vaccination) {
    Color statusColor;
    if (vaccination.isOverdue) {
      statusColor = Colors.red;
    } else if (vaccination.isDueSoon) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.green;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Vaccination Details',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2C3E50),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    // Status Banner
                    Container(
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
                              style: GoogleFonts.inter(
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
                    _buildDetailSection(
                      'Vaccine Information',
                      [
                        _buildDetailItem('Vaccine Name', vaccination.vaccineName),
                        _buildDetailItem('Type', vaccination.vaccineType),
                        _buildDetailItem('Booster', vaccination.isBooster ? 'Yes' : 'No'),
                        if (vaccination.manufacturer != null && vaccination.manufacturer!.isNotEmpty)
                          _buildDetailItem('Manufacturer', vaccination.manufacturer!),
                        if (vaccination.batchNumber != null && vaccination.batchNumber!.isNotEmpty)
                          _buildDetailItem('Batch Number', vaccination.batchNumber!),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailSection(
                      'Vaccination Dates',
                      [
                        _buildDetailItem(
                          'Date Given',
                          DateFormat('MMMM dd, yyyy').format(vaccination.dateGiven),
                        ),
                        if (vaccination.nextDueDate != null)
                          _buildDetailItem(
                            'Next Due Date',
                            DateFormat('MMMM dd, yyyy').format(vaccination.nextDueDate!),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDetailSection(
                      'Administered By',
                      [_buildDetailItem('Veterinarian', vaccination.veterinarianName)],
                    ),
                    if (vaccination.notes != null && vaccination.notes!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildDetailSection(
                        'Additional Notes',
                        [_buildDetailItem('Notes', vaccination.notes!)],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }
}
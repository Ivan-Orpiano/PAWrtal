import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/models/staff_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/image_helper.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/super_ad_staff_management_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SuperAdminVetClinicDetailPage extends StatefulWidget {
  final Clinic clinic;
  final ClinicSettings? settings;

  const SuperAdminVetClinicDetailPage({
    super.key,
    required this.clinic,
    this.settings,
  });

  @override
  State<SuperAdminVetClinicDetailPage> createState() =>
      _SuperAdminVetClinicDetailPageState();
}

class _SuperAdminVetClinicDetailPageState
    extends State<SuperAdminVetClinicDetailPage> {
  final AuthRepository authRepository = Get.find<AuthRepository>();
  bool isLoading = false;
  int totalStaff = 0;

  @override
  void initState() {
    super.initState();
    _loadStaffCount();
  }

  Future<void> _loadStaffCount() async {
    try {
      final staffList =
          await authRepository.getClinicStaff(widget.clinic.documentId ?? '');
      setState(() {
        totalStaff = staffList.length;
      });
    } catch (e) {
      print('Error loading staff count: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 253, 255),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Color.fromARGB(255, 81, 115, 153)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.clinic.clinicName,
          style: const TextStyle(
            color: Color.fromARGB(255, 81, 115, 153),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromARGB(255, 81, 115, 153),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.05,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero Image
                    _buildHeroImage(),
                    const SizedBox(height: 24),

                    // Action Buttons
                    _buildActionButtons(context),
                    const SizedBox(height: 24),

                    // Clinic Information
                    _buildInfoSection(),
                    const SizedBox(height: 24),

                    // Operating Hours
                    if (widget.settings != null) ...[
                      _buildOperatingHours(),
                      const SizedBox(height: 24),
                    ],

                    // Services
                    _buildServices(),
                    const SizedBox(height: 24),

                    // Gallery
                    if (widget.settings != null &&
                        widget.settings!.gallery.isNotEmpty) ...[
                      _buildGallery(),
                      const SizedBox(height: 24),
                    ],

                    // Admin Information
                    _buildAdminInfo(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeroImage() {
    return Container(
      height: 300,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: widget.clinic.image.isNotEmpty
            ? DecorationImage(
                image: NetworkImage(getPetImageUrl(widget.clinic.image)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: widget.clinic.image.isEmpty
          ? Center(
              child: Icon(
                Icons.pets,
                size: 80,
                color: Colors.grey[400],
              ),
            )
          : null,
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SuperAdminStaffManagementPage(
                    clinic: widget.clinic,
                  ),
                ),
              ).then((_) => _loadStaffCount());
            },
            icon: const Icon(Icons.people),
            label: Column(
              children: [
                const Text('Manage Staff'),
                Text(
                  '$totalStaff Staff Members',
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 81, 115, 153),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              _showEditClinicDialog(context);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Edit Clinic'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Clinic Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 81, 115, 153),
              ),
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.location_on, 'Address', widget.clinic.address),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone, 'Contact', widget.clinic.contact),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.email, 'Email', widget.clinic.email),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.person,
              'Admin ID',
              widget.clinic.adminId,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.calendar_today,
              'Registered',
              _formatDate(widget.clinic.createdAt),
            ),
            if (widget.clinic.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.description,
                'Description',
                widget.clinic.description,
              ),
            ],
            if (widget.settings != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                Icons.access_time,
                'Status',
                widget.settings!.isOpen ? 'Open' : 'Closed',
                valueColor: widget.settings!.isOpen ? Colors.green : Colors.red,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.black87,
              fontWeight: valueColor != null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOperatingHours() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Operating Hours',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 81, 115, 153),
              ),
            ),
            const Divider(height: 24),
            ...widget.settings!.operatingHours.entries.map((entry) {
              final day = entry.key;
              final hours = entry.value;
              final isOpen = hours['isOpen'] as bool;
              final openTime = hours['openTime'] as String;
              final closeTime = hours['closeTime'] as String;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      day.substring(0, 1).toUpperCase() + day.substring(1),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      isOpen ? '$openTime - $closeTime' : 'Closed',
                      style: TextStyle(
                        color: isOpen ? Colors.black87 : Colors.red,
                        fontWeight: isOpen ? FontWeight.normal : FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildServices() {
    final services = widget.clinic.services.split(',').map((s) => s.trim()).toList();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Services Offered',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 81, 115, 153),
              ),
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: services.map((service) {
                return Chip(
                  label: Text(service),
                  backgroundColor: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
                  labelStyle: const TextStyle(
                    color: Color.fromARGB(255, 81, 115, 153),
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGallery() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gallery',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 81, 115, 153),
              ),
            ),
            const Divider(height: 24),
            SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.settings!.gallery.length,
                itemBuilder: (context, index) {
                  final imageId = widget.settings!.gallery[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        getPetImageUrl(imageId),
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 120,
                            height: 120,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminInfo() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Administrator Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color.fromARGB(255, 81, 115, 153),
              ),
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.person_outline, 'Created By', widget.clinic.createdBy),
            const SizedBox(height: 12),
            _buildInfoRow(Icons.badge, 'Role', widget.clinic.role),
          ],
        ),
      ),
    );
  }

  void _showEditClinicDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Clinic'),
        content: const Text(
          'Clinic editing functionality can be implemented here.\n\n'
          'This would allow updating clinic information, settings, and images.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return isoDate;
    }
  }
}
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/image_helper.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/veterinary_clinics/super_ad_staff_management_page.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/veterinary_clinics/super_ad_edit_clinic_page.dart';
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
  bool isDeleting = false;
  int totalStaff = 0;
  Clinic? currentClinic;
  ClinicSettings? currentSettings;

  @override
  void initState() {
    super.initState();
    currentClinic = widget.clinic;
    currentSettings = widget.settings;
    _loadStaffCount();
    _setupRealtimeUpdates();
  }

  Future<void> _loadStaffCount() async {
    try {
      final staffList =
          await authRepository.getClinicStaff(widget.clinic.documentId ?? '');
      if (mounted) {
        setState(() {
          totalStaff = staffList.length;
        });
      }
    } catch (e) {
      print('Error loading staff count: $e');
    }
  }

  void _setupRealtimeUpdates() {
    // Subscribe to clinic changes
    authRepository.subscribeToClinicChanges().listen((event) {
      if (event.payload['\$id'] == widget.clinic.documentId) {
        if (event.events
            .contains('databases.*.collections.*.documents.*.delete')) {
          // Clinic was deleted, navigate back
          if (mounted) {
            Navigator.of(context).pop(true); // Signal refresh
          }
        } else if (event.events
            .contains('databases.*.collections.*.documents.*.update')) {
          // Clinic was updated, refresh data
          _refreshClinicData();
        }
      }
    });

    // Subscribe to settings changes
    authRepository.subscribeToClinicSettingsChanges().listen((event) {
      if (mounted && currentSettings != null) {
        if (event.payload['clinicId'] == widget.clinic.documentId) {
          _refreshClinicData();
        }
      }
    });
  }

  Future<void> _refreshClinicData() async {
    try {
      final clinicDoc =
          await authRepository.getClinicById(widget.clinic.documentId ?? '');
      final settingsDoc = await authRepository
          .getClinicSettingsByClinicId(widget.clinic.documentId ?? '');

      if (mounted && clinicDoc != null) {
        setState(() {
          currentClinic = Clinic.fromMap(clinicDoc.data);
          currentClinic!.documentId = clinicDoc.$id;
          currentSettings = settingsDoc;
        });
      }
    } catch (e) {
      print('Error refreshing clinic data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Use current data (updated via realtime)
    final clinic = currentClinic ?? widget.clinic;
    final settings = currentSettings ?? widget.settings;

    // Real-time status
    final isOpen = settings?.isOpenNow() ?? false;
    final detailedStatus = settings?.getDetailedStatus() ?? 'N/A';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: const Color.fromRGBO(81, 115, 153, 0.1),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Color.fromRGBO(81, 115, 153, 1)),
          onPressed: () => Navigator.pop(context, true), // Signal refresh
        ),
        title: Text(
          clinic.clinicName,
          style: const TextStyle(
            color: Color.fromRGBO(81, 115, 153, 1),
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Real-time status indicator
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isOpen ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isOpen ? Colors.green[300]! : Colors.red[300]!,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isOpen ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  detailedStatus,
                  style: TextStyle(
                    color: isOpen ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color.fromRGBO(81, 115, 153, 1),
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
                    // Hero Image with Gallery
                    _buildHeroImageWithGallery(clinic, settings),
                    const SizedBox(height: 24),

                    // Action Buttons
                    _buildActionButtons(context, clinic),
                    const SizedBox(height: 24),

                    // Clinic Information
                    _buildInfoSection(clinic, settings),
                    const SizedBox(height: 24),

                    // Operating Hours (View Only)
                    if (settings != null) ...[
                      _buildOperatingHoursViewOnly(settings),
                      const SizedBox(height: 24),
                    ],

                    // Services
                    _buildServices(clinic),
                    const SizedBox(height: 24),

                    // Gallery
                    if (settings != null && settings.gallery.isNotEmpty) ...[
                      _buildGallery(settings),
                      const SizedBox(height: 24),
                    ],

                    // Admin Information
                    _buildAdminInfo(clinic),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeroImageWithGallery(Clinic clinic, ClinicSettings? settings) {
    return Container(
      height: 350,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(81, 115, 153, 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Main image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: clinic.image.isNotEmpty
                ? Image.network(
                    getPetImageUrl(clinic.image),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildPlaceholder();
                    },
                  )
                : _buildPlaceholder(),
          ),
          // Gallery count badge
          if (settings != null && settings.gallery.isNotEmpty)
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.photo_library,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${settings.gallery.length} photos',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Clinic clinic) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isDeleting
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SuperAdminStaffManagementPage(
                          clinic: clinic,
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
              backgroundColor: const Color.fromRGBO(81, 115, 153, 1),
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
            onPressed: isDeleting
                ? null
                : () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SuperAdminEditClinicPage(
                          clinic: clinic,
                          settings: currentSettings,
                        ),
                      ),
                    );

                    // If edit was successful, refresh will happen via realtime
                    if (result == true) {
                      _showSuccessSnackbar('Clinic updated successfully');
                    }
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
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isDeleting
                ? null
                : () => _showDeleteConfirmation(context, clinic),
            icon: isDeleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.delete_forever),
            label: Text(isDeleting ? 'Deleting...' : 'Delete Clinic'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
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

  Widget _buildInfoSection(Clinic clinic, ClinicSettings? settings) {
    final isOpen = settings?.isOpenNow() ?? false;
    final detailedStatus = settings?.getDetailedStatus() ?? 'N/A';

    return Card(
      elevation: 2,
      shadowColor: const Color.fromRGBO(81, 115, 153, 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Clinic Information',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(81, 115, 153, 1),
              ),
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.location_on, 'Address', clinic.address),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.phone, 'Contact', clinic.contact),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email, 'Email', clinic.email),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.person, 'Admin ID', clinic.adminId),
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.calendar_today,
              'Registered',
              _formatDate(clinic.createdAt),
            ),
            if (clinic.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildInfoRow(
                Icons.description,
                'Description',
                clinic.description,
              ),
            ],
            const SizedBox(height: 16),
            _buildInfoRow(
              Icons.circle,
              'Current Status',
              detailedStatus,
              valueColor: isOpen ? Colors.green[700] : Colors.red[700],
              isBold: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(81, 115, 153, 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon,
              size: 20, color: const Color.fromRGBO(81, 115, 153, 1)),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
              fontSize: 14,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.black87,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOperatingHoursViewOnly(ClinicSettings settings) {
    return Card(
      elevation: 2,
      shadowColor: const Color.fromRGBO(81, 115, 153, 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Operating Hours',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color.fromRGBO(81, 115, 153, 1),
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: settings.isOpen ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: settings.isOpen
                          ? Colors.green[300]!
                          : Colors.red[300]!,
                    ),
                  ),
                  child: Text(
                    settings.isOpen
                        ? 'Accepting Appointments'
                        : 'Not Accepting Appointments',
                    style: TextStyle(
                      color:
                          settings.isOpen ? Colors.green[700] : Colors.red[700],
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...settings.operatingHours.entries.map((entry) {
              final day = entry.key;
              final hours = entry.value;
              final isOpen = hours['isOpen'] as bool;
              final openTime = hours['openTime'] as String;
              final closeTime = hours['closeTime'] as String;

              // Check if it's today
              final today = DateTime.now().weekday;
              final dayName = _getDayName(today);
              final isToday = day == dayName;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isToday
                      ? const Color.fromRGBO(81, 115, 153, 0.05)
                      : Colors.transparent,
                  border: Border.all(
                    color: isToday
                        ? const Color.fromRGBO(81, 115, 153, 0.3)
                        : Colors.grey[300]!,
                    width: isToday ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    if (isToday)
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(81, 115, 153, 1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'TODAY',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        day.substring(0, 1).toUpperCase() + day.substring(1),
                        style: TextStyle(
                          fontWeight:
                              isToday ? FontWeight.bold : FontWeight.w600,
                          fontSize: 16,
                          color: isToday
                              ? const Color.fromRGBO(81, 115, 153, 1)
                              : Colors.black87,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isOpen) ...[
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Colors.green[700],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$openTime - $closeTime',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ] else ...[
                            Icon(
                              Icons.cancel,
                              size: 16,
                              color: Colors.red[700],
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Closed',
                              style: TextStyle(
                                color: Colors.red[700],
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'monday';
      case 2:
        return 'tuesday';
      case 3:
        return 'wednesday';
      case 4:
        return 'thursday';
      case 5:
        return 'friday';
      case 6:
        return 'saturday';
      case 7:
        return 'sunday';
      default:
        return 'monday';
    }
  }

  Widget _buildServices(Clinic clinic) {
    final services = clinic.services.split(',').map((s) => s.trim()).toList();

    return Card(
      elevation: 2,
      shadowColor: const Color.fromRGBO(81, 115, 153, 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Services Offered',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(81, 115, 153, 1),
              ),
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: services.map((service) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(81, 115, 153, 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color.fromRGBO(81, 115, 153, 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Color.fromRGBO(81, 115, 153, 1),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        service,
                        style: const TextStyle(
                          color: Color.fromRGBO(81, 115, 153, 1),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGallery(ClinicSettings settings) {
    return Card(
      elevation: 2,
      shadowColor: const Color.fromRGBO(81, 115, 153, 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Clinic Gallery',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(81, 115, 153, 1),
              ),
            ),
            const Divider(height: 24),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: settings.gallery.length,
                itemBuilder: (context, index) {
                  final imageId = settings.gallery[index];
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        getPetImageUrl(imageId),
                        width: 150,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 150,
                            height: 150,
                            color: Colors.grey[300],
                            child: const Icon(Icons.error, color: Colors.red),
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

  Widget _buildAdminInfo(Clinic clinic) {
    return Card(
      elevation: 2,
      shadowColor: const Color.fromRGBO(81, 115, 153, 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Administrator Information',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(81, 115, 153, 1),
              ),
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.person_outline, 'Created By', clinic.createdBy),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.badge, 'Role', clinic.role),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            size: 80,
            color: Color.fromRGBO(81, 115, 153, 0.3),
          ),
          SizedBox(height: 12),
          Text(
            'No Image Available',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Clinic clinic) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 28),
            const SizedBox(width: 12),
            const Text('Delete Clinic'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to permanently delete "${clinic.clinicName}"?',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          size: 16, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Text(
                        'This action will delete:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('• All clinic appointments'),
                  const Text('• All medical records'),
                  const Text('• All conversations and messages'),
                  const Text('• All staff accounts (deactivated)'),
                  const Text('• All gallery images'),
                  const Text('• Clinic settings'),
                  const SizedBox(height: 8),
                  Text(
                    'This action cannot be undone!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
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
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteClinic(clinic);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteClinic(Clinic clinic) async {
    setState(() {
      isDeleting = true;
    });

    try {
      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                color: Color.fromRGBO(81, 115, 153, 1),
              ),
              const SizedBox(height: 16),
              const Text(
                'Deleting clinic and all associated data...',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );

      // Perform deletion
      final results = await authRepository.deleteClinicCompletely(
        clinic.documentId ?? '',
      );

      // Close progress dialog
      if (mounted) Navigator.pop(context);

      // Show results
      if (results['clinicDeleted'] == true) {
        _showDeletionResults(results);

        // Navigate back to dashboard after short delay
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else {
        _showErrorSnackbar('Failed to delete clinic');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Close progress dialog
      _showErrorSnackbar('Error deleting clinic: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          isDeleting = false;
        });
      }
    }
  }

  void _showDeletionResults(Map<String, dynamic> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 28),
            const SizedBox(width: 12),
            const Text('Deletion Complete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Successfully deleted:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildResultRow('Clinic', results['clinicDeleted'] ? '✓' : '✗'),
            _buildResultRow('Settings', results['settingsDeleted'] ? '✓' : '✗'),
            _buildResultRow(
                'Appointments', '${results['appointmentsDeleted']}'),
            _buildResultRow(
                'Medical Records', '${results['medicalRecordsDeleted']}'),
            _buildResultRow(
                'Conversations', '${results['conversationsDeleted']}'),
            _buildResultRow('Messages', '${results['messagesDeleted']}'),
            _buildResultRow('Staff Deactivated', '${results['staffDeleted']}'),
            _buildResultRow(
                'Gallery Images', '${results['galleryImagesDeleted']}'),
            if (results['errors'].isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Errors: ${results['errors'].length}',
                style: TextStyle(
                    color: Colors.red[700], fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(81, 115, 153, 1),
              foregroundColor: Colors.white,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 5),
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

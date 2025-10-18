import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/image_helper.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/veterinary_clinics/super_ad_staff_management_page.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/veterinary_clinics/super_ad_edit_clinic_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:async';
import 'package:appwrite/appwrite.dart';

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
    extends State<SuperAdminVetClinicDetailPage>
    with SingleTickerProviderStateMixin {
  final AuthRepository authRepository = Get.find<AuthRepository>();

  // State management
  bool isLoading = false;
  bool isDeleting = false;
  int totalStaff = 0;
  Clinic? currentClinic;
  ClinicSettings? currentSettings;

  // Real-time subscriptions
  StreamSubscription? _clinicSubscription;
  StreamSubscription? _settingsSubscription;

  // Animation controller for smooth transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Gallery state
  int _selectedGalleryIndex = 0;
  final PageController _galleryPageController = PageController();

  @override
  void initState() {
    super.initState();
    currentClinic = widget.clinic;
    currentSettings = widget.settings;

    // Initialize animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    _loadStaffCount();
    _setupRealtimeUpdates();
  }

  @override
  void dispose() {
    _clinicSubscription?.cancel();
    _settingsSubscription?.cancel();
    _animationController.dispose();
    _galleryPageController.dispose();
    super.dispose();
  }

  Future<void> _loadStaffCount() async {
    try {
      final staffList =
          await authRepository.getClinicStaff(currentClinic?.documentId ?? '');
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
    _clinicSubscription = authRepository
        .subscribeToClinicChanges()
        .listen((RealtimeMessage event) {
      print('🔔 Clinic real-time event: ${event.events}');

      if (event.payload['\$id'] == currentClinic?.documentId) {
        if (event.events.any((e) => e.contains('.delete'))) {
          // Clinic deleted - navigate back
          if (mounted) {
            _showDeletedDialog();
          }
        } else if (event.events.any((e) => e.contains('.update'))) {
          // Clinic updated - refresh
          _refreshClinicData();
        }
      }
    });

    // Subscribe to settings changes
    _settingsSubscription = authRepository
        .subscribeToClinicSettingsChanges()
        .listen((RealtimeMessage event) {
      print('🔔 Settings real-time event: ${event.events}');

      if (currentSettings != null &&
          event.payload['clinicId'] == currentClinic?.documentId) {
        _refreshClinicData();
      }
    });
  }

  Future<void> _refreshClinicData() async {
    try {
      print('🔄 Refreshing clinic data...');

      final clinicDoc =
          await authRepository.getClinicById(currentClinic?.documentId ?? '');
      final settingsDoc = await authRepository
          .getClinicSettingsByClinicId(currentClinic?.documentId ?? '');

      if (mounted && clinicDoc != null) {
        setState(() {
          currentClinic = Clinic.fromMap(clinicDoc.data);
          currentClinic!.documentId = clinicDoc.$id;
          currentSettings = settingsDoc;
        });

        _showUpdateNotification('Clinic information updated');
      }
    } catch (e) {
      print('❌ Error refreshing clinic data: $e');
    }
  }

  void _showUpdateNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.refresh, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color.fromRGBO(81, 115, 153, 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showDeletedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange[700], size: 28),
            const SizedBox(width: 12),
            const Text('Clinic Archived'),
          ],
        ),
        content: const Text(
          'This clinic has been archived by another administrator.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(81, 115, 153, 1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1000;

    final clinic = currentClinic ?? widget.clinic;
    final settings = currentSettings ?? widget.settings;

    // Real-time status
    final isOpen = settings?.isOpenNow() ?? false;
    final detailedStatus = settings?.getDetailedStatus() ?? 'Status Unknown';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          // Animated App Bar with Hero Image
          _buildSliverAppBar(
              clinic, settings, isOpen, detailedStatus, isMobile),

          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Quick Stats Cards
                    _buildQuickStatsCards(clinic, settings, isMobile),
                    const SizedBox(height: 24),

                    // Action Buttons
                    _buildActionButtons(context, clinic, isMobile),
                    const SizedBox(height: 24),

                    // Gallery Section (Real-time updated)
                    if (settings != null && settings.gallery.isNotEmpty) ...[
                      _buildGallerySection(settings, isMobile),
                      const SizedBox(height: 24),
                    ],

                    // Services Section (Real-time updated)
                    _buildServicesSection(clinic, isMobile),
                    const SizedBox(height: 24),

                    // Operating Hours (Real-time updated)
                    if (settings != null) ...[
                      _buildOperatingHoursSection(settings, isMobile),
                      const SizedBox(height: 24),
                    ],

                    // Contact Information
                    _buildContactSection(clinic, isMobile),
                    const SizedBox(height: 24),

                    // Admin Information
                    _buildAdminSection(clinic, isMobile),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(
    Clinic clinic,
    ClinicSettings? settings,
    bool isOpen,
    String detailedStatus,
    bool isMobile,
  ) {
    return SliverAppBar(
      surfaceTintColor: Colors.transparent,
      expandedHeight: isMobile ? 300 : 400,
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Icon(
            Icons.arrow_back,
            color: Color.fromRGBO(81, 115, 153, 1),
          ),
        ),
        onPressed: () => Navigator.pop(context, true),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.6),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            clinic.clinicName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Hero Image
            clinic.image.isNotEmpty
                ? Image.network(
                    getPetImageUrl(clinic.image),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImagePlaceholder();
                    },
                  )
                : _buildImagePlaceholder(),

            // Gradient Overlay
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

            // Real-time Status Badge
            Positioned(
              top: 100,
              right: 16,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isOpen
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (isOpen ? Colors.green : Colors.red).withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white.withOpacity(0.8),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      detailedStatus,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        letterSpacing: 0.5,
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
  }

  Widget _buildQuickStatsCards(
      Clinic clinic, ClinicSettings? settings, bool isMobile) {
    final services =
        clinic.services.split(',').where((s) => s.trim().isNotEmpty).toList();
    final galleryCount = settings?.gallery.length ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.medical_services,
            label: 'Services',
            value: '${services.length}',
            color: const Color.fromRGBO(81, 115, 153, 1),
            isMobile: isMobile,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.photo_library,
            label: 'Gallery',
            value: '$galleryCount',
            color: Colors.purple,
            isMobile: isMobile,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.people,
            label: 'Staff',
            value: '$totalStaff',
            color: Colors.orange,
            isMobile: isMobile,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isMobile,
  }) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: isMobile ? 24 : 28),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 12 : 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, Clinic clinic, bool isMobile) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.people,
            label: 'Manage Staff',
            subtitle: '$totalStaff Members',
            color: const Color.fromRGBO(81, 115, 153, 1),
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
            isMobile: isMobile,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: Icons.edit,
            label: 'Edit Clinic',
            subtitle: 'Modify Details',
            color: Colors.orange[700]!,
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
                    if (result == true) {
                      _showUpdateNotification('Clinic updated successfully');
                    }
                  },
            isMobile: isMobile,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            icon: isDeleting ? Icons.hourglass_empty : Icons.archive,
            label: isDeleting ? 'Archiving...' : 'Archive',
            subtitle: 'Archive Clinic',
            color: Colors.orange[700]!,
            onPressed: isDeleting
                ? null
                : () => _showDeleteConfirmation(context, clinic),
            isMobile: isMobile,
            isLoading: isDeleting,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback? onPressed,
    required bool isMobile,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 14 : 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color,
                color.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Icon(icon, color: Colors.white, size: isMobile ? 28 : 32),
              SizedBox(height: isMobile ? 8 : 10),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 14 : 15,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: isMobile ? 11 : 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGallerySection(ClinicSettings settings, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            const Color(0xFFF8FAFC),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color.fromRGBO(81, 115, 153, 0.2),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(81, 115, 153, 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Header
          Container(
            padding: EdgeInsets.all(isMobile ? 20 : 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromRGBO(81, 115, 153, 0.05),
                  Colors.transparent,
                ],
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color.fromRGBO(81, 115, 153, 0.15),
                        Color.fromRGBO(81, 115, 153, 0.08),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color.fromRGBO(81, 115, 153, 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: Color.fromRGBO(81, 115, 153, 1),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Clinic Gallery',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color.fromRGBO(81, 115, 153, 1),
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color.fromRGBO(81, 115, 153, 0.15),
                              const Color.fromRGBO(81, 115, 153, 0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color.fromRGBO(81, 115, 153, 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.image_rounded,
                              size: 16,
                              color: Color.fromRGBO(81, 115, 153, 1),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${settings.gallery.length} photos uploaded',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Real-time sync indicator
                // Container(
                //   padding: const EdgeInsets.all(10),
                //   decoration: BoxDecoration(
                //     color: const Color(0xFF10B981).withOpacity(0.1),
                //     shape: BoxShape.circle,
                //     border: Border.all(
                //       color: const Color(0xFF10B981).withOpacity(0.3),
                //       width: 2,
                //     ),
                //   ),
                //   child: const Icon(
                //     Icons.sync_rounded,
                //     color: Color(0xFF10B981),
                //     size: 20,
                //   ),
                // ),
              ],
            ),
          ),

          // Main Gallery Image with Enhanced PageView
          Container(
            height: isMobile ? 280 : 420,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: PageView.builder(
              controller: _galleryPageController,
              itemCount: settings.gallery.length,
              onPageChanged: (index) {
                setState(() {
                  _selectedGalleryIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final imageId = settings.gallery[index];
                return AnimatedBuilder(
                  animation: _galleryPageController,
                  builder: (context, child) {
                    double value = 1.0;
                    if (_galleryPageController.position.haveDimensions) {
                      value = _galleryPageController.page! - index;
                      value = (1 - (value.abs() * 0.3)).clamp(0.7, 1.0);
                    }
                    return Center(
                      child: SizedBox(
                        height: Curves.easeInOut.transform(value) *
                            (isMobile ? 280 : 420),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromRGBO(81, 115, 153, 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            getPetImageUrl(imageId),
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      const Color(0xFFF8FAFC),
                                      const Color.fromRGBO(81, 115, 153, 0.05),
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color.fromRGBO(
                                                      81, 115, 153, 0.2)
                                                  .withOpacity(0.3),
                                              blurRadius: 20,
                                              spreadRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: CircularProgressIndicator(
                                          value: loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                              : null,
                                          strokeWidth: 3,
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                  Color>(
                                            Color.fromRGBO(81, 115, 153, 1),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(24),
                                          boxShadow: [
                                            BoxShadow(
                                              color: const Color.fromRGBO(
                                                      81, 115, 153, 0.15)
                                                  .withOpacity(0.3),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          'Loading image ${index + 1}...',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Colors.red[50]!,
                                      Colors.red[100]!,
                                    ],
                                  ),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.red.withOpacity(0.3),
                                              blurRadius: 20,
                                              spreadRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.broken_image_rounded,
                                          size: 64,
                                          color: Colors.red,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(24),
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.red.withOpacity(0.2),
                                              blurRadius: 12,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          'Failed to load image',
                                          style: TextStyle(
                                            color: Colors.red[700],
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          // Image counter overlay
                          Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(0.75),
                                    Colors.black.withOpacity(0.65),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                '${index + 1} / ${settings.gallery.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Enhanced Gallery Thumbnail Strip
          Container(
            height: 90,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: settings.gallery.length,
              itemBuilder: (context, index) {
                final imageId = settings.gallery[index];
                final isSelected = _selectedGalleryIndex == index;
                return GestureDetector(
                  onTap: () {
                    _galleryPageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutCubic,
                    );
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: isSelected ? 100 : 85,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? const Color.fromRGBO(81, 115, 153, 1)
                            : Colors.transparent,
                        width: isSelected ? 3.5 : 2,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: const Color.fromRGBO(81, 115, 153, 0.4),
                            blurRadius: 16,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            getPetImageUrl(imageId),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.grey[200]!,
                                      Colors.grey[300]!,
                                    ],
                                  ),
                                ),
                                child: const Icon(
                                  Icons.error_outline_rounded,
                                  size: 28,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                          if (!isSelected)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                              ),
                            ),
                          if (isSelected)
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.5),
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(13),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
           const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildServicesSection(Clinic clinic, bool isMobile) {
    final services = clinic.services
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(81, 115, 153, 0.1),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(81, 115, 153, 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.medical_services,
                  color: Color.fromRGBO(81, 115, 153, 1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Services Offered',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(81, 115, 153, 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: services.map((service) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color.fromRGBO(81, 115, 153, 0.15),
                      const Color.fromRGBO(81, 115, 153, 0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: const Color.fromRGBO(81, 115, 153, 0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 18,
                      color: Color.fromRGBO(81, 115, 153, 1),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      service,
                      style: const TextStyle(
                        color: Color.fromRGBO(81, 115, 153, 1),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildOperatingHoursSection(ClinicSettings settings, bool isMobile) {
    final today = DateTime.now().weekday;
    final todayName = _getDayName(today);

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(81, 115, 153, 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(81, 115, 153, 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.access_time,
                      color: Color.fromRGBO(81, 115, 153, 1),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Operating Hours',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color.fromRGBO(81, 115, 153, 1),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: settings.isOpen
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  settings.isOpen ? 'Accepting' : 'Not Accepting',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...settings.operatingHours.entries.map((entry) {
            final day = entry.key;
            final hours = entry.value;
            final isOpen = hours['isOpen'] as bool;
            final openTime = hours['openTime'] as String;
            final closeTime = hours['closeTime'] as String;
            final isToday = day == todayName;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: isToday
                    ? LinearGradient(
                        colors: [
                          const Color.fromRGBO(81, 115, 153, 0.15),
                          const Color.fromRGBO(81, 115, 153, 0.05),
                        ],
                      )
                    : null,
                color: isToday ? null : Colors.grey[50],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isToday
                      ? const Color.fromRGBO(81, 115, 153, 0.4)
                      : Colors.grey[300]!,
                  width: isToday ? 2.5 : 1.5,
                ),
              ),
              child: Row(
                children: [
                  if (isToday)
                    Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(81, 115, 153, 1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'TODAY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      day.substring(0, 1).toUpperCase() + day.substring(1),
                      style: TextStyle(
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
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
                            Icons.schedule,
                            size: 18,
                            color: const Color(0xFF10B981),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$openTime - $closeTime',
                            style: TextStyle(
                              color: Colors.black87,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ] else ...[
                          Icon(
                            Icons.block,
                            size: 18,
                            color: Colors.red[600],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Closed',
                            style: TextStyle(
                              color: Colors.red[600],
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
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
    );
  }

  Widget _buildContactSection(Clinic clinic, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(81, 115, 153, 0.1),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(81, 115, 153, 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.contact_phone,
                  color: Color.fromRGBO(81, 115, 153, 1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Contact Information',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(81, 115, 153, 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildContactRow(
            Icons.location_on,
            'Address',
            clinic.address,
            Colors.red,
          ),
          const Divider(height: 24),
          _buildContactRow(
            Icons.phone,
            'Phone',
            clinic.contact,
            Colors.green,
          ),
          const Divider(height: 24),
          _buildContactRow(
            Icons.email,
            'Email',
            clinic.email,
            Colors.blue,
          ),
          if (clinic.description.isNotEmpty) ...[
            const Divider(height: 24),
            _buildContactRow(
              Icons.description,
              'Description',
              clinic.description,
              Colors.orange,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactRow(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdminSection(Clinic clinic, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromRGBO(81, 115, 153, 0.05),
            const Color.fromRGBO(81, 115, 153, 0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color.fromRGBO(81, 115, 153, 0.2),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(81, 115, 153, 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.admin_panel_settings,
                  color: Color.fromRGBO(81, 115, 153, 1),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Administrator',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color.fromRGBO(81, 115, 153, 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildAdminInfoRow('Admin ID', clinic.adminId, Icons.badge),
          const SizedBox(height: 12),
          _buildAdminInfoRow('Created By', clinic.createdBy, Icons.person),
          const SizedBox(height: 12),
          _buildAdminInfoRow('Role', clinic.role, Icons.verified_user),
          const SizedBox(height: 12),
          _buildAdminInfoRow(
            'Created',
            _formatDate(clinic.createdAt),
            Icons.calendar_today,
          ),
        ],
      ),
    );
  }

  Widget _buildAdminInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color.fromRGBO(81, 115, 153, 0.7),
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            size: 100,
            color: const Color.fromRGBO(81, 115, 153, 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'No Image Available',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return isoDate;
    }
  }

 void _showDeleteConfirmation(BuildContext context, Clinic clinic) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color.fromARGB(255, 248, 253, 255),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(Icons.archive_rounded, color: Colors.orange[700], size: 28),
          const SizedBox(width: 12),
          const Text('Archive Clinic'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to archive "${clinic.clinicName}"?',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
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
                        size: 18, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Text(
                      'This will archive the clinic and:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('• All appointments'),
                const Text('• All medical records'),
                const Text('• All conversations'),
                const Text('• Staff accounts (deactivated)'),
                const Text('• Gallery images'),
                const SizedBox(height: 8),
                Text(
                  'The clinic will be PERMANENTLY DELETED in 30 days.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You can recover it within 30 days from the Archived Clinics page.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
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
            _archiveClinic(clinic); // CHANGED FROM _deleteClinic
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[700],
            foregroundColor: Colors.white,
          ),
          child: const Text('Archive'),
        ),
      ],
    ),
  );
}

  Future<void> _archiveClinic(Clinic clinic) async {
  setState(() {
    isDeleting = true;
  });

  try {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              color: Color.fromRGBO(81, 115, 153, 1),
            ),
            SizedBox(height: 16),
            Text(
              'Archiving clinic...',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );

    // Get current admin info
    final currentUser = await authRepository.getUser();
    final adminName = currentUser?.name ?? 'Super Admin';

    // Archive the clinic
    final results = await authRepository.archiveClinic(
      clinicId: clinic.documentId ?? '',
      clinicDocumentId: clinic.documentId ?? '',
      archivedBy: adminName,
      archiveReason: 'Archived by super admin',
    );

    if (mounted) Navigator.pop(context);

    if (results['success'] == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.archive, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Clinic archived successfully. Will be permanently deleted in 30 days.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } else {
      _showErrorSnackbar('Failed to archive clinic: ${results['error']}');
    }
  } catch (e) {
    if (mounted) Navigator.pop(context);
    _showErrorSnackbar('Error: ${e.toString()}');
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green[700], size: 28),
            const SizedBox(width: 12),
            const Text('Archiving Complete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Successfully archived:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildResultRow(
                'Appointments', '${results['appointmentsDeleted']}'),
            _buildResultRow(
                'Medical Records', '${results['medicalRecordsDeleted']}'),
            _buildResultRow(
                'Conversations', '${results['conversationsDeleted']}'),
            _buildResultRow('Messages', '${results['messagesDeleted']}'),
            _buildResultRow('Staff', '${results['staffDeleted']}'),
            _buildResultRow('Gallery', '${results['galleryImagesDeleted']}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(81, 115, 153, 1),
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
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
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
      ),
    );
  }
}

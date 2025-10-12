import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/mobile/user/pages/clinic_page_maps.dart';
import 'package:capstone_app/mobile/user/pages/schedule_appointment.dart';
import 'package:capstone_app/mobile/user/pages/clinic_reviews_page.dart';
import 'package:flutter/material.dart';
import 'package:capstone_app/mobile/user/controllers/messaging_controller.dart';
import 'package:capstone_app/mobile/user/pages/messages_next_page.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:get/get.dart';

import 'package:capstone_app/data/id_verification/guards/appointment_verification_guard.dart';

class DashboardNextPage extends StatefulWidget {
  final Clinic clinic;
  final ClinicSettings? clinicSettings;

  const DashboardNextPage({
    super.key,
    required this.clinic,
    this.clinicSettings,
  });

  @override
  State<DashboardNextPage> createState() => _DashboardNextPageState();
}

class _DashboardNextPageState extends State<DashboardNextPage> {
  ClinicSettings? _clinicSettings;
  bool _isLoadingSettings = true;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _loadClinicSettings();
  }

  Future<void> _loadClinicSettings() async {
    if (widget.clinicSettings != null) {
      setState(() {
        _clinicSettings = widget.clinicSettings;
        _isLoadingSettings = false;
      });
      return;
    }

    try {
      final authRepository = Get.find<AuthRepository>();
      final settings = await authRepository
          .getClinicSettingsByClinicId(widget.clinic.documentId ?? '');
      setState(() {
        _clinicSettings = settings;
        _isLoadingSettings = false;
      });
    } catch (e) {
      print("Error loading clinic settings: $e");
      setState(() {
        _isLoadingSettings = false;
      });
    }
  }

  Widget _buildStatusCard() {
    if (_isLoadingSettings || _clinicSettings == null) {
      return const SizedBox.shrink();
    }

    final isOpen = _clinicSettings!.isOpen;
    final isOpenNow = _clinicSettings!.isOpenNow();
    final todayHours = _clinicSettings!.getTodayHours();

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!isOpen) {
      statusColor = Colors.red;
      statusText = "Currently Closed";
      statusIcon = Icons.cancel;
    } else if (!isOpenNow) {
      statusColor = Colors.orange;
      statusText = "Closed Now";
      statusIcon = Icons.schedule;
    } else {
      statusColor = Colors.green;
      statusText = "Open Today";
      statusIcon = Icons.check_circle;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                if (isOpen) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Hours: $todayHours",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGallerySection() {
    List<String> galleryImages = [];

    if (_clinicSettings != null && _clinicSettings!.gallery.isNotEmpty) {
      galleryImages = _clinicSettings!.gallery;
    } else if (widget.clinic.image.isNotEmpty) {
      galleryImages = [widget.clinic.image];
    }

    if (galleryImages.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20, top: 20, bottom: 12),
          child: Text(
            "Gallery",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: galleryImages.length + 1, // +1 for "Show all" tile
            itemBuilder: (context, index) {
              // Show "Show all pictures" tile at the end
              if (index == galleryImages.length) {
                return GestureDetector(
                  onTap: () => _showAllPicturesDialog(galleryImages),
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 32,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Show all pictures",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return GestureDetector(
                onTap: () => _showImageDialog(galleryImages, index),
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      galleryImages[index],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAllPicturesDialog(List<String> images) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text(
                        'All Pictures',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Grid of images
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          _showImageDialog(images, index);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            images[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported),
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
      },
    );
  }

  void _showImageDialog(List<String> images, int initialIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Stack(
            children: [
              Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.9,
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: PageView.builder(
                    itemCount: images.length,
                    controller: PageController(initialPage: initialIndex),
                    itemBuilder: (context, index) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          images[index],
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.error, size: 50),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 20,
                right: 20,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContactInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildInfoRow(
              Icons.location_on_outlined, 'Address', widget.clinic.address),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.phone_outlined, 'Contact', widget.clinic.contact),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.email_outlined, 'Email', widget.clinic.email),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isNotEmpty ? value : 'Not provided',
                style: TextStyle(
                  fontSize: 14,
                  color:
                      value.isNotEmpty ? Colors.black87 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServicesSection() {
    List<String> services = [];

    if (_clinicSettings != null && _clinicSettings!.services.isNotEmpty) {
      services = _clinicSettings!.services;
    } else if (widget.clinic.services.isNotEmpty) {
      services = widget.clinic.services
          .split(RegExp(r'[,;|\n]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    if (services.isEmpty) {
      services = [
        'General Consultation',
        'Vaccination',
        'Surgery',
        'Emergency Care'
      ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20, top: 20, bottom: 12),
          child: Text(
            "Services Offered",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                services.map((service) => _buildServiceChip(service)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceChip(String service) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: Colors.grey.shade700,
          ),
          const SizedBox(width: 6),
          Text(
            service,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsSection() {
    const double averageRating = 4.8;
    const int totalReviews = 124;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20, top: 20, bottom: 12),
          child: Text(
            "Ratings & Reviews",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    averageRating.toString(),
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < averageRating.floor()
                            ? Icons.star
                            : index < averageRating
                                ? Icons.star_half
                                : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$totalReviews reviews',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ClinicReviewsPage(
                    clinic: widget.clinic,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Show all $totalReviews reviews",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 18),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOperatingHours() {
    if (_clinicSettings == null) return const SizedBox.shrink();

    final operatingHours = _clinicSettings!.operatingHours;
    final days = [
      'monday',
      'tuesday',
      'wednesday',
      'thursday',
      'friday',
      'saturday',
      'sunday'
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20, top: 20, bottom: 12),
          child: Text(
            "Operating Hours",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: days.map((day) {
              final dayData = operatingHours[day];
              final isOpen = dayData?['isOpen'] ?? false;
              final openTime = dayData?['openTime'] ?? '';
              final closeTime = dayData?['closeTime'] ?? '';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text(
                        day[0].toUpperCase() + day.substring(1),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                    Text(
                      isOpen ? '$openTime - $closeTime' : 'Closed',
                      style: TextStyle(
                        fontSize: 14,
                        color: isOpen ? Colors.black87 : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyContact() {
    if (_clinicSettings == null || _clinicSettings!.emergencyContact.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.emergency, color: Colors.red[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Emergency Contact',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _clinicSettings!.emergencyContact,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.red[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialInstructions() {
    if (_clinicSettings == null ||
        _clinicSettings!.specialInstructions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Special Instructions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _clinicSettings!.specialInstructions,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    if (widget.clinic.description.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20, top: 20, bottom: 12),
          child: Text(
            "About",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            widget.clinic.description,
            style: const TextStyle(
              fontSize: 15,
              height: 1.5,
            ),
            textAlign: TextAlign.justify,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 20, top: 20, bottom: 12),
          child: Text(
            "Location",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
          ),
        ),
        // Address and action buttons
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on,
                    color: Colors.red.shade600,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.clinic.address,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Full address of ${widget.clinic.clinicName}",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _openDirections,
                      icon: const Icon(Icons.directions, size: 18),
                      label: const Text("Get Directions"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _callClinic,
                      icon: const Icon(Icons.phone, size: 18),
                      label: const Text("Call"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue.shade600,
                        side: BorderSide(color: Colors.blue.shade600),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Map container
        Container(
          width: double.infinity,
          height: 300,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [ClinicPageMaps(clinic: widget.clinic)],
            ),
          ),
        ),
      ],
    );
  }

  void _openDirections() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Get Directions"),
          content: Text("Opening directions to ${widget.clinic.clinicName}..."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _callClinic() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Call Clinic"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Call ${widget.clinic.clinicName}?"),
              const SizedBox(height: 8),
              Text(
                widget.clinic.contact,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Implement actual calling functionality
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 81, 115, 153),
              ),
              child: const Text(
                "Call",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getImageUrl() {
    if (_clinicSettings != null && _clinicSettings!.gallery.isNotEmpty) {
      return _clinicSettings!.gallery.first;
    }
    return widget.clinic.image;
  }

  bool _canMakeAppointment() {
    if (_clinicSettings == null) return true;
    return _clinicSettings!.isOpen;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _getImageUrl();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: Colors.white,
            leading: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                iconSize: 24,
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade300,
                          child:
                              const Icon(Icons.image_not_supported, size: 50),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.business, size: 50),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.clinic.clinicName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.clinic.address,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusCard(),
                _buildContactInfo(),
                _buildGallerySection(),
                _buildServicesSection(),
                _buildOperatingHours(),
                _buildEmergencyContact(),
                _buildSpecialInstructions(),
                _buildRatingsSection(),
                _buildDescription(),
                _buildLocationSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Save Button
              InkWell(
                customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                onTap: () {
                  setState(() {
                    _isSaved = !_isSaved;
                  });
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isSaved
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: _isSaved ? Colors.red : Colors.black,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isSaved ? "Saved" : "Save",
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Book Appointment Button
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: _canMakeAppointment()
                        ? const Color.fromARGB(255, 81, 115, 153)
                        : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _canMakeAppointment()
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ScheduleAppointment(
                                clinic: widget.clinic,
                                clinicSettings: _clinicSettings,
                              ),
                            ),
                          );
                        }
                      : null,
                  child: Text(
                    _canMakeAppointment()
                        ? "Book Appointment"
                        : "Clinic Closed",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Message Button
              InkWell(
                customBorder: const CircleBorder(),
                onTap: () async {
                  await _startConversationWithClinic(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 81, 115, 153),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.message_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startConversationWithClinic(BuildContext context) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const Center(
          child: CircularProgressIndicator(
            color: Color.fromARGB(255, 81, 115, 153),
          ),
        ),
      );

      final MessagingController messagingController =
          Get.find<MessagingController>();
      final UserSessionService userSession = Get.find<UserSessionService>();

      if (userSession.userId.isEmpty) {
        Navigator.pop(context);
        _showLoginRequiredDialog(context);
        return;
      }

      final conversation = await messagingController
          .startConversationWithClinic(widget.clinic.documentId!);

      Navigator.pop(context);

      if (conversation != null && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagesNextPage(
              conversation: conversation,
              receiverId: widget.clinic.documentId!,
              receiverType: 'clinic',
              receiverName: widget.clinic.clinicName,
              receiverImage: widget.clinic.image,
            ),
          ),
        );
      } else {
        if (context.mounted) {
          _showErrorDialog(
              context, 'Failed to start conversation. Please try again.');
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
        content: const Text(
            'Please log in to start a conversation with this clinic.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 81, 115, 153),
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
}
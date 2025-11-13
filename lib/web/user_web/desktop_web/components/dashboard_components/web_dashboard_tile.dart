import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/models/ratings_and_review_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/web/user_web/responsive_page_handlers/web_clinic_page_handler.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebDashboardTile extends StatefulWidget {
  final Clinic clinic;
  final double tileWidth;
  final double tileHeight;

  const WebDashboardTile({
    super.key,
    required this.clinic,
    required this.tileWidth,
    double? tileHeight,
  }) : tileHeight = tileHeight ?? tileWidth * 1.4;

  @override
  State<WebDashboardTile> createState() => _WebDashboardTileState();
}

class _WebDashboardTileState extends State<WebDashboardTile> {
  bool _isLiked = false;
  ClinicSettings? _clinicSettings;
  ClinicRatingStats? _ratingStats;
  bool _isLoadingSettings = true;
  bool _isLoadingRating = true;

  @override
  void initState() {
    super.initState();


    _loadClinicSettings();
    _loadRatingStats();
  }

  Future<void> _loadClinicSettings() async {
    try {
      final clinicDocId = widget.clinic.documentId ?? '';

      if (clinicDocId.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoadingSettings = false;
          });
        }
        return;
      }


      final authRepository = Get.find<AuthRepository>();
      final settings =
          await authRepository.getClinicSettingsByClinicId(clinicDocId);

      if (mounted) {
        setState(() {
          _clinicSettings = settings;
          _isLoadingSettings = false;
        });

        if (settings != null) {
        } else {
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSettings = false;
        });
      }
    }
  }

  Future<void> _loadRatingStats() async {
    try {
      final clinicDocId = widget.clinic.documentId ?? '';

      if (clinicDocId.isEmpty) {
        if (mounted) {
          setState(() {
            _isLoadingRating = false;
          });
        }
        return;
      }


      final authRepository = Get.find<AuthRepository>();
      final stats = await authRepository.getClinicRatingStats(clinicDocId);

      if (mounted) {
        setState(() {
          _ratingStats = stats;
          _isLoadingRating = false;
        });

      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingRating = false;
        });
      }
    }
  }

  // Helper method to extract services for display
  List<String> _getServicesList() {
    // First try clinic settings, then fall back to clinic.services
    List<String> services = [];

    if (_clinicSettings != null && _clinicSettings!.services.isNotEmpty) {
      services = _clinicSettings!.services.take(3).toList();
    } else if (widget.clinic.services.isNotEmpty) {
      services = widget.clinic.services
          .split(RegExp(r'[,;|\n]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .take(3)
          .toList();
    }

    return services;
  }

  // Helper method to get service icons
  IconData _getServiceIcon(String service) {
    String serviceLower = service.toLowerCase();
    if (serviceLower.contains('vaccination') ||
        serviceLower.contains('vaccine')) {
      return Icons.vaccines_outlined;
    } else if (serviceLower.contains('surgery') ||
        serviceLower.contains('operation')) {
      return Icons.local_hospital_outlined;
    } else if (serviceLower.contains('checkup') ||
        serviceLower.contains('examination')) {
      return Icons.health_and_safety_outlined;
    } else if (serviceLower.contains('grooming')) {
      return Icons.pets_outlined;
    } else if (serviceLower.contains('dental')) {
      return Icons.medication_outlined;
    } else {
      return Icons.medical_services_outlined;
    }
  }

  Widget _buildStatusBadge() {
    if (_isLoadingSettings) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(strokeWidth: 1),
        ),
      );
    }

    // CRITICAL: Check if today is a closed date FIRST
    final isTodayClosedDate = _isTodayClosedDate();

    final isOpen = _clinicSettings?.isOpen ?? true;
    final isOpenNow = _clinicSettings?.isOpenNow() ?? true;

    Color statusColor;
    String statusText;

    // CRITICAL: Prioritize closed date status
    if (isTodayClosedDate) {
      statusColor = Colors.red;
      statusText = "CLOSED TODAY";
    } else if (!isOpen) {
      statusColor = Colors.red;
      statusText = "CLOSED";
    } else if (!isOpenNow) {
      statusColor = Colors.orange;
      statusText = "CLOSED NOW";
    } else {
      statusColor = Colors.green;
      statusText = "OPEN";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        statusText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildRatingDisplay() {
    if (_isLoadingRating) {
      return const Row(
        children: [
          Icon(Icons.star, color: Colors.amber, size: 18),
          SizedBox(width: 3),
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5),
          ),
        ],
      );
    }

    final rating = _ratingStats?.averageRating ?? 0.0;
    final reviewCount = _ratingStats?.totalReviews ?? 0;

    if (reviewCount == 0) {
      return const Row(
        children: [
          Icon(Icons.star_border, color: Colors.grey, size: 18),
          SizedBox(width: 3),
          Text(
            "No reviews",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        const Icon(Icons.star, color: Colors.amber, size: 18),
        const SizedBox(width: 3),
        Text(
          rating.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          " ($reviewCount)",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildHoursDisplay() {
    if (_isLoadingSettings || _clinicSettings == null) {
      return const SizedBox.shrink();
    }

    // CRITICAL: Check if today is a closed date
    final isTodayClosedDate = _isTodayClosedDate();

    if (isTodayClosedDate) {
      return Text(
        'Closed Today',
        style: TextStyle(
          color: Colors.red[600],
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      );
    }

    // Get today's hours in 24-hour format
    final today = DateTime.now().weekday;
    final dayName = _getDayName(today);
    final daySchedule = _clinicSettings!.operatingHours[dayName];

    if (daySchedule?['isOpen'] != true) {
      return Text(
        'Closed',
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      );
    }

    final openTime = daySchedule?['openTime'] ?? '';
    final closeTime = daySchedule?['closeTime'] ?? '';

    // Convert to 12-hour format
    final openTime12 = _formatTimeTo12Hour(openTime);
    final closeTime12 = _formatTimeTo12Hour(closeTime);

    return Text(
      '$openTime12 - $closeTime12',
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 11,
        fontWeight: FontWeight.w500,
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

  String _formatTimeTo12Hour(String time24) {
    if (time24.isEmpty) return '';

    try {
      final parts = time24.split(':');
      if (parts.length != 2) return time24;

      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);

      return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    } catch (e) {
      return time24;
    }
  }

  String _getProfileImage() {

    // Priority 1: Use dashboardPic from clinic model (already set from settings)
    if (widget.clinic.dashboardPic != null &&
        widget.clinic.dashboardPic!.isNotEmpty) {
      return widget.clinic.dashboardPic!;
    }

    // Priority 2: Use dashboardPic from settings
    if (_clinicSettings != null && _clinicSettings!.dashboardPic.isNotEmpty) {
      return _clinicSettings!.dashboardPic;
    }

    // Priority 3: Use first gallery image from settings
    if (_clinicSettings != null && _clinicSettings!.gallery.isNotEmpty) {
      return _clinicSettings!.gallery.first;
    }

    // Priority 4: Use clinic.image as fallback
    if (widget.clinic.image.isNotEmpty) {
      return widget.clinic.image;
    }

    return '';
  }

  @override
  Widget build(BuildContext context) {
    final services = _getServicesList();
    final profileImage = _getProfileImage();


    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        hoverColor: const Color(0x00000000),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  WebClinicPageHandlerUpdated(clinic: widget.clinic),
            ),
          );
        },
        child: SizedBox(
          width: widget.tileWidth,
          height: widget.tileHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: widget.tileHeight * 0.7,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: profileImage.isNotEmpty
                          ? Image.network(
                              profileImage,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              key: ValueKey(
                                  '${widget.clinic.documentId}_image'), // CRITICAL: Unique key for image
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'lib/images/placeholder.png',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                );
                              },
                            )
                          : Image.asset(
                              'lib/images/placeholder.png',
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                    ),
                  ),
                  // Status badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _buildStatusBadge(),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        widget.clinic.clinicName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _buildRatingDisplay(),
                  ],
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.clinic.address,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              // Hours display
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Expanded(child: _buildHoursDisplay()),
                ],
              ),
              // Services display
              if (services.isNotEmpty)
                Row(
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Text(
                        "Services",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: services.take(2).map((service) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Tooltip(
                              message: service,
                              child: Icon(
                                _getServiceIcon(service),
                                size: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isTodayClosedDate() {
    if (_clinicSettings == null) return false;

    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    return _clinicSettings!.closedDates.contains(todayStr);
  }
}

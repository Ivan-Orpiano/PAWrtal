import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
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
  bool _isLoadingSettings = true;

  @override
  void initState() {
    super.initState();
    _loadClinicSettings();
  }

  Future<void> _loadClinicSettings() async {
    try {
      final authRepository = Get.find<AuthRepository>();
      final settings = await authRepository
          .getClinicSettingsByClinicId(widget.clinic.documentId ?? '');
      setState(() {
        _clinicSettings = settings;
        _isLoadingSettings = false;
      });
    } catch (e) {
      print("Error loading clinic settings for tile: $e");
      setState(() {
        _isLoadingSettings = false;
      });
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

    final isOpen = _clinicSettings?.isOpen ?? true;
    final isOpenToday = _clinicSettings?.isOpenToday() ?? true;

    Color statusColor;
    String statusText;

    if (!isOpen) {
      statusColor = Colors.red;
      statusText = "CLOSED";
    } else if (!isOpenToday) {
      statusColor = Colors.orange;
      statusText = "CLOSED TODAY";
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

  Widget _buildHoursDisplay() {
    if (_isLoadingSettings || _clinicSettings == null) {
      return const SizedBox.shrink();
    }

    final todayHours = _clinicSettings!.getTodayHours();

    return Text(
      todayHours,
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  String _getProfileImage() {
    // Use first gallery image from settings, then fallback to clinic.image
    if (_clinicSettings != null && _clinicSettings!.gallery.isNotEmpty) {
      return _clinicSettings!.gallery.first;
    }
    return widget.clinic.image;
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
                  // Like button
                  Positioned(
                    top: 10,
                    right: 10,
                    child: IconButton(
                      icon: _isLiked
                          ? const Icon(
                              Icons.favorite_rounded,
                              color: Colors.red,
                            )
                          : const Icon(
                              Icons.favorite_border_rounded,
                              color: Colors.white,
                            ),
                      onPressed: () {
                        setState(() {
                          _isLiked = !_isLiked;
                        });
                      },
                    ),
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
                    const Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: Colors.amber,
                          size: 18,
                        ),
                        Text(
                          "4.95", // You can add rating to your clinic model later
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
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
}

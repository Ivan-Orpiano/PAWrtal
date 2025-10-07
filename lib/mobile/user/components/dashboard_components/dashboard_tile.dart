import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/mobile/user/pages/dashboard_next_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MyDashboardTile extends StatelessWidget {
  final Clinic clinic;
  final ClinicSettings? clinicSettings;

  const MyDashboardTile({
    super.key, 
    required this.clinic,
    this.clinicSettings,
  });

  Widget _buildStatusBadge() {
    final isOpen = clinicSettings?.isOpen ?? true;
    final isOpenNow = clinicSettings?.isOpenNow() ?? true;
    
    Color statusColor;
    String statusText;
    
    if (!isOpen) {
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildHoursDisplay() {
    if (clinicSettings == null) {
      return const SizedBox.shrink();
    }

    final todayHours = clinicSettings!.getTodayHours();
    
    return Row(
      children: [
        Icon(
          Icons.access_time,
          size: 14,
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            todayHours,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  List<String> _getServicesList() {
    List<String> services = [];
    
    if (clinicSettings != null && clinicSettings!.services.isNotEmpty) {
      services = clinicSettings!.services.take(2).toList();
    } else if (clinic.services.isNotEmpty) {
      services = clinic.services
          .split(RegExp(r'[,;|\n]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .take(2)
          .toList();
    }
    
    return services;
  }

  IconData _getServiceIcon(String service) {
    String serviceLower = service.toLowerCase();
    if (serviceLower.contains('vaccination') || serviceLower.contains('vaccine')) {
      return Icons.vaccines_outlined;
    } else if (serviceLower.contains('surgery') || serviceLower.contains('operation')) {
      return Icons.local_hospital_outlined;
    } else if (serviceLower.contains('checkup') || serviceLower.contains('examination')) {
      return Icons.health_and_safety_outlined;
    } else if (serviceLower.contains('grooming')) {
      return Icons.pets_outlined;
    } else if (serviceLower.contains('dental')) {
      return Icons.medication_outlined;
    } else if (serviceLower.contains('emergency')) {
      return Icons.emergency_outlined;
    } else {
      return Icons.medical_services_outlined;
    }
  }

  String _getImageUrl() {
    if (clinicSettings != null && clinicSettings!.gallery.isNotEmpty) {
      return clinicSettings!.gallery.first;
    }
    return clinic.image;
  }

  @override
  Widget build(BuildContext context) {
    final services = _getServicesList();
    final imageUrl = _getImageUrl();
    
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardNextPage(
              clinic: clinic,
              clinicSettings: clinicSettings,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade300,
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with status badge
            Stack(
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
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
                Positioned(
                  top: 10,
                  left: 10,
                  child: _buildStatusBadge(),
                ),
              ],
            ),

            // Clinic info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Clinic name and rating row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          clinic.clinicName,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: const Color.fromARGB(255, 81, 115, 153),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Row(
                        children: [
                          Icon(Icons.star, color: Colors.amber, size: 16),
                          SizedBox(width: 3),
                          Text(
                            "5.0",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // Address
                  Text(
                    clinic.address,
                    style: GoogleFonts.dmSans(
                      fontStyle: FontStyle.italic,
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 10),

                  // Hours
                  _buildHoursDisplay(),

                  const SizedBox(height: 10),

                  // Services
                  if (services.isNotEmpty)
                    Row(
                      children: [
                        const Text(
                          "Services: ",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: services.map((service) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
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
          ],
        ),
      ),
    );
  }
}
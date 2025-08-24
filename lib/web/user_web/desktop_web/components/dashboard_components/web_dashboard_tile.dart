import 'package:capstone_app/web/user_web/desktop_web/pages/web_clinic_page.dart';
import 'package:capstone_app/web/user_web/responsive_page_handlers/web_clinic_page_handler.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:flutter/material.dart';

class WebDashboardTileUpdated extends StatefulWidget {
  final Clinic clinic;
  final double tileWidth;
  final double tileHeight;

  const WebDashboardTileUpdated({
    super.key,
    required this.clinic,
    required this.tileWidth, 
    double? tileHeight,
  }) : tileHeight = tileHeight ?? tileWidth * 1.4;

  @override
  State<WebDashboardTileUpdated> createState() => _WebDashboardTileUpdatedState();
}

class _WebDashboardTileUpdatedState extends State<WebDashboardTileUpdated> {
  bool _isLiked = false;

  // Helper method to extract services for display
  List<String> _getServicesList() {
    if (widget.clinic.services.isEmpty) return [];
    
    // Split services by common delimiters and take first few
    List<String> services = widget.clinic.services
        .split(RegExp(r'[,;|\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .take(3)
        .toList();
    
    return services;
  }

  // Helper method to get service icons
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
    } else {
      return Icons.medical_services_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = _getServicesList();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 30),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        hoverColor: const Color(0x00000000),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => WebClinicPageHandlerUpdated(clinic: widget.clinic),
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
                      child: widget.clinic.image.isNotEmpty
                          ? Image.network(
                              widget.clinic.image,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'lib/images/test_image.jpg',
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                );
                              },
                            )
                          : Image.asset(
                              'lib/images/test_image.jpg',
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                    ),
                  ),
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
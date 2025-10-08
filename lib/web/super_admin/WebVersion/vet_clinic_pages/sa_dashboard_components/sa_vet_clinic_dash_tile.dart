import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/utils/image_helper.dart';
import 'package:flutter/material.dart';

class SuperAdminVetClinicTile extends StatelessWidget {
  final Clinic clinic;
  final ClinicSettings? settings;
  final bool isMobile;
  final bool isTablet;

  const SuperAdminVetClinicTile({
    super.key,
    required this.clinic,
    this.settings,
    this.isMobile = false,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = settings?.isOpenNow() ?? false;
    final screenWidth = MediaQuery.of(context).size.width;

    // Responsive sizing
    final cardHeight = isMobile
        ? 380.0
        : isTablet
            ? 340.0
            : 320.0;
    final imageFlexValue = isMobile ? 4 : 3;
    final contentFlexValue = isMobile ? 3 : 2;

    return Card(
      elevation: 4,
      shadowColor: const Color.fromRGBO(81, 115, 153, 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        height: cardHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              const Color(0xFFF8FAFC),
            ],
          ),
          border: Border.all(
            color: const Color.fromRGBO(81, 115, 153, 0.15),
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section with status badge overlay
            Expanded(
              flex: imageFlexValue,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      color: Colors.grey[200],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      child: clinic.image.isNotEmpty
                          ? Image.network(
                              getPetImageUrl(clinic.image),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholder();
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    color:
                                        const Color.fromRGBO(81, 115, 153, 1),
                                    value: loadingProgress.expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                            )
                          : _buildPlaceholder(),
                    ),
                  ),
                  // Enhanced status badge overlay
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 14 : 12,
                        vertical: isMobile ? 8 : 7,
                      ),
                      decoration: BoxDecoration(
                        color: isOpen
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: (isOpen ? Colors.green : Colors.red)
                                .withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: isMobile ? 8 : 7,
                            height: isMobile ? 8 : 7,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white.withOpacity(0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: isMobile ? 6 : 5),
                          Text(
                            isOpen ? 'OPEN' : 'CLOSED',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Gradient overlay for better text visibility
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.4),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Info section - Enhanced with better spacing
            Expanded(
              flex: contentFlexValue,
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 16.0 : 14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Clinic name
                    Text(
                      clinic.clinicName,
                      style: TextStyle(
                        fontSize: isMobile
                            ? 18
                            : isTablet
                                ? 17
                                : 16,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromRGBO(81, 115, 153, 1),
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isMobile ? 6 : 4),

                    // Address
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: isMobile ? 16 : 14,
                          color: const Color.fromRGBO(81, 115, 153, 0.7),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            clinic.address,
                            style: TextStyle(
                              fontSize: isMobile ? 13 : 12,
                              color: Colors.grey[700],
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: isMobile ? 8 : 6),

                    // Contact
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(81, 115, 153, 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.phone_rounded,
                            size: isMobile ? 14 : 12,
                            color: const Color.fromRGBO(81, 115, 153, 1),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            clinic.contact,
                            style: TextStyle(
                              fontSize: isMobile ? 13 : 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets_rounded,
            size: isMobile ? 56 : 48,
            color: const Color.fromRGBO(81, 115, 153, 0.3),
          ),
          SizedBox(height: isMobile ? 12 : 8),
          Text(
            'No Image',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: isMobile ? 14 : 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

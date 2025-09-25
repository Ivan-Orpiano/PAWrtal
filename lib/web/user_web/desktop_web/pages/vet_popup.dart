import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/web/user_web/responsive_page_handlers/web_clinic_page_handler.dart';
import 'package:flutter/material.dart';
import 'dart:ui';

class VetPopup extends StatelessWidget {
  final Clinic clinic;
  final ClinicSettings? clinicSettings;

  const VetPopup({
    super.key,
    required this.clinic,
    this.clinicSettings,
  });

  Color getStatusColor() {
    if (clinicSettings == null) return Colors.grey;

    final isOpen = clinicSettings!.isOpen;
    final isOpenToday = clinicSettings!.isOpenToday();

    if (!isOpen) {
      return Colors.red;
    } else if (!isOpenToday) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  String getStatusText() {
    if (clinicSettings == null) return "Unknown";

    final isOpen = clinicSettings!.isOpen;
    final isOpenToday = clinicSettings!.isOpenToday();

    if (!isOpen) {
      return "CLOSED";
    } else if (!isOpenToday) {
      return "CLOSED TODAY";
    } else {
      return "OPEN";
    }
  }

  String getTodayHours() {
    if (clinicSettings == null) return "Hours not available";
    return clinicSettings!.getTodayHours();
  }

  List<String> getServices() {
    if (clinicSettings != null && clinicSettings!.services.isNotEmpty) {
      return clinicSettings!.services.take(3).toList();
    }

    // Fallback to clinic.services
    return clinic.services
        .split(RegExp(r'[,;|\n]'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .take(3)
        .toList();
  }

  IconData getServiceIcon(String service) {
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

  String getClinicImage() {
    // Use first gallery image from settings if available, otherwise fallback to clinic.image
    if (clinicSettings != null && clinicSettings!.gallery.isNotEmpty) {
      return clinicSettings!.gallery.first;
    }
    return clinic.image.isNotEmpty ? clinic.image : '';
  }

  @override
  Widget build(BuildContext context) {
    final services = getServices();
    final clinicImage = getClinicImage();

    return Container(
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        width: 280,
        child: Card(
          color: const Color.fromARGB(255, 39, 86, 139),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
            side: const BorderSide(color: Colors.white, width: 2),
          ),
          elevation: 8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image Section
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
                child: SizedBox(
                  width: 280,
                  height: 160,
                  child: Stack(
                    children: [
                      // Clinic Image
                      clinicImage.isNotEmpty
                          ? Image.network(
                              clinicImage,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: double.infinity,
                                  height: double.infinity,
                                  color: Colors.grey[300],
                                  child: const Icon(
                                    Icons.local_hospital,
                                    size: 60,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            )
                          : Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.local_hospital,
                                size: 60,
                                color: Colors.grey,
                              ),
                            ),
                      // Status Badge Overlay
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: getStatusColor(),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            getStatusText(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Content Section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Clinic Name
                          Text(
                            clinic.clinicName,
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(255, 39, 86, 139),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Address with icon
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  clinic.address,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Hours with icon
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  getTodayHours(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Services
                          if (services.isNotEmpty) ...[
                            const Text(
                              "Services:",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color.fromARGB(255, 39, 86, 139),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: services.map((service) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        const Color.fromARGB(255, 39, 86, 139)
                                            .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        getServiceIcon(service),
                                        size: 12,
                                        color: const Color.fromARGB(
                                            255, 39, 86, 139),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        service,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color:
                                              Color.fromARGB(255, 39, 86, 139),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Contact Info
                          if (clinic.contact.isNotEmpty) ...[
                            Row(
                              children: [
                                const Icon(
                                  Icons.phone,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    clinic.contact,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Action Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        WebClinicPageHandlerUpdated(
                                            clinic: clinic),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 39, 86, 139),
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: const Text(
                                "View Details",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

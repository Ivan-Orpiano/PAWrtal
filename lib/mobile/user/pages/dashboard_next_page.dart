import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/mobile/user/pages/schedule_appointment.dart';
import 'package:flutter/material.dart';

class DashboardNextPage extends StatelessWidget {
  final Clinic clinic;
  final ClinicSettings? clinicSettings;

  const DashboardNextPage({
    super.key, 
    required this.clinic,
    this.clinicSettings,
  });

  Widget _buildStatusCard() {
    if (clinicSettings == null) return const SizedBox.shrink();

    final isOpen = clinicSettings!.isOpen;
    final isOpenToday = clinicSettings!.isOpenToday();
    final todayHours = clinicSettings!.getTodayHours();

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (!isOpen) {
      statusColor = Colors.red;
      statusText = "Currently Closed";
      statusIcon = Icons.cancel;
    } else if (!isOpenToday) {
      statusColor = Colors.orange;
      statusText = "Closed Today";
      statusIcon = Icons.schedule;
    } else {
      statusColor = Colors.green;
      statusText = "Open Today";
      statusIcon = Icons.check_circle;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 16),
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
    
    if (clinicSettings != null && clinicSettings!.gallery.isNotEmpty) {
      galleryImages = clinicSettings!.gallery;
    } else if (clinic.image.isNotEmpty) {
      galleryImages = [clinic.image];
    }

    if (galleryImages.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 25, top: 25, bottom: 15),
          child: Text(
            "Gallery",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 25),
            itemCount: galleryImages.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showImageDialog(context, galleryImages, index),
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
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
                          child: const Icon(Icons.error),
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

  void _showImageDialog(BuildContext context, List<String> images, int initialIndex) {
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

  Widget _buildServicesSection() {
    List<String> services = [];
    
    if (clinicSettings != null && clinicSettings!.services.isNotEmpty) {
      services = clinicSettings!.services;
    } else if (clinic.services.isNotEmpty) {
      services = clinic.services
          .split(RegExp(r'[,;|\n]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }

    if (services.isEmpty) {
      services = ['General Consultation', 'Vaccination', 'Check-up', 'Grooming'];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 25, top: 25, bottom: 15),
          child: Text(
            "Services Offered",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: services.map((service) => _buildServiceChip(service)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildServiceChip(String service) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getServiceIcon(service),
            size: 16,
            color: const Color.fromARGB(255, 81, 115, 153),
          ),
          const SizedBox(width: 6),
          Text(
            service,
            style: const TextStyle(
              fontSize: 14,
              color: Color.fromARGB(255, 81, 115, 153),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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

  Widget _buildRatingsSection() {
    // Mock data for now - you can replace this with real data later
    const double averageRating = 4.8;
    const int totalReviews = 124;
    
    final reviews = [
      {'name': 'Sarah Johnson', 'rating': 5, 'comment': 'Excellent care for my dog! Very professional staff.'},
      {'name': 'Mike Chen', 'rating': 4, 'comment': 'Good service, clean facilities. Highly recommend.'},
      {'name': 'Lisa Garcia', 'rating': 5, 'comment': 'Dr. Smith was wonderful with my cat. Thank you!'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 25, top: 25, bottom: 15),
          child: Text(
            "Ratings & Reviews",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
        
        // Rating summary
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
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
                      fontSize: 32,
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

        // Recent reviews
        ...reviews.map((review) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                    child: Text(
                      review['name'].toString()[0],
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review['name'].toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Row(
                          children: List.generate(5, (index) {
                            return Icon(
                              index < (review['rating'] as int) 
                                ? Icons.star 
                                : Icons.star_border,
                              color: Colors.amber,
                              size: 14,
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                review['comment'].toString(),
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        )),

        // View all reviews button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
          child: TextButton(
            onPressed: () {
              // Navigate to full reviews page
            },
            child: Text(
              'View all $totalReviews reviews',
              style: const TextStyle(
                color: Color.fromARGB(255, 81, 115, 153),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOperatingHours() {
    if (clinicSettings == null) return const SizedBox.shrink();

    final operatingHours = clinicSettings!.operatingHours;
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Operating Hours',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...days.map((day) {
            final dayData = operatingHours[day];
            final isOpen = dayData?['isOpen'] ?? false;
            final openTime = dayData?['openTime'] ?? '';
            final closeTime = dayData?['closeTime'] ?? '';
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
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
          }),
        ],
      ),
    );
  }

  Widget _buildEmergencyContact() {
    if (clinicSettings == null || clinicSettings!.emergencyContact.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
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
                  clinicSettings!.emergencyContact,
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
    if (clinicSettings == null || clinicSettings!.specialInstructions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 8),
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
                  clinicSettings!.specialInstructions,
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

  String _getImageUrl() {
    if (clinicSettings != null && clinicSettings!.gallery.isNotEmpty) {
      return clinicSettings!.gallery.first;
    }
    return clinic.image;
  }

  bool _canMakeAppointment() {
    if (clinicSettings == null) return true;
    return clinicSettings!.isOpen;
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _getImageUrl();
    
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 253, 255),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.transparent,
        toolbarHeight: 50,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.keyboard_arrow_left_rounded),
            iconSize: 30,
          ),
        ),
        title: const Text("3.2 KM"), // You can calculate distance later
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.favorite_border),
          )
        ],
      ),
      body: ListView(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // CLINIC IMAGE
              Padding(
                padding: const EdgeInsets.only(top: 15),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
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
              const SizedBox(height: 30),

              // CLINIC NAME
              Padding(
                padding: const EdgeInsets.only(left: 25),
                child: Text(
                  clinic.clinicName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 28,
                    color: Color.fromARGB(255, 81, 115, 153),
                  ),
                ),
              ),

              // CLINIC ADDRESS
              Padding(
                padding: const EdgeInsets.only(left: 25),
                child: Text(
                  clinic.address,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),

              // STATUS CARD
              _buildStatusCard(),

              // GALLERY SECTION
              _buildGallerySection(),

              // SERVICES SECTION
              _buildServicesSection(),

              // RATINGS SECTION
              _buildRatingsSection(),

              // OPERATING HOURS
              _buildOperatingHours(),

              // EMERGENCY CONTACT
              _buildEmergencyContact(),

              // SPECIAL INSTRUCTIONS
              _buildSpecialInstructions(),

              const SizedBox(height: 25),

              // DESCRIPTION TITLE
              const Padding(
                padding: EdgeInsets.only(left: 25),
                child: Text(
                  "Description",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),

              // CLINIC DESCRIPTION
              Padding(
                padding: const EdgeInsets.only(left: 25, right: 25),
                child: Text(
                  clinic.description.isNotEmpty
                      ? clinic.description
                      : "No description provided.",
                  style: const TextStyle(fontSize: 14),
                ),
              ),

              const SizedBox(height: 25),

              // LOCATION TITLE
              const Padding(
                padding: EdgeInsets.only(left: 25),
                child: Text(
                  "Location",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),

              const SizedBox(height: 100), // Space for bottom button
            ],
          ),
        ],
      ),

      // BOTTOM BUTTONS
      bottomNavigationBar: SizedBox(
        width: double.infinity,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 20, top: 20, bottom: 20, right: 10),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 75, vertical: 15),
                    backgroundColor: _canMakeAppointment() 
                        ? const Color.fromARGB(255, 81, 115, 153)
                        : Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: _canMakeAppointment() ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ScheduleAppointment(
                          clinic: clinic,
                          clinicSettings: clinicSettings,
                        ),
                      ),
                    );
                  } : null,
                  child: Text(
                    _canMakeAppointment() 
                        ? "Make an Appointment"
                        : "Clinic Closed",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 20, right: 10),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: () {
                  // Message functionality
                },
                child: const Icon(
                  Icons.message_rounded,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
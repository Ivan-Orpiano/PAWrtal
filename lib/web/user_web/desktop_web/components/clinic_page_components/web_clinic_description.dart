import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/mobile/user/controllers/user_messaging_controller.dart';
import 'package:capstone_app/web/pages/web_user_home/web_user_home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebClinicDescriptionUpdated extends StatefulWidget {
  final Clinic clinic;
  
  const WebClinicDescriptionUpdated({super.key, required this.clinic});

  @override
  State<WebClinicDescriptionUpdated> createState() => _WebClinicDescriptionUpdatedState();
}

class _WebClinicDescriptionUpdatedState extends State<WebClinicDescriptionUpdated> {
  bool _showFullDescription = false;
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
      final settings = await authRepository.getClinicSettingsByClinicId(widget.clinic.documentId ?? '');
      setState(() {
        _clinicSettings = settings;
        _isLoadingSettings = false;
      });
    } catch (e) {
      print("Error loading clinic settings for description: $e");
      setState(() {
        _isLoadingSettings = false;
      });
    }
  }

  String get _truncatedDescription {
    const int maxLength = 300;
    final description = widget.clinic.description;
    if (description.length <= maxLength) {
      return description;
    }
    return '${description.substring(0, maxLength)}...';
  }

  bool get _hasLongDescription {
    return widget.clinic.description.length > 300;
  }

  Widget _buildClinicStatus() {
    if (_isLoadingSettings) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text("Loading status..."),
          ],
        ),
      );
    }

    if (_clinicSettings == null) {
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
      margin: const EdgeInsets.only(bottom: 16),
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
          // Message button added here
          OutlinedButton.icon(
            onPressed: () => _startConversationWithClinic(context),
            icon: const Icon(Icons.message_rounded, size: 18),
            label: const Text('Message Clinic'),
            style: OutlinedButton.styleFrom(
              foregroundColor: statusColor,
              side: BorderSide(color: statusColor),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

Future<void> _startConversationWithClinic(BuildContext context) async {
  try {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF5173B8)),
      ),
    );

    final MessagingController messagingController = Get.find<MessagingController>();
    final UserSessionService userSession = Get.find<UserSessionService>();

    if (userSession.userId.isEmpty) {
      Navigator.pop(context);
      _showLoginRequiredDialog(context);
      return;
    }

    // Start or get existing conversation
    final conversation = await messagingController.startConversationWithClinic(
        widget.clinic.documentId!);

    Navigator.pop(context);

    if (conversation != null && context.mounted) {
      // Open the conversation - this will set it as current
      await messagingController.openConversation(
        conversation,
        widget.clinic.documentId!,
        'clinic',
      );
      
      // Navigate to messages page using the home controller
      final homeController = Get.isRegistered<WebUserHomeController>()
          ? Get.find<WebUserHomeController>()
          : Get.put(WebUserHomeController());
      
      homeController.onItemSelected(2); // Navigate to Messages tab
      
      // Close the clinic page
      Navigator.pop(context);
    } else {
      if (context.mounted) {
        _showErrorDialog(context, 'Failed to start conversation. Please try again.');
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
        content: const Text('Please log in to start a conversation with this clinic.'),
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
              backgroundColor: const Color(0xFF5173B8),
            ),
            child: const Text('Login', style: TextStyle(color: Colors.white)),
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

  Widget _buildOperatingHours() {
    if (_isLoadingSettings || _clinicSettings == null) {
      return const SizedBox.shrink();
    }

    final operatingHours = _clinicSettings!.operatingHours;
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
                      day.capitalize!,
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
    if (_isLoadingSettings || 
        _clinicSettings == null || 
        _clinicSettings!.emergencyContact.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
    if (_isLoadingSettings || 
        _clinicSettings == null || 
        _clinicSettings!.specialInstructions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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

  @override
  Widget build(BuildContext context) {
    String description = widget.clinic.description.isNotEmpty 
        ? widget.clinic.description 
        : "This veterinary clinic provides comprehensive pet care services. "
          "We are committed to ensuring the health and well-being of your pets "
          "through professional veterinary care and compassionate service.";

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Text(
                'About this veterinary clinic',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 22
                ),
              ),
            ],
          ),
        ),
        
        // Clinic status with message button
        _buildClinicStatus(),
        
        // Contact Information Section
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildInfoRow(Icons.location_on_outlined, 'Address', widget.clinic.address),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.phone_outlined, 'Contact', widget.clinic.contact),
              const SizedBox(height: 8),
              _buildInfoRow(Icons.email_outlined, 'Email', widget.clinic.email),
            ],
          ),
        ),

        // Operating Hours
        _buildOperatingHours(),

        // Emergency Contact
        _buildEmergencyContact(),

        // Special Instructions
        _buildSpecialInstructions(),

        // Description Section
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            _showFullDescription || !_hasLongDescription 
                ? description 
                : _truncatedDescription,
            textAlign: TextAlign.justify,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),
        
        if (_hasLongDescription)
          InkWell(
            onTap: () {
              setState(() {
                _showFullDescription = !_showFullDescription;
              });
            },
            child: Row(
              children: [
                Text(
                  _showFullDescription ? "Show less" : "Show more",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline
                  ),
                ),
                Icon(
                  _showFullDescription 
                      ? Icons.keyboard_arrow_up_rounded 
                      : Icons.keyboard_arrow_right_rounded,
                  size: 24,
                ),
              ],
            ),
          ),
      ],
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.isNotEmpty ? value : 'Not provided',
                style: TextStyle(
                  fontSize: 15,
                  color: value.isNotEmpty ? Colors.black87 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
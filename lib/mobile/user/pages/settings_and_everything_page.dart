import 'package:capstone_app/data/id_verification/widgets/verification_status_widget.dart';
import 'package:capstone_app/mobile/user/controllers/mobile_feedback_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';
import 'package:capstone_app/utils/logout_helper.dart';
import 'package:capstone_app/data/models/feedback_and_report_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/mobile/user/controllers/mobile_user_pfp_controller.dart';

class FAQItem {
  final String question;
  final String answer;
  bool isExpanded;

  FAQItem({
    required this.question,
    required this.answer,
    this.isExpanded = false,
  });
}

List<FAQItem> faqItems = [
  FAQItem(
    question: 'How do I book an appointment?',
    answer: '''To book an appointment:

1. Go to the Home page
2. Select your preferred clinic
3. Tap the "Book Appointment" button
4. Choose an available time slot
5. Fill in the appointment details
6. Submit your request

You'll receive a notification once the clinic confirms your appointment.''',
  ),
  FAQItem(
    question: 'How do I manage my pets?',
    answer: '''To manage your pets:

1. Go to the Pets section
2. Tap "Add Pet" to register a new pet
3. Fill in your pet's information
4. Save the profile

You can edit or delete pet profiles anytime from the Pets page.''',
  ),
  FAQItem(
    question: 'How do I view pet\'s health records?',
    answer: '''To view pet's health records:

1. Select your pet from the Pets page
2. Tap on "More" button (...)
3. Tap on "Medical Appointment History" or "Vaccination History"

Health records are updated by veterinarians after each visit.''',
  ),
  FAQItem(
    question: 'How do I contact a clinic?',
    answer: '''To contact a clinic:

1. Go to the clinic's profile page
2. Use the messaging feature to chat with them
3. Or call them directly using the provided contact number

Clinics typically respond within 24 hours.''',
  ),
];

class SettingsAndEverythingPage extends StatefulWidget {
  final int initialIndex;
  
  const SettingsAndEverythingPage({super.key, this.initialIndex = 0});

  @override
  State<SettingsAndEverythingPage> createState() => _SettingsAndEverythingPageState();
}

class _SettingsAndEverythingPageState extends State<SettingsAndEverythingPage> {
  int selectedIndex = 0;
  final GetStorage storage = GetStorage();
  late MobileFeedbackController feedbackController;
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  late MobileUserPfpController profilePictureController;

  static const List<String> menuItems = [
    'Profile',
    'Settings',
    'Help',
    'Send feedback',
  ];

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;

    feedbackController = Get.put(MobileFeedbackController(
      authRepository: Get.find<AuthRepository>(),
      session: Get.find<UserSessionService>(),
    ));

    profilePictureController = Get.put(
      MobileUserPfpController(authRepository: Get.find<AuthRepository>()),
      tag: 'mobile_user_profile_picture',
    );
    
    // Initialize with current profile picture if exists
    final profilePictureId = storage.read("userProfilePictureId") as String?;
    if (profilePictureId != null && profilePictureId.isNotEmpty) {
      profilePictureController.setCurrentProfilePicture(profilePictureId);
    }
  }
  

  @override
  void dispose() {
    subjectController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          menuItems[selectedIndex],
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: _buildContentArea(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.person_rounded, 'Profile', 0),
                _buildNavItem(Icons.settings_rounded, 'Settings', 1),
                _buildNavItem(Icons.help_outline_rounded, 'Help', 2),
                _buildNavItem(Icons.feedback_outlined, 'Feedback', 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = selectedIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.blue : Colors.grey[600],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? Colors.blue : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentArea() {
    switch (selectedIndex) {
      case 0: return _buildProfileContent();
      case 1: return _buildSettingsContent();
      case 2: return _buildHelpContent();
      case 3: return _buildFeedbackContent();
      default: return _buildProfileContent();
    }
  }

  Widget _buildProfileContent() {
    final userEmail = storage.read("email") ?? "user@example.com";
    final userName = storage.read("userName") ?? "User";
    final userRole = storage.read("role") ?? "user";
    final userPhone = storage.read("phone") ?? "09";
    final userId = storage.read("userId") ?? "";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header Card
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[50]!, Colors.purple[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blue.withOpacity(0.1), width: 1),
              ),
              child: Column(
                children: [
                  Obx(() => Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              await profilePictureController.pickProfilePicture();
                              
                              // Auto-save if a file was picked
                              if (profilePictureController.hasChanges()) {
                                final userDocId = storage.read("userDocumentId") as String?;
                                if (userDocId != null && userDocId.isNotEmpty) {
                                  final newFileId = await profilePictureController
                                      .saveProfilePicture(userDocId);

                                  // Store in GetStorage after successful upload
                                  if (newFileId != null && newFileId.isNotEmpty) {
                                    await storage.write('userProfilePictureId', newFileId);
                                    setState(() {});
                                    _showSuccess('Profile picture updated successfully');
                                  }
                                } else {
                                  _showError('User document ID not found. Please log in again.');
                                }
                              }
                            },
                            borderRadius: BorderRadius.circular(45),
                            child: profilePictureController.getPreviewImage(
                              size: 90,
                              userName: userName,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              await profilePictureController.pickProfilePicture();
                              
                              // Auto-save if a file was picked
                              if (profilePictureController.hasChanges()) {
                                final userDocId = storage.read("userDocumentId") as String?;
                                if (userDocId != null && userDocId.isNotEmpty) {
                                  final newFileId = await profilePictureController
                                      .saveProfilePicture(userDocId);

                                  // Store in GetStorage after successful upload
                                  if (newFileId != null && newFileId.isNotEmpty) {
                                    await storage.write('userProfilePictureId', newFileId);
                                    setState(() {});
                                    _showSuccess('Profile picture updated successfully');
                                  }
                                } else {
                                  _showError('User document ID not found. Please log in again.');
                                }
                              }
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [Colors.blue[500]!, Colors.blue[700]!]),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.email_outlined, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          userEmail,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Obx(() => profilePictureController.isUploading.value
                  ? Container(
                      margin: const EdgeInsets.only(top: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            height: 14,
                            width: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Uploading...',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink()),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.blue[100]!, Colors.blue[50]!]),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.blue[200]!, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium, size: 12, color: Colors.blue[700]),
                            const SizedBox(width: 4),
                            Text(
                              userRole.toUpperCase(),
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.green[100]!, Colors.green[50]!]),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.green[200]!, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.green[600],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Active',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          VerificationStatusWidget(
            userId: userId,
            email: userEmail,
            userRole: userRole,
            showButton: true,
            onVerificationComplete: () {
              // This callback is triggered when verification is completed
              // You can refresh the page or show a success message
              _showSuccess( 'Verification completed successfully!');
            },
          ),
          const SizedBox(height: 16),
          // Personal Information Card
          _buildModernCard(
            title: 'Personal Information',
            icon: Icons.badge_outlined,
            iconColor: Colors.blue,
            children: [
              _buildModernInfoTile(
                icon: Icons.person_outline,
                label: 'Full Name',
                value: userName,
                iconColor: Colors.blue,
              ),
              _buildModernInfoTile(
                icon: Icons.email_outlined,
                label: 'Email Address',
                value: userEmail,
                iconColor: Colors.purple,
              ),
              _buildModernInfoTile(
                icon: Icons.phone_outlined,
                label: 'Phone Number',
                value: userPhone,
                iconColor: Colors.green,
              ),
            ],
            action: TextButton.icon(
              onPressed: _showEditProfileDialog,
              icon: Icon(Icons.edit_outlined, size: 14, color: Colors.blue[700]),
              label: Text('Edit', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w600, fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                backgroundColor: Colors.blue.withOpacity(0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Account Security Card
          _buildModernCard(
            title: 'Account Security',
            icon: Icons.security,
            iconColor: Colors.green,
            children: [
              _buildSecurityOption(
                icon: Icons.lock_outline,
                title: 'Change Password',
                subtitle: 'Update your password',
                color: Colors.blue,
                onTap: _showChangePasswordDialog,
              ),
              const SizedBox(height: 10),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Danger Zone
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Danger Zone',
                      style: TextStyle(color: Colors.red[800], fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Irreversible actions',
                  style: TextStyle(color: Colors.red[700], fontSize: 11),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _showDeactivateAccountDialog,
                  icon: const Icon(Icons.person_off_outlined, size: 16),
                  label: const Text('Deactivate Account', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[700],
                    side: BorderSide(color: Colors.red[300]!, width: 1.5),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sign Out Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showLogoutDialog,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Sign Out', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red[600],
                side: BorderSide(color: Colors.red[200]!, width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Notifications Card
          _buildModernCard(
            title: 'Notifications',
            icon: Icons.notifications_outlined,
            iconColor: Colors.orange,
            children: [
              _buildModernSettingTile(
                icon: Icons.email_outlined,
                title: 'Email Notifications',
                subtitle: 'Important updates via email',
                iconColor: Colors.red,
                value: false,
              ),
              const SizedBox(height: 10),
              _buildModernSettingTile(
                icon: Icons.notifications_active_outlined,
                title: 'Push Notifications',
                subtitle: 'Real-time updates',
                iconColor: Colors.orange,
                value: true,
              ),
              const SizedBox(height: 10),
              _buildModernSettingTile(
                icon: Icons.vibration_outlined,
                title: 'Sound & Vibration',
                subtitle: 'Notification sounds',
                iconColor: Colors.purple,
                value: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHelpContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FAQ Section
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 15,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.blue[50]!, Colors.cyan[50]!]),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.2),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.quiz_outlined, color: Colors.blue[700], size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Frequently Asked Questions',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                ...faqItems.asMap().entries.map((entry) {
                  int index = entry.key;
                  FAQItem item = entry.value;
                  
                  return Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => setState(() => item.isExpanded = !item.isExpanded),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: item.isExpanded ? Colors.blue.withOpacity(0.04) : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: item.isExpanded 
                                      ? Colors.blue.withOpacity(0.15)
                                      : Colors.grey.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    item.isExpanded ? Icons.remove : Icons.add,
                                    color: item.isExpanded ? Colors.blue[700] : Colors.grey[600],
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.question,
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 13,
                                      fontWeight: item.isExpanded ? FontWeight.w600 : FontWeight.w500,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      if (item.isExpanded)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.04)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.blue.withOpacity(0.1)),
                                ),
                                child: Text(
                                  item.answer,
                                  style: TextStyle(color: Colors.grey[700], fontSize: 12, height: 1.6),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _showSuccess( 'Thank you' "," 'Glad we could help!'),
                                      icon: Icon(Icons.thumb_up_outlined, size: 14, color: Colors.green[700]),
                                      label: Text('Helpful', style: TextStyle(color: Colors.green[700], fontSize: 11, fontWeight: FontWeight.w600)),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: Colors.green[300]!),
                                        backgroundColor: Colors.green.withOpacity(0.05),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _showInfo( 'We appreciate your feedback' "," 'We will work on improving this section.'),
                                      icon: Icon(Icons.thumb_down_outlined, size: 14, color: Colors.grey[700]),
                                      label: Text('Not helpful', style: TextStyle(color: Colors.grey[700], fontSize: 11, fontWeight: FontWeight.w600)),
                                      style: OutlinedButton.styleFrom(
                                        side: BorderSide(color: Colors.grey[300]!),
                                        backgroundColor: Colors.grey.withOpacity(0.05),
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      
                      if (index < faqItems.length - 1)
                        Divider(height: 1, color: Colors.grey[200]),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
             // Daily Report Tracker
        Obx(() {
          final tracker = feedbackController.dailyTracker.value;
          
          if (tracker == null || feedbackController.isCheckingLimit.value) {
            return Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Loading daily limit...',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final reportCount = tracker.reportCount;
          final remaining = tracker.remainingReports;
          final isLimitReached = tracker.hasExceededLimit;
          final timeUntilReset = feedbackController.getTimeUntilReset();
          
          // Calculate progress
          final progress = (reportCount / 3).clamp(0.0, 1.0);
          
          // Determine color based on remaining reports
          Color progressColor;
          Color bgColor;
          IconData icon;
          
          if (isLimitReached) {
            progressColor = Colors.red[600]!;
            bgColor = Colors.red[50]!;
            icon = Icons.block;
          } else if (remaining == 1) {
            progressColor = Colors.orange[600]!;
            bgColor = Colors.orange[50]!;
            icon = Icons.warning_amber;
          } else {
            progressColor = Colors.blue[600]!;
            bgColor = Colors.blue[50]!;
            icon = Icons.info_outline;
          }
          
          return Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: progressColor.withOpacity(0.3), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: progressColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: progressColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isLimitReached 
                              ? 'Daily Limit Reached' 
                              : 'Daily Report Limit',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: progressColor,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$reportCount/3 reports used today',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: progressColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$remaining left',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: progressColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                    minHeight: 8,
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Reset Time Info
                Row(
                  children: [
                    Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      'Resets in: $timeUntilReset',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                
                // Limit Reached Warning
                if (isLimitReached) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You\'ve reached the daily limit. Please try again after reset.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red[700],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[400]!, Colors.blue[600]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.feedback, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Send Feedback',
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Help us improve',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Feedback Type Selection
                const Text(
                  'What type of feedback?',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Type chips
                Obx(() => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: FeedbackType.values.map((type) {
                    final isSelected = feedbackController.selectedType.value == type;
                    return InkWell(
                      onTap: () {
                        feedbackController.selectedType.value = type;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected 
                            ? _getFeedbackTypeColor(type).withOpacity(0.15) 
                            : Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected 
                              ? _getFeedbackTypeColor(type) 
                              : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getFeedbackTypeIcon(type),
                              color: isSelected 
                                ? _getFeedbackTypeColor(type) 
                                : Colors.grey[600],
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              type.displayName,
                              style: TextStyle(
                                color: isSelected 
                                  ? _getFeedbackTypeColor(type) 
                                  : Colors.grey[700],
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                )),
                
                const SizedBox(height: 24),
                
                // Category Selection
                const Text(
                  'Category',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Obx(() => DropdownButtonFormField<FeedbackCategory>(
                  value: feedbackController.selectedCategory.value,
                  decoration: InputDecoration(
                    hintText: 'Select a category',
                    prefixIcon: const Icon(Icons.category, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  items: FeedbackCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category.displayName, style: const TextStyle(fontSize: 13)),
                    );
                  }).toList(),
                  onChanged: (category) {
                    if (category != null) {
                      feedbackController.selectedCategory.value = category;
                    }
                  },
                )),
                
                const SizedBox(height: 24),
                
                // Subject Field
                const Text(
                  'Subject',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Brief summary (min 5 characters)',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: subjectController,
                  maxLength: 100,
                  onChanged: (value) {
                    feedbackController.subject.value = value;
                  },
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'e.g., App crashes when uploading',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                    counterStyle: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Description Field
                const Text(
                  'Details',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Please provide details (min 20 characters)',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  maxLines: 5,
                  maxLength: 1000,
                  onChanged: (value) {
                    feedbackController.description.value = value;
                  },
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Describe what happened, when, and steps to reproduce...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Colors.blue, width: 2),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                    counterStyle: TextStyle(color: Colors.grey[500], fontSize: 11),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // File Upload Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.attachment, color: Colors.blue[700], size: 18),
                          const SizedBox(width: 6),
                          Text(
                            'Attachments (Optional)',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Obx(() => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: feedbackController.selectedFiles.isEmpty 
                                ? Colors.orange[100] 
                                : Colors.green[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${feedbackController.selectedFiles.length}/5',
                              style: TextStyle(
                                color: feedbackController.selectedFiles.isEmpty 
                                  ? Colors.orange[800] 
                                  : Colors.green[800],
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add images or videos (optional)',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '🖼️ Images: Max 5MB • 🎥 Videos: Max 25MB',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      
                      // Upload Button
                      Obx(() => feedbackController.selectedFiles.isEmpty
                        ? InkWell(
                            onTap: () => feedbackController.pickFiles(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.grey[300]!, 
                                  width: 2, 
                                  style: BorderStyle.solid
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(Icons.cloud_upload_outlined, color: Colors.grey[400], size: 32),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to upload files',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Images (JPG, PNG, GIF) or Videos (MP4, MOV)',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                      ),
                      
                      // Display selected files with video preview
                      Obx(() => feedbackController.selectedFiles.isNotEmpty
                        ? Column(
                            children: [
                              ...feedbackController.selectedFiles.map((file) => _buildFileItemWithPreview(file)).toList(),
                              const SizedBox(height: 8),
                              if (feedbackController.selectedFiles.length < 5)
                                OutlinedButton.icon(
                                  onPressed: () => feedbackController.pickFiles(),
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add more files', style: TextStyle(fontSize: 12)),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue[700],
                                    side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                ),
                            ],
                          )
                        : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: Obx(() => ElevatedButton(
                    onPressed: feedbackController.isSubmitting.value 
                      ? null 
                      : () async {
                          final success = await feedbackController.submitFeedback();
                          
                          if (success) {
                            subjectController.clear();
                            descriptionController.clear();
                          }
                        },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                        disabledBackgroundColor: Colors.grey[400],
                      ),
                        child: feedbackController.isSubmitting.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.send, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'Submit Feedback',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                    )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileItem(PlatformFile file) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              feedbackController.getFileIcon(file.extension),
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  feedbackController.getFileSize(file.size),
                  style: TextStyle(
                    color: Colors.grey[600], 
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                feedbackController.removeFile(file);
                feedbackController.selectedFiles.refresh();
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.close, 
                  size: 18, 
                  color: Colors.red[400],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper widgets
  Widget _buildModernCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> children,
    Widget? action,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                if (action != null) action,
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoTile({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    bool isLast = false,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast) const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildSecurityOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    bool value = false,
    bool isSwitch = true,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isSwitch ? null : onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                  ],
                ),
              ),
              if (isSwitch)
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: value,
                    onChanged: (v) => _showSuccess('Setting updated'),
                    activeColor: iconColor,
                  ),
                )
              else
                Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods for feedback types
  Color _getFeedbackTypeColor(FeedbackType type) {
    switch (type) {
      case FeedbackType.bug:
        return Colors.red;
      case FeedbackType.feature:
        return Colors.green;
      case FeedbackType.complaint:
        return Colors.orange;
      case FeedbackType.question:
        return Colors.purple;
      case FeedbackType.compliment:
        return Colors.teal;
      case FeedbackType.systemIssue:
        return Colors.deepOrange;
    }
  }

  IconData _getFeedbackTypeIcon(FeedbackType type) {
    switch (type) {
      case FeedbackType.bug:
        return Icons.bug_report;
      case FeedbackType.feature:
        return Icons.lightbulb_outline;
      case FeedbackType.complaint:
        return Icons.sentiment_dissatisfied;
      case FeedbackType.question:
        return Icons.help_outline;
      case FeedbackType.compliment:
        return Icons.sentiment_satisfied;
      case FeedbackType.systemIssue:
        return Icons.error_outline;
    }
  }

  // Dialog methods
void _showEditProfileDialog() {
  final nameController = TextEditingController(text: storage.read("userName") ?? "");
  
  // Set default to 09 if phone is empty or null
  String currentPhone = storage.read("phone") ?? "09";
  if (currentPhone.isEmpty || currentPhone.trim().isEmpty) {
    currentPhone = "09";
  }
  final phoneController = TextEditingController(text: currentPhone);
  
  final nameError = Rx<String?>(null);
  final phoneError = Rx<String?>(null);
  final isLoading = false.obs;

  // Phone validation function with Philippines format
  String? validatePhone(String phone) {
    if (phone.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove spaces for validation
    final cleanPhone = phone.replaceAll(' ', '');
    
    // Check if it starts with 09 (Philippines mobile format)
    if (!cleanPhone.startsWith('09')) {
      return 'Please use Philippines format: 09XX XXX XXXX';
    }
    
    // Check if it's a valid Philippine mobile format (09 followed by 9 digits = 11 total)
    if (!RegExp(r'^09\d{9}$').hasMatch(cleanPhone)) {
      return 'Invalid Philippine phone number format';
    }
    
    return null;
  }

  // Format phone number with spaces for display
  String formatPhoneNumber(String phone) {
    // Remove all spaces first
    String cleaned = phone.replaceAll(' ', '');
    
    // If empty or just "0", return "09"
    if (cleaned.isEmpty || cleaned == '0') {
      return '09';
    }
    
    // If starts with 0 but not 09, force 09
    if (cleaned.startsWith('0') && !cleaned.startsWith('09')) {
      cleaned = '09${cleaned.substring(1)}';
    }
    
    // If doesn't start with 0, prepend 09
    if (!cleaned.startsWith('0')) {
      cleaned = '09$cleaned';
    }
    
    // Apply formatting: 0XXX XXX XXXX
    if (cleaned.length <= 4) {
      return cleaned;
    } else if (cleaned.length <= 7) {
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4)}';
    } else if (cleaned.length <= 11) {
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 7)} ${cleaned.substring(7)}';
    } else {
      // Limit to 11 digits
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 7)} ${cleaned.substring(7, 11)}';
    }
  }

  // Name validation function
  String? validateName(String name) {
    if (name.isEmpty) {
      return 'Name is required';
    }
    
    if (name.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (name.length > 100) {
      return 'Name is too long';
    }
    
    return null;
  }

  // Update profile function
  Future<void> updateProfile() async {
    // Clear previous errors
    nameError.value = null;
    phoneError.value = null;

    final name = nameController.text.trim();
    final phone = phoneController.text.trim();

    bool hasError = false;

    // Validate name
    final nameValidation = validateName(name);
    if (nameValidation != null) {
      nameError.value = nameValidation;
      hasError = true;
    }

    // Validate phone
    final phoneValidation = validatePhone(phone);
    if (phoneValidation != null) {
      phoneError.value = phoneValidation;
      hasError = true;
    }

    if (hasError) return;

    try {
      isLoading.value = true;

      final userDocId = storage.read("userDocumentId") as String?;
      
      if (userDocId == null || userDocId.isEmpty) {
        throw Exception('User document ID not found. Please log in again.');
      }

      print('>>> Updating user profile...');
      print('>>> Document ID: $userDocId');
      print('>>> New Name: $name');
      print('>>> New Phone: $phone');

      // Update in Appwrite
      final authRepository = Get.find<AuthRepository>();
      await authRepository.updateUserProfile(
        documentId: userDocId,
        fields: {
          'name': name,
          'phone': phone,
        },
      );

      print('>>> ✅ Profile updated successfully in Appwrite');

      // Update GetStorage
      await storage.write("userName", name);
      await storage.write("phone", phone);

      print('>>> ✅ Local storage updated');

      isLoading.value = false;

      // Close dialog
      Navigator.of(context).pop();

      // Refresh UI
      setState(() {});

      // Show success message
      _showSuccess('Profile updated successfully');

      // Dispose controllers
      nameController.dispose();
      phoneController.dispose();

    } catch (e) {
      print('>>> ERROR updating profile: $e');
      isLoading.value = false;

      String errorMessage = 'Failed to update profile. Please try again.';

      if (e.toString().contains('Document') && e.toString().contains('not found')) {
        errorMessage = 'User profile not found. Please log in again.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection.';
      }

      _showError(errorMessage);
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[400]!, Colors.blue[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.edit_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit Profile',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Update your profile information',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 22),
                        onPressed: () {
                          Navigator.of(context).pop();
                          nameController.dispose();
                          phoneController.dispose();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name Field
                    Text(
                      'Full Name',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => TextField(
                      controller: nameController,
                      maxLength: 100,
                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Enter your full name',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                        errorText: nameError.value,
                        errorMaxLines: 2,
                        errorStyle: const TextStyle(fontSize: 11),
                        counterText: '',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 1.5),
                        ),
                        prefixIcon: Icon(Icons.person_outline, size: 20, color: Colors.grey[600]),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (value) {
                        if (nameError.value != null) {
                          nameError.value = null;
                        }
                      },
                    )),
                    const SizedBox(height: 16),
                    
                    // Phone Field with PH format
                    Text(
                      'Phone Number (Philippines)',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => TextField(
                      controller: phoneController,
                      maxLength: 13, // "0XXX XXX XXXX" = 13 characters with spaces
                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: '0XXX XXX XXXX',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                        helperText: 'Format: 09 followed by 9 digits',
                        helperStyle: TextStyle(color: Colors.grey[500], fontSize: 10),
                        errorText: phoneError.value,
                        errorMaxLines: 2,
                        errorStyle: const TextStyle(fontSize: 11),
                        counterText: '',
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 1.5),
                        ),
                        prefixIcon: Icon(Icons.phone_outlined, size: 20, color: Colors.grey[600]),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (value) {
                        // Format the phone number as user types
                        final formatted = formatPhoneNumber(value);
                        if (formatted != value) {
                          phoneController.value = TextEditingValue(
                            text: formatted,
                            selection: TextSelection.collapsed(offset: formatted.length),
                          );
                        }
                        if (phoneError.value != null) {
                          phoneError.value = null;
                        }
                      },
                    )),
                    const SizedBox(height: 16),
                    
                    // Info box
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[50]!, Colors.cyan[50]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Changes will be saved to your account',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 80), // Space for bottom button
                  ],
                ),
              ),
            ),
            
            // Bottom Action Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Obx(() => ElevatedButton(
                  onPressed: isLoading.value ? null : updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[400],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Save Changes',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                )),
              ),
            ),
          ],
        ),
      );
    },
  );
}

void _showChangePasswordDialog() {
  final currentPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  final currentPasswordVisible = false.obs;
  final newPasswordVisible = false.obs;
  final confirmPasswordVisible = false.obs;
  
  final currentPasswordError = Rx<String?>(null);
  final newPasswordError = Rx<String?>(null);
  final confirmPasswordError = Rx<String?>(null);
  final isLoading = false.obs;

  // Password validation function
  String? validatePassword(String password) {
    if (password.isEmpty) {
      return 'Password is required';
    }
    
    if (password.length < 8) {
      return 'Password must be at least 8 characters';
    }
    
    // Check for uppercase letter
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    
    // Check for number
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    
    // Check for special character
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      return 'Password must contain at least one special character';
    }
    
    return null;
  }

  // Change password function
  Future<void> changePassword() async {
    // Clear previous errors
    currentPasswordError.value = null;
    newPasswordError.value = null;
    confirmPasswordError.value = null;

    final currentPassword = currentPasswordController.text.trim();
    final newPassword = newPasswordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    bool hasError = false;

    // Validate current password
    if (currentPassword.isEmpty) {
      currentPasswordError.value = 'Please enter your current password';
      hasError = true;
    }

    // Validate new password
    final newPasswordValidation = validatePassword(newPassword);
    if (newPasswordValidation != null) {
      newPasswordError.value = newPasswordValidation;
      hasError = true;
    }

    // Check if new password is same as current
    if (newPassword.isNotEmpty && currentPassword.isNotEmpty && 
        newPassword == currentPassword) {
      newPasswordError.value = 'New password must be different from current password';
      hasError = true;
    }

    // Validate password confirmation
    if (confirmPassword.isEmpty) {
      confirmPasswordError.value = 'Please confirm your new password';
      hasError = true;
    } else if (newPassword != confirmPassword) {
      confirmPasswordError.value = 'Passwords do not match';
      hasError = true;
    }

    if (hasError) return;

    try {
      isLoading.value = true;

      print('>>> Attempting to change password...');

      // Appwrite's updatePassword automatically verifies old password
      final authRepository = Get.find<AuthRepository>();
      await authRepository.appWriteProvider.account!.updatePassword(
        password: newPassword,
        oldPassword: currentPassword,
      );

      print('>>> ✅ Password updated successfully');

      isLoading.value = false;

      // Close dialog
      Navigator.of(context).pop();

      // Show success message
      _showSuccess('Password changed successfully');

      // Clear controllers
      currentPasswordController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();

    } catch (e) {
      print('>>> ERROR changing password: $e');
      isLoading.value = false;

      String errorMessage = 'Failed to change password. Please try again.';

      // Handle specific Appwrite errors
      if (e.toString().contains('user_invalid_credentials') || 
          e.toString().contains('Invalid credentials') ||
          e.toString().contains('invalid_credentials')) {
        errorMessage = 'Current password is incorrect';
        currentPasswordError.value = errorMessage;
      } else if (e.toString().contains('password_recently_used')) {
        errorMessage = 'This password was recently used. Please choose a different one.';
        newPasswordError.value = errorMessage;
      } else if (e.toString().contains('password')) {
        errorMessage = 'Invalid password format. Please try again.';
        newPasswordError.value = errorMessage;
      } else {
        // Generic error
        _showError(errorMessage);
      }
    }
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: 3),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 12,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue[400]!, Colors.blue[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Change Password',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Update your account password',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 22),
                        onPressed: () {
                          Navigator.of(context).pop();
                          currentPasswordController.dispose();
                          newPasswordController.dispose();
                          confirmPasswordController.dispose();
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Password Requirements Info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[50]!, Colors.cyan[50]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 16,
                                color: Colors.blue[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Password Requirements',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _buildRequirement('At least 8 characters'),
                          _buildRequirement('One uppercase letter (A-Z)'),
                          _buildRequirement('One number (0-9)'),
                          _buildRequirement('One special character (!@#\$%^&*)'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Current Password Field
                    Text(
                      'Current Password',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => TextField(
                      controller: currentPasswordController,
                      obscureText: !currentPasswordVisible.value,
                      maxLength: 50,
                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Enter your current password',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                        counterText: '',
                        errorText: currentPasswordError.value,
                        errorMaxLines: 2,
                        errorStyle: const TextStyle(fontSize: 11),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 1.5),
                        ),
                        prefixIcon: Icon(Icons.lock_outline, size: 20, color: Colors.grey[600]),
                        suffixIcon: IconButton(
                          icon: Icon(
                            currentPasswordVisible.value
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            currentPasswordVisible.value = !currentPasswordVisible.value;
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (value) {
                        if (currentPasswordError.value != null) {
                          currentPasswordError.value = null;
                        }
                      },
                    )),
                    const SizedBox(height: 16),

                    // New Password Field
                    Text(
                      'New Password',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => TextField(
                      controller: newPasswordController,
                      obscureText: !newPasswordVisible.value,
                      maxLength: 50,
                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Enter your new password',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                        counterText: '',
                        errorText: newPasswordError.value,
                        errorMaxLines: 3,
                        errorStyle: const TextStyle(fontSize: 11),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 1.5),
                        ),
                        prefixIcon: Icon(Icons.lock_reset_rounded, size: 20, color: Colors.grey[600]),
                        suffixIcon: IconButton(
                          icon: Icon(
                            newPasswordVisible.value
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            newPasswordVisible.value = !newPasswordVisible.value;
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (value) {
                        if (newPasswordError.value != null) {
                          newPasswordError.value = null;
                        }
                      },
                    )),
                    const SizedBox(height: 16),

                    // Confirm New Password Field
                    Text(
                      'Confirm New Password',
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Obx(() => TextField(
                      controller: confirmPasswordController,
                      obscureText: !confirmPasswordVisible.value,
                      maxLength: 50,
                      style: const TextStyle(color: Colors.black87, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Re-enter your new password',
                        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                        counterText: '',
                        errorText: confirmPasswordError.value,
                        errorMaxLines: 2,
                        errorStyle: const TextStyle(fontSize: 11),
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.blue, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red, width: 1.5),
                        ),
                        prefixIcon: Icon(Icons.check_circle_outline, size: 20, color: Colors.grey[600]),
                        suffixIcon: IconButton(
                          icon: Icon(
                            confirmPasswordVisible.value
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          onPressed: () {
                            confirmPasswordVisible.value = !confirmPasswordVisible.value;
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      onChanged: (value) {
                        if (confirmPasswordError.value != null) {
                          confirmPasswordError.value = null;
                        }
                      },
                    )),
                    const SizedBox(height: 80), // Space for bottom button
                  ],
                ),
              ),
            ),
            
            // Bottom Action Button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Obx(() => ElevatedButton(
                  onPressed: isLoading.value ? null : changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[400],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading.value
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Change Password',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                )),
              ),
            ),
          ],
        ),
      );
    },
  );
}

  void _showDeactivateAccountDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red[700], size: 22),
              const SizedBox(width: 8),
              const Text('Deactivate Account', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          content: const Text(
            'Are you sure you want to deactivate your account? This action can be reversed by contacting support.',
            style: TextStyle(color: Colors.black87, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(fontSize: 13)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showWarning('Not yet implemented',);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Deactivate', style: TextStyle(fontSize: 13)),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Sign Out', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
          content: const Text('Are you sure you want to sign out?', style: TextStyle(color: Colors.black87, fontSize: 13)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(fontSize: 13)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                await LogoutHelper.logout();
              },
              child: const Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFileItemWithPreview(PlatformFile file) {
  final extension = file.extension?.toLowerCase() ?? '';
  final isVideo = ['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(extension);
  final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);

  return Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey[300]!),
    ),
    child: Row(
      children: [
        // Preview thumbnail
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: isVideo ? Colors.purple.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Icon(
              isVideo ? Icons.video_library : Icons.image,
              color: isVideo ? Colors.purple : Colors.blue,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                file.name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isVideo ? Colors.purple.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isVideo ? '🎥 Video' : '🖼️ Image',
                      style: TextStyle(
                        fontSize: 10,
                        color: isVideo ? Colors.purple[700] : Colors.blue[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    feedbackController.getFileSize(file.size),
                    style: TextStyle(
                      color: Colors.grey[600], 
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              feedbackController.removeFile(file);
              feedbackController.selectedFiles.refresh();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.close, 
                size: 18, 
                color: Colors.red[400],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

  void _showCompactNotification(String message,
      {required Color bgColor,
      required IconData icon,
      required Color iconColor}) {
    Get.rawSnackbar(
      messageText: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 16),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      backgroundColor: bgColor,
      snackPosition: SnackPosition.TOP,
      borderRadius: 4,
      margin: const EdgeInsets.only(top: 16, right: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      duration: const Duration(seconds: 2),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      maxWidth: 300,
    );
  }

  void _showSuccess(String message) {
    _showCompactNotification(message,
        bgColor: Colors.green[600]!,
        icon: Icons.check_circle_outline,
        iconColor: Colors.white);
  }

  void _showError(String message) {
    _showCompactNotification(message,
        bgColor: Colors.red[600]!,
        icon: Icons.error_outline,
        iconColor: Colors.white);
  }

  void _showInfo(String message) {
    _showCompactNotification(message,
        bgColor: Colors.blue[600]!,
        icon: Icons.info_outline,
        iconColor: Colors.white);
  }

  void _showWarning(String message) {
    _showCompactNotification(message,
        bgColor: Colors.amber[700]!,
        icon: Icons.warning_amber,
        iconColor: Colors.white);
  }
}
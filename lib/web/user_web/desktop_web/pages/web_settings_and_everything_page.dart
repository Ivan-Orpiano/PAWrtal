import 'package:capstone_app/data/id_verification/widgets/verification_status_widget.dart';
import 'package:capstone_app/data/models/feedback_and_report_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/notification/services/notification_preferences_service.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/web/user_web/controllers/web_user_pfp_controller.dart';
import 'package:capstone_app/web/user_web/controllers/web_feedback_controller.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone_app/utils/logout_helper.dart';

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

class WebSettingsAndEverythingPage extends StatefulWidget {
  final int initialIndex;

  const WebSettingsAndEverythingPage({super.key, this.initialIndex = 0});

  @override
  State<WebSettingsAndEverythingPage> createState() =>
      _WebSettingsAndEverythingPageState();
}

class _WebSettingsAndEverythingPageState
    extends State<WebSettingsAndEverythingPage> {
  int selectedIndex = 0;
  final GetStorage storage = GetStorage();
  late TextEditingController subjectController;
  late TextEditingController descriptionController;

  Key _verificationWidgetKey = UniqueKey();

  void _refreshVerificationWidget() {
    setState(() {
      _verificationWidgetKey = UniqueKey();
    });
  }

  get feedbackController => null;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
    subjectController = TextEditingController();
    descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    subjectController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (bool didPop, Object? result) {},
      child: KeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.keyS &&
                (HardwareKeyboard.instance.isControlPressed ||
                    HardwareKeyboard.instance.isMetaPressed)) {
              return;
            }
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              Navigator.of(context).pop();
              return;
            }
          }
        },
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          body: Column(children: [
            Container(
              height: 81,
              decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                      bottom: BorderSide(color: Colors.black26, width: 1))),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: _getResponsivePadding()),
                    child: SizedBox(
                      height: 80,
                      child: Row(
                        children: [
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            child: Image.asset(
                              'lib/images/PAWrtal_logo.png',
                              width: 150,
                              height: 100,
                            ),
                          ),
                          const Spacer(flex: 1),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 240,
                    color: Colors.white,
                    child: Column(
                      children: [
                        _buildSidebarItem('Profile', Icons.person, 0),
                        _buildSidebarItem('Settings', Icons.settings, 1),
                        _buildSidebarItem('Help', Icons.help_outline, 2),
                        _buildSidebarItem(
                            'Give Feedback', Icons.feedback_outlined, 3),
                        const Divider(color: Colors.grey),
                        _buildSidebarItem('Sign out', Icons.logout, -1,
                            isDestructive: true),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: Colors.grey[50],
                      child: _buildContentArea(),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  double _getResponsivePadding() => MediaQuery.of(context).size.width * 0.02;

  Widget _buildSidebarItem(String title, IconData icon, int index,
      {bool isDestructive = false}) {
    final isSelected = selectedIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isSelected
            ? LinearGradient(
                colors: [Colors.blue[50]!, Colors.blue[100]!.withOpacity(0.3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (title == 'Sign out') {
              _showLogoutDialog();
            } else {
              setState(() => selectedIndex = index);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? Colors.red.withOpacity(0.1)
                        : isSelected
                            ? Colors.blue.withOpacity(0.15)
                            : Colors.grey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive
                        ? Colors.red[600]
                        : isSelected
                            ? Colors.blue[700]
                            : Colors.grey[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isDestructive
                          ? Colors.red[600]
                          : isSelected
                              ? Colors.blue[700]
                              : Colors.grey[700],
                      fontSize: 14,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea() {
    switch (selectedIndex) {
      case 0:
        return _buildProfileContent();
      case 1:
        return _buildSettingsContent();
      case 2:
        return _buildHelpContent();
      case 3:
        return _buildFeedbackContent();
      default:
        return _buildProfileContent();
    }
  }

  // Replace the _buildProfileContent() method in WebSettingsAndEverythingPage with this:

  Widget _buildProfileContent() {
    final userEmail = storage.read("email") ?? "user@example.com";
    final userName = storage.read("userName") ?? "User";
    final userRole = storage.read("role") ?? "user";
    final userPhone = storage.read("phone") ?? "09XX XXX XXXX";
    final userId = storage.read("userId") ?? "";
    final profilePictureId = storage.read("userProfilePictureId") as String?;

    // Initialize profile picture controller
    final profilePictureController = Get.put(
      UserPfpController(authRepository: Get.find<AuthRepository>()),
      tag: 'user_profile_picture',
    );

    // Set current profile picture if exists
    if (profilePictureId != null && profilePictureId.isNotEmpty) {
      profilePictureController.setCurrentProfilePicture(profilePictureId);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[400]!, Colors.purple[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.person, color: Colors.blue[600], size: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Profile',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your personal information and preferences',
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          VerificationStatusWidget(
            key: _verificationWidgetKey,
            userId: userId,
            email: userEmail,
            userRole: userRole,
            showButton: true,
            onVerificationComplete: () async {
              // Sync name from verified ID
              final userDocId = storage.read("userDocumentId") as String?;
              if (userDocId != null) {
                final authRepository = Get.find<AuthRepository>();
                final synced = await authRepository
                    .syncVerifiedNameToUserProfile(userId, userDocId);

                if (synced) {
                  final verifiedName = await authRepository
                      .getVerifiedNameFromIdVerification(userId);
                  if (verifiedName != null && verifiedName.isNotEmpty) {
                    await storage.write("userName", verifiedName);
                    await storage.write("idVerified", true);

                    _refreshVerificationWidget();

                    _showSuccess('Profile updated with verified name');
                  }
                }
              }

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Verification submitted successfully!'),
                  backgroundColor: Color(0xFF4CAF50),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Obx(() => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[50]!, Colors.purple[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.blue.withOpacity(0.1), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => profilePictureController
                                        .pickProfilePicture(),
                                    borderRadius: BorderRadius.circular(60),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(60),
                                      child: profilePictureController
                                          .getPreviewImage(
                                        size: 96,
                                        userName: userName,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 2,
                                right: 2,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => profilePictureController
                                        .pickProfilePicture(),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [
                                          Colors.blue[500]!,
                                          Colors.blue[700]!
                                        ]),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white, width: 3),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.blue.withOpacity(0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(Icons.camera_alt,
                                          size: 16, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  userName,
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Add verification badge for name
                                FutureBuilder<Map<String, dynamic>>(
                                  future: Get.find<AuthRepository>()
                                      .getUserVerificationStatus(userId),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData) {
                                      final isVerified = snapshot.data?['user']
                                              ?['idVerified'] ==
                                          true;
                                      final verifyByClinic =
                                          snapshot.data?['verificationDoc']
                                              ?['verifyByClinic'] as String?;
                                      final isPAWrtalVerified = isVerified &&
                                          (verifyByClinic == null ||
                                              verifyByClinic.isEmpty);

                                      if (isVerified) {
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          margin:
                                              const EdgeInsets.only(bottom: 6),
                                          decoration: BoxDecoration(
                                            color: isPAWrtalVerified
                                                ? Colors.green.withOpacity(0.1)
                                                : Colors.blue.withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                isPAWrtalVerified
                                                    ? Icons.verified_user
                                                    : Icons.local_hospital,
                                                size: 12,
                                                color: isPAWrtalVerified
                                                    ? Colors.green[700]
                                                    : Colors.blue[700],
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                isPAWrtalVerified
                                                    ? 'ID Verified'
                                                    : 'Clinic Verified',
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                  color: isPAWrtalVerified
                                                      ? Colors.green[700]
                                                      : Colors.blue[700],
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(Icons.email_outlined,
                                        size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 6),
                                    Text(userEmail,
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14)),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [
                                          Colors.blue[100]!,
                                          Colors.blue[50]!
                                        ]),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: Colors.blue[200]!, width: 1),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.workspace_premium,
                                              size: 14,
                                              color: Colors.blue[700]),
                                          const SizedBox(width: 6),
                                          Text(
                                            userRole.toUpperCase(),
                                            style: TextStyle(
                                              color: Colors.blue[700],
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(colors: [
                                          Colors.green[100]!,
                                          Colors.green[50]!
                                        ]),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color: Colors.green[200]!,
                                            width: 1),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: Colors.green[600],
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.green
                                                      .withOpacity(0.5),
                                                  blurRadius: 4,
                                                  spreadRadius: 1,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Active',
                                            style: TextStyle(
                                              color: Colors.green[700],
                                              fontSize: 11,
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
                        ],
                      ),

                      // Show save/cancel buttons if there are changes
                      if (profilePictureController.hasChanges()) ...[
                        const SizedBox(height: 20),
                        const Divider(color: Colors.grey),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Spacer(),
                            OutlinedButton(
                              onPressed: () =>
                                  profilePictureController.cancelChanges(),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.grey),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: profilePictureController
                                      .isUploading.value
                                  ? null
                                  : () async {
                                      final userDocId = storage
                                          .read("userDocumentId") as String?;
                                      if (userDocId != null &&
                                          userDocId.isNotEmpty) {
                                        final newFileId =
                                            await profilePictureController
                                                .saveProfilePicture(userDocId);

                                        // ⭐ Store in GetStorage after successful upload
                                        if (newFileId != null &&
                                            newFileId.isNotEmpty) {
                                          await storage.write(
                                              'userProfilePictureId',
                                              newFileId);
                                          setState(() {});
                                          _showSuccess(
                                              'Profile picture updated successfully');
                                        }
                                      } else {
                                        _showError(
                                            'User document ID not found. Please log in again.');
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: profilePictureController.isUploading.value
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text('Save Profile Picture'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 28),
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
                  isLast: true),
            ],
            action: TextButton.icon(
              onPressed: _showEditProfileDialog,
              icon:
                  Icon(Icons.edit_outlined, size: 16, color: Colors.blue[700]),
              label: Text('Edit Profile',
                  style: TextStyle(
                      color: Colors.blue[700], fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                backgroundColor: Colors.blue.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildModernCard(
            title: 'Account Security',
            icon: Icons.security,
            iconColor: Colors.green,
            children: [
              _buildSecurityOption(
                icon: Icons.lock_outline,
                title: 'Change Password',
                color: Colors.blue,
                onTap: _showChangePasswordDialog,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContent() {
    final notificationPrefsService = Get.find<NotificationPreferencesService>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple[400]!, Colors.pink[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child:
                      Icon(Icons.settings, color: Colors.purple[600], size: 24),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Notifications Card
          _buildModernCard(
            title: 'Notifications',
            icon: Icons.notifications_outlined,
            iconColor: Colors.orange,
            children: [
              // Info banner about in-app notifications
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
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
                        'In-app notifications are always enabled to keep you updated within PAWrtal',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Push Notifications Toggle
              Obx(() => _buildFunctionalSettingTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Push Notifications',
                    subtitle: 'Receive notifications on your mobile device',
                    iconColor: Colors.orange,
                    value: notificationPrefsService.isPushEnabled,
                    isLoading: notificationPrefsService.isLoading.value,
                    onChanged: (value) async {
                      final success = await notificationPrefsService
                          .updatePushNotificationPreference(value);
                      if (success) {
                        _showSuccess(value
                            ? 'Push notifications enabled'
                            : 'Push notifications disabled');
                      } else {
                        _showError(
                            'Failed to update preference. Please try again.');
                        // Revert the toggle
                        await notificationPrefsService.loadPreferences();
                      }
                    },
                  )),
              const SizedBox(height: 10),

              // Email Notifications Toggle
              Obx(() => _buildFunctionalSettingTile(
                    icon: Icons.email_outlined,
                    title: 'Email Notifications',
                    subtitle: 'Receive appointment updates via email',
                    iconColor: Colors.red,
                    value: notificationPrefsService.isEmailEnabled,
                    isLoading: notificationPrefsService.isLoading.value,
                    onChanged: (value) async {
                      final success = await notificationPrefsService
                          .updateEmailNotificationPreference(value);
                      if (success) {
                        _showSuccess(value
                            ? 'Email notifications enabled'
                            : 'Email notifications disabled');
                      } else {
                        _showError(
                            'Failed to update preference. Please try again.');
                        // Revert the toggle
                        await notificationPrefsService.loadPreferences();
                      }
                    },
                  )),
              const SizedBox(height: 16),

              // Current notification status summary
              Obx(() {
                final prefs = notificationPrefsService.preferences.value;
                String statusText;
                Color statusColor;
                IconData statusIcon;

                if (prefs.pushNotificationsEnabled &&
                    prefs.emailNotificationsEnabled) {
                  statusText = 'All notifications are enabled';
                  statusColor = Colors.green;
                  statusIcon = Icons.check_circle;
                } else if (!prefs.pushNotificationsEnabled &&
                    !prefs.emailNotificationsEnabled) {
                  statusText = 'Push and email notifications are disabled';
                  statusColor = Colors.red;
                  statusIcon = Icons.notifications_off;
                } else if (!prefs.pushNotificationsEnabled) {
                  statusText = 'Push notifications are disabled';
                  statusColor = Colors.orange;
                  statusIcon = Icons.notifications_paused;
                } else {
                  statusText = 'Email notifications are disabled';
                  statusColor = Colors.orange;
                  statusIcon = Icons.email_outlined;
                }

                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 11,
                            color: statusColor.withOpacity(0.9),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionalSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required bool value,
    required bool isLoading,
    required Function(bool) onChanged,
  }) {
    return Material(
      color: Colors.transparent,
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
                  Text(subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                ],
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              )
            else
              Transform.scale(
                scale: 0.8,
                child: Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: iconColor,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[400]!, Colors.teal[400]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.help_outline,
                      color: Colors.green[600], size: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Help',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Find answers and get assistance when you need it',
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                        colors: [Colors.blue[50]!, Colors.cyan[50]!]),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.quiz_outlined,
                            color: Colors.blue[700], size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Frequently Asked Questions',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
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
                          onTap: () => setState(
                              () => item.isExpanded = !item.isExpanded),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: item.isExpanded
                                  ? Colors.blue.withOpacity(0.04)
                                  : Colors.transparent,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: item.isExpanded
                                        ? Colors.blue.withOpacity(0.15)
                                        : Colors.grey.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    item.isExpanded ? Icons.remove : Icons.add,
                                    color: item.isExpanded
                                        ? Colors.blue[700]
                                        : Colors.grey[600],
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    item.question,
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 14,
                                      fontWeight: item.isExpanded
                                          ? FontWeight.w600
                                          : FontWeight.w500,
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
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.04)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Colors.blue.withOpacity(0.1)),
                                ),
                                child: Text(
                                  item.answer,
                                  style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                      height: 1.7),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Was this helpful?',
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _showSuccess(
                                                'Glad we could help!'),
                                            icon: Icon(Icons.thumb_up_outlined,
                                                size: 16,
                                                color: Colors.green[700]),
                                            label: Text('Yes',
                                                style: TextStyle(
                                                    color: Colors.green[700],
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                  color: Colors.green[300]!),
                                              backgroundColor: Colors.green
                                                  .withOpacity(0.05),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _showInfo(
                                                'We\'ll improve this'),
                                            icon: Icon(
                                                Icons.thumb_down_outlined,
                                                size: 16,
                                                color: Colors.grey[700]),
                                            label: Text('No',
                                                style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontWeight:
                                                        FontWeight.w600)),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(
                                                  color: Colors.grey[300]!),
                                              backgroundColor:
                                                  Colors.grey.withOpacity(0.05),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 10),
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          10)),
                                            ),
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
    final feedbackController = Get.put(WebFeedbackController(
      authRepository: Get.find<AuthRepository>(),
      session: Get.find<UserSessionService>(),
    ));

    return Obx(() => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue[400]!, Colors.blue[600]!],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.feedback,
                        color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Send Feedback',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Help us improve by sharing your thoughts and reporting issues',
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                  ),

                  // NEW: Daily limit indicator
                  if (feedbackController.dailyTracker.value != null)
                    _buildDailyLimitIndicator(feedbackController),
                ],
              ),

              const SizedBox(height: 24),
              // NEW: Daily limit warning banner (if exceeded)
              if (feedbackController.dailyTracker.value != null &&
                  feedbackController.dailyTracker.value!.hasExceededLimit)
                _buildLimitExceededBanner(feedbackController),

              const SizedBox(height: 16),

              const SizedBox(height: 32),

              // Main Form
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                    // Feedback Type Selection
                    const Text(
                      'What type of feedback is this?',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: FeedbackType.values.map((type) {
                        final isSelected =
                            feedbackController.selectedType.value == type;
                        return InkWell(
                          onTap: () =>
                              feedbackController.selectedType.value = type,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? _getFeedbackTypeColor(type)
                                      .withOpacity(0.15)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
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
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  type.displayName,
                                  style: TextStyle(
                                    color: isSelected
                                        ? _getFeedbackTypeColor(type)
                                        : Colors.grey[700],
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 32),

                    // Category Selection
                    const Text(
                      'Which area does this relate to?',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<FeedbackCategory>(
                      menuMaxHeight: 300,
                      dropdownColor: Colors.white,
                      value: feedbackController.selectedCategory.value,
                      decoration: InputDecoration(
                        hintText: 'Select a category',
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.blue, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      items: FeedbackCategory.values.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(category.displayName),
                        );
                      }).toList(),
                      onChanged: (category) {
                        if (category != null) {
                          feedbackController.selectedCategory.value = category;
                        }
                      },
                    ),

                    const SizedBox(height: 32),

                    // Subject Field - USE TextEditingController
                    const Text(
                      'Subject',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Brief summary (min 5 characters)',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: subjectController,
                      maxLength: 100,
                      onChanged: (value) =>
                          feedbackController.subject.value = value,
                      decoration: InputDecoration(
                        hintText: 'e.g., App crashes when uploading images',
                        hintStyle:
                            TextStyle(color: Colors.grey[400], fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.blue, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        counterStyle:
                            TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Description Field - USE TextEditingController
                    const Text(
                      'Details',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Please provide as much detail as possible (minimum 20 characters)',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      maxLines: 6,
                      maxLength: 1000,
                      onChanged: (value) =>
                          feedbackController.description.value = value,
                      decoration: InputDecoration(
                        hintText:
                            'Describe what happened, when it happened, and any steps to reproduce the issue...',
                        hintStyle:
                            TextStyle(color: Colors.grey[400], fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.blue, width: 2),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        counterStyle:
                            TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // File Upload Section (keep as is)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.blue.withOpacity(0.1), width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.attachment,
                                  color: Colors.blue[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Attachments (Optional)',
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color:
                                      feedbackController.selectedFiles.isEmpty
                                          ? Colors.orange[100]
                                          : Colors.green[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${feedbackController.selectedFiles.length}/5',
                                  style: TextStyle(
                                    color:
                                        feedbackController.selectedFiles.isEmpty
                                            ? Colors.orange[800]
                                            : Colors.green[800],
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Images only. Max 5 images, 5MB each.',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '📷 Supported formats: JPG, PNG, GIF, WEBP, BMP',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                          Text(
                            '📏 Max file size: 5MB per image',
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          if (feedbackController.selectedFiles.isEmpty)
                            InkWell(
                              onTap: () => feedbackController.pickFiles(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 32, horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.grey[300]!,
                                      width: 2,
                                      style: BorderStyle.solid),
                                ),
                                child: Column(
                                  children: [
                                    Icon(Icons.cloud_upload_outlined,
                                        color: Colors.grey[400], size: 40),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Click to upload images',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Images only: JPG, PNG, GIF, WEBP, BMP (Max 5MB each)',
                                      style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (feedbackController.selectedFiles.isNotEmpty) ...[
                            ...feedbackController.selectedFiles.map((file) =>
                                Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border:
                                        Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          feedbackController
                                              .getFileIcon(file.extension),
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              file.name,
                                              style: const TextStyle(
                                                color: Colors.black87,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            Text(
                                              feedbackController
                                                  .getFileSize(file.size),
                                              style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 18),
                                        color: Colors.grey[600],
                                        onPressed: () =>
                                            feedbackController.removeFile(file),
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                )),
                            const SizedBox(height: 8),
                            if (feedbackController.selectedFiles.length < 5)
                              OutlinedButton.icon(
                                onPressed: () => feedbackController.pickFiles(),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add more images'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.blue[700],
                                  side: BorderSide(
                                      color: Colors.blue.withOpacity(0.3)),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit Button - CLEAR TextEditingControllers ON SUCCESS
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: feedbackController.isSubmitting.value
                            ? null
                            : () async {
                                final success =
                                    await feedbackController.submitFeedback();
                                if (success) {
                                  // CLEAR THE TextEditingControllers
                                  subjectController.clear();
                                  descriptionController.clear();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                          disabledBackgroundColor: Colors.grey[300],
                        ),
                        child: feedbackController.isSubmitting.value
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.send, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Submit Feedback',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
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

  Widget _buildDailyLimitIndicator(WebFeedbackController controller) {
    final tracker = controller.dailyTracker.value!;
    final remaining = tracker.remainingReports;
    final exceeded = tracker.hasExceededLimit;

    Color indicatorColor;
    IconData indicatorIcon;

    if (exceeded) {
      indicatorColor = Colors.red;
      indicatorIcon = Icons.block;
    } else if (remaining == 1) {
      indicatorColor = Colors.orange;
      indicatorIcon = Icons.warning;
    } else {
      indicatorColor = Colors.green;
      indicatorIcon = Icons.check_circle;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: indicatorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: indicatorColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(indicatorIcon, color: indicatorColor, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                exceeded ? 'Limit Reached' : '$remaining/3 Remaining',
                style: TextStyle(
                  color: indicatorColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (!exceeded) ...[
                const SizedBox(height: 2),
                Text(
                  'Resets in ${controller.getTimeUntilReset()}',
                  style: TextStyle(
                    color: indicatorColor.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // NEW: Limit exceeded banner
  Widget _buildLimitExceededBanner(WebFeedbackController controller) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.info_outline, color: Colors.red[700], size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Limit Reached',
                  style: TextStyle(
                    color: Colors.red[900],
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'You\'ve submitted 3 reports today. You can submit more in ${controller.getTimeUntilReset()}.',
                  style: TextStyle(
                    color: Colors.red[800],
                    fontSize: 14,
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

  // Helper Widgets
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 17,
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
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!isLast) const SizedBox(height: 16),
      ],
    );
  }

// Helper method to format verification date
  String _formatVerificationDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return 'Unknown';

    try {
      final date = DateTime.parse(isoDate);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (e) {
      return 'Unknown';
    }
  }

  Widget _buildSecurityOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style:
                            TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              if (isSwitch)
                Switch(
                  value: value,
                  onChanged: (v) => _showSuccess('Setting updated'),
                  activeColor: iconColor,
                )
              else
                Icon(Icons.arrow_forward_ios,
                    size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog() async {
    final userId = storage.read("userId") ?? "";
    final userDocId = storage.read("userDocumentId") as String?;
    final currentName = storage.read("userName") ?? "";

    // Check verification status
    final authRepository = Get.find<AuthRepository>();
    final verificationStatus =
        await authRepository.getUserVerificationStatus(userId);

    final isVerified = verificationStatus['isVerified'] == true;
    final isPAWrtalVerified = verificationStatus['isPAWrtalVerified'] == true;
    final isClinicVerified = verificationStatus['isClinicVerified'] == true;

    // If PAWrtal verified, sync name first
    // if (isPAWrtalVerified && userDocId != null) {
    //   final synced =
    //       await authRepository.syncVerifiedNameToUserProfile(userId, userDocId);
    //   if (synced) {
    //     final verifiedName =
    //         await authRepository.getVerifiedNameFromIdVerification(userId);
    //     if (verifiedName != null && verifiedName.isNotEmpty) {
    //       await storage.write("userName", verifiedName);
    //       setState(() {}); // Refresh UI
    //       _showSuccess('Name updated from verified ID');
    //     }
    //   }
    // }

    final nameController =
        TextEditingController(text: storage.read("userName") ?? "");

    String currentPhone = storage.read("phone") ?? "09";
    if (currentPhone.isEmpty || currentPhone.trim().isEmpty) {
      currentPhone = "09";
    }
    final phoneController = TextEditingController(text: currentPhone);

    final nameError = Rx<String?>(null);
    final phoneError = Rx<String?>(null);
    final isLoading = false.obs;

    // Phone validation
    String? validatePhone(String phone) {
      if (phone.isEmpty) {
        return 'Phone number is required';
      }

      final cleanPhone = phone.replaceAll(' ', '');

      if (!cleanPhone.startsWith('09')) {
        return 'Please use Philippines format: 09XX XXX XXXX';
      }

      if (!RegExp(r'^09\d{9}$').hasMatch(cleanPhone)) {
        return 'Invalid Philippine phone number format';
      }

      return null;
    }

    // Format phone number
    String formatPhoneNumber(String phone) {
      String cleaned = phone.replaceAll(' ', '');

      if (cleaned.isEmpty || cleaned == '0') {
        return '09';
      }

      if (cleaned.startsWith('0') && !cleaned.startsWith('09')) {
        cleaned = '09${cleaned.substring(1)}';
      }

      if (!cleaned.startsWith('0')) {
        cleaned = '09$cleaned';
      }

      if (cleaned.length <= 4) {
        return cleaned;
      } else if (cleaned.length <= 7) {
        return '${cleaned.substring(0, 4)} ${cleaned.substring(4)}';
      } else if (cleaned.length <= 11) {
        return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 7)} ${cleaned.substring(7)}';
      } else {
        return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 7)} ${cleaned.substring(7, 11)}';
      }
    }

    // Name validation
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

    // Update profile
    Future<void> updateProfile() async {
      nameError.value = null;
      phoneError.value = null;

      final name = nameController.text.trim();
      final phone = phoneController.text.trim();

      bool hasError = false;

      // Only validate name if user can edit it
      if (!isVerified) {
        final nameValidation = validateName(name);
        if (nameValidation != null) {
          nameError.value = nameValidation;
          hasError = true;
        }
      }

      final phoneValidation = validatePhone(phone);
      if (phoneValidation != null) {
        phoneError.value = phoneValidation;
        hasError = true;
      }

      if (hasError) return;

      try {
        isLoading.value = true;

        if (userDocId == null || userDocId.isEmpty) {
          throw Exception('User document ID not found. Please log in again.');
        }

        // Prepare update data
        final updateData = <String, dynamic>{
          'phone': phone,
        };

        // Only update name if user is not verified
        if (!isVerified) {
          updateData['name'] = name;
        }

        await authRepository.updateUserProfile(
          documentId: userDocId,
          fields: updateData,
        );

        if (!isVerified && updateData.containsKey('name')) {
          await authRepository.updateAuthAccountName(updateData['name']);
        }

        // Update GetStorage (name only if not verified)
        if (!isVerified) {
          await storage.write("userName", name);
        }
        await storage.write("phone", phone);

        isLoading.value = false;

        Navigator.of(context).pop();
        setState(() {});

        _showSuccess('Profile updated successfully');

        nameController.dispose();
        phoneController.dispose();
      } catch (e) {
        isLoading.value = false;

        String errorMessage = 'Failed to update profile. Please try again.';

        if (e.toString().contains('Document') &&
            e.toString().contains('not found')) {
          errorMessage = 'User profile not found. Please log in again.';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Network error. Please check your connection.';
        }

        _showError(errorMessage);
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.edit_outlined,
                  color: Colors.blue[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Edit Profile',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verification status banner
                  if (isVerified) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isPAWrtalVerified
                              ? [Colors.green[50]!, Colors.green[100]!]
                              : [Colors.blue[50]!, Colors.blue[100]!],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isPAWrtalVerified
                              ? Colors.green[300]!
                              : Colors.blue[300]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPAWrtalVerified
                                ? Icons.verified_user
                                : Icons.local_hospital,
                            color: isPAWrtalVerified
                                ? Colors.green[700]
                                : Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isPAWrtalVerified
                                      ? 'PAWrtal Verified Account'
                                      : 'Clinic Verified Account',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isPAWrtalVerified
                                        ? Colors.green[800]
                                        : Colors.blue[800],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isPAWrtalVerified
                                      ? 'Your name is locked and matches your verified ID'
                                      : 'Your name is locked as verified by clinic staff',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isPAWrtalVerified
                                        ? Colors.green[700]
                                        : Colors.blue[700],
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Name Field
                  Obx(() => TextField(
                        controller: nameController,
                        enabled: !isVerified, // Disable if verified
                        maxLength: 100,
                        style: TextStyle(
                          color: isVerified ? Colors.grey[600] : Colors.black87,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          errorText: nameError.value,
                          errorMaxLines: 2,
                          counterText: '',
                          filled: isVerified,
                          fillColor: isVerified ? Colors.grey[100] : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color:
                                  isVerified ? Colors.grey[300]! : Colors.blue,
                              width: 2,
                            ),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          prefixIcon: Icon(
                            isVerified ? Icons.lock : Icons.person_outline,
                            color: isVerified ? Colors.grey[500] : null,
                          ),
                          suffixIcon: isVerified
                              ? Tooltip(
                                  message: isPAWrtalVerified
                                      ? 'Name verified by PAWrtal ID verification'
                                      : 'Name verified by clinic staff',
                                  child: Icon(
                                    isPAWrtalVerified
                                        ? Icons.verified_user
                                        : Icons.local_hospital,
                                    color: isPAWrtalVerified
                                        ? Colors.green[600]
                                        : Colors.blue[600],
                                    size: 20,
                                  ),
                                )
                              : null,
                        ),
                        onChanged: (value) {
                          if (nameError.value != null) {
                            nameError.value = null;
                          }
                        },
                      )),
                  const SizedBox(height: 20),

                  // Phone Field
                  Obx(() => TextField(
                        controller: phoneController,
                        maxLength: 13,
                        style: const TextStyle(color: Colors.black87),
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone Number (Philippines)',
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          hintText: '0XXX XXX XXXX',
                          hintStyle: TextStyle(color: Colors.grey[400]),
                          helperText: 'Format: 09 followed by 9 digits',
                          helperStyle:
                              TextStyle(color: Colors.grey[500], fontSize: 11),
                          errorText: phoneError.value,
                          errorMaxLines: 2,
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.blue, width: 2),
                          ),
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                        onChanged: (value) {
                          final formatted = formatPhoneNumber(value);
                          if (formatted != value) {
                            phoneController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(
                                  offset: formatted.length),
                            );
                          }
                          if (phoneError.value != null) {
                            phoneError.value = null;
                          }
                        },
                      )),
                  const SizedBox(height: 16),

                  // Info box
                  if (!isVerified)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
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
                              'Your name can be changed until you verify your account',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                nameController.dispose();
                phoneController.dispose();
              },
              child: const Text('Cancel'),
            ),
            Obx(() => ElevatedButton(
                  onPressed: isLoading.value ? null : updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                  child: isLoading.value
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Save Changes'),
                )),
          ],
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
      if (newPassword.isNotEmpty &&
          currentPassword.isNotEmpty &&
          newPassword == currentPassword) {
        newPasswordError.value =
            'New password must be different from current password';
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

        // Appwrite's updatePassword automatically verifies old password
        final authRepository = Get.find<AuthRepository>();
        await authRepository.appWriteProvider.account!.updatePassword(
          password: newPassword,
          oldPassword: currentPassword,
        );

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
        isLoading.value = false;

        String errorMessage = 'Failed to change password. Please try again.';

        // Handle specific Appwrite errors
        if (e.toString().contains('user_invalid_credentials') ||
            e.toString().contains('Invalid credentials') ||
            e.toString().contains('invalid_credentials')) {
          errorMessage = 'Current password is incorrect';
          currentPasswordError.value = errorMessage;
        } else if (e.toString().contains('password_recently_used')) {
          errorMessage =
              'This password was recently used. Please choose a different one.';
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
        padding: const EdgeInsets.only(left: 8, top: 4),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 14,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.lock_outline,
                  color: Colors.blue[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Change Password',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Password Requirements Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
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
                              'Password Requirements:',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildRequirement('At least 8 characters'),
                        _buildRequirement('One uppercase letter (A-Z)'),
                        _buildRequirement('One number (0-9)'),
                        _buildRequirement('One special character (!@#\$%^&*)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Current Password Field
                  Obx(() => TextField(
                        controller: currentPasswordController,
                        obscureText: !currentPasswordVisible.value,
                        maxLength: 50,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          counterText: '',
                          errorText: currentPasswordError.value,
                          errorMaxLines: 2,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              currentPasswordVisible.value
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              currentPasswordVisible.value =
                                  !currentPasswordVisible.value;
                            },
                          ),
                        ),
                        onChanged: (value) {
                          if (currentPasswordError.value != null) {
                            currentPasswordError.value = null;
                          }
                        },
                      )),
                  const SizedBox(height: 16),

                  // New Password Field
                  Obx(() => TextField(
                        controller: newPasswordController,
                        obscureText: !newPasswordVisible.value,
                        maxLength: 50,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          counterText: '',
                          errorText: newPasswordError.value,
                          errorMaxLines: 3,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              newPasswordVisible.value
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              newPasswordVisible.value =
                                  !newPasswordVisible.value;
                            },
                          ),
                        ),
                        onChanged: (value) {
                          if (newPasswordError.value != null) {
                            newPasswordError.value = null;
                          }
                        },
                      )),
                  const SizedBox(height: 16),

                  // Confirm New Password Field
                  Obx(() => TextField(
                        controller: confirmPasswordController,
                        obscureText: !confirmPasswordVisible.value,
                        maxLength: 50,
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          labelStyle: TextStyle(color: Colors.grey[600]),
                          counterText: '',
                          errorText: confirmPasswordError.value,
                          errorMaxLines: 2,
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              confirmPasswordVisible.value
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              confirmPasswordVisible.value =
                                  !confirmPasswordVisible.value;
                            },
                          ),
                        ),
                        onChanged: (value) {
                          if (confirmPasswordError.value != null) {
                            confirmPasswordError.value = null;
                          }
                        },
                      )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                currentPasswordController.dispose();
                newPasswordController.dispose();
                confirmPasswordController.dispose();
              },
              child: const Text('Cancel'),
            ),
            Obx(() => ElevatedButton(
                  onPressed: isLoading.value ? null : changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey,
                  ),
                  child: isLoading.value
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Change Password'),
                )),
          ],
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
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red[700]),
              const SizedBox(width: 8),
              const Text('Deactivate Account',
                  style: TextStyle(color: Colors.black87)),
            ],
          ),
          content: const Text(
            'Are you sure you want to deactivate your account? This action can be reversed by contacting support.',
            style: TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showWarning('Not yet implemented');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Deactivate'),
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
          title:
              const Text('Sign out', style: TextStyle(color: Colors.black87)),
          content: const Text('Are you sure you want to sign out?',
              style: TextStyle(color: Colors.black87)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                await LogoutHelper.logout();
              },
              child:
                  const Text('Sign out', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWebFileItemWithPreview(PlatformFile file) {
    final extension = file.extension?.toLowerCase() ?? '';
    final isImage =
        ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(extension);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Preview thumbnail
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[100]!, Colors.blue[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(
                Icons.photo_rounded,
                color: Colors.blue[700],
                size: 28,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 12,
                            color: Colors.blue[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Image',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      feedbackController.getFileSize(file.size),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '.${extension.toUpperCase()}',
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                feedbackController.removeFile(file);
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: Colors.red[600],
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

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

1. Go to the Clinics page
2. Select your preferred clinic
3. Choose an available time slot
4. Fill in the appointment details
5. Submit your request

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
    question: 'How do I view medical records?',
    answer: '''To view medical records:

1. Select your pet from the Pets page
2. Tap on "Medical Records"
3. View all vaccination and treatment history

Medical records are updated by veterinarians after each visit.''',
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
  }

  @override
  void dispose() {
    subjectController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  void _showSnackbar(String title, String message, Color backgroundColor) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
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
    final userPhone = storage.read("phone") ?? "+1 (555) 000-0000";
    final userBio = storage.read("bio") ?? "";
    final userJoinDate = storage.read("joinDate") ?? "January 2024";

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
                  Stack(
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
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.transparent,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Colors.blue[400]!, Colors.purple[500]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _showSnackbar('Info', 'Profile photo upload coming soon', Colors.blue),
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
                    ],
                  ),
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
              _buildModernInfoTile(
                icon: Icons.calendar_today_outlined,
                label: 'Member Since',
                value: userJoinDate,
                iconColor: Colors.orange,
                isLast: true,
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
          
          // About Card
          _buildModernCard(
            title: 'About',
            icon: Icons.info_outline,
            iconColor: Colors.indigo,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  userBio.isEmpty ? 'No bio added yet. Share something about yourself!' : userBio,
                  style: TextStyle(
                    color: userBio.isEmpty ? Colors.grey[500] : Colors.grey[700],
                    fontSize: 12,
                    fontStyle: userBio.isEmpty ? FontStyle.italic : FontStyle.normal,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            action: TextButton.icon(
              onPressed: () => _showEditBioDialog(userBio),
              icon: Icon(Icons.edit_outlined, size: 14, color: Colors.indigo[700]),
              label: Text('Edit', style: TextStyle(color: Colors.indigo[700], fontWeight: FontWeight.w600, fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                backgroundColor: Colors.indigo.withOpacity(0.08),
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
              _buildSecurityOption(
                icon: Icons.verified_user_outlined,
                title: 'Two-Factor Auth',
                subtitle: 'Extra security layer',
                color: Colors.green,
                onTap: () => _showSnackbar('Info', '2FA coming soon', Colors.blue),
              ),
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
          // Appearance Card
          _buildModernCard(
            title: 'Appearance',
            icon: Icons.palette_outlined,
            iconColor: Colors.purple,
            children: [
              _buildModernSettingTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'Switch between themes',
                iconColor: Colors.indigo,
                value: true,
              ),
              const SizedBox(height: 10),
              _buildModernSettingTile(
                icon: Icons.language_outlined,
                title: 'Language',
                subtitle: 'English (US)',
                iconColor: Colors.blue,
                isSwitch: false,
                onTap: () => _showSnackbar('Info', 'Language selection coming soon', Colors.blue),
              ),
              const SizedBox(height: 10),
              _buildModernSettingTile(
                icon: Icons.format_size_outlined,
                title: 'Text Size',
                subtitle: 'Adjust readability',
                iconColor: Colors.cyan,
                isSwitch: false,
                onTap: () => _showSnackbar('Info', 'Text size adjustment coming soon', Colors.blue),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Notifications Card
          _buildModernCard(
            title: 'Notifications',
            icon: Icons.notifications_outlined,
            iconColor: Colors.orange,
            children: [
              _buildModernSettingTile(
                icon: Icons.notifications_active_outlined,
                title: 'Push Notifications',
                subtitle: 'Real-time updates',
                iconColor: Colors.orange,
                value: true,
              ),
              const SizedBox(height: 10),
              _buildModernSettingTile(
                icon: Icons.email_outlined,
                title: 'Email Notifications',
                subtitle: 'Important updates via email',
                iconColor: Colors.red,
                value: false,
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
                                      onPressed: () => _showSnackbar('Thank you', 'Glad we could help!', Colors.green),
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
                                      onPressed: () => _showSnackbar('Feedback', 'We\'ll improve this', Colors.orange),
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
                        'Add images/videos if needed. Max 5 files.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '📷 Images: Max 5MB • 🎥 Videos: Max 25MB',
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
                                    'Images or Videos',
                                    style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                      ),
                      
                      // Display selected files
                      Obx(() => feedbackController.selectedFiles.isNotEmpty
                        ? Column(
                            children: [
                              ...feedbackController.selectedFiles.map((file) => _buildFileItem(file)).toList(),
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
                    onChanged: (v) => _showSnackbar('Settings', 'Setting updated', Colors.green),
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
    final phoneController = TextEditingController(text: storage.read("phone") ?? "");

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Edit Profile', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(fontSize: 13)),
            ),
            ElevatedButton(
              onPressed: () {
                storage.write("userName", nameController.text);
                storage.write("phone", phoneController.text);
                Navigator.of(context).pop();
                setState(() {});
                _showSnackbar('Success', 'Profile updated successfully', Colors.green);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save', style: TextStyle(fontSize: 13)),
            ),
          ],
        );
      },
    );
  }

  void _showEditBioDialog(String currentBio) {
    final bioController = TextEditingController(text: currentBio);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Edit Bio', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
          content: TextField(
            controller: bioController,
            maxLines: 4,
            maxLength: 200,
            style: const TextStyle(color: Colors.black87, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Tell us about yourself...',
              hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(fontSize: 13)),
            ),
            ElevatedButton(
              onPressed: () {
                storage.write("bio", bioController.text);
                Navigator.of(context).pop();
                setState(() {});
                _showSnackbar('Success', 'Bio updated successfully', Colors.green);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save', style: TextStyle(fontSize: 13)),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Change Password', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline, size: 20),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline, size: 20),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(fontSize: 13)),
            ),
            ElevatedButton(
              onPressed: () {
                if (newPasswordController.text == confirmPasswordController.text) {
                  Navigator.of(context).pop();
                  _showSnackbar('Success', 'Password changed successfully', Colors.green);
                } else {
                  _showSnackbar('Error', 'Passwords do not match', Colors.red);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Change Password', style: TextStyle(fontSize: 13)),
            ),
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
                _showSnackbar('Info', 'Account deactivation requires admin approval', Colors.orange);
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
}
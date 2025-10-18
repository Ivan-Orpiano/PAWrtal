import 'package:capstone_app/data/models/feedback_and_report_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/web/user_web/controllers/web_user_pfp_controller.dart';
import 'package:capstone_app/web/user_web/controllers/web_feedback_controller.dart';
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
    question: 'Log into your Facebook account',
    answer: '''Log in using your Facebook login information

1. Go to facebook.com
2. Click Email or phone number and enter one of the following:
   • Email: You can log in with any email that's listed on your Facebook account.
   • Phone number: If you have a mobile phone number confirmed on your account, you can enter it here (don't add any zeros before the country code, or any symbols).
   • Username: You can also log in with your username, if you created one.
3. Enter your password and click Log In.

You can also use a passkey instead of entering a password for a safer and more convenient way to log into your account.''',
  ),
  FAQItem(
    question: 'Log out of Facebook',
    answer: '''To log out of Facebook:

1. Click your profile picture in the top right
2. Select "Log Out" from the dropdown menu
3. You'll be logged out and returned to the login screen''',
  ),
  FAQItem(
    question: 'Manage logging in with accounts in Accounts Center',
    answer: '''You can manage all your connected accounts from Accounts Center:

1. Go to Settings & Privacy
2. Click on Accounts Center
3. Here you can add or remove accounts
4. Manage login settings across all your Meta accounts''',
  ),
  FAQItem(
    question: 'I don\'t know if I still have a Facebook account',
    answer: '''If you're not sure if you have an account:

1. Go to facebook.com/login/identify
2. Enter your email address or phone number
3. Facebook will tell you if an account exists
4. If found, you can reset your password to regain access''',
  ),
];

class WebSettingsAndEverythingPage extends StatefulWidget {
  final int initialIndex;
  
  const WebSettingsAndEverythingPage({super.key, this.initialIndex = 0});

  @override
  State<WebSettingsAndEverythingPage> createState() => _WebSettingsAndEverythingPageState();
}

class _WebSettingsAndEverythingPageState extends State<WebSettingsAndEverythingPage> {
  int selectedIndex = 0;
  final GetStorage storage = GetStorage();

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
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
          body: Column(
            children: [
              Container(
                height: 81,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.black26, width: 1)
                  )
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: _getResponsivePadding()),
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
                          _buildSidebarItem('Give Feedback', Icons.feedback_outlined, 3),
                          const Divider(color: Colors.grey),
                          _buildSidebarItem('Sign out', Icons.logout, -1, isDestructive: true),
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
            ]
          ),
        ),
      ),
    );
  }

  double _getResponsivePadding() => MediaQuery.of(context).size.width * 0.02;

  Widget _buildSidebarItem(String title, IconData icon, int index, {bool isDestructive = false}) {
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
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
      case 0: return _buildProfileContent();
      case 1: return _buildSettingsContent();
      case 2: return _buildHelpContent();
      case 3: return _buildFeedbackContent();
      default: return _buildProfileContent();
    }
  }

// Replace the _buildProfileContent() method in WebSettingsAndEverythingPage with this:

Widget _buildProfileContent() {
  final userEmail = storage.read("email") ?? "user@example.com";
  final userName = storage.read("userName") ?? "User";
  final userRole = storage.read("role") ?? "user";
  final userPhone = storage.read("phone") ?? "+1 (555) 000-0000";
  final userBio = storage.read("bio") ?? "";
  final userJoinDate = storage.read("joinDate") ?? "January 2024";
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
                    style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
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
              border: Border.all(color: Colors.blue.withOpacity(0.1), width: 1),
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
                              onTap: () => profilePictureController.pickProfilePicture(),
                              borderRadius: BorderRadius.circular(60),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(60),
                                child: profilePictureController.getPreviewImage(
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
                              onTap: () => profilePictureController.pickProfilePicture(),
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
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
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
                          Row(
                            children: [
                              Icon(Icons.email_outlined, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 6),
                              Text(userEmail, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
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
                                    Icon(Icons.workspace_premium, size: 14, color: Colors.blue[700]),
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
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: Colors.green[600],
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.green.withOpacity(0.5),
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
                        onPressed: () => profilePictureController.cancelChanges(),
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
                        onPressed: profilePictureController.isUploading.value
                            ? null
                            : () async {
                                // Get user document ID
                                final userDoc = await Get.find<AuthRepository>().getUserById(userId);
                                if (userDoc != null) {
                                  final newFileId = await profilePictureController.saveProfilePicture(
                                    userId,
                                    userDoc.$id,
                                  );
                                  if (newFileId != null) {
                                    // Update GetStorage with new profile picture ID
                                    storage.write('userProfilePictureId', newFileId);
                                    setState(() {});
                                  }
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
                                  valueColor: AlwaysStoppedAnimation<Color>(
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
            icon: Icon(Icons.edit_outlined, size: 16, color: Colors.blue[700]),
            label: Text('Edit Profile', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              backgroundColor: Colors.blue.withOpacity(0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        _buildModernCard(
          title: 'About',
          icon: Icons.info_outline,
          iconColor: Colors.indigo,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                userBio.isEmpty ? 'No bio added yet. Share something about yourself!' : userBio,
                style: TextStyle(
                  color: userBio.isEmpty ? Colors.grey[500] : Colors.grey[700],
                  fontSize: 14,
                  fontStyle: userBio.isEmpty ? FontStyle.italic : FontStyle.normal,
                  height: 1.6,
                ),
              ),
            ),
          ],
          action: TextButton.icon(
            onPressed: () => _showEditBioDialog(userBio),
            icon: Icon(Icons.edit_outlined, size: 16, color: Colors.indigo[700]),
            label: Text('Edit Bio', style: TextStyle(color: Colors.indigo[700], fontWeight: FontWeight.w600)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              backgroundColor: Colors.indigo.withOpacity(0.08),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              subtitle: 'Last changed 30 days ago',
              color: Colors.blue,
              onTap: _showChangePasswordDialog,
            ),
            const SizedBox(height: 12),
            _buildSecurityOption(
              icon: Icons.verified_user_outlined,
              title: 'Two-Factor Authentication',
              subtitle: 'Add an extra layer of security',
              color: Colors.green,
              onTap: () => _showSnackbar('Info', 'Two-factor authentication setup coming soon', Colors.blue),
            ),
          ],
        ),
        
        const SizedBox(height: 20),
        
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red[200]!, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Danger Zone',
                    style: TextStyle(color: Colors.red[800], fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Irreversible actions that require careful consideration',
                style: TextStyle(color: Colors.red[700], fontSize: 13),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _showDeactivateAccountDialog,
                icon: const Icon(Icons.person_off_outlined, size: 18),
                label: const Text('Deactivate Account'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red[700],
                  side: BorderSide(color: Colors.red[300]!, width: 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildSettingsContent() {
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
                  child: Icon(Icons.settings, color: Colors.purple[600], size: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Customize your application experience',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          _buildModernCard(
            title: 'Appearance',
            icon: Icons.palette_outlined,
            iconColor: Colors.purple,
            children: [
              _buildModernSettingTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'Switch between light and dark theme',
                iconColor: Colors.indigo,
                value: true,
              ),
              const SizedBox(height: 12),
              _buildModernSettingTile(
                icon: Icons.language_outlined,
                title: 'Language',
                subtitle: 'English (US)',
                iconColor: Colors.blue,
                isSwitch: false,
                onTap: () => _showSnackbar('Info', 'Language selection coming soon', Colors.blue),
              ),
              const SizedBox(height: 12),
              _buildModernSettingTile(
                icon: Icons.format_size_outlined,
                title: 'Text Size',
                subtitle: 'Adjust font size for better readability',
                iconColor: Colors.cyan,
                isSwitch: false,
                onTap: () => _showSnackbar('Info', 'Text size adjustment coming soon', Colors.blue),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          _buildModernCard(
            title: 'Notifications',
            icon: Icons.notifications_outlined,
            iconColor: Colors.orange,
            children: [
              _buildModernSettingTile(
                icon: Icons.notifications_active_outlined,
                title: 'Push Notifications',
                subtitle: 'Receive real-time updates and alerts',
                iconColor: Colors.orange,
                value: true,
              ),
              const SizedBox(height: 12),
              _buildModernSettingTile(
                icon: Icons.email_outlined,
                title: 'Email Notifications',
                subtitle: 'Get important updates via email',
                iconColor: Colors.red,
                value: false,
              ),
              const SizedBox(height: 12),
              _buildModernSettingTile(
                icon: Icons.vibration_outlined,
                title: 'Sound & Vibration',
                subtitle: 'Enable notification sounds',
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
                  child: Icon(Icons.help_outline, color: Colors.green[600], size: 24),
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
                      style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.4),
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
                    gradient: LinearGradient(colors: [Colors.blue[50]!, Colors.cyan[50]!]),
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
                        child: Icon(Icons.quiz_outlined, color: Colors.blue[700], size: 22),
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
                          onTap: () => setState(() => item.isExpanded = !item.isExpanded),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: item.isExpanded ? Colors.blue.withOpacity(0.04) : Colors.transparent,
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
                                    color: item.isExpanded ? Colors.blue[700] : Colors.grey[600],
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
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.04)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue.withOpacity(0.1)),
                                ),
                                child: Text(
                                  item.answer,
                                  style: TextStyle(color: Colors.grey[700], fontSize: 13, height: 1.7),
                                ),
                              ),
                              const SizedBox(height: 16),
                              
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _buildActionChip(
                                    icon: Icons.open_in_new,
                                    label: 'Open Article',
                                    color: Colors.blue,
                                    onTap: () => _showSnackbar('Info', 'Opening detailed article...', Colors.blue),
                                  ),
                                  _buildActionChip(
                                    icon: Icons.link,
                                    label: 'Copy Link',
                                    color: Colors.green,
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: item.answer));
                                      _showSnackbar('Success', 'Link copied!', Colors.green);
                                    },
                                  ),
                                ],
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
                                            onPressed: () => _showSnackbar('Thank you', 'Glad we could help!', Colors.green),
                                            icon: Icon(Icons.thumb_up_outlined, size: 16, color: Colors.green[700]),
                                            label: Text('Yes', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600)),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(color: Colors.green[300]!),
                                              backgroundColor: Colors.green.withOpacity(0.05),
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _showSnackbar('Feedback', 'We\'ll improve this', Colors.orange),
                                            icon: Icon(Icons.thumb_down_outlined, size: 16, color: Colors.grey[700]),
                                            label: Text('No', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600)),
                                            style: OutlinedButton.styleFrom(
                                              side: BorderSide(color: Colors.grey[300]!),
                                              backgroundColor: Colors.grey.withOpacity(0.05),
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
  // Initialize controller if not already done
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
              child: const Icon(Icons.feedback, color: Colors.white, size: 24),
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
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
        
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
                  final isSelected = feedbackController.selectedType.value == type;
                  return InkWell(
                    onTap: () => feedbackController.selectedType.value = type,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? _getFeedbackTypeColor(type).withOpacity(0.15) 
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
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
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
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
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
              
              // Subject Field
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
                maxLength: 100,
                onChanged: (value) => feedbackController.subject.value = value,
                decoration: InputDecoration(
                  hintText: 'e.g., App crashes when uploading images',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  counterStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Description Field
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
                maxLines: 6,
                maxLength: 1000,
                onChanged: (value) => feedbackController.description.value = value,
                decoration: InputDecoration(
                  hintText: 'Describe what happened, when it happened, and any steps to reproduce the issue...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  counterStyle: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // File Upload Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.1), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.attachment, color: Colors.blue[700], size: 20),
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
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: feedbackController.selectedFiles.isEmpty
                              ? Colors.orange[100]
                              : Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${feedbackController.selectedFiles.length}/5',
                            style: TextStyle(
                              color: feedbackController.selectedFiles.isEmpty
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
                      'At least one image or video is required. Max 5 files.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '📷 Images: Max 5MB (JPG, PNG, GIF)',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    Text(
                      '🎥 Videos: Max 25MB (MP4, MOV, AVI)',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    const SizedBox(height: 16),
                    
                    // Upload Button or File List
                    if (feedbackController.selectedFiles.isEmpty)
                      InkWell(
                        onTap: () => feedbackController.pickFiles(),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!, width: 2, style: BorderStyle.solid),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.cloud_upload_outlined, color: Colors.grey[400], size: 40),
                              const SizedBox(height: 12),
                              Text(
                                'Click to upload files',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Images (JPG, PNG, GIF) or Videos (MP4, MOV, AVI)',
                                style: TextStyle(color: Colors.grey[500], fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    // Display selected files
                    if (feedbackController.selectedFiles.isNotEmpty) ...[
                      ...feedbackController.selectedFiles.map((file) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                                    feedbackController.getFileSize(file.size),
                                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              color: Colors.grey[600],
                              onPressed: () => feedbackController.removeFile(file),
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
                          label: const Text('Add more files'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.blue[700],
                            side: BorderSide(color: Colors.blue.withOpacity(0.3)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: feedbackController.isSubmitting.value
                    ? null
                    : () async {
                        final success = await feedbackController.submitFeedback();
                        if (success) {
                          // Optionally show success dialog or navigate
                        }
                      },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey[300],
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
                          Icon(Icons.send, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Submit Feedback',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
                    const SizedBox(height: 2),
                    Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
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
                    Text(subtitle, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              if (isSwitch)
                Switch(
                  value: value,
                  onChanged: (v) => _showSnackbar('Settings', 'Setting updated', Colors.green),
                  activeColor: iconColor,
                )
              else
                Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: storage.read("userName") ?? "");
    final phoneController = TextEditingController(text: storage.read("phone") ?? "");

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Edit Profile', style: TextStyle(color: Colors.black87)),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: TextStyle(color: Colors.grey[600]),
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
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
              child: const Text('Save Changes'),
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
          title: const Text('Edit Bio', style: TextStyle(color: Colors.black87)),
          content: SizedBox(
            width: 400,
            child: TextField(
              controller: bioController,
              maxLines: 5,
              maxLength: 200,
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Tell us about yourself...',
                hintStyle: TextStyle(color: Colors.grey[500]),
                border: const OutlineInputBorder(),
                counterText: '',
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
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
              child: const Text('Save'),
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
          title: const Text('Change Password', style: TextStyle(color: Colors.black87)),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.black87),
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.black87),
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: Colors.black87),
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
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
              child: const Text('Change Password'),
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
          title: Row(
            children: [
              Icon(Icons.warning_amber, color: Colors.red[700]),
              const SizedBox(width: 8),
              const Text('Deactivate Account', style: TextStyle(color: Colors.black87)),
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
                _showSnackbar('Info', 'Account deactivation requires admin approval', Colors.orange);
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
          title: const Text('Sign out', style: TextStyle(color: Colors.black87)),
          content: const Text('Are you sure you want to sign out?', style: TextStyle(color: Colors.black87)),
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
              child: const Text('Sign out', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
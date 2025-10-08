import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class SettingsAndEverythingPage extends StatefulWidget {
  final int initialIndex;
  
  const SettingsAndEverythingPage({super.key, this.initialIndex = 0});

  @override
  State<SettingsAndEverythingPage> createState() => _SettingsAndEverythingPageState();
}

class _SettingsAndEverythingPageState extends State<SettingsAndEverythingPage> {
  int selectedIndex = 0;
  final GetStorage storage = GetStorage();

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
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.5),
                                    blurRadius: 3,
                                    spreadRadius: 1,
                                  ),
                                ],
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
          
          const SizedBox(height: 20),
          
          // Personal Information Card
          _buildMobileCard(
            title: 'Personal Information',
            icon: Icons.badge_outlined,
            iconColor: Colors.blue,
            children: [
              _buildMobileInfoTile(
                icon: Icons.person_outline,
                label: 'Full Name',
                value: userName,
                iconColor: Colors.blue,
              ),
              _buildMobileInfoTile(
                icon: Icons.email_outlined,
                label: 'Email Address',
                value: userEmail,
                iconColor: Colors.purple,
              ),
              _buildMobileInfoTile(
                icon: Icons.phone_outlined,
                label: 'Phone Number',
                value: userPhone,
                iconColor: Colors.green,
              ),
              _buildMobileInfoTile(
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                backgroundColor: Colors.blue.withOpacity(0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // About Card
          _buildMobileCard(
            title: 'About',
            icon: Icons.info_outline,
            iconColor: Colors.indigo,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Text(
                  userBio.isEmpty ? 'No bio added yet. Share something about yourself!' : userBio,
                  style: TextStyle(
                    color: userBio.isEmpty ? Colors.grey[500] : Colors.grey[700],
                    fontSize: 13,
                    fontStyle: userBio.isEmpty ? FontStyle.italic : FontStyle.normal,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            action: TextButton.icon(
              onPressed: () => _showEditBioDialog(userBio),
              icon: Icon(Icons.edit_outlined, size: 16, color: Colors.indigo[700]),
              label: Text('Edit Bio', style: TextStyle(color: Colors.indigo[700], fontWeight: FontWeight.w600)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                backgroundColor: Colors.indigo.withOpacity(0.08),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Account Security Card
          _buildMobileCard(
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
              const SizedBox(height: 10),
              _buildSecurityOption(
                icon: Icons.verified_user_outlined,
                title: 'Two-Factor Authentication',
                subtitle: 'Add an extra layer of security',
                color: Colors.green,
                onTap: () => _showSnackbar('Info', 'Two-factor authentication setup coming soon', Colors.blue),
              ),
            ],
          ),
          
          const SizedBox(height: 16),

          _buildActionCard(
            icon: Icons.logout_rounded,
            title: 'Sign Out',
            subtitle: 'Sign out from your account',
            color: Colors.red,
            onTap: _showLogoutDialog,
          ),
          
          const SizedBox(height: 16),
          // Danger Zone
          Container(
            padding: const EdgeInsets.all(18),
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
                      style: TextStyle(color: Colors.red[800], fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Irreversible actions that require careful consideration',
                  style: TextStyle(color: Colors.red[700], fontSize: 12),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _showDeactivateAccountDialog,
                    icon: const Icon(Icons.person_off_outlined, size: 16),
                    label: const Text('Deactivate Account'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red[700],
                      side: BorderSide(color: Colors.red[300]!, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
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
          // Appearance Settings
          _buildMobileCard(
            title: 'Appearance',
            icon: Icons.palette_outlined,
            iconColor: Colors.purple,
            children: [
              _buildMobileSettingTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'Switch between light and dark theme',
                iconColor: Colors.indigo,
                value: true,
              ),
              const SizedBox(height: 10),
              _buildMobileSettingTile(
                icon: Icons.language_outlined,
                title: 'Language',
                subtitle: 'English (US)',
                iconColor: Colors.blue,
                isSwitch: false,
                onTap: () => _showSnackbar('Info', 'Language selection coming soon', Colors.blue),
              ),
              const SizedBox(height: 10),
              _buildMobileSettingTile(
                icon: Icons.format_size_outlined,
                title: 'Text Size',
                subtitle: 'Adjust font size for better readability',
                iconColor: Colors.cyan,
                isSwitch: false,
                onTap: () => _showSnackbar('Info', 'Text size adjustment coming soon', Colors.blue),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Notifications Settings
          _buildMobileCard(
            title: 'Notifications',
            icon: Icons.notifications_outlined,
            iconColor: Colors.orange,
            children: [
              _buildMobileSettingTile(
                icon: Icons.notifications_active_outlined,
                title: 'Push Notifications',
                subtitle: 'Receive real-time updates and alerts',
                iconColor: Colors.orange,
                value: true,
              ),
              const SizedBox(height: 10),
              _buildMobileSettingTile(
                icon: Icons.email_outlined,
                title: 'Email Notifications',
                subtitle: 'Get important updates via email',
                iconColor: Colors.red,
                value: false,
              ),
              const SizedBox(height: 10),
              _buildMobileSettingTile(
                icon: Icons.vibration_outlined,
                title: 'Sound & Vibration',
                subtitle: 'Enable notification sounds',
                iconColor: Colors.purple,
                value: true,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Privacy & Security Settings
          _buildMobileCard(
            title: 'Privacy & Security',
            icon: Icons.shield_outlined,
            iconColor: Colors.green,
            children: [
              _buildMobileSettingTile(
                icon: Icons.analytics_outlined,
                title: 'Analytics & Data Collection',
                subtitle: 'Help us improve by sharing usage data',
                iconColor: Colors.blue,
                value: false,
              ),
              const SizedBox(height: 10),
              _buildMobileSettingTile(
                icon: Icons.cookie_outlined,
                title: 'Cookies',
                subtitle: 'Allow cookies for better experience',
                iconColor: Colors.brown,
                value: true,
              ),
              const SizedBox(height: 10),
              _buildMobileSettingTile(
                icon: Icons.visibility_off_outlined,
                title: 'Activity Status',
                subtitle: 'Show when you\'re active',
                iconColor: Colors.teal,
                value: true,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Advanced Settings
          _buildMobileCard(
            title: 'Advanced',
            icon: Icons.tune_outlined,
            iconColor: Colors.deepPurple,
            children: [
              _buildMobileSettingTile(
                icon: Icons.storage_outlined,
                title: 'Clear Cache',
                subtitle: 'Free up space by clearing cached data',
                iconColor: Colors.amber,
                isSwitch: false,
                onTap: () => _showSnackbar('Success', 'Cache cleared successfully', Colors.green),
              ),
              const SizedBox(height: 10),
              _buildMobileSettingTile(
                icon: Icons.download_outlined,
                title: 'Download Data',
                subtitle: 'Export your account information',
                iconColor: Colors.lightBlue,
                isSwitch: false,
                onTap: () => _showSnackbar('Info', 'Data export initiated', Colors.blue),
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
                              
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
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
                              
                              const SizedBox(height: 12),
                              
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Was this helpful?',
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: OutlinedButton.icon(
                                            onPressed: () => _showSnackbar('Thank you', 'Glad we could help!', Colors.green),
                                            icon: Icon(Icons.thumb_up_outlined, size: 14, color: Colors.green[700]),
                                            label: Text('Yes', style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.w600, fontSize: 12)),
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
                                            label: Text('No', style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600, fontSize: 12)),
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
          
          const SizedBox(height: 20),
          
          // Contact Support Cards
          _buildContactCard(
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: 'support@example.com',
            description: 'Get help via email',
            color: Colors.blue,
            onTap: () => _showSnackbar('Info', 'Opening email client...', Colors.blue),
          ),
          
          const SizedBox(height: 12),
          
          _buildContactCard(
            icon: Icons.chat_bubble_outline,
            title: 'Live Chat',
            subtitle: 'Available 9AM-5PM',
            description: 'Chat with our team',
            color: Colors.green,
            onTap: () => _showSnackbar('Info', 'Starting live chat...', Colors.blue),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackContent() {
    return StatefulBuilder(
      builder: (context, setState) {
        final TextEditingController feedbackController = TextEditingController();
        String selectedCategory = '';
        int starRating = 0;
        List<String> attachedFiles = [];
        bool isSubmitted = false;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isSubmitted) ...[
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
                      const Text(
                        'How would you rate your experience?',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          return GestureDetector(
                            onTap: () => setState(() => starRating = index + 1),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Icon(
                                index < starRating ? Icons.star : Icons.star_border,
                                color: index < starRating ? Colors.amber[600] : Colors.grey[400],
                                size: 32,
                              ),
                            ),
                          );
                        }),
                      ),
                      if (starRating > 0) ...[
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            _getRatingText(starRating),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      const Text(
                        'What is your feedback about?',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildCategoryChip('Bug Report', Icons.bug_report, Colors.red, selectedCategory, (c) => setState(() => selectedCategory = c)),
                          _buildCategoryChip('Feature Request', Icons.lightbulb_outline, Colors.orange, selectedCategory, (c) => setState(() => selectedCategory = c)),
                          _buildCategoryChip('Improvement', Icons.trending_up, Colors.blue, selectedCategory, (c) => setState(() => selectedCategory = c)),
                          _buildCategoryChip('Complaint', Icons.sentiment_dissatisfied, Colors.purple, selectedCategory, (c) => setState(() => selectedCategory = c)),
                          _buildCategoryChip('Question', Icons.help_outline, Colors.green, selectedCategory, (c) => setState(() => selectedCategory = c)),
                          _buildCategoryChip('Other', Icons.more_horiz, Colors.grey, selectedCategory, (c) => setState(() => selectedCategory = c)),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      const Text(
                        'Tell us more',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Please provide as much detail as possible',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: feedbackController,
                        maxLines: 5,
                        maxLength: 500,
                        style: const TextStyle(color: Colors.black87, fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Share your thoughts, suggestions, or report an issue...',
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                          filled: true,
                          fillColor: Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                          ),
                          counterStyle: TextStyle(color: Colors.grey[500], fontSize: 11),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.blue.withOpacity(0.1), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.attachment, color: Colors.blue[700], size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Attachments',
                                  style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${attachedFiles.length}/5',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            
                            if (attachedFiles.isEmpty)
                              InkWell(
                                onTap: () => _selectFiles(setState, attachedFiles),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!, width: 1),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(Icons.cloud_upload_outlined, color: Colors.grey[400], size: 32),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Click to upload files',
                                        style: TextStyle(
                                          color: Colors.grey[700],
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'PNG, JPG, PDF up to 10MB',
                                        style: TextStyle(color: Colors.grey[500], fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            
                            if (attachedFiles.isNotEmpty) ...[
                              ...attachedFiles.map((file) => Container(
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
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(_getFileIcon(file), color: Colors.blue[700], size: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            file,
                                            style: const TextStyle(
                                              color: Colors.black87,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            _getFileSize(file),
                                            style: TextStyle(color: Colors.grey[600], fontSize: 10),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close, size: 16),
                                      color: Colors.grey[600],
                                      onPressed: () => setState(() => attachedFiles.remove(file)),
                                      padding: const EdgeInsets.all(4),
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              )),
                              const SizedBox(height: 8),
                              if (attachedFiles.length < 5)
                                OutlinedButton.icon(
                                  onPressed: () => _selectFiles(setState, attachedFiles),
                                  icon: const Icon(Icons.add, size: 14),
                                  label: const Text('Add more files', style: TextStyle(fontSize: 12)),
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
                      
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_validateFeedback(feedbackController.text, selectedCategory, starRating)) {
                              setState(() => isSubmitted = true);
                              _showSnackbar('Success', 'Thank you! Your feedback has been submitted.', Colors.green);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[600],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          child: const Row(
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
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                _buildSuccessState(() => setState(() => isSubmitted = false)),
              ],
              
              const SizedBox(height: 16),
              
              // Info Cards
              _buildInfoCard('Response Time', '24-48 hours', Icons.access_time, Colors.blue),
              const SizedBox(height: 12),
              _buildInfoCard('Privacy', 'Your data is secure', Icons.lock_outline, Colors.green),
            ],
          ),
        );
      },
    );
  }

  // Helper Widgets
  Widget _buildMobileCard({
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

  Widget _buildMobileInfoTile({
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
                  const SizedBox(height: 3),
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

  Widget _buildMobileSettingTile({
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

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 15,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [color.withOpacity(0.2), color.withOpacity(0.1)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
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
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(description, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, size: 16, color: color),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(
    String label,
    IconData icon,
    Color color,
    String selectedCategory,
    Function(String) onSelect,
  ) {
    final isSelected = selectedCategory == label;
    
    return InkWell(
      onTap: () => onSelect(label),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey[600], size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey[700],
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessState(VoidCallback onNewFeedback) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_circle, color: Colors.green[600], size: 48),
          ),
          const SizedBox(height: 20),
          const Text(
            'Feedback Submitted!',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Thank you for taking the time to share your feedback.\nWe\'ll review it and get back to you soon.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.5),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: onNewFeedback,
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Submit Another Feedback'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue[700],
              side: BorderSide(color: Colors.blue[300]!),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
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
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1: return 'Poor - We\'ll do better';
      case 2: return 'Fair - Needs improvement';
      case 3: return 'Good - Meeting expectations';
      case 4: return 'Very Good - Exceeding expectations';
      case 5: return 'Excellent - Outstanding experience!';
      default: return '';
    }
  }

  String _getFileSize(String fileName) {
    final random = fileName.length % 3;
    switch (random) {
      case 0: return '2.4 MB';
      case 1: return '856 KB';
      default: return '1.2 MB';
    }
  }

  bool _validateFeedback(String message, String category, int rating) {
    if (rating == 0) {
      _showSnackbar('Required', 'Please rate your experience', Colors.orange);
      return false;
    }
    if (category.isEmpty) {
      _showSnackbar('Required', 'Please select a category', Colors.orange);
      return false;
    }
    if (message.trim().isEmpty) {
      _showSnackbar('Required', 'Please enter your feedback message', Colors.orange);
      return false;
    }
    if (message.trim().length < 10) {
      _showSnackbar('Too Short', 'Please provide more details (at least 10 characters)', Colors.orange);
      return false;
    }
    return true;
  }

  void _selectFiles(StateSetter setState, List<String> attachedFiles) {
    List<String> sampleFiles = [
      'screenshot.png',
      'error_log.txt',
      'bug_report.pdf',
      'feature_request.doc'
    ];
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('Select Files', style: TextStyle(color: Colors.black87)),
          content: SizedBox(
            width: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: sampleFiles.map((fileName) => ListTile(
                leading: Icon(_getFileIcon(fileName), color: Colors.blue),
                title: Text(fileName, style: const TextStyle(color: Colors.black87)),
                onTap: () {
                  if (!attachedFiles.contains(fileName)) {
                    setState(() => attachedFiles.add(fileName));
                  }
                  Navigator.of(context).pop();
                  _showSnackbar('Success', 'File "$fileName" attached', Colors.green);
                },
              )).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  IconData _getFileIcon(String fileName) {
    String extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'png':
      case 'jpg':
      case 'jpeg':
      case 'gif':
        return Icons.image;
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      default:
        return Icons.insert_drive_file;
    }
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
          content: TextField(
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
          content: SingleChildScrollView(
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Sign Out',
            style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
          ),
          content: const Text(
            'Are you sure you want to sign out?',
            style: TextStyle(color: Colors.black87),
          ),
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
              child: const Text(
                'Sign Out',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }
}
  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
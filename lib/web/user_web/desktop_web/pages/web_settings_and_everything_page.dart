import 'package:capstone_app/web/user_web/desktop_web/components/appbar_components/web_notification_icon.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/appbar_components/web_profile_icon.dart';
import 'package:capstone_app/web/user_web/desktop_web/components/dashboard_components/web_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone_app/utils/logout_helper.dart';

class WebSettingsAndEverythingPage extends StatefulWidget {
  final String? initialSelection;
  
  const WebSettingsAndEverythingPage({super.key, this.initialSelection});

  @override
  State<WebSettingsAndEverythingPage> createState() => _WebSettingsAndEverythingPageState();
}

class _WebSettingsAndEverythingPageState extends State<WebSettingsAndEverythingPage> {
  String selectedItem = 'Profile';
  final GetStorage storage = GetStorage();

  @override
  void initState() {
    super.initState();
    
    // Set initial selection based on parameter
    if (widget.initialSelection != null) {
      selectedItem = widget.initialSelection!;
    }
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
      onPopInvokedWithResult: (bool didPop, Object? result) {
        // Handle any cleanup if needed when popping
      },
      child: KeyboardListener(
        focusNode: FocusNode(),
        autofocus: true,
        onKeyEvent: (KeyEvent event) {
          // Handle keyboard shortcuts without interfering with browser
          if (event is KeyDownEvent) {
            // Prevent certain browser shortcuts from causing issues
            if (event.logicalKey == LogicalKeyboardKey.keyS && 
                (HardwareKeyboard.instance.isControlPressed || 
                 HardwareKeyboard.instance.isMetaPressed)) {
              // Consume the event to prevent "page not found" error
              return;
            }
            // Handle Escape key to go back
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
              // Custom Header
              Container(
                height: 81,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.black26,
                      width: 1
                    )
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
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: Image.asset(
                                'lib/images/PAWrtal_logo.png',
                                width: 150,
                                height: 100,
                              ),
                            ),
                            const Spacer(flex: 1),
                            const Expanded(
                              flex: 2,
                              child: WebSearchBar(width: 380),
                            ),
                            const Spacer(flex: 1),
                            WebNotificationIcon(
                              right: _getNotifRight(),
                              top: 70,
                              width: 500,
                            ),
                            WebProfileIcon(
                              right: _getIconRight(),
                              top: 70,
                              width: 250,
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Main Content
              Expanded(
                child: Row(
                  children: [
                    // Left Sidebar
                    Container(
                      width: 240,
                      color: Colors.white,
                      child: Column(
                        children: [
                          _buildSidebarItem('Profile', Icons.person),
                          _buildSidebarItem('Settings', Icons.settings),
                          _buildSidebarItem('Help', Icons.help_outline),
                          _buildSidebarItem('Send feedback', Icons.feedback_outlined),
                          const Divider(color: Colors.grey),
                          _buildSidebarItem('Sign out', Icons.logout, isDestructive: true),
                        ],
                      ),
                    ),
                    // Right Content Area
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

  // Helper methods for responsive design
  double _getResponsivePadding() {
    return MediaQuery.of(context).size.width * 0.02;
  }

  double _getNotifRight() {
    return 75.0;
  }

  double _getIconRight() {
    return 75.0;
  }

  Widget _buildSidebarItem(String title, IconData icon, {bool isDestructive = false}) {
    final isSelected = selectedItem == title;
    
    return InkWell(
      onTap: () {
        if (title == 'Sign out') {
          _showLogoutDialog();
        } else {
          // Update selected item
          setState(() {
            selectedItem = title;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.transparent,
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : (isSelected ? Colors.blue : Colors.grey[600]),
              size: 20,
            ),
            const SizedBox(width: 24),
            Text(
              title,
              style: TextStyle(
                color: isDestructive ? Colors.red : (isSelected ? Colors.blue : Colors.grey[700]),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentArea() {
    switch (selectedItem) {
      case 'Profile':
        return _buildProfileContent();
      case 'Settings':
        return _buildSettingsContent();
      case 'Help':
        return _buildHelpContent();
      case 'Send feedback':
        return _buildFeedbackContent();
      default:
        return _buildProfileContent();
    }
  }

  Widget _buildProfileContent() {
    final userEmail = storage.read("email") ?? "user@example.com";
    final userName = storage.read("userName") ?? "User";
    final userRole = storage.read("role") ?? "user";

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your profile',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose how you appear and what you see on this platform',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                      radius: 40,
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userEmail,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              userRole.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    _showSnackbar(
                      'Info',
                      'Edit profile functionality coming soon',
                      Colors.blue,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Edit Profile'),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your application preferences',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          _buildSettingsSection('Appearance', [
            _buildSettingItem('Dark mode', 'Use dark theme', true),
            _buildSettingItem('Language', 'English', false),
          ]),
          const SizedBox(height: 24),
          _buildSettingsSection('Notifications', [
            _buildSettingItem('Push notifications', 'Receive notifications', true),
            _buildSettingItem('Email notifications', 'Get updates via email', false),
          ]),
          const SizedBox(height: 24),
          _buildSettingsSection('Privacy', [
            _buildSettingItem('Data collection', 'Allow analytics', false),
            _buildSettingItem('Cookies', 'Accept cookies', true),
          ]),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSettingItem(String title, String subtitle, bool isEnabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: (value) {
              // Handle switch toggle
              _showSnackbar(
                'Settings',
                'Setting updated successfully',
                Colors.green,
              );
            },
            activeColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildHelpContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Help & Support',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get help and find answers to common questions',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          _buildHelpSection('Frequently Asked Questions', [
            'How do I reset my password?',
            'How do I change my profile information?',
            'How do I delete my account?',
            'How do I contact support?',
          ]),
          const SizedBox(height: 24),
          _buildHelpSection('Contact Support', [
            'Email: support@example.com',
            'Phone: +1 (555) 123-4567',
            'Live Chat: Available 9AM-5PM',
          ]),
        ],
      ),
    );
  }

  Widget _buildHelpSection(String title, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              item,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildFeedbackContent() {
    final TextEditingController feedbackController = TextEditingController();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Send Feedback',
            style: TextStyle(
              color: Colors.black87,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Help us improve by sharing your thoughts and suggestions',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'What would you like to tell us?',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                const DropdownMenu(
                  width: 300,
                  enableSearch: false,
                  label: Text(
                    "Select kind of problem"
                  ),
                  inputDecorationTheme: InputDecorationTheme(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15))
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15))
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15))
                    ),
                  ),
                  menuStyle: MenuStyle(
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15))
                      )
                    ),
                    backgroundColor: WidgetStatePropertyAll(
                      Colors.white,
                    )
                  ),
                  dropdownMenuEntries: [
                    DropdownMenuEntry(value: Text(""), label: "Bug"),
                    DropdownMenuEntry(value: Text(""), label: "Feature"),
                    DropdownMenuEntry(value: Text(""), label: "Complaint"),
                    DropdownMenuEntry(value: Text(""), label: "Question"),
                  ],
                ),
                const SizedBox(height: 16,),
                TextField(
                  controller: feedbackController,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Enter your feedback here...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (feedbackController.text.trim().isNotEmpty) {
                      _showSnackbar(
                        'Success',
                        'Thank you for your feedback!',
                        Colors.green,
                      );
                      feedbackController.clear();
                    } else {
                      _showSnackbar(
                        'Error',
                        'Please enter your feedback before submitting',
                        Colors.orange,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Send Feedback'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Sign out',
            style: TextStyle(color: Colors.black87),
          ),
          content: const Text(
            'Are you sure you want to sign out?',
            style: TextStyle(color: Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous page
                await LogoutHelper.logout();
              },
              child: const Text(
                'Sign out',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
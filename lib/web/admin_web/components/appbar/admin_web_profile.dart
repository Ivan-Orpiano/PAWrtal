import 'package:capstone_app/utils/logout_helper.dart';
import 'package:capstone_app/web/admin_web/pages/admin_settings_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class AdminWebProfile extends StatefulWidget {
  final double? right;
  final double? top;
  final double? width;

  const AdminWebProfile(
      {super.key, this.right = 75, this.top = 70, this.width = 250});

  @override
  State<AdminWebProfile> createState() => _AdminWebProfileState();
}

class _AdminWebProfileState extends State<AdminWebProfile> {
  OverlayEntry? _overlayEntry;
  final GetStorage storage = GetStorage();

  void _togglePopup(BuildContext context) {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry(context);
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      _closePopup();
    }
  }

  void _closePopup() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _navigateToAdminSettings(int index) {
    _closePopup();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => AdminSettingsPage(initialIndex: index),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                _closePopup();
                await LogoutHelper.logout();
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  OverlayEntry _createOverlayEntry(BuildContext context) {
    final userEmail = storage.read("email") ?? "admin@example.com";
    final userName = storage.read("name") ?? "Admin User";
    final userRole = storage.read("role") ?? "admin";
    final clinicName = storage.read("clinicName") ?? "Clinic";

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closePopup,
              child: Container(),
            ),
          ),
          Positioned(
            right: widget.right,
            top: widget.top,
            width: widget.width,
            child: Material(
              elevation: 5,
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.purple.withOpacity(0.7),
                        child: Text(
                          userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(
                        userName,
                        style: const TextStyle(
                            color: Colors.black87, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userEmail,
                            style: const TextStyle(
                                color: Colors.black87, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${userRole.toUpperCase()} • $clinicName',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.black87, height: 1),
                    SizedBox(
                      width: double.infinity,
                      child: _popupItem(
                        "Profile",
                        Icons.person_outline,
                        () {
                          _navigateToAdminSettings(0);
                        },
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: _popupItem(
                        "Settings",
                        Icons.settings_outlined,
                        () {
                          _navigateToAdminSettings(1);
                        },
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: _popupItem(
                        "Help & Support",
                        Icons.help_outline,
                        () {
                          _navigateToAdminSettings(2);
                        },
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: _popupItem(
                        "Send Feedback",
                        Icons.feedback_outlined,
                        () {
                          _navigateToAdminSettings(3);
                        },
                      ),
                    ),
                    const Divider(color: Colors.black87, height: 1),
                    SizedBox(
                      width: double.infinity,
                      child: _popupItem(
                        "Sign out",
                        Icons.logout_outlined,
                        () {
                          Navigator.pop(context);
                          _showLogoutDialog(context);
                        },
                        isDestructive: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _popupItem(
    String text,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isDestructive ? Colors.red[600] : Colors.grey[700],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: isDestructive ? Colors.red[600] : Colors.black87,
                  fontSize: 13,
                  fontWeight: isDestructive ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = storage.read("email") ?? "admin@example.com";
    final userName = storage.read("name") ?? "Admin User";

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Tooltip(
        message: '$userName ($userEmail)',
        child: InkWell(
          onTap: () => _togglePopup(context),
          borderRadius: BorderRadius.circular(50),
          child: CircleAvatar(
            backgroundColor: Colors.purple.withOpacity(0.7),
            radius: 17.5,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

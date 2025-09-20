import 'package:capstone_app/utils/logout_helper.dart';
import 'package:capstone_app/web/user_web/desktop_web/pages/web_settings_and_everything_page.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class WebProfileIcon extends StatefulWidget {
  final double? right;
  final double? top;
  final double? width;

  const WebProfileIcon(
      {super.key, this.right = 75, this.top = 70, this.width = 250});

  @override
  State<WebProfileIcon> createState() => _WebProfileIconState();
}

class _WebProfileIconState extends State<WebProfileIcon> {
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

  // Navigate to settings page with specific section - Updated to use named routes
  void _navigateToSettings(String section) {
    _closePopup();
    Get.toNamed(Routes.webSettings, parameters: {'initialSelection': section});
  }

  OverlayEntry _createOverlayEntry(BuildContext context) {
    final userEmail = storage.read("email") ?? "user@example.com";
    final userName = storage.read("userName") ?? "User";
    final userRole = storage.read("role") ?? "user";

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
                      leading: const CircleAvatar(
                        backgroundColor: Color.fromARGB(255, 81, 115, 153),
                        child: Icon(
                          Icons.person,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(
                        userName,
                        style: const TextStyle(color: Colors.black87),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userEmail,
                            style: const TextStyle(color: Colors.black87),
                          ),
                          Text(
                            userRole.toUpperCase(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.black87),
                    SizedBox(
                      width: double.infinity,
                      child: _popupItem("Profile", () {
                        _navigateToSettings("Profile");
                      }),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: _popupItem("Settings", () {
                        _navigateToSettings("Settings");
                      }),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: _popupItem("Help", () {
                        _navigateToSettings("Help");
                      }),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: _popupItem("Send feedback", () {
                        _navigateToSettings("Send feedback");
                      }),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: _popupItem("Sign out", () {
                        _showLogoutDialog(context);
                      }),
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

  Widget _popupItem(String text, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8),
        child: Text(text, style: const TextStyle(color: Colors.black87)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: InkWell(
        onTap: () => _togglePopup(context),
        child: const CircleAvatar(
          backgroundColor: Color.fromARGB(255, 81, 115, 153),
          radius: 17.5,
          child: Icon(
            Icons.person,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }
}
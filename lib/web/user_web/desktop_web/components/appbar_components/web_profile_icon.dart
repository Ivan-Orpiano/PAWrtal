import 'package:capstone_app/utils/logout_helper.dart';
import 'package:capstone_app/web/user_web/responsive_page_handlers/web_settings_and_everything_page_handler.dart';
import 'package:flutter/material.dart';
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
  Size? _lastScreenSize;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Track screen size changes and close popup if size changes significantly
    final currentSize = MediaQuery.of(context).size;
    if (_lastScreenSize != null && _overlayEntry != null) {
      // Check if screen width changed enough to trigger layout change
      // Typically mobile breakpoint is around 600-800px
      final wasDesktop = _lastScreenSize!.width >= 800;
      final isNowDesktop = currentSize.width >= 800;
      
      if (wasDesktop != isNowDesktop) {
        // Layout changed from desktop to mobile or vice versa
        _closePopup();
      }
    }
    _lastScreenSize = currentSize;
  }

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

  @override
  void dispose() {
    _closePopup();
    super.dispose();
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

  // Navigate to settings page with specific index
  void _navigateToSettings(int index) {
    _closePopup();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => WebSettingsAndEverythingPageHandler(
          initialIndex: index,
        ),
      ),
    );
  }

  OverlayEntry _createOverlayEntry(BuildContext context) {
    final userEmail = storage.read("email") ?? "user@example.com";
    final userName = storage.read("userName") ?? "User";
    final userRole = storage.read("role") ?? "user";

    return OverlayEntry(
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) {
          // Auto-close if screen becomes too small for desktop layout
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (constraints.maxWidth < 800 && _overlayEntry != null) {
              _closePopup();
            }
          });

          return Stack(
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
                            _navigateToSettings(0);
                          }),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: _popupItem("Settings", () {
                            _navigateToSettings(1);
                          }),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: _popupItem("Help & Support", () {
                            _navigateToSettings(2);
                          }),
                        ),
                        SizedBox(
                          width: double.infinity,
                          child: _popupItem("Give feedback", () {
                            _navigateToSettings(3);
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
          );
        },
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
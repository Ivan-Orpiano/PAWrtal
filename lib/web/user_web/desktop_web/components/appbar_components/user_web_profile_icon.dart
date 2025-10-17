import 'package:appwrite/models.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/data/id_verification/screens/id_verification_screen.dart';
import 'package:capstone_app/utils/logout_helper.dart';
import 'package:capstone_app/web/user_web/responsive_page_handlers/web_settings_and_everything_page_handler.dart';
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
  final AppWriteProvider appWriteProvider = AppWriteProvider();
  final AuthRepository authRepository = Get.find<AuthRepository>();
  Size? _lastScreenSize;
  
  User? currentUser;
  bool isIdVerified = false;
  bool isLoadingVerification = true;

  @override
  void initState() {
    super.initState();
    _loadUserVerificationStatus();
  }

  Future<void> _loadUserVerificationStatus() async {
    try {
      final user = await appWriteProvider.getUser();
      if (user != null) {
        final verificationStatus =
            await appWriteProvider.getUserVerificationStatus(user.$id);

        if (mounted) {
          setState(() {
            currentUser = user;
            isIdVerified = verificationStatus['isVerified'] as bool? ?? false;
            isLoadingVerification = false;
          });
        }
      }
    } catch (e) {
      print('Error loading verification status: $e');
      if (mounted) {
        setState(() {
          isLoadingVerification = false;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentSize = MediaQuery.of(context).size;
    if (_lastScreenSize != null && _overlayEntry != null) {
      final wasDesktop = _lastScreenSize!.width >= 800;
      final isNowDesktop = currentSize.width >= 800;
      
      if (wasDesktop != isNowDesktop) {
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                _closePopup();
                await LogoutHelper.logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

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

  Future<void> _handleVerifyNow() async {
    if (currentUser == null) return;
    
    _closePopup();
    
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => IdVerificationScreen(
          userId: currentUser!.$id,
          email: currentUser!.email,
          authRepository: authRepository,
        ),
      ),
    );

    // Refresh verification status if verification was completed
    if (result == true) {
      await _loadUserVerificationStatus();
    }
  }

  OverlayEntry _createOverlayEntry(BuildContext context) {
    final userEmail = storage.read("email") ?? "user@example.com";
    final userName = storage.read("userName") ?? "User";
    final userRole = storage.read("role") ?? "user";
    
    // Determine if user should show ID verification (only for regular users, not admin/staff)
    final shouldShowIdVerification =
        userRole == 'customer' || userRole == 'user';

    return OverlayEntry(
      builder: (context) => LayoutBuilder(
        builder: (context, constraints) {
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
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.transparent,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Colors.grey.shade50,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User Profile Header
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color.fromARGB(255, 81, 115, 153),
                                        Color.fromARGB(255, 95, 135, 175),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName,
                                        style: const TextStyle(
                                          color: Colors.black87,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        userEmail,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color.fromARGB(255, 81, 115, 153).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          userRole.toUpperCase(),
                                          style: const TextStyle(
                                            color: Color.fromARGB(255, 81, 115, 153),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // ID Verification Status (only for regular users)
                          if (shouldShowIdVerification && !isLoadingVerification)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isIdVerified
                                      ? const Color(0xFF4CAF50).withOpacity(0.1)
                                      : const Color(0xFFFF9800).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isIdVerified
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFFFF9800),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isIdVerified
                                          ? Icons.verified_user_rounded
                                          : Icons.badge_outlined,
                                      color: isIdVerified
                                          ? const Color(0xFF4CAF50)
                                          : const Color(0xFFFF9800),
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isIdVerified ? "ID Verified" : "ID Not Verified",
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isIdVerified
                                              ? const Color(0xFF4CAF50)
                                              : const Color(0xFFFF9800),
                                        ),
                                      ),
                                    ),
                                    if (!isIdVerified)
                                      GestureDetector(
                                        onTap: _handleVerifyNow,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1976D2),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            "Verify Now",
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Divider(color: Colors.grey.shade300, height: 1),
                          ),
                          _popupItem(Icons.person_outline, "Profile", () {
                            _navigateToSettings(0);
                          }),
                          _popupItem(Icons.settings_outlined, "Settings", () {
                            _navigateToSettings(1);
                          }),
                          _popupItem(Icons.help_outline, "Help", () {
                            _navigateToSettings(2);
                          }),
                          _popupItem(Icons.feedback_outlined, "Give feedback", () {
                            _navigateToSettings(3);
                          }),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: Divider(color: Colors.grey.shade300, height: 1),
                          ),
                          _popupItem(Icons.logout_rounded, "Sign out", () {
                            _showLogoutDialog(context);
                          }, isLogout: true),
                        ],
                      ),
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

  Widget _popupItem(IconData icon, String text, VoidCallback onTap, {bool isLogout = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          hoverColor: isLogout 
              ? Colors.red.withOpacity(0.08) 
              : const Color.fromARGB(255, 81, 115, 153).withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isLogout ? Colors.red.shade700 : Colors.grey[700],
                ),
                const SizedBox(width: 12),
                Text(
                  text,
                  style: TextStyle(
                    color: isLogout ? Colors.red.shade700 : Colors.black87,
                    fontSize: 14,
                    fontWeight: isLogout ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
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
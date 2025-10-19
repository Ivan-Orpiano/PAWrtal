import 'package:capstone_app/utils/logout_helper.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:capstone_app/web/admin_web/pages/admin_settings_page.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
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
  late AuthRepository _authRepository;

  String _cachedClinicName = 'Clinic';
  String _cachedProfilePictureId = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _authRepository = Get.find<AuthRepository>();
    _loadClinicDataFromStorage();
    // Load clinic data from database immediately on init
    _initializeClinicData();
  }

  void _loadClinicDataFromStorage() {
    _cachedClinicName = storage.read("clinicName") as String? ?? 'Clinic';
    _cachedProfilePictureId =
        storage.read("clinicProfilePictureId") as String? ?? '';
  }

  /// Initialize clinic data from database on first load
  Future<void> _initializeClinicData() async {
    try {
      final clinicId = storage.read("clinicId") as String?;
      if (clinicId == null || clinicId.isEmpty) {
        _isInitialized = true;
        return;
      }

      final clinicDoc = await _authRepository.getClinicById(clinicId);
      if (clinicDoc != null) {
        final newClinicName = clinicDoc.data['clinicName'] ?? 'Clinic';
        final newProfilePictureId = clinicDoc.data['profilePictureId'] ?? '';

        if (mounted) {
          setState(() {
            _cachedClinicName = newClinicName;
            _cachedProfilePictureId = newProfilePictureId;
            _isInitialized = true;
          });
        }

        // Update storage for next time
        storage.write('clinicName', newClinicName);
        storage.write('clinicProfilePictureId', newProfilePictureId);
      } else {
        _isInitialized = true;
      }
    } catch (e) {
      print('Error initializing clinic data: $e');
      _isInitialized = true;
    }
  }

  Future<void> _refreshClinicDataInBackground() async {
    try {
      final clinicId = storage.read("clinicId") as String?;
      if (clinicId == null || clinicId.isEmpty) return;

      final clinicDoc = await _authRepository.getClinicById(clinicId);
      if (clinicDoc != null) {
        final newClinicName = clinicDoc.data['clinicName'] ?? 'Clinic';
        final newProfilePictureId = clinicDoc.data['profilePictureId'] ?? '';

        if (mounted) {
          setState(() {
            _cachedClinicName = newClinicName;
            _cachedProfilePictureId = newProfilePictureId;
          });
        }
        storage.write('clinicName', newClinicName);
        storage.write('clinicProfilePictureId', newProfilePictureId);
      }
    } catch (e) {
      print('Error refreshing clinic data: $e');
    }
  }

  void _togglePopup(BuildContext context) {
    if (_overlayEntry == null) {
      _refreshClinicDataInBackground();
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
    Navigator.of(context).push(
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
    final userEmail = storage.read("email") as String? ?? "user@example.com";
    final userName = storage.read("name") as String? ?? "User";
    final userRole = storage.read("role") as String? ?? "user";

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
                      leading: _buildProfileAvatar(_cachedProfilePictureId),
                      title: Text(
                        userName,
                        style: const TextStyle(
                            color: Colors.black87, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${userRole.toUpperCase()} • $_cachedClinicName',
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
                          _closePopup();
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

  Widget _buildProfileAvatar(String? profilePictureId) {
    if (profilePictureId != null && profilePictureId.isNotEmpty) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: Colors.grey[200],
        backgroundImage: NetworkImage(
          _getProfilePictureUrl(profilePictureId),
        ),
        onBackgroundImageError: (exception, stackTrace) {
          print('Error loading profile picture: $exception');
        },
      );
    }

    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.purple.withOpacity(0.7),
      child: const Icon(
        Icons.local_hospital,
        color: Colors.white,
        size: 18,
      ),
    );
  }

  String _getProfilePictureUrl(String profilePictureId) {
    return '${AppwriteConstants.endPoint}/storage/buckets/${AppwriteConstants.imageBucketID}/files/$profilePictureId/view?project=${AppwriteConstants.projectID}';
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
    final userName = storage.read("name") as String? ?? "User";

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Tooltip(
        message: userName,
        child: InkWell(
          onTap: () => _togglePopup(context),
          borderRadius: BorderRadius.circular(50),
          child: _buildProfileAvatar(_cachedProfilePictureId),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    super.dispose();
  }
}

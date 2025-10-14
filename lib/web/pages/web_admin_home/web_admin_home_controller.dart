import 'package:capstone_app/web/admin_web/pages/admin_web_appointments.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_clinicpage.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_dashboard.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_messages.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_staffs.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class WebAdminHomeController extends GetxController {
  final GetStorage _getStorage = GetStorage();

  final selectedIndex = 0.obs;
  final userRole = ''.obs;
  final userAuthorities = <String>[].obs;

  // Dynamic pages based on permissions
  final RxList<Widget> pages = <Widget>[].obs;
  final RxList<String> navigationLabels = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    print('>>> ============================================');
    print('>>> WebAdminHomeController: Initializing...');
    print('>>> ============================================');

    _loadUserRole();
    _buildNavigationBasedOnPermissions();
  }

  void _loadUserRole() {
    print('>>> Loading user role from storage...');

    final role = _getStorage.read("role") as String?;
    final clinicId = _getStorage.read("clinicId") as String?;
    final userId = _getStorage.read("userId") as String?;

    print('>>> Raw data from storage:');
    print('>>>   - role: $role');
    print('>>>   - clinicId: $clinicId');
    print('>>>   - userId: $userId');

    if (role == null || role.isEmpty) {
      print('>>> ERROR: No role found in storage!');
      userRole.value = '';
    } else {
      userRole.value = role;
    }

    // Load authorities for staff users
    if (role == "staff") {
      final authorities = _getStorage.read("authorities");
      print('>>>   - raw authorities: $authorities');
      print('>>>   - authorities type: ${authorities.runtimeType}');

      if (authorities != null) {
        if (authorities is List) {
          userAuthorities.value = List<String>.from(authorities);
          print('>>>   - parsed authorities: ${userAuthorities.value}');
        } else if (authorities is String) {
          userAuthorities.value = [authorities];
          print('>>>   - converted string to list: ${userAuthorities.value}');
        } else {
          print('>>>   - ERROR: Unexpected authorities type');
          userAuthorities.value = [];
        }
      } else {
        print('>>>   - WARNING: No authorities found');
        userAuthorities.value = [];
      }
    } else {
      userAuthorities.value = [];
    }

    _printAccessSummary();
  }

  void _buildNavigationBasedOnPermissions() {
    print('>>> ============================================');
    print('>>> BUILDING NAVIGATION BASED ON PERMISSIONS');
    print('>>> ============================================');

    // Clear existing pages and labels
    pages.clear();
    navigationLabels.clear();

    // HOME is always available for everyone
    pages.add(const AdminWebDashboard());
    navigationLabels.add("Home");
    print('>>> Added: Home (always visible)');

    if (userRole.value == "admin") {
      // Admin sees all pages
      pages.add(const AdminWebClinicpage());
      navigationLabels.add("Clinic");
      print('>>> Added: Clinic (admin full access)');

      pages.add(const AdminWebAppointments());
      navigationLabels.add("Appointments");
      print('>>> Added: Appointments (admin full access)');

      pages.add(const AdminWebMessages());
      navigationLabels.add("Messages");
      print('>>> Added: Messages (admin full access)');

      pages.add(const AdminWebStaffs());
      navigationLabels.add("Staffs");
      print('>>> Added: Staffs (admin only)');
    } else if (userRole.value == "staff") {
      // Staff only sees pages they have permission for
      if (hasAuthority("Clinic")) {
        pages.add(const AdminWebClinicpage());
        navigationLabels.add("Clinic");
        print('>>> Added: Clinic (staff has permission)');
      }

      if (hasAuthority("Appointments")) {
        pages.add(const AdminWebAppointments());
        navigationLabels.add("Appointments");
        print('>>> Added: Appointments (staff has permission)');
      }

      if (hasAuthority("Messages")) {
        pages.add(const AdminWebMessages());
        navigationLabels.add("Messages");
        print('>>> Added: Messages (staff has permission)');
      }

      // Staffs page is NEVER shown to staff users
      print('>>> Staffs page: HIDDEN (staff user)');
    }

    print('>>> Total pages built: ${pages.length}');
    print('>>> Navigation labels: ${navigationLabels.join(", ")}');
    print('>>> ============================================');
  }

  void _printAccessSummary() {
    print('>>> ============================================');
    print('>>> ACCESS SUMMARY');
    print('>>> ============================================');
    print('>>> Current role: "${userRole.value}"');
    print('>>> Current authorities: ${userAuthorities.value}');

    if (userRole.value == "admin") {
      print('>>> ADMIN: Full access to all pages');
    } else if (userRole.value == "staff") {
      print('>>> STAFF: Limited access based on permissions');
      print('>>> Has access to: ${userAuthorities.join(", ")}');
      final allPages = ["Clinic", "Appointments", "Messages"];
      final noAccess =
          allPages.where((page) => !userAuthorities.contains(page)).toList();
      if (noAccess.isNotEmpty) {
        print('>>> No access to: ${noAccess.join(", ")}');
      }
      print('>>> Staffs page: ALWAYS HIDDEN');
    }

    print('>>> ============================================');
  }

  void setSelectedIndex(int index) {
    final maxIndex = pages.length - 1;

    print('>>> Navigation: Attempting to go to index $index (max: $maxIndex)');

    if (index >= 0 && index <= maxIndex) {
      selectedIndex.value = index;
      print('>>> Navigation: Success - now at ${navigationLabels[index]}');

      // Permission info
      if (userRole.value == "staff" && index > 0) {
        final pageName = navigationLabels[index];
        print('>>> Page "$pageName" - Staff has permission (page is visible)');
      }
    } else {
      print('>>> Navigation: ERROR - Index $index out of bounds');
      selectedIndex.value = 0;
      print('>>> Navigation: Fallback to ${navigationLabels[0]}');
    }
  }

  String get userName {
    return _getStorage.read("userName") ?? "User";
  }

  String get userEmail {
    return _getStorage.read("email") ?? "";
  }

  String get clinicId {
    return _getStorage.read("clinicId") ?? "";
  }

  bool get isAdmin => userRole.value == "admin";
  bool get isStaff => userRole.value == "staff";

  bool hasAuthority(String authority) {
    if (isAdmin) {
      return true; // Admins have full access to everything
    }

    // Staff users - check their authorities
    final hasAuth = userAuthorities.contains(authority);
    return hasAuth;
  }

  bool hasFullAccessToCurrentPage() {
    if (isAdmin) return true;
    if (selectedIndex.value == 0) return true; // Home is always accessible

    final pageName = navigationLabels[selectedIndex.value];
    return hasAuthority(pageName);
  }

  String getCurrentPagePermission() {
    if (selectedIndex.value == 0) return "Home";
    return navigationLabels[selectedIndex.value];
  }

  // NEW: Check if staff can access a specific feature
  bool canAccessFeature(String featureName) {
    if (isAdmin) return true;

    // Map feature names to permissions
    final featurePermissions = {
      'clinic_info': 'Clinic',
      'clinic_settings': 'Clinic',
      'appointments': 'Appointments',
      'messages': 'Messages',
      'staffs': 'admin_only', // Special case - admin only
    };

    final requiredPermission = featurePermissions[featureName];

    if (requiredPermission == 'admin_only') {
      return false; // Staff can never access
    }

    if (requiredPermission == null) {
      return true; // Unknown feature, allow by default
    }

    return hasAuthority(requiredPermission);
  }

  // NEW: Show permission denied dialog
  void showPermissionDeniedDialog(String featureName) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: Colors.orange[700], size: 28),
            const SizedBox(width: 12),
            const Text('Access Denied'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You do not have permission to access this feature.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Please contact your administrator to request access.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void refreshRoleData() {
    print('>>> Manual refresh of role data requested');
    _loadUserRole();
    _buildNavigationBasedOnPermissions();
  }

  void debugPrintState() {
    print('>>> ============================================');
    print('>>> DEBUG STATE');
    print('>>> ============================================');
    print('>>> Role: ${userRole.value}');
    print('>>> Is Admin: $isAdmin');
    print('>>> Is Staff: $isStaff');
    print('>>> Authorities: ${userAuthorities.value}');
    print('>>> Pages count: ${pages.length}');
    print('>>> Navigation labels: ${navigationLabels.join(", ")}');
    print('>>> Selected index: ${selectedIndex.value}');
    print('>>> Current page: ${navigationLabels[selectedIndex.value]}');
    print(
        '>>> Has full access to current page: ${hasFullAccessToCurrentPage()}');
    print('>>> User: $userName ($userEmail)');
    print('>>> Clinic ID: $clinicId');
    print('>>> ============================================');
    print('>>> STORAGE DUMP:');
    print('>>>   - userId: ${_getStorage.read("userId")}');
    print('>>>   - role: ${_getStorage.read("role")}');
    print('>>>   - clinicId: ${_getStorage.read("clinicId")}');
    print('>>>   - staffId: ${_getStorage.read("staffId")}');
    print('>>>   - authorities: ${_getStorage.read("authorities")}');
    print('>>> ============================================');
  }

  @override
  void onClose() {
    super.onClose();
  }
}

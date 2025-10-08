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

  // ALL pages are ALWAYS available - both admin and staff see all 5 pages
  final RxList<Widget> pages = <Widget>[
    const AdminWebDashboard(),
    const AdminWebClinicpage(),
    const AdminWebAppointments(),
    const AdminWebMessages(),
    const AdminWebStaffs(), // ALWAYS AVAILABLE
  ].obs;

  // ALL navigation labels are ALWAYS available
  final RxList<String> navigationLabels = <String>[
    "Home",
    "Clinic",
    "Appointments",
    "Messages",
    "Staffs", // ALWAYS VISIBLE
  ].obs;

  @override
  void onInit() {
    super.onInit();
    print('>>> ============================================');
    print('>>> WebAdminHomeController: Initializing...');
    print('>>> ============================================');

    _loadUserRole();
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

  void _printAccessSummary() {
    print('>>> ============================================');
    print('>>> ACCESS SUMMARY');
    print('>>> ============================================');
    print('>>> Current role: "${userRole.value}"');
    print('>>> Current authorities: ${userAuthorities.value}');
    print('>>> Total pages visible: ${pages.length}');
    print('>>> Navigation labels: ${navigationLabels.join(", ")}');

    if (userRole.value == "admin") {
      print('>>> ADMIN: Full access to all pages including Staffs');
    } else if (userRole.value == "staff") {
      print('>>> STAFF: Can view all pages');
      print('>>> Full access to: ${userAuthorities.join(", ")}');
      print('>>> View-only access to: ${_getViewOnlyPages().join(", ")}');
      print('>>> IMPORTANT: Staffs page is ALWAYS view-only for staff');
    }

    print('>>> ============================================');
  }

  List<String> _getViewOnlyPages() {
    final allPages = ["Clinic", "Appointments", "Messages", "Staffs"];
    return allPages.where((page) => !userAuthorities.contains(page)).toList();
  }

  void setSelectedIndex(int index) {
    final maxIndex = pages.length - 1;

    print('>>> Navigation: Attempting to go to index $index (max: $maxIndex)');

    if (index >= 0 && index <= maxIndex) {
      selectedIndex.value = index;
      print('>>> Navigation: Success - now at ${navigationLabels[index]}');

      // Check if user has permission for this page
      if (userRole.value == "staff" && index > 0) {
        final pageName = navigationLabels[index];
        final hasPermission = hasAuthority(pageName);
        print(
            '>>> Permission check for "$pageName": ${hasPermission ? "FULL ACCESS" : "VIEW-ONLY"}');
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

    // IMPORTANT: Staff can NEVER have "Staffs" authority
    if (authority == "Staffs") {
      return false; // Always false for staff users
    }

    // Staff users - check their authorities for other pages
    final hasAuth = userAuthorities.contains(authority);
    print('>>> Authority check for "$authority": $hasAuth');
    return hasAuth;
  }

  bool hasFullAccessToCurrentPage() {
    if (isAdmin) return true;
    if (selectedIndex.value == 0) return true; // Home is always accessible

    final pageName = navigationLabels[selectedIndex.value];

    // Staffs page is always view-only for staff
    if (pageName == "Staffs" && isStaff) return false;

    return hasAuthority(pageName);
  }

  String getCurrentPagePermission() {
    if (selectedIndex.value == 0) return "Home"; // Home page
    return navigationLabels[selectedIndex.value];
  }

  void refreshRoleData() {
    print('>>> Manual refresh of role data requested');
    _loadUserRole();
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

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
  final canAccessStaffs = false.obs;

  List<Widget> get pages {
    List<Widget> basePages = const [
      AdminWebDashboard(),
      AdminWebClinicpage(),
      AdminWebAppointments(),
      AdminWebMessages(),
    ];

    // Only add staffs page if user has permission
    // if (canAccessStaffs.value) {
    //   basePages.add(const AdminWebStaffs());
    // }

    return basePages;
  }

  @override
  void onInit() {
    super.onInit();
    _loadUserRole();
  }

  void _loadUserRole() {
    final role = _getStorage.read("role") as String?;
    userRole.value = role ?? '';
    
    // Only admins can access staff management, not regular staff
    canAccessStaffs.value = role == "admin";
  }

  void setSelectedIndex(int index) {
    // Validate index bounds based on available pages
    final maxIndex = canAccessStaffs.value ? 4 : 3;
    if (index >= 0 && index <= maxIndex) {
      selectedIndex.value = index;
    }
  }

  String get userName {
    return _getStorage.read("userName") ?? "Admin User";
  }

  String get userEmail {
    return _getStorage.read("email") ?? "";
  }

  bool get isAdmin => userRole.value == "admin";
  bool get isStaff => userRole.value == "staff";
}
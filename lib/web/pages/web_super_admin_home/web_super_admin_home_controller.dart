import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/utils/logout_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class WebSuperAdminHomeController extends GetxController {
  final AuthRepository _authRepository;
  WebSuperAdminHomeController(this._authRepository);

  final GetStorage _getStorage = GetStorage();
  final isLoggingOut = false.obs;

  String get userName {
    return _getStorage.read("userName") ?? "Developer";
  }

  String get userEmail {
    return _getStorage.read("email") ?? "";
  }

  Future<void> logout() async {
    try {
      isLoggingOut.value = true;
      await LogoutHelper.logout();
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred during logout: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoggingOut.value = false;
    }
  }

  // Navigation methods for super admin features
  void navigateToVetClinics() {
    // Navigate to vet clinic management
    // You can implement this based on your existing super admin pages
  }

  void navigateToPetOwners() {
    // Navigate to pet owner management
  }

  void navigateToReports() {
    // Navigate to reports and analytics
  }
}
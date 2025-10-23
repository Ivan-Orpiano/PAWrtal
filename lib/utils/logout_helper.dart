import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/mobile/user/controllers/user_messaging_controller.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LogoutHelper {
  static final GetStorage _getStorage = GetStorage();

  static Future<void> logout() async {
    try {
      print('>>> ============================================');
      print('>>> LOGOUT PROCESS STARTED');
      print('>>> ============================================');

      // Show loading indicator
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      // Step 1: Clear MessagingController FIRST (before logout)
      print('>>> Step 1: Clearing MessagingController...');
      if (Get.isRegistered<MessagingController>()) {
        final messagingController = Get.find<MessagingController>();
        
        // Set user offline
        try {
          await messagingController.setUserOffline();
          print('>>> User status set to offline');
        } catch (e) {
          print('>>> Warning: Could not set user offline: $e');
        }
        
        // Clear all messaging data
        messagingController.clearAllData();
        print('>>> MessagingController data cleared');
        
        // Delete the controller instance
        Get.delete<MessagingController>();
        print('>>> MessagingController deleted from GetX');
      } else {
        print('>>> No MessagingController registered');
      }

      // Step 2: Clear UserSessionService
      print('>>> Step 2: Clearing user session...');
      if (Get.isRegistered<UserSessionService>()) {
        final userSession = Get.find<UserSessionService>();
        await userSession.clearSession();
        print('>>> User session cleared');
      }

      // Step 3: Clear GetStorage
      print('>>> Step 3: Clearing GetStorage...');
      await _clearAllUserData();
      print('>>> GetStorage cleared');

      // Step 4: Perform Appwrite logout
      print('>>> Step 4: Logging out from Appwrite...');
      try {
        final appWriteProvider = Get.find<AppWriteProvider>();
        await appWriteProvider.webLogout();
        print('>>> Appwrite logout successful');
      } catch (e) {
        print('>>> Server logout failed: $e');
      }

      // Step 5: Close loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // Step 6: Navigate to login page
      print('>>> Step 6: Navigating to login...');
      Get.offAllNamed(Routes.login);

      print('>>> ============================================');
      print('>>> LOGOUT COMPLETED SUCCESSFULLY');
      print('>>> ============================================');

      // Show success message
      Get.snackbar(
        'Logged Out',
        'You have been successfully logged out',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      print('>>> ============================================');
      print('>>> LOGOUT ERROR: $e');
      print('>>> ============================================');

      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // Even if there's an error, try to navigate to login
      try {
        Get.offAllNamed(Routes.login);
      } catch (navError) {
        print('>>> Navigation error: $navError');
      }

      Get.snackbar(
        'Logout Error',
        'There was an error during logout, but you have been signed out',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    }
  }

  /// Alternative logout with custom navigation
  static Future<void> logoutWithNavigation(BuildContext context, String route) async {
    try {
      print('>>> ============================================');
      print('>>> LOGOUT WITH CUSTOM NAVIGATION');
      print('>>> Target route: $route');
      print('>>> ============================================');

      // Step 1: Clear MessagingController
      if (Get.isRegistered<MessagingController>()) {
        final messagingController = Get.find<MessagingController>();
        await messagingController.setUserOffline();
        messagingController.clearAllData();
        Get.delete<MessagingController>();
      }

      // Step 2: Clear session and storage
      if (Get.isRegistered<UserSessionService>()) {
        await Get.find<UserSessionService>().clearSession();
      }
      await _clearAllUserData();

      // Step 3: Logout from Appwrite
      try {
        await Get.find<AppWriteProvider>().webLogout();
      } catch (e) {
        print('>>> Server logout failed: $e');
      }

      // Step 4: Custom navigation
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
      }

      print('>>> LOGOUT WITH CUSTOM NAVIGATION COMPLETED');
    } catch (e) {
      print('>>> ERROR IN LOGOUT WITH NAVIGATION: $e');
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
      }
    }
  }

  static Future<void> _clearAllUserData() async {
    final keys = [
      "userId",
      "sessionId",
      "role",
      "email",
      "userName",
      "clinicId",
      "staffId",
      "customerId",
      "userProfile",
      "lastLogin",
      "preferences"
    ];

    for (String key in keys) {
      _getStorage.remove(key);
    }
  }

  // Utility getters
  static bool get isLoggedIn {
    final userId = _getStorage.read("userId");
    final role = _getStorage.read("role");
    return userId != null && role != null;
  }

  static String? get currentUserRole {
    return _getStorage.read("role");
  }

  static String? get currentUserId {
    return _getStorage.read("userId");
  }

  static String? get currentUserEmail {
    return _getStorage.read("email");
  }

  static String? get currentUserName {
    return _getStorage.read("userName");
  }
}
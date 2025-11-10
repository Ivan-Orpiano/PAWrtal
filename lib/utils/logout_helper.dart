import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/mobile/user/controllers/user_messaging_controller.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/utils/snackbar_helper.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/web/admin_web/components/appointments/admin_web_appointment_controller.dart';
import 'package:capstone_app/web/admin_web/components/dashboard/admin_dashboard_controller.dart'; // NEW: Import dashboard controller
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LogoutHelper {
  static final GetStorage _getStorage = GetStorage();

  // ✅ NEW: Global logout flag
  static final RxBool isLoggingOut = false.obs;

  static Future<void> logout() async {
    try {

      // ✅ CRITICAL: Set global logout flag FIRST
      isLoggingOut.value = true;

      // Show loading indicator
      Get.dialog(
        const Center(
          child: CircularProgressIndicator(),
        ),
        barrierDismissible: false,
      );

      // Step 1: Clear MessagingController FIRST (before logout)
      if (Get.isRegistered<MessagingController>()) {
        final messagingController = Get.find<MessagingController>();

        try {
          await messagingController.setUserOffline();
        } catch (e) {
        }

        messagingController.clearAllData();

        Get.delete<MessagingController>();
      }

      // Step 2: CRITICAL - Clear WebAppointmentController
      if (Get.isRegistered<WebAppointmentController>()) {
        try {
          final appointmentController = Get.find<WebAppointmentController>();

          // Call cleanup method
          appointmentController.cleanupOnLogout();

          // Delete the controller instance
          Get.delete<WebAppointmentController>(force: true);
        } catch (e) {
        }
      } else {
      }

      // Step 2.5: CRITICAL - Clear AdminDashboardController with cache cleanup
      if (Get.isRegistered<AdminDashboardController>()) {
        try {
          final dashboardController = Get.find<AdminDashboardController>();

          // CRITICAL: Call cleanup method (clears cache too)
          dashboardController.cleanupOnLogout();

          // Delete the controller instance
          Get.delete<AdminDashboardController>(force: true);
        } catch (e) {
        }
      } else {
      }
      // Step 3: Clear UserSessionService
      if (Get.isRegistered<UserSessionService>()) {
        final userSession = Get.find<UserSessionService>();
        await userSession.clearSession();
      }

      // Step 4: Get session ID BEFORE clearing storage
      final sessionId = _getStorage.read('sessionId');

      // Step 5: Perform Appwrite logout BEFORE clearing storage
      bool serverLogoutSuccess = false;
      try {
        final appWriteProvider = Get.find<AppWriteProvider>();

        if (sessionId != null && sessionId.isNotEmpty) {
          await appWriteProvider.account!.deleteSession(sessionId: sessionId);
          serverLogoutSuccess = true;
        } else {
          await appWriteProvider.account!.deleteSession(sessionId: 'current');
          serverLogoutSuccess = true;
        }
      } catch (e) {

        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('unauthorized') ||
            errorMessage.contains('session') ||
            errorMessage.contains('guests')) {
          serverLogoutSuccess = true;
        }
      }

      // Step 6: Clear GetStorage (do this AFTER Appwrite logout attempt)
      await _clearAllUserData();

      // Step 7: Reinitialize AppwriteProvider with fresh client (web only)
      if (kIsWeb) {
        try {
          final appWriteProvider = Get.find<AppWriteProvider>();
          appWriteProvider.client = appWriteProvider.client
              .setEndpoint(appWriteProvider.client.endPoint)
              .setProject(appWriteProvider.client.config['project']);
          appWriteProvider.account = appWriteProvider.account;
          appWriteProvider.storage = appWriteProvider.storage;
          appWriteProvider.databases = appWriteProvider.databases;
        } catch (e) {
        }
      }

      // Step 8: Close loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // Step 9: Navigate to login page
      Get.offAllNamed(Routes.login);


      // Show success message
      SnackbarHelper.showSuccess(
        context: Get.overlayContext,
        title: "Logged Out",
        message: "You have been successfully logged out"
      );
      // Get.snackbar(
      //   'Logged Out',
      //   'You have been successfully logged out',
      //   snackPosition: SnackPosition.TOP,
      //   backgroundColor: Colors.green,
      //   colorText: Colors.white,
      //   duration: const Duration(seconds: 2),
      // );
    } catch (e) {

      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // CRITICAL: Always clear local data and navigate, even on error
      try {
        await _clearAllUserData();
        Get.offAllNamed(Routes.login);
      } catch (navError) {
      }

      Get.snackbar(
        'Logged Out',
        'You have been signed out locally',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    } finally {
      // ✅ CRITICAL: Reset global logout flag
      isLoggingOut.value = false;
    }
  }

  /// Alternative logout with custom navigation
  static Future<void> logoutWithNavigation(
      BuildContext context, String route) async {
    try {

      // Step 1: Clear MessagingController
      if (Get.isRegistered<MessagingController>()) {
        final messagingController = Get.find<MessagingController>();
        await messagingController.setUserOffline();
        messagingController.clearAllData();
        Get.delete<MessagingController>();
      }

      // Step 2: Clear WebAppointmentController
      if (Get.isRegistered<WebAppointmentController>()) {
        try {
          final appointmentController = Get.find<WebAppointmentController>();

          // Call cleanup method
          appointmentController.cleanupOnLogout();

          // Delete the controller instance
          Get.delete<WebAppointmentController>(force: true);
        } catch (e) {
        }
      } else {
      }

      // Step 2.5: CRITICAL - Clear AdminDashboardController with cache cleanup
      if (Get.isRegistered<AdminDashboardController>()) {
        try {
          final dashboardController = Get.find<AdminDashboardController>();

          // Call cleanup method (clears cache too)
          dashboardController.cleanupOnLogout();

          // Delete the controller instance
          Get.delete<AdminDashboardController>(force: true);
        } catch (e) {
        }
      } else {
      }

      // Step 3: Get session ID before clearing
      final sessionId = _getStorage.read('sessionId');

      // Step 4: Logout from Appwrite
      try {
        final appWriteProvider = Get.find<AppWriteProvider>();
        if (sessionId != null && sessionId.isNotEmpty) {
          await appWriteProvider.account!.deleteSession(sessionId: sessionId);
        } else {
          await appWriteProvider.account!.deleteSession(sessionId: 'current');
        }
      } catch (e) {
      }

      // Step 5: Clear session and storage
      if (Get.isRegistered<UserSessionService>()) {
        await Get.find<UserSessionService>().clearSession();
      }
      await _clearAllUserData();

      // Step 6: Custom navigation
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
      }

    } catch (e) {
      await _clearAllUserData();
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
      "preferences",
      "userDocumentId",
      "userProfilePictureId",
      "push_target_id",
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

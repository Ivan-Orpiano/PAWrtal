import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/mobile/user/controllers/user_messaging_controller.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LogoutHelper {
  static final GetStorage _getStorage = GetStorage();

  static Future<void> logout() async {
    try {
      print('>>> ============================================');
      print('>>> LOGOUT PROCESS STARTED');
      print('>>> Platform: ${kIsWeb ? "Web" : "Mobile"}');
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

      // Step 3: Get session ID BEFORE clearing storage
      final sessionId = _getStorage.read('sessionId');
      print('>>> Step 3: Session ID: ${sessionId ?? "none"}');

      // Step 4: Perform Appwrite logout BEFORE clearing storage
      print('>>> Step 4: Logging out from Appwrite...');
      bool serverLogoutSuccess = false;
      try {
        final appWriteProvider = Get.find<AppWriteProvider>();
        
        if (sessionId != null && sessionId.isNotEmpty) {
          // Try to delete specific session
          print('>>> Attempting to delete session: $sessionId');
          await appWriteProvider.account!.deleteSession(sessionId: sessionId);
          serverLogoutSuccess = true;
          print('>>> ✅ Appwrite session deleted');
        } else {
          // Fallback: Delete current session
          print('>>> No session ID, deleting current session...');
          await appWriteProvider.account!.deleteSession(sessionId: 'current');
          serverLogoutSuccess = true;
          print('>>> ✅ Appwrite current session deleted');
        }
      } catch (e) {
        print('>>> ⚠️ Server logout error: $e');
        
        // CRITICAL FIX: Even if session deletion fails, continue with logout
        // This handles the case where session is already invalid/expired
        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('unauthorized') || 
            errorMessage.contains('session') ||
            errorMessage.contains('guests')) {
          print('>>> Session already invalid, proceeding with local cleanup');
          serverLogoutSuccess = true;
        }
      }

      // Step 5: Clear GetStorage (do this AFTER Appwrite logout attempt)
      print('>>> Step 5: Clearing GetStorage...');
      await _clearAllUserData();
      print('>>> GetStorage cleared');

      // Step 6: CRITICAL - Reinitialize AppwriteProvider with fresh client
      if (kIsWeb) {
        print('>>> Step 6: Reinitializing AppwriteProvider for web...');
        try {
          final appWriteProvider = Get.find<AppWriteProvider>();
          // Force create new client to clear session cookies
          appWriteProvider.client = appWriteProvider.client
              .setEndpoint(appWriteProvider.client.endPoint)
              .setProject(appWriteProvider.client.config['project']);
          appWriteProvider.account = appWriteProvider.account;
          appWriteProvider.storage = appWriteProvider.storage;
          appWriteProvider.databases = appWriteProvider.databases;
          print('>>> ✅ AppwriteProvider reinitialized');
        } catch (e) {
          print('>>> Warning: Could not reinitialize provider: $e');
        }
      }

      // Step 7: Close loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // Step 8: Navigate to login page
      print('>>> Step 7: Navigating to login...');
      Get.offAllNamed(Routes.login);

      print('>>> ============================================');
      print('>>> LOGOUT COMPLETED SUCCESSFULLY');
      print('>>> Server logout: ${serverLogoutSuccess ? "✅" : "⚠️ (local only)"}');
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

      // CRITICAL: Always clear local data and navigate, even on error
      try {
        await _clearAllUserData();
        Get.offAllNamed(Routes.login);
      } catch (navError) {
        print('>>> Navigation error: $navError');
      }

      Get.snackbar(
        'Logged Out',
        'You have been signed out locally',
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

      // Step 2: Get session ID before clearing
      final sessionId = _getStorage.read('sessionId');

      // Step 3: Logout from Appwrite
      try {
        final appWriteProvider = Get.find<AppWriteProvider>();
        if (sessionId != null && sessionId.isNotEmpty) {
          await appWriteProvider.account!.deleteSession(sessionId: sessionId);
        } else {
          await appWriteProvider.account!.deleteSession(sessionId: 'current');
        }
      } catch (e) {
        print('>>> Server logout failed: $e');
      }

      // Step 4: Clear session and storage
      if (Get.isRegistered<UserSessionService>()) {
        await Get.find<UserSessionService>().clearSession();
      }
      await _clearAllUserData();

      // Step 5: Custom navigation
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
      }

      print('>>> LOGOUT WITH CUSTOM NAVIGATION COMPLETED');
    } catch (e) {
      print('>>> ERROR IN LOGOUT WITH NAVIGATION: $e');
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
    
    print('>>> Cleared ${keys.length} storage keys');
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
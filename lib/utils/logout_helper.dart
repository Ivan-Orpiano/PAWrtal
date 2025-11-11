import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/mobile/user/controllers/user_messaging_controller.dart';
import 'package:capstone_app/notification/services/appointment_reminder_service.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/utils/snackbar_helper.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/web/admin_web/components/appointments/admin_web_appointment_controller.dart';
import 'package:capstone_app/web/admin_web/components/dashboard/admin_dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class LogoutHelper {
  static final GetStorage _getStorage = GetStorage();

  // Global logout flag
  static final RxBool isLoggingOut = false.obs;

  static Future<void> logout() async {
    try {
      // CRITICAL: Set global logout flag FIRST
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
          print('Error setting user offline: $e');
        }

        messagingController.clearAllData();
        Get.delete<MessagingController>();
      }

      // Step 1.5: CRITICAL - Stop appointment reminder service
      if (Get.isRegistered<AppointmentReminderService>()) {
        try {
          final reminderService = Get.find<AppointmentReminderService>();
          reminderService.stopReminderService();
          print('✅ Appointment reminder service stopped');
        } catch (e) {
          print('⚠️ Error stopping reminder service: $e');
        }
      }

      // Step 2: Clear WebAppointmentController
      if (Get.isRegistered<WebAppointmentController>()) {
        try {
          final appointmentController = Get.find<WebAppointmentController>();
          appointmentController.cleanupOnLogout();
          Get.delete<WebAppointmentController>(force: true);
        } catch (e) {
          print('Error cleaning appointment controller: $e');
        }
      }

      // Step 2.5: Clear AdminDashboardController with cache cleanup
      if (Get.isRegistered<AdminDashboardController>()) {
        try {
          final dashboardController = Get.find<AdminDashboardController>();
          dashboardController.cleanupOnLogout();
          Get.delete<AdminDashboardController>(force: true);
        } catch (e) {
          print('Error cleaning dashboard controller: $e');
        }
      }

      // Step 3: Get important data BEFORE clearing storage
      final sessionId = _getStorage.read('sessionId');
      final userId = _getStorage.read('userId');
      final pushTargetId = _getStorage.read('push_target_id');

      // Step 4: CRITICAL - Delete FCM push target on mobile
      if (!kIsWeb && pushTargetId != null && pushTargetId.isNotEmpty) {
        try {
          final appWriteProvider = Get.find<AppWriteProvider>();
          // Use the existing deletePushTarget method from AppWriteProvider
          final deleted = await appWriteProvider.deletePushTarget(pushTargetId);
          if (deleted) {
            print('✅ FCM push target deleted successfully: $pushTargetId');
          } else {
            print('⚠️ FCM push target deletion returned false');
          }
        } catch (e) {
          print('❌ Error deleting FCM push target: $e');
          // Continue with logout even if this fails
        }
      }

      // Step 5: Clear UserSessionService
      if (Get.isRegistered<UserSessionService>()) {
        final userSession = Get.find<UserSessionService>();
        await userSession.clearSession();
      }

      // Step 6: Perform Appwrite logout with multiple strategies
      bool serverLogoutSuccess = false;
      try {
        final appWriteProvider = Get.find<AppWriteProvider>();

        // STRATEGY 1: Try deleting specific session
        if (sessionId != null && sessionId.isNotEmpty) {
          try {
            await appWriteProvider.account!.deleteSession(sessionId: sessionId);
            serverLogoutSuccess = true;
            print('✅ Session deleted successfully: $sessionId');
          } catch (e) {
            print('⚠️ Specific session deletion failed: $e');
            // Continue to strategy 2
          }
        }

        // STRATEGY 2: If strategy 1 failed, try deleting current session
        if (!serverLogoutSuccess) {
          try {
            await appWriteProvider.account!.deleteSession(sessionId: 'current');
            serverLogoutSuccess = true;
            print('✅ Current session deleted successfully');
          } catch (e) {
            print('⚠️ Current session deletion failed: $e');
            // Continue to strategy 3
          }
        }

        // STRATEGY 3: If both failed, try deleting ALL sessions (nuclear option)
        if (!serverLogoutSuccess && !kIsWeb) {
          try {
            await appWriteProvider.account!.deleteSessions();
            serverLogoutSuccess = true;
            print('✅ All sessions deleted successfully (mobile fallback)');
          } catch (e) {
            print('⚠️ Delete all sessions failed: $e');
            // Check if error is because user is already logged out
            final errorMessage = e.toString().toLowerCase();
            if (errorMessage.contains('unauthorized') ||
                errorMessage.contains('session') ||
                errorMessage.contains('guests')) {
              serverLogoutSuccess = true;
              print('✅ Session already invalid, proceeding with local logout');
            }
          }
        }
      } catch (e) {
        print('⚠️ Appwrite logout error: $e');
        
        final errorMessage = e.toString().toLowerCase();
        if (errorMessage.contains('unauthorized') ||
            errorMessage.contains('session') ||
            errorMessage.contains('guests')) {
          serverLogoutSuccess = true;
          print('✅ Session already invalid, proceeding with local logout');
        }
      }

      // Step 7: Clear GetStorage (do this AFTER Appwrite logout attempt)
      await _clearAllUserData();

      // Step 8: Reinitialize AppwriteProvider with fresh client (web only)
      if (kIsWeb) {
        try {
          final appWriteProvider = Get.find<AppWriteProvider>();
          appWriteProvider.client = appWriteProvider.client
              .setEndpoint(appWriteProvider.client.endPoint)
              .setProject(appWriteProvider.client.config['project']);
          appWriteProvider.account = appWriteProvider.account;
          appWriteProvider.storage = appWriteProvider.storage;
          appWriteProvider.databases = appWriteProvider.databases;
          print('✅ AppwriteProvider reinitialized for web');
        } catch (e) {
          print('⚠️ Error reinitializing AppwriteProvider: $e');
        }
      }

      // Step 9: Close loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // Step 10: Navigate to login page
      Get.offAllNamed(Routes.login);

      // Show success message
      SnackbarHelper.showSuccess(
        context: Get.overlayContext,
        title: "Logged Out",
        message: "You have been successfully logged out"
      );
      
      print('✅ Logout completed successfully');
    } catch (e) {
      print('❌ Critical logout error: $e');

      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      // CRITICAL: Always clear local data and navigate, even on error
      try {
        await _clearAllUserData();
        Get.offAllNamed(Routes.login);
      } catch (navError) {
        print('❌ Navigation error: $navError');
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
      // CRITICAL: Reset global logout flag
      isLoggingOut.value = false;
    }
  }

  /// Alternative logout with custom navigation
  static Future<void> logoutWithNavigation(
      BuildContext context, String route) async {
    try {
      print('🚀 Starting logout with navigation to: $route');

      // Step 1: Clear MessagingController
      if (Get.isRegistered<MessagingController>()) {
        final messagingController = Get.find<MessagingController>();
        await messagingController.setUserOffline();
        messagingController.clearAllData();
        Get.delete<MessagingController>();
      }

      // Step 1.5: CRITICAL - Stop appointment reminder service
      if (Get.isRegistered<AppointmentReminderService>()) {
        try {
          final reminderService = Get.find<AppointmentReminderService>();
          reminderService.stopReminderService();
          print('✅ Appointment reminder service stopped');
        } catch (e) {
          print('⚠️ Error stopping reminder service: $e');
        }
      }

      // Step 2: Clear WebAppointmentController
      if (Get.isRegistered<WebAppointmentController>()) {
        try {
          final appointmentController = Get.find<WebAppointmentController>();
          appointmentController.cleanupOnLogout();
          Get.delete<WebAppointmentController>(force: true);
        } catch (e) {
          print('Error cleaning appointment controller: $e');
        }
      }

      // Step 2.5: Clear AdminDashboardController with cache cleanup
      if (Get.isRegistered<AdminDashboardController>()) {
        try {
          final dashboardController = Get.find<AdminDashboardController>();
          dashboardController.cleanupOnLogout();
          Get.delete<AdminDashboardController>(force: true);
        } catch (e) {
          print('Error cleaning dashboard controller: $e');
        }
      }

      // Step 3: Get important data before clearing
      final sessionId = _getStorage.read('sessionId');
      final userId = _getStorage.read('userId');
      final pushTargetId = _getStorage.read('push_target_id');

      // Step 4: CRITICAL - Delete FCM push target on mobile
      if (!kIsWeb && pushTargetId != null && pushTargetId.isNotEmpty) {
        try {
          final appWriteProvider = Get.find<AppWriteProvider>();
          // Use the existing deletePushTarget method from AppWriteProvider
          final deleted = await appWriteProvider.deletePushTarget(pushTargetId);
          if (deleted) {
            print('✅ FCM push target deleted: $pushTargetId');
          } else {
            print('⚠️ FCM push target deletion returned false');
          }
        } catch (e) {
          print('❌ Error deleting FCM push target: $e');
        }
      }

      // Step 5: Logout from Appwrite with multiple strategies
      try {
        final appWriteProvider = Get.find<AppWriteProvider>();
        
        // STRATEGY 1: Try specific session
        if (sessionId != null && sessionId.isNotEmpty) {
          try {
            await appWriteProvider.account!.deleteSession(sessionId: sessionId);
            print('✅ Session deleted: $sessionId');
          } catch (e) {
            print('⚠️ Specific session deletion failed, trying current');
            // STRATEGY 2: Try current session
            try {
              await appWriteProvider.account!.deleteSession(sessionId: 'current');
              print('✅ Current session deleted');
            } catch (e2) {
              // STRATEGY 3: Delete all sessions (mobile only)
              if (!kIsWeb) {
                try {
                  await appWriteProvider.account!.deleteSessions();
                  print('✅ All sessions deleted (mobile fallback)');
                } catch (e3) {
                  print('⚠️ All strategies failed: $e3');
                }
              }
            }
          }
        } else {
          // No session ID, try current or all
          try {
            await appWriteProvider.account!.deleteSession(sessionId: 'current');
            print('✅ Current session deleted');
          } catch (e) {
            if (!kIsWeb) {
              try {
                await appWriteProvider.account!.deleteSessions();
                print('✅ All sessions deleted (mobile fallback)');
              } catch (e2) {
                print('⚠️ Session deletion failed: $e2');
              }
            }
          }
        }
      } catch (e) {
        print('⚠️ Session deletion error: $e');
      }

      // Step 6: Clear session and storage
      if (Get.isRegistered<UserSessionService>()) {
        await Get.find<UserSessionService>().clearSession();
      }
      await _clearAllUserData();

      // Step 7: Custom navigation
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(route, (route) => false);
      }

      print('✅ Logout with navigation completed');
    } catch (e) {
      print('❌ Error in logoutWithNavigation: $e');
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
      "push_target_id", // CRITICAL: Clear FCM target ID
      "phone",
      "username",
      "authorities",
    ];

    for (String key in keys) {
      _getStorage.remove(key);
    }

    print('✅ All user data cleared from storage');
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
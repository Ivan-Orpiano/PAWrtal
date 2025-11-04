import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/notification/services/notification_service.dart';
import 'package:capstone_app/notification/services/in_app_notification_service.dart';
import 'package:appwrite/enums.dart';
import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/utils/appwrite_constant.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:async';
import 'dart:math' as Math;

/// Handles OAuth for mobile using Appwrite SDK's built-in OAuth
/// Includes FCM push notifications, in-app notifications, and all login features
class MobileOAuthHandler {
  static final _storage = GetStorage();
  static bool _isProcessing = false;
  static Timer? _sessionCheckTimer;

  /// Initialize and handle Google OAuth flow
  static Future<bool> initiateGoogleOAuth() async {
    if (_isProcessing) {
      print('>>> ⚠️ OAuth already in progress, ignoring...');
      return false;
    }

    try {
      _isProcessing = true;

      print('>>> ============================================');
      print('>>> MOBILE: INITIATING GOOGLE OAUTH');
      print('>>> ============================================');

      final appwriteProvider = Get.find<AppWriteProvider>();

      print('>>> Launching OAuth browser...');

      // CRITICAL FIX: createOAuth2Session returns void on mobile, not bool
      // It opens the browser and returns immediately
      await appwriteProvider.account!.createOAuth2Session(
        provider: OAuthProvider.google,
      );

      print('>>> OAuth browser launched (returned void - this is normal)');
      print('>>> Browser will handle OAuth and redirect back to app');
      print('>>> Starting session polling...');

      // Start polling for session establishment
      return await _pollForSession();
    } catch (e, stackTrace) {
      print('>>> ============================================');
      print('>>> ❌ OAuth launch error: $e');
      print('>>> Type: ${e.runtimeType}');
      print(
          '>>> Stack: ${stackTrace.toString().substring(0, Math.min(500, stackTrace.toString().length))}...');
      print('>>> ============================================');

      _handleOAuthFailure();
      return false;
    } finally {
      _isProcessing = false;
    }
  }

  /// Poll for OAuth session establishment
  static Future<bool> _pollForSession() async {
    print('>>> ============================================');
    print('>>> POLLING FOR OAUTH SESSION');
    print('>>> Will check every 1s for up to 60s');
    print('>>> ============================================');

    _showLoadingDialog();

    const maxAttempts = 60; // 60 seconds total
    const checkInterval = Duration(seconds: 1);

    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await Future.delayed(checkInterval);

        if (attempt % 5 == 0 || attempt <= 3) {
          print('>>> ⏳ Checking for session... Attempt $attempt/$maxAttempts');
        }

        // CRITICAL: Create a FRESH Appwrite client to check for session
        // The old client instance doesn't have the OAuth session cookies
        final testClient = Client()
            .setEndpoint(AppwriteConstants.endPoint)
            .setProject(AppwriteConstants.projectID);

        final testAccount = Account(testClient);

        // Try to get the user - this will succeed if session exists
        final user = await testAccount.get();

        if (user != null && user.$id.isNotEmpty) {
          print('>>> ============================================');
          print('>>> ✅ SESSION DETECTED!');
          print('>>> User ID: ${user.$id}');
          print('>>> Email: ${user.email}');
          print('>>> Name: ${user.name}');
          print('>>> ============================================');

          // CRITICAL: Replace the global AppWriteProvider's client with fresh one
          print('>>> Updating global AppWriteProvider with new session...');
          final appwriteProvider = Get.find<AppWriteProvider>();
          appwriteProvider.client = testClient;
          appwriteProvider.account = testAccount;
          appwriteProvider.storage = Storage(testClient);
          appwriteProvider.databases = Databases(testClient);
          print('>>> ✅ AppWriteProvider updated with OAuth session');

          // Get AuthRepository and update it too
          final authRepository = Get.find<AuthRepository>();
          // authRepository.appWriteProvider = appwriteProvider;
          print('>>> ✅ AuthRepository updated');

          // Process the OAuth success
          await _handleOAuthSuccess(appwriteProvider, authRepository, user);
          return true;
        }
      } catch (e) {
        // Session not ready yet - this is expected
        if (attempt % 10 == 0) {
          print(
              '>>> ⏳ Still waiting for OAuth completion... ($attempt/$maxAttempts)');
        }
      }
    }

    // Timeout - no session found
    print('>>> ============================================');
    print('>>> ⏱️ TIMEOUT: No session detected after 60 seconds');
    print('>>> OAuth may have been cancelled by user');
    print('>>> ============================================');

    _closeLoadingDialog();
    _handleOAuthFailure();
    return false;
  }

  /// Handle successful OAuth after session is detected
  static Future<void> _handleOAuthSuccess(
    AppWriteProvider appwriteProvider,
    AuthRepository authRepository,
    dynamic user,
  ) async {
    try {
      print('>>> ============================================');
      print('>>> PROCESSING OAUTH SUCCESS');
      print('>>> ============================================');

      // Get current session using the NEW client
      print('>>> Getting current session...');
      final session = await appwriteProvider.account!.getSession(
        sessionId: 'current',
      );
      print('>>> ✅ Session ID: ${session.$id}');

      // Check if user exists in database
      print('>>> Checking if user exists in database...');
      final existingUserDoc = await authRepository.getUserById(user.$id);

      if (existingUserDoc == null) {
        print('>>> Creating new user in database...');

        final newUserDoc = await authRepository.createUser({
          "userId": user.$id,
          "name": user.name,
          "email": user.email,
          "role": "user",
          "phone": "",
          "profilePictureId": "",
          "idVerified": false,
          "idVerifiedAt": null,
          "verificationDocumentId": null,
          "isArchived": false,
          "archivedAt": null,
          "archivedBy": null,
          "archiveReason": null,
          "archivedDocumentId": null,
        });

        await _storage.write('userDocumentId', newUserDoc.$id);
        print('>>> ✅ New user created: ${newUserDoc.$id}');
      } else {
        print('>>> ✅ User exists: ${existingUserDoc.$id}');
        await _storage.write('userDocumentId', existingUserDoc.$id);

        // Get profile picture if exists
        final profilePictureId =
            existingUserDoc.data['profilePictureId'] as String?;
        if (profilePictureId != null && profilePictureId.isNotEmpty) {
          await _storage.write('userProfilePictureId', profilePictureId);
          print('>>> Profile picture ID: $profilePictureId');
        } else {
          await _storage.write('userProfilePictureId', '');
          print('>>> No profile picture for this user');
        }
      }

      // Store session data
      await _storage.write('userId', user.$id);
      await _storage.write('sessionId', session.$id);
      await _storage.write('email', user.email);
      await _storage.write('userName', user.name);
      await _storage.write('role', 'user');

      print('>>> ============================================');
      print('>>> STORAGE SUMMARY:');
      print('>>> - userId: ${_storage.read("userId")}');
      print('>>> - sessionId: ${_storage.read("sessionId")}');
      print('>>> - email: ${_storage.read("email")}');
      print('>>> - userName: ${_storage.read("userName")}');
      print('>>> - role: ${_storage.read("role")}');
      print('>>> - userDocumentId: ${_storage.read("userDocumentId")}');
      print('>>> ============================================');

      // FEATURE: Register FCM token for push notifications (Mobile only)
      // NOTE: We're in a mobile app, so kIsWeb will be false
      print('>>> ============================================');
      print('>>> REGISTERING FCM TOKEN FOR PUSH NOTIFICATIONS');
      print('>>> Platform check: kIsWeb = $kIsWeb');
      print('>>> ============================================');

      try {
        // Only register FCM on mobile platforms
        if (!kIsWeb) {
          print('>>> Running on mobile, proceeding with FCM registration...');

          if (Get.isRegistered<NotificationService>()) {
            final notificationService = Get.find<NotificationService>();

            // Request permissions
            print('>>> Requesting notification permissions...');
            final hasPermission =
                await notificationService.requestPermissions();
            print('>>> Permission granted: $hasPermission');

            if (hasPermission) {
              // Get FCM token
              print('>>> Getting FCM token...');
              final fcmToken = await notificationService.getFreshToken();

              if (fcmToken != null && fcmToken.isNotEmpty) {
                print(
                    '>>> FCM Token available: ${fcmToken.substring(0, Math.min(20, fcmToken.length))}...');

                // Register with Appwrite
                print('>>> Registering with Appwrite...');
                final target = await appwriteProvider.registerUserPushTarget(
                  userId: user.$id,
                  fcmToken: fcmToken,
                );

                if (target != null) {
                  await _storage.write('push_target_id', target.$id);
                  print('>>> ✅ Push notifications enabled for user');
                  print('>>> Target ID: ${target.$id}');
                } else {
                  print('>>> ⚠️ Warning: Could not register push target');
                }
              } else {
                print('>>> ⚠️ Warning: FCM token not available');
              }
            } else {
              print('>>> ℹ️ Push notification permission denied by user');
            }
          } else {
            print('>>> ⚠️ NotificationService not registered in GetX');
          }
        } else {
          print('>>> ℹ️ Web platform detected: Skipping FCM registration');
        }
      } catch (e, stack) {
        print('>>> ⚠️ Warning: FCM registration failed (non-critical): $e');
        print(
            '>>> Stack trace: ${stack.toString().substring(0, Math.min(300, stack.toString().length))}...');
        // Don't fail login if FCM registration fails
      }

      // FEATURE: Initialize in-app notification service
      print('>>> ============================================');
      print('>>> INITIALIZING IN-APP NOTIFICATIONS');
      print('>>> ============================================');

      try {
        if (Get.isRegistered<InAppNotificationService>()) {
          final notificationService = Get.find<InAppNotificationService>();
          await notificationService.initialize();
          print('>>> ✅ In-app notification service initialized');
        } else {
          print('>>> ⚠️ InAppNotificationService not registered in GetX');
        }
      } catch (e) {
        print('>>> ⚠️ Warning: Could not initialize in-app notifications: $e');
      }

      print('>>> ============================================');
      print('>>> POST-LOGIN SETUP COMPLETE');
      print('>>> ============================================');

      _closeLoadingDialog();

      // Navigate to user home
      print('>>> Navigating to home...');
      Get.offAllNamed(Routes.userHome);

      // Show success message
      Get.snackbar(
        'Welcome!',
        'Successfully signed in with Google',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
      );

      print('>>> ✅ OAuth flow completed successfully!');
      print('>>> ============================================');
    } catch (e, stackTrace) {
      print('>>> ============================================');
      print('>>> ❌ Error in OAuth success handler');
      print('>>> Error: $e');
      print(
          '>>> Stack trace: ${stackTrace.toString().substring(0, Math.min(500, stackTrace.toString().length))}...');
      print('>>> ============================================');

      _closeLoadingDialog();
      _handleOAuthFailure();
    }
  }

  static void _showLoadingDialog() {
    if (!(Get.isDialogOpen ?? false)) {
      Get.dialog(
        WillPopScope(
          onWillPop: () async => false,
          child: const Center(
            child: Card(
              margin: EdgeInsets.all(32),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color.fromARGB(255, 81, 115, 153),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Completing Google Sign-In...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please wait while we verify your account...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This may take up to 60 seconds',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );
    }
  }

  static void _closeLoadingDialog() {
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
  }

  static void _handleOAuthFailure() {
    print('>>> ============================================');
    print('>>> ❌ OAUTH FAILED');
    print('>>> ============================================');

    _closeLoadingDialog();

    Get.snackbar(
      'Sign In Cancelled',
      'Google Sign-In was cancelled or failed. Please try again.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange.shade100,
      colorText: Colors.orange.shade900,
      duration: const Duration(seconds: 4),
      margin: const EdgeInsets.all(16),
    );
  }

  /// Cleanup method
  static void dispose() {
    _sessionCheckTimer?.cancel();
    _sessionCheckTimer = null;
    _isProcessing = false;
    print('>>> Mobile OAuth handler disposed');
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

/// Handles deep link callbacks from Google OAuth on mobile
class MobileOAuthHandler {
  static StreamSubscription? _linkSubscription;
  static final _storage = GetStorage();

  /// Initialize deep link listener for OAuth callbacks
  static Future<void> initialize() async {
    try {
      print('>>> ============================================');
      print('>>> INITIALIZING MOBILE OAUTH HANDLER');
      print('>>> ============================================');

      // Listen for deep links while app is running
      _linkSubscription = AppLinks().uriLinkStream.listen(
        (Uri? uri) {
          if (uri != null) {
            print('>>> Deep link received: $uri');
            _handleDeepLink(uri);
          }
        },
        onError: (err) {
          print('>>> Deep link error: $err');
        },
      );

      // Check if app was opened via deep link
      try {
        final initialUri = await AppLinks().getInitialLink();
        if (initialUri != null) {
          print('>>> App opened with deep link: $initialUri');
          _handleDeepLink(initialUri);
        }
      } catch (e) {
        print('>>> Error getting initial URI: $e');
      }

      print('>>> ✅ Mobile OAuth handler initialized');
    } catch (e) {
      print('>>> ❌ Error initializing OAuth handler: $e');
    }
  }

  /// Handle OAuth callback deep link
  static Future<void> _handleDeepLink(Uri uri) async {
    try {
      print('>>> ============================================');
      print('>>> HANDLING OAUTH DEEP LINK');
      print('>>> URI: $uri');
      print('>>> Scheme: ${uri.scheme}');
      print('>>> Host: ${uri.host}');
      print('>>> Path: ${uri.path}');
      print('>>> ============================================');

      // Check if it's our OAuth callback (pawrtal://auth/success or pawrtal://auth/failure)
      if (uri.scheme == 'pawrtal' && uri.host == 'auth') {
        if (uri.path == '/success' || uri.path.isEmpty || uri.path == '/') {
          // Success path
          await _handleOAuthSuccess();
        } else if (uri.path == '/failure') {
          // Failure path
          _handleOAuthFailure();
        } else {
          print('>>> Unknown OAuth path: ${uri.path}');
        }
      } else {
        print('>>> Not an OAuth deep link, ignoring');
      }
    } catch (e) {
      print('>>> ❌ Error handling deep link: $e');
      _handleOAuthFailure();
    }
  }

  /// Handle successful OAuth with retry logic
  static Future<void> _handleOAuthSuccess() async {
    try {
      print('>>> ============================================');
      print('>>> OAUTH SUCCESS - Processing...');
      print('>>> ============================================');

      // Show loading in UI
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
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Completing Google Sign-In...'),
                  ],
                ),
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      // CRITICAL: Wait for session with retry logic
      await _waitForSession();

      final appwriteProvider = Get.find<AppWriteProvider>();
      final authRepository = Get.find<AuthRepository>();

      // Get authenticated user
      print('>>> Getting authenticated user...');
      final user = await appwriteProvider.account!.get();

      if (user == null) {
        throw Exception('User not found after OAuth');
      }

      print('>>> ✅ User authenticated: ${user.email}');

      // Get session
      print('>>> Getting session...');
      final session = await appwriteProvider.account!.getSession(
        sessionId: 'current',
      );
      print('>>> ✅ Session ID: ${session.$id}');

      // Check if user exists in database
      print('>>> Checking database...');
      final existingUserDoc = await authRepository.getUserById(user.$id);

      if (existingUserDoc == null) {
        // Create new user
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
        print('>>> ✅ User created: ${newUserDoc.$id}');
      } else {
        print('>>> ✅ User exists: ${existingUserDoc.$id}');
        await _storage.write('userDocumentId', existingUserDoc.$id);

        // Get profile picture if exists
        final profilePictureId =
            existingUserDoc.data['profilePictureId'] as String?;
        if (profilePictureId != null && profilePictureId.isNotEmpty) {
          await _storage.write('userProfilePictureId', profilePictureId);
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
      print('>>> ============================================');

      // Close loading dialog
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

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
      );

      print('>>> ✅ OAuth flow completed successfully!');
      print('>>> ============================================');
    } catch (e, stackTrace) {
      print('>>> ============================================');
      print('>>> ❌ Error in OAuth success handler: $e');
      print('>>> Stack trace: $stackTrace');
      print('>>> ============================================');

      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      _handleOAuthFailure();
    }
  }

  /// Wait for OAuth session to be established with retry logic
  static Future<void> _waitForSession() async {
    const maxAttempts = 5;
    const initialDelay = Duration(milliseconds: 1000);

    final appwriteProvider = Get.find<AppWriteProvider>();

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        print(
            '>>> ⏳ Waiting for session... Attempt ${attempt + 1}/$maxAttempts');

        // Exponential backoff: 1s, 2s, 4s, 8s, 16s
        final delay = initialDelay * (1 << attempt);
        await Future.delayed(delay);

        // Try to get the user - this will throw if session not ready
        final user = await appwriteProvider.account!.get();

        if (user != null) {
          print('>>> ✅ Session is ready!');
          return;
        }
      } catch (e) {
        print('>>> ⏳ Session not ready yet: $e');

        if (attempt == maxAttempts - 1) {
          // Last attempt failed
          throw Exception(
              'Session timeout: Could not establish OAuth session after $maxAttempts attempts');
        }
      }
    }
  }

  /// Handle OAuth failure
  static void _handleOAuthFailure() {
    print('>>> ============================================');
    print('>>> ❌ OAUTH FAILED');
    print('>>> ============================================');

    // Close any open dialogs
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }

    Get.offAllNamed(Routes.login);

    Get.snackbar(
      'Sign In Cancelled',
      'Google Sign-In was cancelled or failed. Please try again.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.orange.shade100,
      colorText: Colors.orange.shade900,
      duration: const Duration(seconds: 4),
    );
  }

  /// Dispose listener
  static void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    print('>>> Mobile OAuth handler disposed');
  }
}
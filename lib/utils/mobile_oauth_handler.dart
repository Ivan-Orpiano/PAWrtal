import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';

/// Handles deep link callbacks from Google OAuth on mobile
/// This works with the pawrtal:// custom scheme registered in AndroidManifest.xml
class MobileOAuthHandler {
  static StreamSubscription? _linkSubscription;
  static final _storage = GetStorage();
  static bool _isProcessing = false; // Prevent duplicate processing

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
            print('>>> 📲 Deep link received: $uri');
            _handleDeepLink(uri);
          }
        },
        onError: (err) {
          print('>>> ❌ Deep link error: $err');
        },
      );

      // Check if app was opened via deep link
      try {
        final initialUri = await AppLinks().getInitialLink();
        if (initialUri != null) {
          print('>>> 📲 App opened with deep link: $initialUri');
          _handleDeepLink(initialUri);
        }
      } catch (e) {
        print('>>> Error getting initial URI: $e');
      }

      print('>>> ✅ Mobile OAuth handler initialized');
      print('>>> Listening for: pawrtal://auth/*');
    } catch (e) {
      print('>>> ❌ Error initializing OAuth handler: $e');
    }
  }

  /// Handle OAuth callback deep link
  static Future<void> _handleDeepLink(Uri uri) async {
    // Prevent duplicate processing
    if (_isProcessing) {
      print('>>> ⚠️ Already processing an OAuth callback, ignoring...');
      return;
    }

    try {
      print('>>> ============================================');
      print('>>> HANDLING OAUTH DEEP LINK');
      print('>>> URI: $uri');
      print('>>> Scheme: ${uri.scheme}');
      print('>>> Host: ${uri.host}');
      print('>>> Path: ${uri.path}');
      print('>>> ============================================');

      // Check if it's our OAuth callback
      // Accepts: pawrtal://auth/success, pawrtal://auth/failure, or pawrtal://auth
      if (uri.scheme == 'pawrtal' && uri.host == 'auth') {
        _isProcessing = true;
        
        // Determine success or failure
        if (uri.path == '/success' || uri.path.isEmpty || uri.path == '/') {
          await _handleOAuthSuccess();
        } else if (uri.path == '/failure') {
          _handleOAuthFailure();
        } else {
          print('>>> ⚠️ Unknown OAuth path: ${uri.path}');
          _handleOAuthFailure();
        }
      } else {
        print('>>> ℹ️ Not an OAuth deep link (expected pawrtal://auth), ignoring');
      }
    } catch (e) {
      print('>>> ❌ Error handling deep link: $e');
      _handleOAuthFailure();
    } finally {
      _isProcessing = false;
    }
  }

  /// Handle successful OAuth with retry logic
  static Future<void> _handleOAuthSuccess() async {
    try {
      print('>>> ============================================');
      print('>>> ✅ OAUTH SUCCESS - Processing...');
      print('>>> ============================================');

      // Show loading dialog
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
                      'Please wait...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
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

      // Wait for session to be established
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
      print('>>> User ID: ${user.$id}');
      print('>>> User Name: ${user.name}');

      // Get session
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
        final profilePictureId = existingUserDoc.data['profilePictureId'] as String?;
        if (profilePictureId != null && profilePictureId.isNotEmpty) {
          await _storage.write('userProfilePictureId', profilePictureId);
          print('>>> Profile picture ID: $profilePictureId');
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
        margin: const EdgeInsets.all(16),
      );

      print('>>> ✅ OAuth flow completed successfully!');
      print('>>> ============================================');
      
    } catch (e, stackTrace) {
      print('>>> ============================================');
      print('>>> ❌ Error in OAuth success handler');
      print('>>> Error: $e');
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
    const maxAttempts = 8; // Increased attempts
    const initialDelay = Duration(milliseconds: 1000);
    
    final appwriteProvider = Get.find<AppWriteProvider>();
    
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        print('>>> ⏳ Waiting for session... Attempt ${attempt + 1}/$maxAttempts');
        
        // Progressive delays: 1s, 2s, 3s, 4s, 5s, 6s, 7s, 8s
        final delay = initialDelay * (attempt + 1);
        await Future.delayed(delay);
        
        // Try to get the user - this will throw if session not ready
        final user = await appwriteProvider.account!.get();
        
        if (user != null) {
          print('>>> ✅ Session is ready!');
          return;
        }
      } catch (e) {
        final errorMsg = e.toString();
        print('>>> ⏳ Attempt ${attempt + 1} failed: ${errorMsg.substring(0, errorMsg.length > 80 ? 80 : errorMsg.length)}...');
        
        if (attempt == maxAttempts - 1) {
          throw Exception('Session timeout: Could not establish OAuth session after $maxAttempts attempts (${maxAttempts * (maxAttempts + 1) ~/ 2} seconds)');
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

    // Navigate back to login
    Get.offAllNamed(Routes.login);

    // Show error message
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

  /// Dispose listener when no longer needed
  static void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _isProcessing = false;
    print('>>> Mobile OAuth handler disposed');
  }
}
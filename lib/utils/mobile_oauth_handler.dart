import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:appwrite/enums.dart';
import 'dart:async';

/// Handles OAuth for mobile using Appwrite SDK's built-in OAuth
/// NO external packages needed - uses appwrite's createOAuth2Session
class MobileOAuthHandler {
  static final _storage = GetStorage();
  static bool _isProcessing = false;
  static Completer<bool>? _oauthCompleter;

  /// Initialize and handle Google OAuth flow
  static Future<bool> initiateGoogleOAuth() async {
    if (_isProcessing) {
      print('>>> ⚠️ OAuth already in progress, ignoring...');
      return false;
    }

    try {
      _isProcessing = true;
      _oauthCompleter = Completer<bool>();
      
      print('>>> ============================================');
      print('>>> MOBILE: INITIATING GOOGLE OAUTH');
      print('>>> ============================================');

      final appwriteProvider = Get.find<AppWriteProvider>();

      print('>>> Launching OAuth browser...');
      
      // CRITICAL: This opens the browser and automatically handles the redirect
      // It returns a boolean indicating success/failure
      final result = await appwriteProvider.account!.createOAuth2Session(
        provider: OAuthProvider.google,
      );

      print('>>> OAuth browser returned: $result');

      if (result == true || result == false) {
        // The OAuth completed (either success or failure)
        if (result == true) {
          print('>>> ✅ OAuth succeeded, processing...');
          await _handleOAuthSuccess();
          return true;
        } else {
          print('>>> ❌ OAuth failed');
          _handleOAuthFailure();
          return false;
        }
      } else {
        // Unexpected result
        print('>>> ⚠️ Unexpected OAuth result: $result');
        _handleOAuthFailure();
        return false;
      }
      
    } catch (e, stackTrace) {
      print('>>> ============================================');
      print('>>> ❌ OAuth error: $e');
      print('>>> Type: ${e.runtimeType}');
      print('>>> Stack: ${stackTrace.toString().substring(0, 500)}...');
      print('>>> ============================================');
      
      _handleOAuthFailure();
      return false;
    } finally {
      _isProcessing = false;
      _oauthCompleter = null;
    }
  }

  /// Handle successful OAuth
  static Future<void> _handleOAuthSuccess() async {
    try {
      print('>>> ============================================');
      print('>>> PROCESSING OAUTH SUCCESS');
      print('>>> ============================================');

      final appwriteProvider = Get.find<AppWriteProvider>();
      final authRepository = Get.find<AuthRepository>();

      _showLoadingDialog();

      // IMPORTANT: Wait for session to be fully established
      print('>>> Waiting for session to stabilize...');
      await Future.delayed(const Duration(milliseconds: 2000));

      // Get authenticated user
      print('>>> Getting authenticated user...');
      final user = await appwriteProvider.account!.get();

      if (user == null) {
        throw Exception('User not found after OAuth');
      }

      print('>>> ✅ User authenticated: ${user.email}');
      print('>>> User ID: ${user.$id}');
      print('>>> User Name: ${user.name}');

      // Get current session
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
      print('>>> Stack trace: ${stackTrace.toString().substring(0, 500)}...');
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
}
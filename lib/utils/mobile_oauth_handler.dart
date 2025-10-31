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

      print('>>> Mobile OAuth handler initialized');
    } catch (e) {
      print('>>> Error initializing OAuth handler: $e');
    }
  }

  /// Handle OAuth callback deep link
  static Future<void> _handleDeepLink(Uri uri) async {
    try {
      print('>>> ============================================');
      print('>>> HANDLING OAUTH CALLBACK');
      print('>>> URI: $uri');
      print('>>> Scheme: ${uri.scheme}');
      print('>>> Host: ${uri.host}');
      print('>>> Path: ${uri.path}');
      print('>>> ============================================');

      // CRITICAL: Check for mobile auth callbacks from web domain
      if (uri.scheme == 'https' && uri.host == 'www.pawrtal.online') {
        if (uri.path == '/mobile-auth-success') {
          print('>>> ✅ Mobile OAuth SUCCESS detected');
          await _handleOAuthSuccess();
        } else if (uri.path == '/mobile-auth-failure') {
          print('>>> ❌ Mobile OAuth FAILURE detected');
          _handleOAuthFailure();
        }
      }
    } catch (e) {
      print('>>> Error handling deep link: $e');
      _handleOAuthFailure();
    }
  }

  /// Handle successful OAuth
  static Future<void> _handleOAuthSuccess() async {
    try {
      print('>>> OAuth SUCCESS - Processing...');

      // Wait for Appwrite session to be established
      await Future.delayed(const Duration(milliseconds: 2000));

      final appwriteProvider = Get.find<AppWriteProvider>();
      final authRepository = Get.find<AuthRepository>();

      // Get authenticated user
      final user = await appwriteProvider.account!.get();

      if (user == null) {
        throw Exception('User not found after OAuth');
      }

      print('>>> User authenticated: ${user.email}');

      // Get session
      final session = await appwriteProvider.account!.getSession(
        sessionId: 'current',
      );

      // Check if user exists in database
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
        print('>>> User created: ${newUserDoc.$id}');
      } else {
        print('>>> User exists: ${existingUserDoc.$id}');
        await _storage.write('userDocumentId', existingUserDoc.$id);

        // Get profile picture if exists
        final profilePictureId = existingUserDoc.data['profilePictureId'] as String?;
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

      print('>>> Session stored, navigating to home...');

      // Navigate to user home
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

      print('>>> OAuth flow completed successfully');
    } catch (e) {
      print('>>> Error in OAuth success handler: $e');
      _handleOAuthFailure();
    }
  }

  /// Handle OAuth failure
  static void _handleOAuthFailure() {
    print('>>> OAuth FAILED');

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
  }
}
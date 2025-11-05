import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';

class AuthMiddleware extends GetMiddleware {
  final GetStorage _storage = GetStorage();

  @override
  int? get priority => 2; // Runs after RouteGuard

  @override
  RouteSettings? redirect(String? route) {
    return null; // No redirect, just validation
  }

  @override
  GetPage? onPageCalled(GetPage? page) {
    print('>>> AUTH MIDDLEWARE: Page called - ${page?.name}');
    
    // Skip validation for public pages
    if (page?.name == Routes.landing ||
        page?.name == Routes.login || 
        page?.name == Routes.signup || 
        page?.name == Routes.splash) {
      return page;
    }

    // Validate session is still active
    _validateSession();
    
    return page;
  }

  /// Validate if the user's session is still active
  Future<void> _validateSession() async {
    try {
      final sessionId = _storage.read('sessionId');
      
      if (sessionId == null) {
        print('>>> ⚠️ No session ID found');
        return;
      }

      print('>>> Validating session: ${sessionId.substring(0, 8)}...');

      // Check with Appwrite if session is still valid
      final appWriteProvider = AppWriteProvider();
      final isValid = await appWriteProvider.isSessionValid();

      if (!isValid) {
        print('>>> ✗ Session invalid - logging out');
        _handleInvalidSession();
      } else {
        print('>>> ✓ Session valid');
      }
    } catch (e) {
      print('>>> ✗ Session validation error: $e');
      _handleInvalidSession();
    }
  }

  /// Handle invalid session
  void _handleInvalidSession() {
    // Clear storage
    _storage.erase();
    
    // Redirect to landing page
    Future.delayed(Duration.zero, () {
      Get.offAllNamed(Routes.landing);
      Get.snackbar(
        'Session Expired',
        'Please log in again',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    });
  }
}
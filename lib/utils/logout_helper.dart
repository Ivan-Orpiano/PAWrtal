import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LogoutHelper {
  static final GetStorage _getStorage = GetStorage();
  static final AppWriteProvider _appWriteProvider = AppWriteProvider();

  static Future<void> logout() async {
    try {
      // Logout from Appwrite - use the method that exists in your AppWriteProvider
      // If you don't have a webLogout method, just use account.deleteSession
      try {
        await _appWriteProvider.account?.deleteSession(sessionId: 'current');
      } catch (e) {
        // Even if logout fails, we should clear local storage
        print('Logout error: $e');
      }
      
      // Clear all stored user data
      await _getStorage.remove("userId");
      await _getStorage.remove("sessionId");
      await _getStorage.remove("role");
      await _getStorage.remove("email");
      await _getStorage.remove("userName");
      await _getStorage.remove("clinicId");
      await _getStorage.remove("staffId");
      await _getStorage.remove("customerId");
      
      // Navigate to login page
      Get.offAllNamed(Routes.login);
      
      Get.snackbar(
        'Success',
        'Logged out successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'An error occurred during logout: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
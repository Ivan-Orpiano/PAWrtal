import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/notification/services/in_app_notification_service.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/utils/web_error_handler.dart';
import 'package:capstone_app/utils/web_loading_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:capstone_app/utils/session_manager.dart';
import 'package:capstone_app/utils/security_monitor.dart';

class WebLoginController extends GetxController {
  final AuthRepository _authRepository;
  WebLoginController(this._authRepository);

  final GetStorage _getStorage = GetStorage();

  // Form controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final emailForPasswordResetController = TextEditingController();

  // Form key
  final formKey = GlobalKey<FormState>();
  final resetPasswordFormKey = GlobalKey<FormState>();

  // Reactive variables
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final errorMessage = ''.obs; // NEW: For unified error messages
  final isGoogleLoading = false.obs;

  final AppWriteProvider _appWriteProvider = AppWriteProvider();

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void navigateToSignUp() {
    Get.toNamed(Routes.signup);
  }

  // REMOVED: Old validateEmail method - only used for password reset now
  // Keeping separate method for password reset since it requires actual email
  String? validateEmailForReset(String? value) {
    if (value == null || !GetUtils.isEmail(value)) {
      return "Provide a valid Email";
    }
    return null;
  }

  /// NEW: Validator for username or email - accepts both formats
  /// Just checks: not empty and max 50 characters
  String? validateEmailOrUsername(String? value) {
    if (value!.trim().length > 50) {
      return "Maximum 50 characters allowed";
    }

    return null;
  }

  /// UPDATED: Password validator with 50 character limit
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Please enter your password";
    }

    if (value.length > 50) {
      return "Maximum 50 characters allowed";
    }
    return null;
  }

  Future<void> signIn() async {
    // Clear any previous error
    errorMessage.value = '';

    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      print('>>> ============================================');
      print('>>> WEB LOGIN CONTROLLER: Starting login...');
      print('>>> ============================================');

      // CRITICAL FIX: Clear any existing dashboard controller before login
      _clearExistingControllers();

      final emailOrUsername = emailController.text.trim();
      print('>>> Input: $emailOrUsername');
      print(
          '>>> Input Type: ${emailOrUsername.contains('@') ? 'EMAIL' : 'USERNAME'}');

      // Call the repository login method
      final value = await _authRepository.login({
        "email": emailOrUsername,
        "password": passwordController.text,
      });

      try {
        final notificationService = Get.find<InAppNotificationService>();
        await notificationService.initialize();
        print('>>> Notification service initialized after login');
      } catch (e) {
        print('>>> Warning: Could not initialize notifications: $e');
      }

      print('>>> Login response received');
      print('>>> Response keys: ${value.keys}');

      // Validate response
      final session = value["session"];
      if (session == null) {
        throw Exception("Login failed: Session data is missing");
      }
      final userId = session.userId;

      final user = value["user"];
      if (user == null) {
        throw Exception("Login failed: User data is missing");
      }
      final userEmail = user.email;

      // Store basic user info
      await _getStorage.write("userId", userId);
      await _getStorage.write("sessionId", session.$id);
      await _getStorage.write("email", userEmail);

      if (user.name != null) {
        await _getStorage.write("userName", user.name);
      }

      print('>>> User ID: $userId');
      print('>>> Email: $userEmail');

      // Get role from response (already determined by provider)
      String role = value["role"] ?? "";
      print('>>> Role from response: $role');

      if (role.isEmpty) {
        throw Exception("Login failed: Role not determined");
      }

      // Store role-specific data
      if (role == "admin") {
        print('>>> Processing ADMIN login...');

        final clinicId = value["clinicId"];
        if (clinicId != null && clinicId.isNotEmpty) {
          await _getStorage.write("clinicId", clinicId);
          print('>>> Clinic ID stored: $clinicId');
        } else {
          print('>>> WARNING: Admin has no clinic ID!');
        }
      } else if (role == "staff") {
        print('>>> Processing STAFF login...');

        final clinicId = value["clinicId"];
        if (clinicId != null && clinicId.isNotEmpty) {
          await _getStorage.write("clinicId", clinicId);
          print('>>> Clinic ID stored: $clinicId');
        } else {
          print('>>> WARNING: Staff has no clinic ID!');
        }

        if (value["staffDocumentId"] != null) {
          await _getStorage.write("staffId", value["staffDocumentId"]);
          print('>>> Staff ID stored: ${value["staffDocumentId"]}');
        }

        if (value["authorities"] != null) {
          await _getStorage.write("authorities", value["authorities"]);
          print('>>> Authorities stored: ${value["authorities"]}');
        } else {
          print('>>> WARNING: Staff has no authorities!');
          await _getStorage.write("authorities", <String>[]);
        }
      } else if (role == "user") {
        print('>>> Processing USER login...');
        // No additional data needed for regular users
      }

      // Store the role
      await _getStorage.write("role", role);

      _initializeSecureSession(userId, role);

      print('>>> ============================================');
      print('>>> STORAGE SUMMARY:');
      print('>>> - userId: ${_getStorage.read("userId")}');
      print('>>> - role: ${_getStorage.read("role")}');
      print('>>> - clinicId: ${_getStorage.read("clinicId")}');
      print('>>> - authorities: ${_getStorage.read("authorities")}');
      print('>>> ============================================');

      // Navigate based on role
      print('>>> Navigating to home...');
      _navigateBasedOnRole(role);

      // Clear controllers
      _clearControllers();
    } catch (e) {
      print('>>> ============================================');
      print('>>> WEB LOGIN CONTROLLER ERROR: $e');
      print('>>> ============================================');

      // UNIFIED ERROR MESSAGE: Always show this for any login error
      errorMessage.value =
          'Invalid username/email or password. Please try again.';

      // Don't use WebErrorHandler for login errors - show in UI instead
      // WebErrorHandler.handleError(e, context: 'Login');
    } finally {
      isLoading.value = false;
    }
  }

  // CRITICAL FIX: Clear any existing controllers to prevent data persistence
  void _clearExistingControllers() {
    try {
      print('>>> Clearing existing controllers...');

      // Delete AdminDashboardController if it exists
      if (Get.isRegistered<dynamic>(tag: 'AdminDashboardController')) {
        Get.delete<dynamic>(tag: 'AdminDashboardController', force: true);
        print('>>> AdminDashboardController deleted (tagged)');
      }

      // Try to delete by finding it
      try {
        Get.delete(force: true);
      } catch (e) {
        // Ignore if not found
      }

      print('>>> Controller cleanup complete');
    } catch (e) {
      print('>>> Error during controller cleanup: $e');
      // Continue anyway - not critical
    }
  }

  Future<void> signInWithGoogle() async {
    if (isLoading.value || isGoogleLoading.value) return;

    try {
      isGoogleLoading.value = true;
      errorMessage.value = '';

      print('>>> WEB LOGIN: Initiating Google Sign-In...');

      final appWriteProvider = Get.find<AppWriteProvider>();

      // This will redirect to Google OAuth
      await appWriteProvider.signInWithGoogle();

      // Code won't reach here due to redirect
    } catch (e) {
      print('>>> WEB LOGIN: Google Sign-In error: $e');

      isGoogleLoading.value = false;

      errorMessage.value =
          'Google Sign-In failed. Please try again or use email/password.';
    }
  }

  Future<void> sendPasswordResetEmail() async {
    if (!resetPasswordFormKey.currentState!.validate()) return;

    try {
      final email = emailForPasswordResetController.text.trim();

      print('>>> ============================================');
      print('>>> WEB FORGOT PASSWORD REQUEST');
      print('>>> Email: $email');
      print('>>> ============================================');

      WebLoadingHelper.showLoading(message: 'Sending password reset email...');

      final result = await _authRepository.sendPasswordResetEmail(email);

      WebLoadingHelper.hideLoading();

      if (result['success'] == true) {
        print('>>> ✅ Password reset email sent');

        emailForPasswordResetController.clear();

        WebErrorHandler.handleSuccess(
          result['message'] ??
              'Password reset link sent to your email. Please check your inbox.',
        );
      } else {
        print('>>> ❌ Failed to send password reset email');

        WebErrorHandler.handleError(
          result['message'] ?? 'Failed to send password reset email',
        );
      }

      print('>>> ============================================');
    } catch (e) {
      print('>>> ❌ Error sending password reset email: $e');

      WebLoadingHelper.hideLoading();
      WebErrorHandler.handleError(e, context: 'Password Reset');
    }
  }

  void _navigateBasedOnRole(String? role) {
    print('>>> Navigating for role: $role');

    switch (role) {
      case "admin":
      case "staff":
        print('>>> -> adminHome');
        Get.offAllNamed(Routes.adminHome);
        WebErrorHandler.handleSuccess('Login successful');
        break;
      case "developer":
        print('>>> -> superAdminHome');
        Get.offAllNamed(Routes.superAdminHome);
        WebErrorHandler.handleSuccess('Login successful');
        break;
      case "user":
        print('>>> -> userHome');
        Get.offAllNamed(Routes.userHome);
        WebErrorHandler.handleSuccess('Login successful');
        break;
      default:
        print('>>> ERROR: Invalid role');
        WebErrorHandler.handleError('No account detected');
        break;
    }
  }

  void _clearControllers() {
    emailController.clear();
    passwordController.clear();
    errorMessage.value = '';
  }

  @override
  void onClose() {
    // emailController.dispose();
    // passwordController.dispose();
    emailForPasswordResetController.dispose();
    super.onClose();
  }

  void _initializeSecureSession(String userId, String role) {
    print('>>> ============================================');
    print('>>> WEB: INITIALIZING SECURE SESSION');
    print('>>> User ID: $userId');
    print('>>> Role: $role');
    print('>>> ============================================');

    // Store session timestamp
    _getStorage.write('sessionTimestamp', DateTime.now().toIso8601String());

    // Start session monitoring
    SessionManager.startSessionMonitoring();

    // Log successful login event
    SecurityMonitor.logSecurityEvent(
      eventType: 'WEB_LOGIN_SUCCESS',
      userId: userId,
      details: 'Role: $role, Platform: Web',
    );

    // Clean up old security data
    SessionManager.cleanupOldData();

    print('>>> Secure session initialized');
    print('>>> ============================================');
  }
}

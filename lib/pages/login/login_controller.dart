import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/notification/services/in_app_notification_service.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/utils/custom_snack_bar.dart';
import 'package:capstone_app/utils/full_screen_dialog_loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone_app/data/models/staff_model.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:capstone_app/notification/services/notification_service.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';

import 'package:capstone_app/utils/session_manager.dart';
import 'package:capstone_app/utils/security_monitor.dart';

class LoginController extends GetxController {
  AuthRepository authRepository;
  LoginController(this.authRepository);

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController emailEditingController = TextEditingController();
  TextEditingController passwordEditingController = TextEditingController();
  TextEditingController emailForPasswordResetController =
      TextEditingController();

  bool isFormValid = false;

  final GetStorage _getStorage = GetStorage();

  // Observable for password visibility
  final isPasswordVisible = false.obs;

  // Observable for error message
  final errorMessage = ''.obs;

  // NEW: Observable for Google Sign-In loading
  final isGoogleLoading = false.obs;

  @override
  void onClose() {
    super.onClose();
    emailEditingController.dispose();
    passwordEditingController.dispose();
    emailForPasswordResetController.dispose();
  }

  void clearTextEditingControllers() {
    emailEditingController.clear();
    passwordEditingController.clear();
    errorMessage.value = '';
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  // REMOVED: Old validateEmail method - no longer needed

  /// Validator for username or email - accepts both formats
  /// Just checks: not empty and max 50 characters
  String? validateEmailOrUsername(String value) {
    // Check length limit (50 characters)
    if (value.length > 50) {
      return "Maximum 50 characters allowed";
    }

    // That's it! No format validation - let the database check handle it
    return null;
  }

  /// Password validator with 50 character limit
  String? validatePassword(String value) {
    if (value.isEmpty) {
      return "Please enter your password";
    }

    return null;
  }

  /// Login method - accepts username or email
  /// Shows "Invalid username/email or password" for any login failure
  void validateAndLogin({
    required String emailOrUsername,
    required String password,
  }) async {
    // Clear any previous error
    errorMessage.value = '';

    // Trim inputs
    emailOrUsername = emailOrUsername.trim();
    password = password.trim();

    isFormValid = formKey.currentState!.validate();
    if (!isFormValid) return;

    String? sessionId;

    try {
      formKey.currentState!.save();
      FullScreenDialogLoader.showDialog();

      print('>>> ==========================================');
      print('>>> LOGIN ATTEMPT');
      print('>>> Input: $emailOrUsername');
      print(
          '>>> Input Type: ${emailOrUsername.contains('@') ? 'EMAIL' : 'USERNAME'}');
      print('>>> ==========================================');

      // Check if input is username or email
      final isEmail = emailOrUsername.contains('@');

      if (!isEmail) {
        // It's a username - check if staff account exists first in database
        print(
            '>>> Detected USERNAME format, checking staff account in database...');
        final staffDoc =
            await authRepository.getStaffByUsername(emailOrUsername);

        if (staffDoc == null) {
          print('>>> ✗ No staff account found with username: $emailOrUsername');
          FullScreenDialogLoader.cancelDialog();
          errorMessage.value =
              'Invalid username/email or password. Please check your credentials.';
          return;
        }

        if (!staffDoc.isActive) {
          print('>>> ✗ Staff account is deactivated');
          FullScreenDialogLoader.cancelDialog();
          errorMessage.value =
              'Your account has been deactivated. Please contact your administrator.';
          return;
        }

        print('>>> ✓ Staff account found in database and active');
        print('>>> Staff Name: ${staffDoc.name}');
        print('>>> Staff Role: ${staffDoc.role}');
        print('>>> Staff Clinic: ${staffDoc.clinicId}');
      } else {
        print(
            '>>> Detected EMAIL format, will check roles after authentication');
      }

      // Attempt authentication
      print('>>> Attempting authentication...');
      final value = await authRepository.login({
        "email": emailOrUsername,
        "password": password,
      });

      final session = value["session"];
      if (session == null) {
        throw Exception("Login failed: Session data is missing");
      }

      sessionId = session.$id;
      final userId = session.userId;

      final user = value["user"];
      if (user == null) {
        throw Exception("Login failed: User data is missing");
      }
      final userEmail = user.email;

      _getStorage.write("userId", userId);
      _getStorage.write("sessionId", session.$id);

      print('>>> ✓ Authentication successful');
      print('>>> Auth User ID: $userId');
      print('>>> Email: $userEmail');

      String role = "";
      bool matched = false;

      // Step 1: Check if account is ADMIN
      print('>>> ==========================================');
      print('>>> STEP 1: Checking if ADMIN...');
      final clinicDoc = await authRepository.getClinicByAdminId(userId);
      if (clinicDoc != null) {
        role = clinicDoc.data["role"];
        _getStorage.write("clinicId", clinicDoc.$id);
        _getStorage.write("userName", clinicDoc.data["createdBy"] ?? user.name);
        matched = true;
        print('>>> ✓ ADMIN FOUND');
        print('>>> Role: $role');
        print('>>> Clinic ID: ${clinicDoc.$id}');
      } else {
        print('>>> ✗ Not an admin account');
      }

      // Step 2: Check if account is STAFF
      if (!matched) {
        print('>>> ==========================================');
        print('>>> STEP 2: Checking if STAFF...');

        // Try by userId first
        var staff = await authRepository.getStaffByUserId(userId);

        // If not found, try by username (catches userId mismatches)
        if (staff == null && !isEmail) {
          print('>>> Not found by userId, trying by USERNAME...');
          staff = await authRepository.getStaffByUsername(emailOrUsername);

          // Auto-fix userId if found by username
          if (staff != null) {
            print('>>> ✓ STAFF FOUND BY USERNAME (userId mismatch detected)');
            await _autoFixStaffUserId(staff, userId);
          }
        } else if (staff != null) {
          print('>>> ✓ STAFF FOUND BY USERID');
        }

        if (staff != null) {
          role = staff.role;
          _getStorage.write("staffId", staff.documentId);
          _getStorage.write("clinicId", staff.clinicId);
          _getStorage.write("authorities", staff.authorities);
          _getStorage.write("userName", staff.name);
          _getStorage.write("username", staff.username);
          matched = true;
          print('>>> ✓ STAFF VERIFIED');
          print('>>> Staff Role: $role');
          print('>>> Staff Name: ${staff.name}');
          print('>>> Staff Username: ${staff.username}');
          print('>>> Staff Department: ${staff.department}');
          print('>>> Staff Authorities: ${staff.authorities}');
        } else {
          print('>>> ✗ Not a staff account');
        }
      }

      // Step 3: Check if CUSTOMER
      if (!matched) {
        print('>>> ==========================================');
        print('>>> STEP 3: Checking if CUSTOMER...');
        final userDoc = await authRepository.getUserById(userId);
        if (userDoc != null) {
          role = userDoc.data["role"];
          _getStorage.write("customerId", userDoc.$id);
          _getStorage.write("userName", user.name);
          matched = true;
          print('>>> ✓ CUSTOMER FOUND');
          print('>>> Role: $role');
          print('>>> Customer ID: ${userDoc.$id}');
        } else {
          print('>>> ✗ Not a customer account');
        }
      }

      // Step 4: Check if DEVELOPER
      if (!matched && userEmail == "test.developer@gmail.com") {
        role = "developer";
        _getStorage.write("userName", user.name);
        matched = true;
        print('>>> ==========================================');
        print('>>> ✓ DEVELOPER ACCOUNT DETECTED');
      }

      // If no role matched, deny access
      if (!matched) {
        print('>>> ==========================================');
        print('>>> ✗ NO VALID ROLE FOUND');
        print('>>> This account has no assigned role in the database');
        print('>>> ==========================================');

        if (sessionId != null) {
          await authRepository.logout(sessionId);
        }

        FullScreenDialogLoader.cancelDialog();
        errorMessage.value =
            'Invalid username/email or password. Please try again.';
        return;
      }

      _getStorage.write("role", role);
      _getStorage.write("email", userEmail);

      _initializeSecureSession(userId, role);

      // Register FCM token for push notifications (Mobile only)
      print('>>> ==========================================');
      print('>>> REGISTERING FCM TOKEN FOR PUSH NOTIFICATIONS');
      print('>>> ==========================================');

      try {
        // Only register FCM on mobile platforms
        if (!kIsWeb) {
          final notificationService = Get.find<NotificationService>();

          // Request permissions
          final hasPermission = await notificationService.requestPermissions();

          if (hasPermission) {
            // Get FCM token
            final fcmToken = await notificationService.getFreshToken();

            if (fcmToken != null && fcmToken.isNotEmpty) {
              print('>>> FCM Token available: ${fcmToken.substring(0, 20)}...');

              // Get AppwriteProvider instance
              final appwriteProvider = Get.find<AppWriteProvider>();

              // Register with Appwrite
              final target = await appwriteProvider.registerUserPushTarget(
                userId: userId,
                fcmToken: fcmToken,
              );

              if (target != null) {
                _getStorage.write('push_target_id', target.$id);
                print('>>> ✓ Push notifications enabled for user');
                print('>>> Target ID: ${target.$id}');
              } else {
                print('>>> ⚠ Warning: Could not register push target');
              }
            } else {
              print('>>> ⚠ Warning: FCM token not available');
            }
          } else {
            print('>>> ℹ Push notification permission denied by user');
          }
        } else {
          print('>>> ℹ Web platform: Skipping FCM registration');
        }
      } catch (e) {
        print('>>> ⚠ Warning: FCM registration failed (non-critical): $e');
        // Don't fail login if FCM registration fails
      }

      // Initialize in-app notification service
      try {
        final notificationService = Get.find<InAppNotificationService>();
        await notificationService.initialize();
        print('>>> Notification service initialized after login');
      } catch (e) {
        print('>>> Warning: Could not initialize notifications: $e');
      }

      print('>>> ==========================================');

      print('>>> ==========================================');
      print('>>> ✓✓✓ LOGIN SUCCESS ✓✓✓');
      print('>>> Final Role: $role');
      print('>>> User ID: $userId');
      print('>>> Session ID: $sessionId');
      print('>>> ==========================================');

      FullScreenDialogLoader.cancelDialog();
      CustomSnackBar.showSuccessSnackBar(
          context: Get.overlayContext,
          title: "Success",
          message: "Login Success");

      clearTextEditingControllers();

      // Route by role
      if (role == "admin") {
        Get.offAllNamed(Routes.adminHome);
      } else if (role == "developer") {
        Get.offAllNamed(Routes.superAdminHome);
      } else if (role == "staff") {
        Get.offAllNamed(Routes.adminHome);
      } else {
        Get.offAllNamed(Routes.userHome);
      }
    } catch (e) {
      print('>>> ==========================================');
      print('>>> ✗✗✗ LOGIN ERROR ✗✗✗');
      print('>>> Error Type: ${e.runtimeType}');
      print('>>> Error Details: $e');
      print('>>> ==========================================');

      if (sessionId != null) {
        try {
          await authRepository.logout(sessionId);
          print('>>> Session cleaned up');
        } catch (logoutError) {
          print('>>> Error during session cleanup: $logoutError');
        }
      }

      FullScreenDialogLoader.cancelDialog();

      // UNIFIED ERROR MESSAGE: Always show this for any login error
      errorMessage.value =
          'Invalid username/email or password. Please check your credentials.';
    }
  }

  Future<void> _autoFixStaffUserId(Staff staff, String correctUserId) async {
    if (staff.userId != correctUserId) {
      print('>>> Auto-fixing userId mismatch...');
      print('>>> DB userId: ${staff.userId}');
      print('>>> Auth userId: $correctUserId');

      try {
        await authRepository.fixStaffUserId(staff.documentId!, correctUserId);
        staff.userId = correctUserId;
        print('>>> ✓ UserId fixed!');
      } catch (e) {
        print('>>> Warning: Could not auto-fix userId: $e');
      }
    }
  }

  Future<void> signInWithGoogle() async {
    if (isGoogleLoading.value) return;

    try {
      isGoogleLoading.value = true;
      errorMessage.value = '';

      print('>>> LOGIN: Initiating Google Sign-In...');

      final appWriteProvider = Get.find<AppWriteProvider>();

      // This will redirect to Google OAuth
      // After success, user will land on /auth/success -> /auth/callback
      await appWriteProvider.signInWithGoogle();

      // Code won't reach here due to redirect
    } catch (e) {
      print('>>> LOGIN: Google Sign-In error: $e');

      isGoogleLoading.value = false;

      errorMessage.value =
          'Google Sign-In failed. Please try again or use email/password.';
    }
  }

  void moveToSignUp() {
    clearTextEditingControllers();
    Get.toNamed(Routes.signup);
  }

  void _initializeSecureSession(String userId, String role) {
    print('>>> ============================================');
    print('>>> INITIALIZING SECURE SESSION');
    print('>>> User ID: $userId');
    print('>>> Role: $role');
    print('>>> ============================================');

    // Store session timestamp
    _getStorage.write('sessionTimestamp', DateTime.now().toIso8601String());

    // Start session monitoring
    SessionManager.startSessionMonitoring();

    // Log successful login event
    SecurityMonitor.logSecurityEvent(
      eventType: 'LOGIN_SUCCESS',
      userId: userId,
      details: 'Role: $role',
    );

    // Clean up old security data periodically
    SessionManager.cleanupOldData();

    print('>>> Secure session initialized');
    print('>>> ============================================');
  }
}

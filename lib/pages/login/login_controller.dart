import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/utils/custom_snack_bar.dart';
import 'package:capstone_app/utils/full_screen_dialog_loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone_app/data/models/staff_model.dart';

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

  @override
  void onClose() {
    super.onClose();
    emailEditingController.dispose();
    passwordEditingController.dispose();
  }

  void clearTextEditingControllers() {
    emailEditingController.clear();
    passwordEditingController.clear();
  }

  String? validateEmail(String value) {
    if (!GetUtils.isEmail(value)) {
      return "Provide a valid Email";
    }
    return null;
  }

  String? validatePassword(String value) {
    if (value.isEmpty) {
      return "Provide valid password";
    }
    return null;
  }

  /// AUTO-HEALING LOGIN - Fixes userId mismatches automatically
  void validateAndLogin({
    required String email,
    required String password,
  }) async {
    isFormValid = formKey.currentState!.validate();
    if (!isFormValid) return;

    String? sessionId;

    try {
      formKey.currentState!.save();
      FullScreenDialogLoader.showDialog();

      print('>>> ==========================================');
      print('>>> LOGIN ATTEMPT');
      print('>>> Email: $email');
      print('>>> ==========================================');

      final value = await authRepository.login({
        "email": email,
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

      print('>>> Auth User ID: $userId');
      print('>>> Email: $userEmail');

      String role = "";
      bool matched = false;

      // Check if account is admin
      print('>>> Step 1: Checking if ADMIN...');
      final clinicDoc = await authRepository.getClinicByAdminId(userId);
      if (clinicDoc != null) {
        role = clinicDoc.data["role"];
        _getStorage.write("clinicId", clinicDoc.$id);
        _getStorage.write("userName", clinicDoc.data["createdBy"] ?? user.name);
        matched = true;
        print('>>> ✓ ADMIN FOUND - Role: $role');
      }

      // Check if account is staff
      if (!matched) {
        print('>>> Step 2: Checking if STAFF...');

        // Try by userId first
        var staff = await authRepository.getStaffByUserId(userId);

        // If not found, try by email (this catches userId mismatches)
        if (staff == null) {
          print('>>> Not found by userId, trying by EMAIL...');
          staff = await authRepository.getStaffByEmail(userEmail);

          // Auto-fix userId if found by email
          if (staff != null) {
            print('>>> ✓ STAFF FOUND BY EMAIL');
            await _autoFixStaffUserId(staff, userId);
          }
        } else {
          print('>>> ✓ STAFF FOUND BY USERID');
        }

        if (staff != null) {
          role = staff.role;
          _getStorage.write("staffId", staff.documentId);
          _getStorage.write("clinicId", staff.clinicId);
          _getStorage.write("authorities", staff.authorities);
          _getStorage.write("userName", staff.name);
          matched = true;
          print('>>> Staff Role: $role');
          print('>>> Staff Name: ${staff.name}');
        }
      }

      // Check if user (customer)
      if (!matched) {
        print('>>> Step 3: Checking if CUSTOMER...');
        final userDoc = await authRepository.getUserById(userId);
        if (userDoc != null) {
          role = userDoc.data["role"];
          _getStorage.write("customerId", userDoc.$id);
          _getStorage.write("userName", user.name);
          matched = true;
          print('>>> ✓ CUSTOMER FOUND - Role: $role');
        }
      }

      // Check if developer
      if (!matched && userEmail == "test.developer@gmail.com") {
        role = "developer";
        _getStorage.write("userName", user.name);
        matched = true;
        print('>>> ✓ DEVELOPER ACCOUNT');
      }

      if (!matched) {
        print('>>> ==========================================');
        print('>>> ✗ NO ROLE MATCHED');
        print('>>> ==========================================');

        if (sessionId != null) {
          await authRepository.logout(sessionId);
        }
        throw Exception(
            "No role found for this account. Please contact support.");
      }

      _getStorage.write("role", role);
      _getStorage.write("email", userEmail);

      print('>>> ==========================================');
      print('>>> ✓ LOGIN SUCCESS - Role: $role');
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
      print('>>> ✗ LOGIN ERROR: $e');
      print('>>> ==========================================');

      if (sessionId != null) {
        try {
          await authRepository.logout(sessionId);
        } catch (_) {}
      }

      FullScreenDialogLoader.cancelDialog();
      CustomSnackBar.showErrorSnackBar(
          context: Get.overlayContext,
          title: "Login Failed",
          message: e is AppwriteException
              ? e.response ?? "Appwrite error"
              : e.toString());
    }
  }

  /// AUTO-FIX HELPER: Runs every login, only updates if mismatch detected
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
        // Continue anyway, the login should still work
      }
    }
  }

  void moveToSignUp() {
    Get.toNamed(Routes.signup);
  }
}

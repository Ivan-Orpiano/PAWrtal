import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';

class ResetPasswordController extends GetxController {
  final AuthRepository _authRepository;
  ResetPasswordController(this._authRepository);

  // Form
  final formKey = GlobalKey<FormState>();
  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // Observables
  final isNewPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final isLoading = false.obs;
  final isValidating = true.obs;
  final resetSuccess = false.obs;
  final validationError = ''.obs;

  // URL parameters
  String? userId;
  String? token;

  @override
  void onInit() {
    super.onInit();
    _validateResetLink();
  }

  @override
  void onClose() {
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }

  void toggleNewPasswordVisibility() {
    isNewPasswordVisible.value = !isNewPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  /// Validate the reset link from URL parameters
  Future<void> _validateResetLink() async {
    try {
      print('>>> ============================================');
      print('>>> VALIDATING RESET LINK');
      print('>>> ============================================');

      // Get URL parameters
      final parameters = Get.parameters;
      userId = parameters['userId'];
      token = parameters['token'];

      print('>>> User ID: $userId');
      print('>>> Token: ${token?.substring(0, 10)}...');

      if (userId == null || token == null || userId!.isEmpty || token!.isEmpty) {
        print('>>> ❌ Missing parameters');
        validationError.value = 'Invalid reset link. Please request a new password reset.';
        isValidating.value = false;
        return;
      }

      // Validate token with backend
      final isValid = await _authRepository.validatePasswordResetToken(userId!, token!);

      if (isValid) {
        print('>>> ✅ Token is valid');
        isValidating.value = false;
      } else {
        print('>>> ❌ Token is invalid or expired');
        validationError.value = 'This reset link has expired or is invalid. Please request a new one.';
        isValidating.value = false;
      }

      print('>>> ============================================');
    } catch (e) {
      print('>>> ❌ Error validating reset link: $e');
      validationError.value = 'An error occurred. Please try again.';
      isValidating.value = false;
    }
  }

  /// Password validator
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Password is required";
    }

    if (value.length < 8) {
      return "Password must be at least 8 characters";
    }

    // Check for at least one uppercase letter
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return "Password must contain at least one uppercase letter";
    }

    // Check for at least one number
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return "Password must contain at least one number";
    }

    // Check for at least one special character
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
      return "Password must contain at least one special character";
    }

    return null;
  }

  /// Confirm password validator
  String? validateConfirmPassword(String? value, String newPassword) {
    if (value == null || value.isEmpty) {
      return "Please confirm your password";
    }

    if (value != newPassword) {
      return "Passwords do not match";
    }

    return null;
  }

  /// Reset password
  Future<void> resetPassword() async {
    if (!formKey.currentState!.validate()) return;

    try {
      isLoading.value = true;

      print('>>> ============================================');
      print('>>> RESETTING PASSWORD');
      print('>>> User ID: $userId');
      print('>>> ============================================');

      final success = await _authRepository.resetPassword(
        userId: userId!,
        token: token!,
        newPassword: newPasswordController.text,
      );

      if (success) {
        print('>>> ✅ Password reset successful');
        resetSuccess.value = true;
        
        // Clear form
        newPasswordController.clear();
        confirmPasswordController.clear();
      } else {
        print('>>> ❌ Password reset failed');
        Get.snackbar(
          'Error',
          'Failed to reset password. Please try again.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red.shade100,
          colorText: Colors.red.shade900,
        );
      }

      print('>>> ============================================');
    } catch (e) {
      print('>>> ❌ Error resetting password: $e');
      Get.snackbar(
        'Error',
        'An error occurred. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    } finally {
      isLoading.value = false;
    }
  }
}
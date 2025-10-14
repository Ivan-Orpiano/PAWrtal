import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/utils/custom_snack_bar.dart';
import 'package:capstone_app/utils/full_screen_dialog_loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignUpController extends GetxController {
  AuthRepository authRepository;
  SignUpController(this.authRepository);

  // Form Key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController emailEditingController = TextEditingController();
  final TextEditingController passwordEditingController = TextEditingController();
  final TextEditingController confirmPasswordEditingController = TextEditingController();
  final TextEditingController nameEditingController = TextEditingController();

  // Observable properties
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final termsAccepted = false.obs;

  @override
  void onClose() {
    super.onClose();
    emailEditingController.dispose();
    passwordEditingController.dispose();
    confirmPasswordEditingController.dispose();
    nameEditingController.dispose();
  }

  void clearTextEditingControllers() {
    emailEditingController.clear();
    passwordEditingController.clear();
    confirmPasswordEditingController.clear();
    nameEditingController.clear();
    termsAccepted.value = false;
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  // Validate form fields
  String? validateEmail(String? value) {
    if (value == null || !GetUtils.isEmail(value)) {
      return "Provide a valid Email";
    }
    return null;
  }

  // 🔒 Updated password validation rule to match web version
  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Password is required";
    }

    if (value.length < 8) {
      return "Password must be at least 8 characters long";
    }

    // Require at least 1 uppercase, 1 digit, and 1 special character
    final passwordRegex =
        RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*(),.?":{}|<>]).{8,}$');
    if (!passwordRegex.hasMatch(value)) {
      return "Password must contain an uppercase letter, a digit, and a special character";
    }

    return null;
  }

  String? validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Please confirm your password";
    }
    if (value != passwordEditingController.text) {
      return "Passwords do not match";
    }
    return null;
  }

  String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return "Name cannot be empty";
    }
    return null;
  }

  void moveToLogin() {
    clearTextEditingControllers();
    Get.toNamed(Routes.login);
  }

  void showTermsAndConditions() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Terms and Conditions",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 81, 115, 153),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTermsSection(
                        "1. Acceptance of Terms",
                        "By accessing and using PAWrtal, you accept and agree to be bound by the terms and provision of this agreement.",
                      ),
                      _buildTermsSection(
                        "2. User Account",
                        "You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account.",
                      ),
                      _buildTermsSection(
                        "3. Privacy Policy",
                        "Your use of PAWrtal is also governed by our Privacy Policy. We collect and process personal information in accordance with applicable data protection laws.",
                      ),
                      _buildTermsSection(
                        "4. User Data",
                        "We collect information you provide when creating an account, including your name, email address, and other relevant details for providing our veterinary services.",
                      ),
                      _buildTermsSection(
                        "5. Service Usage",
                        "PAWrtal provides veterinary clinic management services. You agree to use the service only for lawful purposes and in accordance with these terms.",
                      ),
                      _buildTermsSection(
                        "6. Prohibited Activities",
                        "You may not use PAWrtal to transmit any harmful code, interfere with the service, or engage in any activity that disrupts or impairs the service.",
                      ),
                      _buildTermsSection(
                        "7. Intellectual Property",
                        "All content, features, and functionality of PAWrtal are owned by us and are protected by international copyright, trademark, and other intellectual property laws.",
                      ),
                      _buildTermsSection(
                        "8. Limitation of Liability",
                        "PAWrtal shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the service.",
                      ),
                      _buildTermsSection(
                        "9. Changes to Terms",
                        "We reserve the right to modify these terms at any time. We will notify users of any material changes via email or through the service.",
                      ),
                      _buildTermsSection(
                        "10. Contact Information",
                        "For questions about these Terms and Conditions, please contact us through our support channels.",
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Get.back();
                  },
                  child: const Text(
                    "Close",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> signUpWithGoogle() async {
    try {
      FullScreenDialogLoader.showDialog();

      final appWriteProvider = AppWriteProvider();
      final success = await appWriteProvider.signInWithGoogle();

      FullScreenDialogLoader.cancelDialog();

      if (success) {
        CustomSnackBar.showSuccessSnackBar(
          context: Get.overlayContext,
          title: "Success",
          message: "Account created with Google successfully!",
        );
        clearTextEditingControllers();
        Get.offAllNamed(Routes.userHome);
      } else {
        CustomSnackBar.showErrorSnackBar(
          context: Get.overlayContext,
          title: "Error",
          message: "Failed to create account with Google",
        );
      }
    } catch (e) {
      FullScreenDialogLoader.cancelDialog();
      CustomSnackBar.showErrorSnackBar(
        context: Get.overlayContext,
        title: "Error",
        message: "Google sign-up error: ${e.toString()}",
      );
    }
  }

  void validateAndSignUp({
    required String email,
    required String password,
    required String name,
  }) async {
    // Check if terms are accepted
    if (!termsAccepted.value) {
      CustomSnackBar.showErrorSnackBar(
        context: Get.overlayContext,
        title: "Terms Required",
        message: "Please accept the Terms and Conditions to continue",
      );
      return;
    }

    if (formKey.currentState == null || !formKey.currentState!.validate()) {
      return;
    }
    formKey.currentState!.save();

    try {
      FullScreenDialogLoader.showDialog();
      final user = await authRepository.signup({
        "userId": ID.unique(),
        "name": name,
        "email": email,
        "password": password,
      });

      final userId = user.$id;

      await authRepository.createUser({
        "userId": userId,
        "name": name,
        "email": email,
        "role": "user",
      });

      FullScreenDialogLoader.cancelDialog();
      CustomSnackBar.showSuccessSnackBar(
        context: Get.overlayContext,
        title: "Success",
        message: "User account created successfully!",
      );
      clearTextEditingControllers();
      Get.offAllNamed(Routes.login);
    } catch (error) {
      FullScreenDialogLoader.cancelDialog();
      if (error is AppwriteException) {
        if (error.code == 409) {
          CustomSnackBar.showErrorSnackBar(
            context: Get.overlayContext,
            title: "Error",
            message: "This email is already registered.",
          );
        } else {
          CustomSnackBar.showErrorSnackBar(
            context: Get.overlayContext,
            title: "Error",
            message: error.response ?? "An error occurred",
          );
        }
      } else {
        CustomSnackBar.showErrorSnackBar(
          context: Get.overlayContext,
          title: "Error",
          message: "Something went wrong",
        );
      }
    }
  }
}

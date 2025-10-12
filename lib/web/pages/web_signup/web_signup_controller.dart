import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class WebSignUpController extends GetxController {
  final AuthRepository _authRepository;
  WebSignUpController(this._authRepository);

  final GetStorage _getStorage = GetStorage();

  late TextEditingController emailController;
  late TextEditingController nameController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;

  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final termsAccepted = false.obs;

  @override
  void onInit() {
    super.onInit();
    emailController = TextEditingController();
    nameController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  void navigateToLogin() {
    _clearControllersBeforeNavigation();
    Get.offAllNamed(Routes.login);
  }

  void _clearControllersBeforeNavigation() {
    try {
      emailController.clear();
      nameController.clear();
      passwordController.clear();
      confirmPasswordController.clear();
      termsAccepted.value = false;
    } catch (e) {
      print('Controller clear error: $e');
    }
  }

  void showTermsAndConditions() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(32),
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Terms and Conditions",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color.fromARGB(255, 81, 115, 153),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTermsSection(
                        "1. Acceptance of Terms",
                        "By accessing and using PAWrtal, you accept and agree to be bound by the terms and provision of this agreement. If you do not agree to abide by the above, please do not use this service.",
                      ),
                      _buildTermsSection(
                        "2. User Account",
                        "You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities that occur under your account. You must notify us immediately of any unauthorized use of your account.",
                      ),
                      _buildTermsSection(
                        "3. Privacy Policy",
                        "Your use of PAWrtal is also governed by our Privacy Policy. We collect and process personal information in accordance with applicable data protection laws. We are committed to protecting your privacy and handling your data with care.",
                      ),
                      _buildTermsSection(
                        "4. User Data",
                        "We collect information you provide when creating an account, including your name, email address, and other relevant details for providing our veterinary services. This data is used solely for the purpose of service delivery and improvement.",
                      ),
                      _buildTermsSection(
                        "5. Service Usage",
                        "PAWrtal provides veterinary clinic management services including appointment scheduling, medical records management, and communication tools. You agree to use the service only for lawful purposes and in accordance with these terms.",
                      ),
                      _buildTermsSection(
                        "6. Prohibited Activities",
                        "You may not use PAWrtal to transmit any harmful code, interfere with the service, attempt unauthorized access, or engage in any activity that disrupts or impairs the service. Violations may result in account termination.",
                      ),
                      _buildTermsSection(
                        "7. Intellectual Property",
                        "All content, features, and functionality of PAWrtal are owned by us and are protected by international copyright, trademark, and other intellectual property laws. You may not reproduce, distribute, or create derivative works without our express permission.",
                      ),
                      _buildTermsSection(
                        "8. Limitation of Liability",
                        "PAWrtal shall not be liable for any indirect, incidental, special, consequential, or punitive damages resulting from your use of or inability to use the service. Our total liability shall not exceed the amount paid by you for the service.",
                      ),
                      _buildTermsSection(
                        "9. Medical Disclaimer",
                        "PAWrtal is a management tool and does not provide veterinary medical advice. Always consult with qualified veterinary professionals for medical decisions. We are not responsible for medical outcomes.",
                      ),
                      _buildTermsSection(
                        "10. Changes to Terms",
                        "We reserve the right to modify these terms at any time. We will notify users of any material changes via email or through the service. Continued use after changes constitutes acceptance of the new terms.",
                      ),
                      _buildTermsSection(
                        "11. Termination",
                        "We reserve the right to terminate or suspend your account at any time for violations of these terms. Upon termination, your right to use the service will immediately cease.",
                      ),
                      _buildTermsSection(
                        "12. Contact Information",
                        "For questions about these Terms and Conditions, please contact us through our support channels. We aim to respond to all inquiries within 48 hours.",
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Last Updated: October 2025",
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
              height: 1.6,
            ),
            textAlign: TextAlign.justify,
          ),
        ],
      ),
    );
  }

  Future<void> signUp() async {
    if (!_validateForm()) return;

    // Check if terms are accepted
    if (!termsAccepted.value) {
      Get.snackbar(
        'Terms Required',
        'Please accept the Terms and Conditions to continue',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    try {
      isLoading.value = true;

      final user = await _authRepository.signup({
        "userId": ID.unique(),
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "password": passwordController.text,
      });

      final userId = user.$id;

      await _authRepository.createUser({
        "userId": userId,
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "role": "user",
      });

      Get.snackbar(
        'Success',
        'User account created successfully!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      _clearControllersBeforeNavigation();

      await Future.delayed(const Duration(milliseconds: 300));

      Get.offAllNamed(Routes.login);
    } catch (error) {
      String errorMessage = "Something went wrong";

      if (error is AppwriteException) {
        if (error.code == 409) {
          errorMessage = "This email is already registered.";
        } else {
          errorMessage = error.response ?? "An error occurred";
        }
      }

      Get.snackbar(
        'Error',
        errorMessage,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUpWithGoogle() async {
    try {
      isLoading.value = true;

      final appWriteProvider = AppWriteProvider();
      final success = await appWriteProvider.signInWithGoogle();

      if (success) {
        Get.snackbar(
          'Success',
          'Account created with Google successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        Get.offAllNamed(Routes.userHome);
      } else {
        Get.snackbar(
          'Error',
          'Failed to create account with Google',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Google sign-up error: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  bool _validateForm() {
    if (emailController.text.isEmpty ||
        nameController.text.isEmpty ||
        passwordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in all fields',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    if (!GetUtils.isEmail(emailController.text.trim())) {
      Get.snackbar(
        'Error',
        'Please enter a valid email address',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    if (passwordController.text.length < 8) {
      Get.snackbar(
        'Error',
        'Password must be at least 8 characters long',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    if (confirmPasswordController.text.isNotEmpty &&
        passwordController.text != confirmPasswordController.text) {
      Get.snackbar(
        'Error',
        'Passwords do not match',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    }

    return true;
  }

  @override
  void onClose() {
    try {
      _clearControllersBeforeNavigation();
    } catch (e) {
      print('Controller disposal error: $e');
    }
    super.onClose();
  }
}
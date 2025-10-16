import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class SignUpController extends GetxController {
  final AuthRepository _authRepository;
  SignUpController(this._authRepository);

  final GetStorage _getStorage = GetStorage();

  late TextEditingController emailController;
  late TextEditingController nameController;
  late TextEditingController passwordController;
  late TextEditingController confirmPasswordController;

  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;
  final termsAccepted = false.obs;
  final isGoogleLoading = false.obs;

  // Error messages for each field
  final emailError = Rx<String?>(null);
  final nameError = Rx<String?>(null);
  final passwordError = Rx<String?>(null);
  final confirmPasswordError = Rx<String?>(null);
  final termsError = Rx<String?>(null);
  final generalError = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    emailController = TextEditingController();
    nameController = TextEditingController();
    passwordController = TextEditingController();
    confirmPasswordController = TextEditingController();

    // Add listeners to clear errors on text change
    emailController.addListener(() => emailError.value = null);
    nameController.addListener(() => nameError.value = null);
    passwordController.addListener(() {
      passwordError.value = null;
      if (confirmPasswordController.text.isNotEmpty) {
        confirmPasswordError.value = null;
      }
    });
    confirmPasswordController
        .addListener(() => confirmPasswordError.value = null);
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
      _clearAllErrors();
    } catch (e) {
      print('Controller clear error: $e');
    }
  }

  void _clearAllErrors() {
    emailError.value = null;
    nameError.value = null;
    passwordError.value = null;
    confirmPasswordError.value = null;
    termsError.value = null;
    generalError.value = null;
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
    _clearAllErrors();

    if (!_validateForm()) return;

    // Check if terms are accepted
    if (!termsAccepted.value) {
      termsError.value = 'Please accept the Terms and Conditions to continue';
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

      // Show success dialog instead of snackbar
      Get.dialog(
        Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(24),
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Color(0xFF4CAF50),
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Account Created!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your account has been created successfully. You can now sign in.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 24),
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
                      _clearControllersBeforeNavigation();
                      Get.offAllNamed(Routes.login);
                    },
                    child: const Text(
                      'Continue to Sign In',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );
    } catch (error) {
      String errorMessage = "Something went wrong. Please try again.";

      if (error is AppwriteException) {
        if (error.code == 409) {
          emailError.value = "This email is already registered";
          errorMessage =
              "This email is already registered. Please use a different email or sign in.";
        } else {
          errorMessage = error.response ?? "An error occurred during sign up";
        }
      }

      generalError.value = errorMessage;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signUpWithGoogle() async {
    if (isLoading.value || isGoogleLoading.value) return;

    try {
      isGoogleLoading.value = true;
      _clearAllErrors();

      final appWriteProvider = AppWriteProvider();
      final success = await appWriteProvider.signInWithGoogle();

      if (success) {
        Get.offAllNamed(Routes.userHome);
      } else {
        generalError.value =
            'Failed to create account with Google. Please try again.';
      }
    } catch (e) {
      generalError.value = 'Google sign-up error';
    } finally {
      isGoogleLoading.value = false;
    }
  }

  bool _validateForm() {
    final email = emailController.text.trim();
    final name = nameController.text.trim();
    final password = passwordController.text;
    final confirmPassword = confirmPasswordController.text;

    bool isValid = true;

    // Check empty fields
    if (email.isEmpty) {
      emailError.value = 'Email is required';
      isValid = false;
    }

    if (name.isEmpty) {
      nameError.value = 'Full name is required';
      isValid = false;
    }

    if (password.isEmpty) {
      passwordError.value = 'Password is required';
      isValid = false;
    }

    if (confirmPassword.isEmpty) {
      confirmPasswordError.value = 'Please confirm your password';
      isValid = false;
    }

    // Email validation
    if (email.isNotEmpty && !GetUtils.isEmail(email)) {
      emailError.value = 'Please enter a valid email address';
      isValid = false;
    }

    // Text length limit
    if (email.length > 50) {
      emailError.value = 'Email must not exceed 50 characters';
      isValid = false;
    }

    if (name.length > 50) {
      nameError.value = 'Name must not exceed 50 characters';
      isValid = false;
    }

    if (password.length > 50) {
      passwordError.value = 'Password must not exceed 50 characters';
      isValid = false;
    }

    // Password length
    if (password.isNotEmpty && password.length < 8) {
      passwordError.value = 'Password must be at least 8 characters';
      isValid = false;
    }

    // Password complexity
    if (password.isNotEmpty && password.length >= 8) {
      final passwordRegex =
          RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$%^&*(),.?":{}|<>]).{8,}$');
      if (!passwordRegex.hasMatch(password)) {
        passwordError.value =
            'Password must contain uppercase, digit, and special character';
        isValid = false;
      }
    }

    // Password confirmation
    if (password.isNotEmpty &&
        confirmPassword.isNotEmpty &&
        password != confirmPassword) {
      confirmPasswordError.value = 'Passwords do not match';
      isValid = false;
    }

    return isValid;
  }

  @override
  void onClose() {
    try {
      emailController.dispose();
      nameController.dispose();
      passwordController.dispose();
      confirmPasswordController.dispose();
    } catch (e) {
      print('Controller disposal error: $e');
    }
    super.onClose();
  }
}

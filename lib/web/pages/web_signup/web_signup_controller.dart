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
  
  // Form controllers
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  // Reactive variables
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;
  final isConfirmPasswordVisible = false.obs;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmPasswordVisibility() {
    isConfirmPasswordVisible.value = !isConfirmPasswordVisible.value;
  }

  void navigateToLogin() {
    Get.toNamed(Routes.login);
  }

  Future<void> signUp() async {
    if (!_validateForm()) return;

    try {
      isLoading.value = true;
      
      // Use the same method as your mobile signup controller
      final user = await _authRepository.signup({
        "userId": ID.unique(),
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "password": passwordController.text,
      });

      final userId = user.$id;

      // Create user document in database
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
      );

      // Clear controllers
      emailController.clear();
      nameController.clear();
      passwordController.clear();
      confirmPasswordController.clear();

      // Navigate to login page
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
      
      // For Google signup, you might want to handle this differently
      // This is a simplified version - you may need additional logic
      final appWriteProvider = AppWriteProvider();
      final success = await appWriteProvider.signInWithGoogle();
      
      if (success) {
        Get.snackbar(
          'Success',
          'Account created with Google successfully!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        
        // Navigate to user home for Google signup
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

  void _navigateBasedOnRole(String role) {
    switch (role) {
      case "admin":
      case "staff":
        Get.offAllNamed(Routes.adminHome);
        break;
      case "developer":
        Get.offAllNamed(Routes.superAdminHome);
        break;
      case "user":
        Get.offAllNamed(Routes.userHome);
        break;
      default:
        Get.offAllNamed(Routes.userHome); // Default to user home
        break;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    nameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.onClose();
  }
}
import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class WebLoginController extends GetxController {
  final AuthRepository _authRepository;
  WebLoginController(this._authRepository);

  final GetStorage _getStorage = GetStorage();
  
  // Form controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  
  // Reactive variables
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void navigateToSignUp() {
    Get.toNamed(Routes.signup);
  }

  Future<void> signIn() async {
    if (emailController.text.isEmpty || passwordController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill in all fields',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    try {
      isLoading.value = true;
      
      // Use the same method as your mobile login controller
      final value = await _authRepository.login({
        "email": emailController.text.trim(),
        "password": passwordController.text,
      });

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

      _getStorage.write("userId", userId);
      _getStorage.write("sessionId", session.$id);

      String role = "";
      bool matched = false;

      // Check if account is admin
      final clinicDoc = await _authRepository.getClinicByAdminId(userId);
      if (clinicDoc != null) {
        role = clinicDoc.data["role"];
        _getStorage.write("clinicId", clinicDoc.$id);
        matched = true;
      }

      // Check if account is staff
      if (!matched) {
        final staffDoc = await _authRepository.getStaffByClinicId(userEmail);
        if (staffDoc != null) {
          role = staffDoc.data["role"];
          _getStorage.write("staffId", staffDoc.$id);
          _getStorage.write("clinicId", staffDoc.data["clinicId"]);
          matched = true;
        }
      }

      // Check if user (customer)
      if (!matched) {
        final userDoc = await _authRepository.getUserById(userId);
        if (userDoc != null) {
          role = userDoc.data["role"]; // role should be "user"
          _getStorage.write("customerId", userDoc.$id);
          matched = true;
        }
      }

      // Check if developer (super admin)
      if (!matched && userEmail == "test.developer@gmail.com") {
        role = "developer";
        matched = true;
      }

      if (!matched) throw Exception("No role found for this account");

      _getStorage.write("role", role);

      // Navigate based on role
      _navigateBasedOnRole(role);
      
      Get.snackbar(
        'Success',
        'Login successful',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );

      // Clear controllers
      emailController.clear();
      passwordController.clear();
      
    } catch (e) {
      Get.snackbar(
        'Error',
        'Login failed: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      isLoading.value = true;
      
      // Use AppWriteProvider directly for Google sign-in like in mobile
      final appWriteProvider = AppWriteProvider();
      final success = await appWriteProvider.signInWithGoogle();
      
      if (success) {
        // For Google sign-in, typically redirects to user home
        // You may need to implement additional role checking here
        _navigateBasedOnRole("user");
        
        Get.snackbar(
          'Success',
          'Logged in with Google successfully',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      } else {
        Get.snackbar(
          'Error',
          'Failed to login with Google',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Google sign-in error: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void _navigateBasedOnRole(String? role) {
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
        Get.snackbar(
          'Error',
          'Invalid user role',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        break;
    }
  }

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
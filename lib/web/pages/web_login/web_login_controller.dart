import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/utils/web_error_handler.dart';
import 'package:capstone_app/utils/web_loading_helper.dart';
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
  final emailForPasswordResetController = TextEditingController();
  
  // Form key
  final formKey = GlobalKey<FormState>();
  final resetPasswordFormKey = GlobalKey<FormState>();
  
  // Reactive variables
  final isLoading = false.obs;
  final isPasswordVisible = false.obs;

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void navigateToSignUp() {
    Get.toNamed(Routes.signup);
  }

  // Form validation methods
  String? validateEmail(String? value) {
    if (value == null || !GetUtils.isEmail(value)) {
      return "Provide a valid Email";
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return "Provide valid password";
    }
    return null;
  }

  Future<void> signIn() async {
    if (!formKey.currentState!.validate()) return;

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

      await _getStorage.write("userId", userId);
      await _getStorage.write("sessionId", session.$id);

      String role = "";
      bool matched = false;

      // Check if account is admin
      final clinicDoc = await _authRepository.getClinicByAdminId(userId);
      if (clinicDoc != null) {
        role = clinicDoc.data["role"];
        await _getStorage.write("clinicId", clinicDoc.$id);
        matched = true;
      }

      // Check if account is staff
      if (!matched) {
        final staffDoc = await _authRepository.getStaffByClinicId(userEmail);
        if (staffDoc != null) {
          role = staffDoc.data["role"];
          await _getStorage.write("staffId", staffDoc.$id);
          await _getStorage.write("clinicId", staffDoc.data["clinicId"]);
          matched = true;
        }
      }

      // Check if user (customer)
      if (!matched) {
        final userDoc = await _authRepository.getUserById(userId);
        if (userDoc != null) {
          role = userDoc.data["role"]; // role should be "user"
          await _getStorage.write("customerId", userDoc.$id);
          matched = true;
        }
      }

      // Check if developer (super admin)
      if (!matched && userEmail == "test.developer@gmail.com") {
        role = "developer";
        matched = true;
      }

      if (!matched) throw Exception("No role found for this account");

      await _getStorage.write("role", role);
      await _getStorage.write("email", userEmail);
      
      // Store user name if available
      if (user.name != null) {
        await _getStorage.write("userName", user.name);
      }

      // Navigate based on role
      _navigateBasedOnRole(role);
      
      WebErrorHandler.handleSuccess('Login successful');

      // Clear controllers
      _clearControllers();
      
    } catch (e) {
      WebErrorHandler.handleError(e, context: 'Login');
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
        await _getStorage.write("role", "user");
        _navigateBasedOnRole("user");
        
        WebErrorHandler.handleSuccess('Logged in with Google successfully');
      } else {
        WebErrorHandler.handleError('Failed to login with Google');
      }
    } catch (e) {
      WebErrorHandler.handleError(e, context: 'Google Sign In');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> sendPasswordResetEmail() async {
    if (!resetPasswordFormKey.currentState!.validate()) return;

    try {
      WebLoadingHelper.showLoading(message: 'Sending recovery email...');
      
      final appWriteProvider = AppWriteProvider();
      final success = await appWriteProvider.sendRecoveryEmail(
        emailForPasswordResetController.text.trim()
      );
      
      WebLoadingHelper.hideLoading();
      
      if (success) {
        WebErrorHandler.handleSuccess('Recovery email sent successfully');
        emailForPasswordResetController.clear();
      } else {
        WebErrorHandler.handleError('Cannot send recovery email');
      }
    } catch (e) {
      WebLoadingHelper.hideLoading();
      WebErrorHandler.handleError(e, context: 'Password Reset');
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
        WebErrorHandler.handleError('Invalid user role');
        break;
    }
  }

  void _clearControllers() {
    emailController.clear();
    passwordController.clear();
  }

  @override
  void onClose() {
    // emailController.dispose();
    // passwordController.dispose();
    // emailForPasswordResetController.dispose();
    super.onClose();
  }
}
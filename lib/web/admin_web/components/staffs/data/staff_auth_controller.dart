import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/utils/user_session_service.dart';
import 'package:capstone_app/data/models/staff_model.dart';

class StaffAuthController extends GetxController {
  final AuthRepository authRepository;
  final UserSessionService userSession;

  StaffAuthController({
    required this.authRepository,
    required this.userSession,
  });

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final RxBool isLoading = false.obs;
  final RxBool obscurePassword = true.obs;
  final RxString errorMessage = ''.obs;

  Rx<Staff?> currentStaff = Rx<Staff?>(null);
  RxList<String> staffAuthorities = <String>[].obs;

  // Store session data in the controller instead of UserSessionService
  final RxString sessionId = ''.obs;
  final RxString clinicId = ''.obs;
  final RxString staffDocId = ''.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
  }

  Future<void> login() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      errorMessage.value = 'Please enter email and password';
      return;
    }

    isLoading.value = true;
    errorMessage.value = '';

    try {
      final result = await authRepository.staffLogin(
        emailController.text.trim(),
        passwordController.text,
      );

      // Store session data in controller
      sessionId.value = result['session'].$id;

      // Store staff data
      final staffDoc = result['staffDoc'];
      final staff = Staff.fromMap(staffDoc.data);
      staff.documentId = staffDoc.$id;

      currentStaff.value = staff;
      staffAuthorities.value = staff.authorities;

      // Store clinic ID and staff doc ID
      clinicId.value = result['clinicId'];
      staffDocId.value = staff.documentId!;

      Get.snackbar(
        'Success',
        'Welcome back, ${staff.name}!',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        icon: const Icon(Icons.check_circle, color: Colors.white),
      );

      // Navigate to staff dashboard
      Get.offAllNamed('/staff/home');
    } catch (e) {
      print('Login error: $e');
      errorMessage.value = 'Invalid email or password';

      Get.snackbar(
        'Login Failed',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        icon: const Icon(Icons.error, color: Colors.white),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadStaffData() async {
    try {
      final staff = await authRepository.getStaffByUserId(userSession.userId);
      if (staff != null) {
        currentStaff.value = staff;
        staffAuthorities.value = staff.authorities;
        clinicId.value = staff.clinicId;
        staffDocId.value = staff.documentId ?? '';
      }
    } catch (e) {
      print('Error loading staff data: $e');
    }
  }

  bool hasAuthority(String authority) {
    return staffAuthorities.contains(authority);
  }

  bool hasAnyAuthority(List<String> authorities) {
    return authorities.any((auth) => staffAuthorities.contains(auth));
  }

  bool hasAllAuthorities(List<String> authorities) {
    return authorities.every((auth) => staffAuthorities.contains(auth));
  }

  Future<void> logout() async {
    try {
      // Use the sessionId stored in controller if available, otherwise use current session
      final logoutSessionId =
          sessionId.value.isNotEmpty ? sessionId.value : 'current';

      await authRepository.logout(logoutSessionId);

      // Clear controller state
      currentStaff.value = null;
      staffAuthorities.clear();
      sessionId.value = '';
      clinicId.value = '';
      staffDocId.value = '';

      Get.offAllNamed('/login');

      Get.snackbar(
        'Logged Out',
        'You have been logged out successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    } catch (e) {
      print('Logout error: $e');
    }
  }
}

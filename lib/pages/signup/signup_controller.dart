import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/utils/custom_snack_bar.dart';
import 'package:capstone_app/utils/full_screen_dialog_loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignUpController extends GetxController {
  AuthRepository authRepository;
  SignUpController(this.authRepository);

  //Form Key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  //controllers
  final TextEditingController emailEditingController = TextEditingController();
  final TextEditingController passwordEditingController =
      TextEditingController();
  final TextEditingController nameEditingController = TextEditingController();

  //form validation
  bool isFormValid = false;

  @override
  void onClose() {
    super.onClose();
    emailEditingController.dispose();
    passwordEditingController.dispose();
    nameEditingController.dispose();
  }

  void clearTextEditingControllers() {
    emailEditingController.clear();
    passwordEditingController.clear();
    nameEditingController.clear();
  }

  // validate form fields
  String? validateEmail(String? value) {
    if (value == null || !GetUtils.isEmail(value)) {
      return "Provide a valid Email";
    }
    return null;
  }

  String? validatePassword(String? value) {
    if (value == null || value.length < 8) {
      return "Password must be at least 8 characters";
    }
    return null;
  }

  String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return "Phone number cannot be empty";
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
    Get.toNamed(Routes.login);
  }

  void validateAndSignUp({
    required String email,
    required String password,
    required String name,
  }) async {
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
        message: "User account created",
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
              message: "This email is already registered.");
        } else {
          CustomSnackBar.showErrorSnackBar(
              context: Get.overlayContext,
              title: "Error",
              message: error.response ?? "An error occurred");
        }
      } else {
        CustomSnackBar.showErrorSnackBar(
            context: Get.overlayContext,
            title: "Error",
            message: "Something went wrong");
      }
    }
  }
}

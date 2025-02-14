import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/pages/utils/custom_snack_bar.dart';
import 'package:capstone_app/pages/utils/full_screen_dialog_loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SignUpController extends GetxController {

  AuthRepository authRepository;
  SignUpController(this.authRepository);

  //Form Key
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  //controllers
  final TextEditingController emailEditingController = TextEditingController();
  final TextEditingController passwordEditingController = TextEditingController();
  final TextEditingController nameEditingController = TextEditingController();

  //form validation
  bool isFormValid = false;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() async {
    super.onReady();
  }
  
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

  // Validate form fields
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
    required String name}) async {

      if (formKey.currentState == null) {
      debugPrint("Error: formKey.currentState is null");
      return;
    }

    bool isFormValid = formKey.currentState != null && formKey.currentState!.validate();
    debugPrint('Form validation result: $isFormValid');
    debugPrint('User details: $email, $password, $name');

      if (!isFormValid) {
        return;
      }else {
        formKey.currentState!.save();
        try {
          FullScreenDialogLoader.showDialog();
          await authRepository.signup({
            "userId": ID.unique(),
            "name": name,
            "email": email,
            "password": password
          }).then((value){
            debugPrint("Signup response: $value");
            FullScreenDialogLoader.cancelDialog();
            CustomSnackBar.showSuccessSnackBar(context: Get.overlayContext, title: "Success", message: "User account created");
            clearTextEditingControllers();
            Get.offAllNamed(Routes.login);
          }).catchError((error){
            FullScreenDialogLoader.cancelDialog();
            debugPrint("Error details: $error");
            if(error is AppwriteException){
              if (error.code == 409) {
                CustomSnackBar.showErrorSnackBar(context: Get.overlayContext, title: "Error", message: "This email is already registered. Please try logging in.");
              } if (error.code == 429) {
                CustomSnackBar.showErrorSnackBar(context: Get.overlayContext, title: "Error", message: "Too many requests. Please try again later.");
              } else {
                final message = error.response != null ? error.response['message'] : "An error occurred";
                CustomSnackBar.showErrorSnackBar(context: Get.overlayContext, title: "Error", message: message);
              }  
            }
            else{
              CustomSnackBar.showErrorSnackBar(context: Get.overlayContext, title: "Error", message: "Something went wong");
            }
          });
        } catch (e) {
          FullScreenDialogLoader.cancelDialog();
          CustomSnackBar.showErrorSnackBar(context: Get.overlayContext, title: "Error", message: "Something went wong");
        }
    }
  }
}
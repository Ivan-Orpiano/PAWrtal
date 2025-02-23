import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/pages/utils/custom_snack_bar.dart';
import 'package:capstone_app/pages/utils/full_screen_dialog_loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class LoginController extends GetxController {

    AuthRepository authRepository;
    LoginController(this.authRepository); 

    //Form Key
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    //controllers
    TextEditingController emailEditingController = TextEditingController();
    TextEditingController passwordEditingController = TextEditingController();

    //form validation
    bool isFormValid = false;

    final GetStorage _getStorage = GetStorage();

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
    }

    void clearTextEditingControllers() {
      emailEditingController.clear();
      passwordEditingController.clear();
    }

    String? validateEmail(String value) {
      if (!GetUtils.isEmail(value)) {
        return "Provide a valid Email";
      }
      
      return null;
    }

    String? validatePassword(String value) {
      if (value.isEmpty) {
        return "Provide valid password";
      }
      
      return null;
    }

  void validateAndLogin({
    required String email,
    required String password,}) async {
    isFormValid = formKey.currentState!.validate();
    if (!isFormValid) {
      return;
    } else {
      formKey.currentState!.save();
      try {
          FullScreenDialogLoader.showDialog();
          await authRepository.login({
            "email": email,
            "password": password
          }).then((value){
            debugPrint("Login response: $value");
            FullScreenDialogLoader.cancelDialog();
            CustomSnackBar.showSuccessSnackBar(context: Get.overlayContext, title: "Success", message: "Login Success");
            clearTextEditingControllers();

            _getStorage.write("userId", value.userId);
            _getStorage.write("sessionId", value.$id);

            Get.offAllNamed(Routes.userHome);
          }).catchError((error){
            FullScreenDialogLoader.cancelDialog();
            debugPrint("Error details: $error");
            if(error is AppwriteException){
                final message = error.response != null ? error.response['message'] : "An error occurred";
                CustomSnackBar.showErrorSnackBar(context: Get.overlayContext, title: "Error", message: message);               
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

  void moveToSignUp() {
    Get.toNamed(Routes.signup);
  }
}
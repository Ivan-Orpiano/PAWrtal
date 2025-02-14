import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/pages/utils/custom_snack_bar.dart';
import 'package:capstone_app/pages/utils/full_screen_dialog_loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class UserHomeController extends GetxController {
  AuthRepository authRepository;
  UserHomeController(this.authRepository);

  final GetStorage  _getStorage = GetStorage();

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
  }

  logout() async {
    try {
          FullScreenDialogLoader.showDialog();
          await authRepository.logout(_getStorage.read("sessionId")
          ).then((value){
            FullScreenDialogLoader.cancelDialog();
            _getStorage.erase();
            Get.offAllNamed(Routes.login);
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

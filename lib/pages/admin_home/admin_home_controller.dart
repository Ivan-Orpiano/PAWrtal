import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/pages/utils/custom_snack_bar.dart';
import 'package:capstone_app/pages/utils/full_screen_dialog_loader.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'package:capstone_app/data/models/staff_model.dart';

class AdminHomeController extends GetxController with StateMixin<List<Staff>> {
  AuthRepository authRepository;
  AdminHomeController(this.authRepository);

  final GetStorage _getStorage = GetStorage();
  late List<Staff> staffList = [];

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    getStaff();
  }

  @override
  void onClose() {
    super.onClose();
  }

  logout() async {
    try {
      FullScreenDialogLoader.showDialog();
      await authRepository.logout(_getStorage.read("sessionId")).then((value) {
        FullScreenDialogLoader.cancelDialog();

        _getStorage.erase();
        Get.offAllNamed(Routes.login);
      }).catchError((error) {
        FullScreenDialogLoader.cancelDialog();
        if (error is AppwriteException) {
          CustomSnackBar.showErrorSnackBar(
              context: Get.context,
              title: "Error",
              message: error.response['message']);
        } else {
          CustomSnackBar.showErrorSnackBar(
              context: Get.context,
              title: "Error",
              message: "Something went wrong");
        }
      });
    } catch (e) {
      FullScreenDialogLoader.cancelDialog();
      CustomSnackBar.showErrorSnackBar(
          context: Get.context,
          title: "Error",
          message: "Something went wrong");
    }
  }

  moveToCreateStaff() {
    Get.toNamed(Routes.createStaff);
  }

  moveToEditStaff(Staff staff) {
    Get.toNamed(Routes.createStaff, arguments: {
      'staff': staff,
      'currentImage': staff.image,
    });
  }

  getStaff() async {
    try {
      change(null, status: RxStatus.loading());
      await authRepository.getStaff().then((value) {
        Map<String, dynamic> data = value.toMap();
        List d = data['documents'].toList();

        staffList = d.map((e) {
          return Staff.fromMap(e['data']);
        }).toList();

        change(staffList, status: RxStatus.success());
      }).catchError((error) {
        debugPrint("Error fetching staff: $error");
        if (error is AppwriteException) {
          change(null, status: RxStatus.error(error.response['message']));
        } else {
          change(null, status: RxStatus.error("Something went wrong"));
        }
      });
    } catch (e) {
      change(null, status: RxStatus.error("Something went wrong"));
    }
  }

  deleteStaff(Staff staff) async {
    try {
      FullScreenDialogLoader.showDialog();
      await authRepository.deleteStaff({
        "documentId": staff.documentId,
      }).then((value) async {
        await authRepository.deleteStaffImage(staff.image);
        FullScreenDialogLoader.cancelDialog();
        CustomSnackBar.showSuccessSnackBar(
            context: Get.context,
            title: "Success",
            message: "Staff deleted successfully");
        Get.find<AdminHomeController>().getStaff();
        Get.offNamedUntil(Routes.adminHome, (route) => route.isFirst);
      }).catchError((error) async {
        FullScreenDialogLoader.cancelDialog();
        if (error is AppwriteException) {
          CustomSnackBar.showErrorSnackBar(
              context: Get.context,
              title: "Error",
              message: error.response['message']);
        } else {
          CustomSnackBar.showErrorSnackBar(
              context: Get.context,
              title: "Error",
              message: "Something went wrong");
        }
      });
    } catch (e) {
      FullScreenDialogLoader.cancelDialog();
      CustomSnackBar.showErrorSnackBar(
          context: Get.context,
          title: "Error",
          message: "Something went wrong");
    }
  }
}

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/staff_model.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/utils/custom_snack_bar.dart';
import 'package:capstone_app/utils/full_screen_dialog_loader.dart';
import 'package:flutter/material.dart';
import 'package:appwrite/appwrite.dart';

class AdminHomeController extends GetxController with StateMixin<List<Staff>> {
  final AuthRepository authRepository;
  final GetStorage _getStorage = GetStorage();

  AdminHomeController(this.authRepository);

  final Rxn<Clinic> clinic = Rxn<Clinic>();
  late List<Staff> staffList = [];

  @override
  void onReady() {
    super.onReady();
    fetchClinicInfo();
    getStaff();
  }

  Future<void> fetchClinicInfo() async {
    try {
      final user = await authRepository.getUser();
      final clinicDoc = await authRepository.getClinicByAdminId(user!.$id);

      if (clinicDoc != null) {
        clinic.value = Clinic.fromMap(clinicDoc.data);
        print("Clinic name: ${clinic.value!.clinicName}");
      } else {
        print("No clinic found for this admin.");
      }
    } catch (e) {
      print("Failed to fetch clinic: $e");
    }
  }

  Future<void> getStaff() async {
    try {
      change(null, status: RxStatus.loading());

      final clinicId = clinic.value?.documentId ?? _getStorage.read("clinicId");
      final value = await authRepository.getStaffByClinicId(clinicId!);

      List documents = value!.toMap()['documents'];
      staffList = documents.map((e) => Staff.fromMap(e['data'])).toList();

      change(staffList, status: RxStatus.success());
    } catch (e) {
      debugPrint("Error fetching staff: $e");
      change(null, status: RxStatus.error("Failed to fetch staff"));
    }
  }

  void logout() async {
    try {
      FullScreenDialogLoader.showDialog();
      await authRepository.logout(_getStorage.read("sessionId"));
      _getStorage.erase();
      FullScreenDialogLoader.cancelDialog();
      Get.offAllNamed(Routes.login);
    } catch (e) {
      FullScreenDialogLoader.cancelDialog();
      CustomSnackBar.showErrorSnackBar(
        context: Get.overlayContext,
        title: "Logout Failed",
        message: e.toString(),
      );
    }
  }

  void moveToCreateStaff() {
    Get.toNamed(Routes.createStaff);
  }

  void moveToEditStaff(Staff staff) {
    Get.toNamed(Routes.createStaff, arguments: {
      'staff': staff,
      'currentImage': staff.image,
    });
  }

  Future<void> deleteStaff(Staff staff) async {
    try {
      FullScreenDialogLoader.showDialog();
      await authRepository.deleteStaff({"documentId": staff.documentId});
      await authRepository.deleteStaffImage(staff.image);

      FullScreenDialogLoader.cancelDialog();
      CustomSnackBar.showSuccessSnackBar(
        context: Get.context,
        title: "Success",
        message: "Staff deleted",
      );

      getStaff();
    } catch (e) {
      FullScreenDialogLoader.cancelDialog();
      CustomSnackBar.showErrorSnackBar(
        context: Get.context,
        title: "Error",
        message: e.toString(),
      );
    }
  }
}

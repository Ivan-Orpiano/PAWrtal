import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/pages/utils/custom_snack_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';

class StaffAccountController extends GetxController {
  AuthRepository authRepository;
  StaffAccountController(this.authRepository);

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController nameEditingController = TextEditingController();
  TextEditingController departmentEditingController = TextEditingController();

  bool isFormValid = false;

  final GetStorage _getStorage = GetStorage();

  var imagePath = ''.obs;
  final ImagePicker _picker = ImagePicker();

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
    nameEditingController.dispose();
    departmentEditingController.dispose();
  }

  void clearTextEditingControllers() {
    nameEditingController.clear();
    departmentEditingController.clear();
  }

  String? validateName (String value) {
    if (value.isEmpty) {
      return "Provide a valid name";
    }
    return null;
  }

  String? validateDepartment (String value) {
    if (value.isEmpty) {
      return "Provide a valid department";
    }
    return null;
  }

  void selectImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      imagePath.value = image.path;
    } else {
      CustomSnackBar.showErrorSnackBar(
        context: Get.overlayContext,
        title: "Error",
        message: "Image selection cancelled");
    }
  }

  void validateAndSave ({required String name, required String department}) async {
    isFormValid = formKey.currentState!.validate();
    if (!isFormValid) {
      return;
    } else {
      formKey.currentState!.save();
    }
  }
}
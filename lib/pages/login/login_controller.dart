import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/utils/custom_snack_bar.dart';
import 'package:capstone_app/utils/full_screen_dialog_loader.dart';
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
  TextEditingController emailForPasswordResetController =
      TextEditingController();

  //form validation
  bool isFormValid = false;

  final GetStorage _getStorage = GetStorage();

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
    required String password,
  }) async {
    isFormValid = formKey.currentState!.validate();
    if (!isFormValid) return;

    try {
      formKey.currentState!.save();
      FullScreenDialogLoader.showDialog();

      final value = await authRepository.login({
        "email": email,
        "password": password,
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

      // check if account is admin
      final clinicDoc = await authRepository.getClinicByAdminId(userId);
      if (clinicDoc != null) {
        role = clinicDoc.data["role"];
        _getStorage.write("clinicId", clinicDoc.$id);
        matched = true;
      }

      // check if account is staff
      if (!matched) {
        final staffDoc = await authRepository.getStaffByClinicId(userEmail);
        if (staffDoc != null) {
          role = staffDoc.data["role"];
          _getStorage.write("staffId", staffDoc.$id);
          _getStorage.write("clinicId", staffDoc.data["clinicId"]);
          matched = true;
        }
      }

      // check if user (customer)
      if (!matched) {
        final userDoc = await authRepository.getUserById(userId);
        if (userDoc != null) {
          role = userDoc.data["role"]; // role should be "user"
          _getStorage.write("customerId", userDoc.$id);
          matched = true;
        }
      }

      // check if developer (super admin)
      if (!matched && userEmail == "test.developer@gmail.com") {
        role = "developer";
        matched = true;
      }

      if (!matched) throw Exception("No role found for this account");

      _getStorage.write("role", role);

      FullScreenDialogLoader.cancelDialog();
      CustomSnackBar.showSuccessSnackBar(
          context: Get.overlayContext,
          title: "Success",
          message: "Login Success");

      clearTextEditingControllers();

      // route by role
      if (role == "admin") {
        Get.offAllNamed(Routes.adminHome);
      } else if (role == "developer") {
        Get.offAllNamed(Routes.superAdminHome);
      } else if (role == "staff") {
        Get.offAllNamed(Routes.adminHome);
      } else {
        Get.offAllNamed(Routes.userHome);
      }
    } catch (e) {
      FullScreenDialogLoader.cancelDialog();
      CustomSnackBar.showErrorSnackBar(
          context: Get.overlayContext,
          title: "Login Failed",
          message: e is AppwriteException
              ? e.response['message'] ?? "Appwrite error"
              : e.toString());
    }
  }

  void moveToSignUp() {
    Get.toNamed(Routes.signup);
  }
}

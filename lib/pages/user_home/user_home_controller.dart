import 'package:appwrite/appwrite.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';
import 'package:capstone_app/utils/custom_snack_bar.dart';
import 'package:capstone_app/utils/full_screen_dialog_loader.dart';
import 'package:capstone_app/utils/logout_helper.dart'; // ADD THIS IMPORT
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class UserHomeController extends GetxController {
  AuthRepository authRepository;
  UserHomeController(this.authRepository);

  final GetStorage _getStorage = GetStorage();

  /// IMPROVED: Use LogoutHelper for consistent logout across the app
  logout() async {
    try {
      // Use the centralized logout helper
      await LogoutHelper.logout();
    } catch (e) {
      
      // Fallback: Force local logout
      try {
        FullScreenDialogLoader.cancelDialog();
        await _getStorage.erase();
        Get.offAllNamed(Routes.login);
        
        CustomSnackBar.showErrorSnackBar(
          context: Get.overlayContext,
          title: "Logged Out",
          message: "You have been signed out locally"
        );
      } catch (fallbackError) {
      }
    }
  }

  /// DEPRECATED: Old logout method (kept for backward compatibility)
  /// This is no longer used - logout() now calls LogoutHelper.logout()
  _legacyLogout() async {
    try {
      FullScreenDialogLoader.showDialog();
      await authRepository.logout(_getStorage.read("sessionId")).then((value) {
        FullScreenDialogLoader.cancelDialog();
        _getStorage.erase();
        Get.offAllNamed(Routes.login);
      }).catchError((error) {
        FullScreenDialogLoader.cancelDialog();
        if (error is AppwriteException) {
          final message = error.response ?? "An error occurred";
          CustomSnackBar.showErrorSnackBar(
              context: Get.overlayContext, title: "Error", message: message);
        } else {
          CustomSnackBar.showErrorSnackBar(
              context: Get.overlayContext,
              title: "Error",
              message: "Something went wrong");
        }
      });
    } catch (e) {
      FullScreenDialogLoader.cancelDialog();
      CustomSnackBar.showErrorSnackBar(
          context: Get.overlayContext,
          title: "Error",
          message: "Something went wrong");
    }
  }
}
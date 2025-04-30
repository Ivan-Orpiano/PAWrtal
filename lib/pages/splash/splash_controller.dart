import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../routes/app_pages.dart';

class SplashController extends GetxController {
  SplashController(AuthRepository authRepository);

  final GetStorage _getStorage = GetStorage();

  @override
  void onReady() async {
    super.onReady();
    await Future.delayed(const Duration(seconds: 1));

    final role = _getStorage.read("role");

    if (role != null) {
      switch (role) {
        case "admin":
          Get.offAllNamed(Routes.adminHome);
          break;
        case "staff":
          Get.offAllNamed(Routes.adminHome);
          break;
        case "developer":
          Get.offAllNamed(Routes.superAdminHome);
          break;
        case "user":
          Get.offAllNamed(Routes.userHome);
          break;
        default:
          Get.offAllNamed(Routes.login);
          break;
      }
    } else {
      Get.offAllNamed(Routes.login);
    }
  }
}

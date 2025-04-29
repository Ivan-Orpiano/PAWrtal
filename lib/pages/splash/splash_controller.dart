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

    if (_getStorage.read("userId") != null) {
      Get.offAllNamed(Routes.userHome);
    } else {
      Get.offAllNamed(Routes.login);
    }
  }
}

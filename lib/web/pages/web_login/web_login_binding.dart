import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/web/pages/web_login/web_login_controller.dart';
import 'package:get/get.dart';

class WebLoginBinding extends Bindings {
  @override
  void dependencies() {
    // Register AuthRepository if not already registered
    if (!Get.isRegistered<AuthRepository>()) {
      Get.lazyPut<AuthRepository>(() => AuthRepository(AppWriteProvider()));
    }

    // Register WebLoginController
    Get.lazyPut<WebLoginController>(
      () => WebLoginController(Get.find<AuthRepository>()),
    );
  }
}
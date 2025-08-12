import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/web/pages/web_signup/web_signup_controller.dart';
import 'package:get/get.dart';

class WebSignUpBinding extends Bindings {
  @override
  void dependencies() {
    // Register AuthRepository if not already registered
    if (!Get.isRegistered<AuthRepository>()) {
      Get.lazyPut<AuthRepository>(() => AuthRepository(AppWriteProvider()));
    }

    // Register WebSignUpController
    Get.lazyPut<WebSignUpController>(
      () => WebSignUpController(Get.find<AuthRepository>()),
    );
  }
}
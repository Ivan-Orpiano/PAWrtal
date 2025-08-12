import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/web/pages/web_super_admin_home/web_super_admin_home_controller.dart';
import 'package:get/get.dart';

class WebSuperAdminHomeBinding extends Bindings {
  @override
  void dependencies() {
    // Register AuthRepository if not already registered
    if (!Get.isRegistered<AuthRepository>()) {
      Get.lazyPut<AuthRepository>(() => AuthRepository(AppWriteProvider()));
    }

    // Register WebSuperAdminHomeController
    Get.lazyPut<WebSuperAdminHomeController>(
      () => WebSuperAdminHomeController(Get.find<AuthRepository>()),
    );
  }
}
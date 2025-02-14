import 'package:capstone_app/data/provider/appwrite_provider.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:get/get.dart';
import 'signup_controller.dart';

class SignUpBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthRepository>(() => AuthRepository(AppWriteProvider()));  
    Get.lazyPut(() => SignUpController(Get.find<AuthRepository>()));

  }
}
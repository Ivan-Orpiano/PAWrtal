import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:get/get.dart';

class SuperAdminHomeController extends GetxController {
  AuthRepository authRepository;
  SuperAdminHomeController(this.authRepository);
}
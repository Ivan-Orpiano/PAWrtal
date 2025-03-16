import 'package:capstone_app/pages/admin_home/admin_home_binding.dart';
import 'package:capstone_app/pages/admin_home/admin_home_page.dart';
import 'package:capstone_app/pages/super_admin_home/super_admin_home_binding.dart';
import 'package:capstone_app/pages/super_admin_home/super_admin_home_page.dart';
import 'package:capstone_app/pages/user_home/user_home_binding.dart';
import 'package:capstone_app/pages/user_home/user_home_page.dart';
import 'package:capstone_app/pages/login/login_binding.dart';
import 'package:capstone_app/pages/login/login_page.dart';
import 'package:capstone_app/pages/signup/signup_binding.dart';
import 'package:capstone_app/pages/signup/signup_page.dart';
import 'package:capstone_app/pages/splash/splash_binding.dart';
import 'package:capstone_app/pages/splash/splash_page.dart';
import 'package:get/get.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.adminHome;

  static final routes = [
    GetPage(
      name: _Paths.splash,
      page: () => const SplashPage(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: _Paths.login,
      page: () => const LoginPage(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.signup,
      page: () => const SignUpPage(),
      binding: SignUpBinding(),
    ),
    GetPage(
      name: _Paths.userHome,
      page: () => const UserHomePage(),
      binding: UserHomeBinding(),
    ),
    GetPage(
      name: _Paths.adminHome,
      page: () => const AdminHomePage(),
      binding: AdminHomeBinding(),
    ),
    GetPage(
      name: _Paths.superAdminHome,
      page: () => const SuperAdminHomePage(),
      binding: SuperAdminHomeBinding(),
    )
  ];
}
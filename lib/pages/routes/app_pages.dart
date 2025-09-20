import 'package:capstone_app/mobile/admin/pages/staff_account_creation/staff_account_binding.dart';
import 'package:capstone_app/mobile/admin/pages/staff_account_creation/staff_account_creation_page.dart';
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
// Web imports
import 'package:capstone_app/web/pages/web_login/web_login_binding.dart';
import 'package:capstone_app/web/pages/web_login/web_login_page.dart';
import 'package:capstone_app/web/pages/web_signup/web_sign_up_page.dart';
import 'package:capstone_app/web/pages/web_signup/web_signup_binding.dart';
import 'package:capstone_app/web/pages/web_user_home/web_user_home_binding.dart';
import 'package:capstone_app/web/pages/web_user_home/web_user_home_page.dart';
import 'package:capstone_app/web/pages/web_admin_home/web_admin_home_binding.dart';
import 'package:capstone_app/web/pages/web_admin_home/web_admin_home_page.dart';
import 'package:capstone_app/web/pages/web_super_admin_home/web_super_admin_home_binding.dart';
import 'package:capstone_app/web/pages/web_super_admin_home/web_super_admin_home_page.dart';
// Add this import for the settings page
import 'package:capstone_app/web/user_web/desktop_web/pages/web_settings_and_everything_page.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = Routes.splash;

  static final routes = [
    GetPage(
      name: _Paths.splash,
      page: () => const SplashPage(),
      binding: SplashBinding(),
    ),
    // Mobile/Web agnostic login routes - controller will handle platform detection
    GetPage(
      name: _Paths.login,
      page: () => kIsWeb ? const WebLoginPage() : const LoginPage(),
      binding: kIsWeb ? WebLoginBinding() : LoginBinding(),
    ),
    GetPage(
      name: _Paths.signup,
      page: () => kIsWeb ? const WebSignUpPage() : const SignUpPage(),
      binding: kIsWeb ? WebSignUpBinding() : SignUpBinding(),
    ),
    GetPage(
      name: _Paths.userHome,
      page: () => kIsWeb ? const WebUserHomePage() : const UserHomePage(),
      binding: kIsWeb ? WebUserHomeBinding() : UserHomeBinding(),
    ),
    GetPage(
      name: _Paths.adminHome,
      page: () => kIsWeb ? const WebAdminHomePage() : const AdminHomePage(),
      binding: kIsWeb ? WebAdminHomeBinding() : AdminHomeBinding(),
    ),
    GetPage(
      name: _Paths.superAdminHome,
      page: () => kIsWeb ? const WebSuperAdminHomePage() : const SuperAdminHomePage(),
      binding: kIsWeb ? WebSuperAdminHomeBinding() : SuperAdminHomeBinding(),
    ),
    GetPage(
      name: _Paths.createStaff,
      page: () => const StaffAccountCreationPage(),
      binding: CreateStaffBinding(),
    ),
    // Add the settings page route
    GetPage(
      name: _Paths.webSettings,
      page: () => const WebSettingsAndEverythingPage(),
    ),
  ];
}
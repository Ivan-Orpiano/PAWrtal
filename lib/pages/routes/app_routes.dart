part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const splash = _Paths.splash;
  static const signup = _Paths.signup;
  static const userHome = _Paths.userHome;
  static const adminHome = _Paths.adminHome;
  static const superAdminHome = _Paths.superAdminHome;
  static const login = _Paths.login;
  static const createStaff = _Paths.createStaff;
  static const staffHome = _Paths.staffHome; // ADD THIS
  static const oauthSuccess = _Paths.oauthSuccess;
  static const oauthFailure = _Paths.oauthFailure;
  static const oauthCallback = _Paths.oauthCallback;
}

abstract class _Paths {
  static const splash = '/splash';
  static const signup = '/signup';
  static const userHome = '/userHome';
  static const adminHome = '/adminHome';
  static const superAdminHome = '/superAdminHome';
  static const login = '/login';
  static const createStaff = '/createStaff';
  static const staffHome = '/staffHome'; // ADD THIS
  static const oauthSuccess = '/auth/success';
  static const oauthFailure = '/auth/failure';
  static const oauthCallback = '/auth/callback';
}

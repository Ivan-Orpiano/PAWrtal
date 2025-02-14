part of 'app_pages.dart';

abstract class Routes {
  Routes._();
  static const splash = _Paths.splash;
  static const signup = _Paths.signup;
  static const home = _Paths.home;
  static const login = _Paths.login;
}

abstract class _Paths {
  static const splash = '/splash';
  static const signup = '/signup';
  static const home = '/home';
  static const login = '/login';
}
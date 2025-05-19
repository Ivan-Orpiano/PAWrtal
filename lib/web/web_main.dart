import 'package:capstone_app/pages/super_admin_home/super_admin_home_page.dart';
import 'package:capstone_app/web/login_web/web_login_page.dart';
import 'package:capstone_app/web/user_web/pages/web_clinic_page.dart';
import 'package:capstone_app/web/user_web/pages/web_user_home_page.dart';
import 'package:flutter/material.dart';

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(); // 
  }
}

class WebMain extends StatelessWidget {
  const WebMain({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scrollBehavior: MyCustomScrollBehavior(),
      home: const WebUserHomePage(),
    );
  }
}
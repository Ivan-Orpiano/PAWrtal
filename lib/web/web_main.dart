import 'package:capstone_app/web/login_web/web_login_page.dart';
import 'package:capstone_app/web/user_web/pages/web_clinic_page.dart';
import 'package:capstone_app/web/user_web/pages/web_user_home_page.dart';
import 'package:flutter/material.dart';

class WebMain extends StatelessWidget {
  const WebMain({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: WebClinicPage(),
    );
  }
}
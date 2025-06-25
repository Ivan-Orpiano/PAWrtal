import 'package:capstone_app/web/desktop_web/user_web/pages/web_clinic_page.dart';
import 'package:capstone_app/web/desktop_web/user_web/pages/web_user_home_page.dart';
import 'package:flutter/material.dart';

class DesktopBody extends StatelessWidget {
  const DesktopBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: WebClinicPage(),
    );
  }
}
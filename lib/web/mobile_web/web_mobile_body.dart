import 'package:capstone_app/web/mobile_web/pages/web_mobile_user_homepage.dart';
import 'package:flutter/material.dart';

class MobileBody extends StatelessWidget {
  const MobileBody({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: WebMobileUserHomepage(),
    );
  }
}
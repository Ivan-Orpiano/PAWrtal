import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/pages/routes/app_pages.dart';

class OAuthFailurePage extends StatelessWidget {
  const OAuthFailurePage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.offAllNamed(Routes.login);
      Get.snackbar(
        'Sign In Failed',
        'Google Sign-In was cancelled or failed',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade900,
      );
    });

    return const Scaffold(
      body: Center(
        child: Text('Redirecting...'),
      ),
    );
  }
}
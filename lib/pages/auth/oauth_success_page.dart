import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/pages/auth/oauth_callback_page.dart';

class OAuthSuccessPage extends StatelessWidget {
  const OAuthSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Immediately redirect to callback handler
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Get.off(() => const OAuthCallbackPage());
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
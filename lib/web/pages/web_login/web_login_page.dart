import 'package:capstone_app/pages/login/login_page.dart';
import 'package:capstone_app/utils/web_loading_helper.dart';
import 'package:capstone_app/web/dimensions.dart';
import 'package:capstone_app/web/pages/web_login/web_login_controller.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebLoginPage extends GetView<WebLoginController> {
  const WebLoginPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth <= mobileWidth) {
            return const LoginPage();
          } else {
            return _buildDesktopTabletLayout(context);
          }
        },
      ),
    );
  }

  Widget _buildDesktopTabletLayout(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive dimensions
        final screenWidth = constraints.maxWidth;
        final screenHeight = constraints.maxHeight;
        
        // Container dimensions (responsive)
        final containerWidth = (screenWidth * 0.9).clamp(800.0, 1000.0);
        final containerHeight = (screenHeight * 0.85).clamp(600.0, 700.0);
        
        // Side panel widths (responsive)
        final sideWidth = (containerWidth - 10) / 2; // 10px for divider
        
        // Form field width (responsive)
        final fieldWidth = (sideWidth * 0.8).clamp(300.0, 400.0);
        
        // Logo dimensions (responsive)
        final logoWidth = (sideWidth * 0.6).clamp(250.0, 300.0);
        final logoHeight = logoWidth / 3;

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              transform: GradientRotation(2.61799),
              colors: <Color>[
                Color(0xFFf9f9f9),
                Color(0xFFd4dad6),
                Color(0xFFafbbb6),
                Color(0xFF8b9d9b),
                Color(0xFF698083),
                Color(0xFF49636f),
                Color(0xFF2c475c),
                Color(0xFF142b4e)
              ]
            )
          ),
          child: Center(
            child: Container(
              width: containerWidth,
              height: containerHeight,
              decoration: BoxDecoration(
                color: const Color.fromARGB(223, 255, 255, 255),
                borderRadius: BorderRadius.circular(20)
              ),
              child: Row(
                children: [
                  // Left side - Welcome section
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: containerHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        spacing: 20,
                        children: [
                          const Spacer(flex: 1),
                          const Text(
                            "WELCOME TO",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          Image.asset(
                            'lib/images/PAWrtal_logo.png',
                            width: logoWidth,
                            height: logoHeight,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                style: const TextStyle(color: Colors.black),
                                children: <TextSpan>[
                                  const TextSpan(text: "Don't have an account? "),
                                  TextSpan(
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 81, 115, 153),
                                    ),
                                    text: "Sign up",
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = controller.navigateToSignUp,
                                  )
                                ],
                              ),
                            ),
                          ),
                          const Spacer(flex: 2)
                        ],
                      ),
                    ),
                  ),
                  // Divider
                  Container(
                    width: 1,
                    height: containerHeight * 0.8,
                    color: Colors.grey.shade300,
                  ),
                  // Right side - Login form
                  Expanded(
                    flex: 1,
                    child: Container(
                      height: containerHeight,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const Spacer(flex: 1),
                          Expanded(
                            flex: 8,
                            child: SingleChildScrollView(
                              child: Form(
                                key: controller.formKey,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: containerHeight * 0.09, 
                                        bottom: 16
                                      ),
                                      child: const Text(
                                        "Sign In",
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    ),
                                    // Email Field
                                    SizedBox(
                                      width: fieldWidth,
                                      child: TextFormField(
                                        controller: controller.emailController,
                                        keyboardType: TextInputType.emailAddress,
                                        decoration: InputDecoration(
                                          prefixIcon: const Icon(Icons.email_rounded),
                                          hintText: "Email",
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(20)
                                          )
                                        ),
                                        validator: controller.validateEmail,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // Password Field
                                    SizedBox(
                                      width: fieldWidth,
                                      child: Obx(() => TextFormField(
                                        controller: controller.passwordController,
                                        obscureText: !controller.isPasswordVisible.value,
                                        decoration: InputDecoration(
                                          prefixIcon: const Icon(Icons.lock_rounded),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              controller.isPasswordVisible.value
                                                ? Icons.visibility
                                                : Icons.visibility_off,
                                            ),
                                            onPressed: controller.togglePasswordVisibility,
                                          ),
                                          hintText: "Password",
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(20)
                                          ),
                                        ),
                                        validator: controller.validatePassword,
                                      )),
                                    ),
                                    // Forgot Password
                                    Container(
                                      width: fieldWidth,
                                      padding: const EdgeInsets.only(top: 8, bottom: 0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          GestureDetector(
                                            onTap: () => _showResetPasswordDialog(context),
                                            child: Text(
                                              "Forgot Password?",
                                              style: TextStyle(color: Colors.blue.shade700),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // Sign In Button
                                    SizedBox(
                                      width: fieldWidth,
                                      child: Obx(() => WebLoadingHelper.buildLoadingButton(
                                        text: "Sign In",
                                        isLoading: controller.isLoading.value,
                                        onPressed: controller.signIn,
                                      )),
                                    ),
                                    const SizedBox(height: 24),
                                    // Divider
                                    SizedBox(
                                      width: fieldWidth,
                                      child: const Row(
                                        children: [
                                          Expanded(
                                            child: Divider(),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 8),
                                            child: Text(
                                              "or",
                                              style: TextStyle(
                                                fontStyle: FontStyle.italic
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Divider()
                                          )
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // Google Sign In section
                                    SizedBox(
                                      width: fieldWidth,
                                      child: Column(
                                        children: [
                                          const Text("Sign in with"),
                                          const SizedBox(height: 16),
                                          Obx(() => InkWell(
                                            onTap: controller.isLoading.value 
                                              ? null 
                                              : controller.signInWithGoogle,
                                            child: Container(
                                              width: 50,
                                              height: 50,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                boxShadow: [
                                                  BoxShadow(
                                                    spreadRadius: 1,
                                                    blurRadius: 1,
                                                    color: Colors.grey.shade400,
                                                    offset: const Offset(0, 2)
                                                  )
                                                ]
                                              ),
                                              child: controller.isLoading.value
                                                ? const Center(
                                                    child: SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                      ),
                                                    ),
                                                  )
                                                : Image.asset('lib/images/google_logo.png'),
                                            ),
                                          )),
                                        ],
                                      ),
                                    ),
                                  ]
                                ),
                              ),
                            ),
                          ),
                          const Spacer(flex: 1)
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showResetPasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Password"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Please enter your email. We will send a recovery link."),
            const SizedBox(height: 10),
            Form(
              key: controller.resetPasswordFormKey,
              child: TextFormField(
                controller: controller.emailForPasswordResetController,
                keyboardType: TextInputType.emailAddress,
                validator: controller.validateEmail,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Email",
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              controller.emailForPasswordResetController.clear();
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              controller.sendPasswordResetEmail();
              Navigator.pop(context);
            },
            child: const Text("Send Link"),
          ),
        ],
      ),
    );
  }
}
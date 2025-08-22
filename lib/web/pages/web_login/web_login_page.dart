import 'package:capstone_app/utils/web_loading_helper.dart';
import 'package:capstone_app/web/pages/web_login/web_login_controller.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebLoginPage extends GetView<WebLoginController> {
  const WebLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Center(
              child: Container(
                width: 1000,
                height: 700,
                decoration:  BoxDecoration(
                  color: const Color.fromARGB(223, 255, 255, 255),
                  borderRadius: BorderRadius.circular(20)
                ),
                child: Row(
                  children: [
                    // Left side - Welcome section
                    SizedBox(
                      width: 495,
                      height: 700,
                      child: Column(
                        spacing: 20,
                        children: [
                          Spacer(flex: 1,),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "WELCOME TO",
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold
                                ),
                              ),
                            ],
                          ),
                          Image.asset(
                            'lib/images/PAWrtal_logo.png',
                            width: 300,
                            height: 100,
                          ),
                          RichText(
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
                          Spacer(flex: 2,)
                        ],
                      ),
                    ),
                    // Divider
                    const SizedBox(
                      width: 10,
                      height: 700,
                      child: VerticalDivider(
                        indent: 20,
                        endIndent: 20,
                      ),
                    ),
                    // Right side - Login form
                    SizedBox(
                      width: 495,
                      height: 700,
                      child: Column(
                        children: [
                          const Spacer(flex: 1,),
                          SingleChildScrollView(
                            child: Form(
                              key: controller.formKey,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              child: Column(
                                children: [
                                  const Row(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.only(top: 64, left: 16, bottom: 16),
                                        child: Text(
                                          "Sign In",
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.bold
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  // Email Field
                                  SizedBox(
                                    width: 400,
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
                                  const SizedBox(height: 32),
                                  // Password Field
                                  SizedBox(
                                    width: 400,
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
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8, bottom: 0, right: 60),
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
                                  const SizedBox(height: 32),
                                  // Sign In Button
                                  SizedBox(
                                    width: 400,
                                    child: Obx(() => WebLoadingHelper.buildLoadingButton(
                                      text: "Sign In",
                                      isLoading: controller.isLoading.value,
                                      onPressed: controller.signIn,
                                    )),
                                  ),
                                  const SizedBox(height: 32),
                                  // Divider
                                  const Row(
                                    children: [
                                      Expanded(
                                        child: Divider(
                                          indent: 10,
                                        ),
                                      ),
                                      Text(
                                        "  or  ",
                                        style: TextStyle(
                                          fontStyle: FontStyle.italic
                                        ),
                                      ),
                                      Expanded(
                                        child: Divider(
                                          endIndent: 10,
                                        )
                                      )
                                    ],
                                  ),
                                  const SizedBox(height: 32),
                                  const Text("Sign in with"),
                                  const SizedBox(height: 16),
                                  // Google Sign In Button
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
                                ]
                              ),
                            ),
                          ),
                          const Spacer(flex: 2,)
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      )
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
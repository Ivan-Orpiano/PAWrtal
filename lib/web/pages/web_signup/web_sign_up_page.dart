import 'package:capstone_app/web/pages/web_signup/web_signup_controller.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebSignUpPage extends GetView<WebSignUpController> {
  const WebSignUpPage({super.key});

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
            ],
          ),
        ),
        child: Center(
          child: Container(
            width: 500,
            height: 700,
            decoration: BoxDecoration(
              color: const Color.fromARGB(223, 255, 255, 255),
              boxShadow: [
                BoxShadow(
                  spreadRadius: 1,
                  blurRadius: 1,
                  color: Colors.grey.shade400,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16, left: 16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.keyboard_arrow_left_rounded),
                          onPressed: () {
                            controller.navigateToLogin();
                          },
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    'lib/images/PAWrtal_logo.png',
                    height: 50,
                    width: 300,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 400,
                    child: TextFormField(
                      controller: controller.emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email_rounded),
                        hintText: "Email",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 400,
                    child: TextFormField(
                      controller: controller.nameController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_rounded),
                        hintText: "Full Name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 400,
                    child: Obx(
                      () => TextFormField(
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
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 400,
                    child: Obx(
                      () => TextFormField(
                        controller: controller.confirmPasswordController,
                        obscureText: !controller.isConfirmPasswordVisible.value,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline_rounded),
                          suffixIcon: IconButton(
                            icon: Icon(
                              controller.isConfirmPasswordVisible.value
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: controller.toggleConfirmPasswordVisibility,
                          ),
                          hintText: "Confirm Password",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Terms and Conditions Checkbox
                  SizedBox(
                    width: 400,
                    child: Obx(() => Row(
                          children: [
                            Checkbox(
                              value: controller.termsAccepted.value,
                              onChanged: (value) {
                                controller.termsAccepted.value = value ?? false;
                              },
                              activeColor: const Color.fromARGB(255, 81, 115, 153),
                            ),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontSize: 13,
                                  ),
                                  children: [
                                    const TextSpan(text: "I agree to the "),
                                    TextSpan(
                                      text: "Terms and Conditions",
                                      style: const TextStyle(
                                        color: Color.fromARGB(255, 81, 115, 153),
                                        fontWeight: FontWeight.bold,
                                        decoration: TextDecoration.underline,
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () {
                                          controller.showTermsAndConditions();
                                        },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 400,
                    height: 50,
                    child: Obx(
                      () => ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                        ),
                        onPressed: controller.isLoading.value
                            ? null
                            : controller.signUp,
                        child: controller.isLoading.value
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "Sign Up",
                                style: TextStyle(fontSize: 20, color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black),
                      children: <TextSpan>[
                        const TextSpan(text: "Already have an account? "),
                        TextSpan(
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 81, 115, 153),
                          ),
                          text: "Sign in",
                          recognizer: TapGestureRecognizer()
                            ..onTap = controller.navigateToLogin,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      Expanded(child: Divider(indent: 8)),
                      Text("  or  "),
                      Expanded(child: Divider(endIndent: 8)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text("Sign up with"),
                  const SizedBox(height: 16),
                  Obx(
                    () => InkWell(
                      onTap: controller.isLoading.value
                          ? null
                          : controller.signUpWithGoogle,
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
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: controller.isLoading.value
                            ? const Center(child: CircularProgressIndicator())
                            : Image.asset('lib/images/google_logo.png'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
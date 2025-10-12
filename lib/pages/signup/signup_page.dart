import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:capstone_app/pages/signup/signup_controller.dart';
import 'package:get/get.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignUpPage> {
  final SignUpController controller = SignUpController(Get.find<AuthRepository>());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
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
        child: SafeArea(
          child: Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              decoration: BoxDecoration(
                color: const Color.fromARGB(223, 255, 255, 255),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    spreadRadius: 1,
                    blurRadius: 5,
                    color: Colors.grey.shade400,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Form(
                key: controller.formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Back button
                      Padding(
                        padding: const EdgeInsets.only(top: 16, left: 8),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.keyboard_arrow_left_rounded),
                              onPressed: () {
                                controller.moveToLogin();
                              },
                            ),
                          ],
                        ),
                      ),
                      
                      // Logo
                      Image.asset(
                        "lib/images/PAWrtal_logo.png",
                        height: 80,
                        width: 200,
                      ),
                      const SizedBox(height: 20),

                      // Email Field
                      SizedBox(
                        width: 300,
                        child: TextFormField(
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.email_rounded),
                            hintText: "Email",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          controller: controller.emailEditingController,
                          validator: (value) {
                            return controller.validateEmail(value!);
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Name Field
                      SizedBox(
                        width: 300,
                        child: TextFormField(
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.person_rounded),
                            hintText: "Full Name",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          keyboardType: TextInputType.name,
                          controller: controller.nameEditingController,
                          validator: (value) {
                            return controller.validateName(value!);
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Password Field
                      SizedBox(
                        width: 300,
                        child: Obx(() => TextFormField(
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
                              keyboardType: TextInputType.visiblePassword,
                              controller: controller.passwordEditingController,
                              validator: (value) {
                                return controller.validatePassword(value!);
                              },
                            )),
                      ),
                      const SizedBox(height: 20),

                      // Confirm Password Field
                      SizedBox(
                        width: 300,
                        child: Obx(() => TextFormField(
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
                              keyboardType: TextInputType.visiblePassword,
                              controller: controller.confirmPasswordEditingController,
                              validator: (value) {
                                return controller.validateConfirmPassword(value!);
                              },
                            )),
                      ),
                      const SizedBox(height: 20),

                      // Terms and Conditions Checkbox
                      SizedBox(
                        width: 300,
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
                                        fontSize: 12,
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
                      const SizedBox(height: 20),

                      // Register Button
                      SizedBox(
                        width: 300,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            elevation: 5,
                            backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          onPressed: () {
                            controller.validateAndSignUp(
                              email: controller.emailEditingController.text,
                              password: controller.passwordEditingController.text,
                              name: controller.nameEditingController.text,
                            );
                          },
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Already have account text
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
                                ..onTap = controller.moveToLogin,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Divider
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Row(
                          children: [
                            Expanded(child: Divider()),
                            Text("  or  "),
                            Expanded(child: Divider()),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sign up with Google
                      const Text(
                        "Sign up with",
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: controller.signUpWithGoogle,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                spreadRadius: 1,
                                blurRadius: 3,
                                color: Colors.grey.shade400,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Image.asset('lib/images/google_logo.png'),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
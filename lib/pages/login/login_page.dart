import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/pages/login/login_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final LoginController controller = LoginController(Get.find<AuthRepository>());

  TextStyle defaultstyle = const TextStyle(
    color: Colors.grey,
    fontSize: 20
  );
  TextStyle linkStyle = const TextStyle(
    color: Colors.grey,
    fontWeight: FontWeight.bold,
    fontSize: 20
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Form(
          key: controller.formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "lib/images/logo.png"
                ),
                const SizedBox(height: 20),
            
                const Text(
                  "Login",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22
                  ),
                ),
                const SizedBox(height: 20),
            
                SizedBox(
                  width: 300,
                  child: TextFormField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email),
                      hintText: "Email",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20)
                      ),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    controller: controller.emailEditingController,
                    validator: (value) { 
                      return controller.validateEmail(value!);
                    },
                  ),
                ),
                const SizedBox(height: 15),
            
                SizedBox(
                  width: 300,
                  child: TextFormField(
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock),
                      hintText: "Password",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20)
                      )
                    ),
                    keyboardType: TextInputType.visiblePassword,
                    controller: controller.passwordEditingController,
                    validator: (value) {
                      return controller.validatePassword(value!);
                    },
                  ),
                ),
            
                const SizedBox(height: 20),
            
                SizedBox(
                  width: 300,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      elevation: 5,
                      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                    ),
                    onPressed: () {
                      controller.validateAndLogin(
                        email: controller.emailEditingController.text,
                        password: controller.passwordEditingController.text
                      );
                    },
                    child: const Text(
                      "Sign In",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white
                      ) ,
                    ),
                  ),
                ),
            
                const SizedBox(height: 32),
            
                const Center(
              child: Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: Colors.grey,
                      thickness: 1,
                      indent: 60,
                    ),
                  ),
                  Text(
                    "or",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey
                    ),
                  ),
                  Expanded(
                    child: Divider(
                      color: Colors.grey,
                      thickness: 1,
                      endIndent: 60,
                    ),
                  )
                ]
              ),
            ),
            
                const SizedBox(
                  height: 32,
                ),
            
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black
                    ),
                    borderRadius: BorderRadius.circular(10)
                  ),
                  child: Image.asset(
                    "lib/images/google_logo.png",
                    fit: BoxFit.cover,
                  ),
                ),
            
                const SizedBox(height: 32),
            
                GestureDetector(
                  onTap: () {
                          controller.moveToSignUp();
                        },
                        child: const Text(
                          "Don't have an account? Sign Up",
                          style: TextStyle(fontSize: 20, color: Colors.black),
                        ),
                )
              ],
            ),
          ),
        ),
      )
    );
  }
}
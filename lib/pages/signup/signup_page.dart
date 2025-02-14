import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:flutter/material.dart';
import 'package:capstone_app/pages/signup/signup_controller.dart';
import 'package:get/get.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignUpPage>{

  final SignUpController controller = SignUpController(Get.find<AuthRepository>());

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
                  "Sign Up",
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
            
                const SizedBox(height: 20),
            
                SizedBox(
                  width: 300,
                  child: TextFormField(
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person),
                      hintText: "Name",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20)
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
            
                SizedBox(
                  width: 300,
                  child: TextFormField(
                    obscureText: true,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock),
                      hintText: "Password",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20)
                      ),                   
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
                      controller.validateAndSignUp(
                        email: controller.emailEditingController.text,
                        password: controller.passwordEditingController.text,
                        name: controller.nameEditingController.text,
                      );
                    },
                    child: const Text(
                      "Register",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.white
                      ) ,
                    ),
                  ),
                ),
            
                const SizedBox(height: 32),
            
                GestureDetector(
                  onTap: () {
                          controller.moveToLogin();
                        },
                        child: const Text(
                          "Already have an account? Sign In",
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
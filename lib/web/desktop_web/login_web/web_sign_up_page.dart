import 'package:capstone_app/web/desktop_web/login_web/web_login_page.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class WebSignUpPage extends StatefulWidget {
  const WebSignUpPage({super.key});

  @override
  State<WebSignUpPage> createState() => _WebSignUpPageState();
}

class _WebSignUpPageState extends State<WebSignUpPage> {

  TextStyle linkStyle = const TextStyle(
  fontWeight: FontWeight.bold,
    );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: Container(
              width: 500,
              height: 700,
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
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Image.asset(
                      'lib/images/PAWrtal_logo.png',
                      height: 50,
                      width: 300,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 400,
                    child: TextFormField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email_rounded),
                        hintText: "Email",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20)
                        )
                      ),
                    )
                  ),
                  const SizedBox(
                    height: 32
                  ),
                  SizedBox(
                    width: 400,
                    child: TextFormField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.person_rounded),
                        hintText: "Name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20)
                        )
                      ),
                    )
                  ),
                  const SizedBox(
                    height: 32
                  ),
                  SizedBox(
                    width: 400,
                    child: TextFormField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_rounded),
                        hintText: "Password",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20)
                        )
                      ),
                    )
                  ),
                  const SizedBox(
                    height: 32
                  ),
                  SizedBox(
                    width: 400,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                      ),
                      onPressed: () {},
                      child: const Text(
                        "Sign Up",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 16
                  ),
                  RichText(
                    text: TextSpan(
                      children: <TextSpan> [
                        const TextSpan(
                          text: "Already have an account?"
                        ),
                        TextSpan(
                          style: linkStyle,
                          text: "Sign in",
                          recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WebLoginPage(),
                              )
                            );
                          }
                        )
                      ]
                    ),
                  ),
                  const SizedBox(
                    height: 32,
                  ),
                  const Row(
                    children: [
                      Expanded(
                        child: Divider(
                          indent: 10,
                        )
                      ),
                      Text("  or  "),
                      Expanded(
                        child: Divider(
                          endIndent: 10,
                        )
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 32
                  ),
                  InkWell(
                    onTap: () {},
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
                      child: Image.asset(
                        'lib/images/google_logo.png'
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
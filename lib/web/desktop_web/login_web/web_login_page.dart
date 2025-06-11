import 'package:capstone_app/web/desktop_web/login_web/web_sign_up_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

class WebLoginPage extends StatefulWidget {
  const WebLoginPage({super.key});

  @override
  State<WebLoginPage> createState() => _WebLoginPageState();
}

class _WebLoginPageState extends State<WebLoginPage> {

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
              width: 1000,
              height: 700,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade400,
                    blurRadius: 1,
                    spreadRadius: 1,
                    offset: const Offset(0, 2)
                  )
                ]
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 495,
                    height: 700,
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 200, left: 16, bottom: 16),
                              child: Text(
                                "Welcome to",
                                style: TextStyle(
                                  fontSize: 22
                                ),
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
                            children: <TextSpan> [
                              const TextSpan(
                                text: "Don't have an account?"
                              ),
                              TextSpan(
                                style: linkStyle,
                                text: "Sign up",
                                recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const WebSignUpPage(),
                                    )
                                  );
                                }
                              )
                            ]
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                    height: 700,
                    child: VerticalDivider(
                      indent: 20,
                      endIndent: 20,
                    ),
                  ),
                  SizedBox(
                    width: 495,
                    height: 700,
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: 64, left: 16, bottom: 16),
                              child: Text(
                                "Sign up",
                                style: TextStyle(
                                  fontSize: 22
                                ),
                              ),
                            ),
                          ],
                        ),
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
                              prefixIcon: const Icon(Icons.lock_rounded),
                              hintText: "Password",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20)
                              ),
                            ),
                          )
                        ),
                        const SizedBox(
                          height: 32,
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
                              "Sign In",
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white
                              ),
                            ),
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
                              ),
                            ),
                            Text("  or  "),
                            Expanded(
                              child: Divider(
                                endIndent: 10,
                              )
                            )
                          ],
                        ),
                        const SizedBox(
                          height: 32,
                        ),
                        const Text(
                          "Sign in with"
                        ),
                        const SizedBox(
                          height: 16,
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
                      ]
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      )
    );
  }
}
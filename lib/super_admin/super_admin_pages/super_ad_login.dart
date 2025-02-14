import 'package:capstone_app/super_admin/super_admin_pages/super_ad_main_page.dart';
import 'package:flutter/material.dart';

class SuperAdLogin extends StatefulWidget {
  const SuperAdLogin({super.key});

  @override
  State<SuperAdLogin> createState() => _SuperAdLoginState();
}

class _SuperAdLoginState extends State<SuperAdLogin> {
  TextStyle defaultstyle = const TextStyle(color: Colors.grey, fontSize: 20);
  TextStyle linkStyle = const TextStyle(
      color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 20);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("lib/images/logo.png"),
            const SizedBox(height: 20),
            const Text(
              "Login",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 300,
              child: TextField(
                decoration: InputDecoration(
                    labelText: "Email",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20))),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: 300,
              child: TextField(
                decoration: InputDecoration(
                    labelText: "Password",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20))),
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: 300,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SuperAdMainPage(),
                    ),
                  );
                },
                style: ButtonStyle(
                  overlayColor: WidgetStateProperty.resolveWith<Color?>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.pressed)) {
                        return Colors.grey.withOpacity(0.3);
                      }
                      return null;
                    },
                  ),
                ),
                child: const Text("Login"),
              ),
            ),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }
}

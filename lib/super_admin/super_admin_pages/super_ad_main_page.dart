//import 'package:capstone_app/super_admin/components/vet_clinic_tile.dart';
import 'package:capstone_app/super_admin/super_admin_pages/super_ad_login.dart';
import 'package:flutter/material.dart';

class SuperAdMainPage extends StatefulWidget {
  const SuperAdMainPage({super.key});

  @override
  State<SuperAdMainPage> createState() => _MySuperAdMainPage();
}

class _MySuperAdMainPage extends State<SuperAdMainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          //Top
          Padding(
            padding: const EdgeInsets.only(top: 30),
            child: Center(
              child: Image.asset("lib/images/PAWrtal_logo.png", height: 70),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(60.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SuperAdLogin(),
                  ),
                );
              },
              child: const Text('Log Out'),
            ),
          ),
        ],
      ),
    );
  }
}

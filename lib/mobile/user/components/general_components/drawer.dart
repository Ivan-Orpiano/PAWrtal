import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:flutter/material.dart';
import 'package:capstone_app/pages/user_home/user_home_controller.dart';
import 'package:get/get.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {

  final UserHomeController controller = UserHomeController(Get.find<AuthRepository>());

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
        child: SingleChildScrollView(
          child: Column(
            children: [
            //user image
              const DrawerHeader(
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 50,
                ),
              ),
          
              //name
              const ListTile(
                title: Text(
                  "Name",
                  style: TextStyle(
                    fontSize: 25,
                    color: Color.fromARGB(255, 248, 253, 255)
                  ),
                ),
              ),
          
              //email
              const Padding(
                padding: EdgeInsets.only(bottom: 350),
                child: ListTile(
                  title: Text(
                    "Email",
                    style: TextStyle(
                      fontSize: 18,
                      color: Color.fromARGB(255, 248, 253, 255)
                    ),
                  ),
                ),
              ),
          
              //bottom
              //settings
              ListTile(
                onTap: () {},
                leading: const Icon(Icons.settings_rounded),
                iconColor: const Color.fromARGB(255, 248, 253, 255),
                title: const Text(
                  "Settings",
                  style: TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 248, 253, 255)
                  ),
                ),
              ),
          
            //about us
            ListTile(
              onTap: () {},
              leading: const Icon(Icons.info_outline_rounded),
              iconColor: const Color.fromARGB(255, 248, 253, 255),
              title: const Text(
                "About us",
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(255, 248, 253, 255)
                ),
              ),
            ),
          
            //sign out
            ListTile(
              onTap: () {
                controller.logout();
              },
              leading: const Icon(Icons.door_back_door_rounded),
              iconColor: const Color.fromARGB(255, 248, 253, 255),
              title: const Text(
                "Sign out",
                style: TextStyle(
                  fontSize: 16,
                  color: Color.fromARGB(255, 248, 253, 255)
                ),
              ),
            ),
          ],
                ),
        ),
    );
  }
}
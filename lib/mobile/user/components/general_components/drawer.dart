import 'package:appwrite/models.dart';
import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:flutter/material.dart';
import 'package:capstone_app/pages/user_home/user_home_controller.dart';
import 'package:get/get.dart';
import 'package:capstone_app/data/provider/appwrite_provider.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  final UserHomeController controller =
      UserHomeController(Get.find<AuthRepository>());
  final AppWriteProvider appWriteProvider = AppWriteProvider();

  late User currentUser;
  bool isLoading = true;

  @override
  void initState() {
    appWriteProvider.getUser().then((value) => setState(() {
          currentUser = value!;
          isLoading = false;
        }));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
      child: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
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
                  ListTile(
                    title: Text(
                      currentUser.name,
                      style: const TextStyle(
                          fontSize: 25,
                          color: Color.fromARGB(255, 248, 253, 255)),
                    ),
                  ),

                  //email
                  Padding(
                    padding: const EdgeInsets.only(),
                    child: ListTile(
                      title: Text(
                        currentUser.email,
                        style: const TextStyle(
                            fontSize: 18,
                            color: Color.fromARGB(255, 248, 253, 255)),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(bottom: 320),
                    child: ListTile(
                      title: Text(
                        currentUser.emailVerification
                            ? "Verified"
                            : "Not Verified",
                        style: const TextStyle(
                            fontSize: 18,
                            color: Color.fromARGB(255, 248, 253, 255)),
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
                          color: Color.fromARGB(255, 248, 253, 255)),
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
                          color: Color.fromARGB(255, 248, 253, 255)),
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
                          color: Color.fromARGB(255, 248, 253, 255)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

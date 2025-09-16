import 'package:capstone_app/web/pages/web_super_admin_home/web_super_admin_home_controller.dart';
import 'package:capstone_app/web/super_admin/WebVersion/main_components/pet_owner_menu_tile.dart';
import 'package:capstone_app/web/super_admin/WebVersion/main_components/vet_clinic_menu_tile.dart';
import 'package:capstone_app/web/super_admin/WebVersion/main_components/view_report_menu_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SuperAdminDesktopHomePage extends GetView<WebSuperAdminHomeController> {
  const SuperAdminDesktopHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        centerTitle: true,
        toolbarHeight: screenHeight * 0.1,
        flexibleSpace: Container(
          margin: const EdgeInsets.only(top: 15.0),
          child: Center(
            child: Image.asset(
              "lib/images/PAWrtal_logo.png",
              height: double.infinity,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: PopupMenuButton<String>(
              onSelected: (String value) {
                switch (value) {
                  case 'profile':
                    Get.snackbar('Info', 'Profile page coming soon',
                        backgroundColor: Colors.blue, colorText: Colors.white);
                    break;
                  case 'settings':
                    controller.navigateToSettings();
                    break;
                  case 'logout':
                    _showLogoutDialog(context);
                    break;
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: ListTile(
                    leading: Icon(Icons.person),
                    title: Text('Profile'),
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: ListTile(
                    leading: Icon(Icons.settings),
                    title: Text('Settings'),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.red),
                    title: Text('Log Out', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
              child: Obx(() => TextButton.icon(
                    onPressed: controller.isLoggingOut.value ? null : () {},
                    icon: controller.isLoggingOut.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color.fromRGBO(81, 115, 153, 0.8),
                              ),
                            ),
                          )
                        : const Icon(Icons.account_circle,
                            color: Color.fromRGBO(81, 115, 153, 0.8)),
                    label: Text(
                      controller.isLoggingOut.value
                          ? 'Processing...'
                          : controller.userName,
                      style: const TextStyle(
                          color: Color.fromRGBO(81, 115, 153, 0.8)),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color.fromRGBO(81, 115, 153, 0.8),
                    ),
                  )),
            ),
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 248, 253, 255),
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 60),
              child: constraints.maxWidth > 800
                  ? const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(child: VetClinicTile()),
                        Expanded(child: PetOwnerTile()),
                        Expanded(child: ViewReportTile()),
                      ],
                    )
                  : const SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Column(
                        children: [
                          VetClinicTile(),
                          PetOwnerTile(),
                          ViewReportTile(),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await controller.logout();
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}

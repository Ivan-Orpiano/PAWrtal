import 'package:capstone_app/web/pages/web_super_admin_home/web_super_admin_home_controller.dart';
import 'package:capstone_app/web/super_admin/WebVersion/main_components/pet_owner_menu_tile.dart';
import 'package:capstone_app/web/super_admin/WebVersion/main_components/vet_clinic_menu_tile.dart';
import 'package:capstone_app/web/super_admin/WebVersion/main_components/view_report_menu_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SuperAdminMobileHomePage extends GetView<WebSuperAdminHomeController> {
  const SuperAdminMobileHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        centerTitle: true,
        toolbarHeight: 70,
        title: Image.asset(
          "lib/images/PAWrtal_logo.png",
          height: 35,
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showProfileDrawer(context);
            },
            icon: const Icon(
              Icons.menu,
              color: Color.fromRGBO(81, 115, 153, 0.8),
            ),
          ),
        ],
      ),
      backgroundColor: const Color.fromARGB(255, 248, 253, 255),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 60, left: 16, right: 16),
          child: Column(
            children: const [
              VetClinicTile(),
              SizedBox(height: 20),
              PetOwnerTile(),
              SizedBox(height: 20),
              ViewReportTile(),
            ],
          ),
        ),
      ),
    );
  }

  void _showProfileDrawer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          color: const Color.fromRGBO(249, 253, 255, 1),
          height: MediaQuery.of(context).size.height * 0.6,
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              CircleAvatar(
                backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                radius: 40,
                child: Text(
                  controller.userName.isNotEmpty ? controller.userName[0].toUpperCase() : 'D',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                controller.userName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                controller.userEmail,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: ListView(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.dashboard),
                      title: const Text('Dashboard'),
                      onTap: () {
                        Navigator.pop(context);
                        // Already on dashboard
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.local_hospital),
                      title: const Text('Vet Clinics'),
                      onTap: () {
                        Navigator.pop(context);
                        controller.navigateToVetClinics();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.pets),
                      title: const Text('Pet Owners'),
                      onTap: () {
                        Navigator.pop(context);
                        controller.navigateToPetOwners();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.analytics),
                      title: const Text('Reports'),
                      onTap: () {
                        Navigator.pop(context);
                        controller.navigateToReports();
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('Profile'),
                      onTap: () {
                        Navigator.pop(context);
                        Get.snackbar('Info', 'Profile page coming soon',
                            backgroundColor: Colors.blue, colorText: Colors.white);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.settings),
                      title: const Text('Settings'),
                      onTap: () {
                        Navigator.pop(context);
                        controller.navigateToSettings();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('Logout', style: TextStyle(color: Colors.red)),
                      onTap: () {
                        Navigator.pop(context);
                        _showLogoutDialog(context);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
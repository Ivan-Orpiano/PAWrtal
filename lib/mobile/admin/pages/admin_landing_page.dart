import 'package:capstone_app/data/repository/auth.repository.dart';
import 'package:capstone_app/pages/admin_home/admin_home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminLandingPage extends StatefulWidget {
  const AdminLandingPage({super.key});

  @override
  State<AdminLandingPage> createState() => _AdminLandingPageState();
}

class _AdminLandingPageState extends State<AdminLandingPage> {
  final AdminHomeController controller = Get.find<AdminHomeController>();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Image.asset('lib/images/PAWrtal_logo.png', width: 120, height: 120),
        elevation: 0,
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF608BC1),
        child: Column(
          children: [
            ListTile(
              onTap: () {
                controller.logout();
              },
              leading: const Icon(Icons.logout, color: Colors.white),
              title: const Text(
                "Sign out",
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      body: Obx(() {
        final clinic = controller.clinic.value;
        if (clinic == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset('lib/images/test_image.jpg', height: 200, fit: BoxFit.cover),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  clinic.clinicName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF517399),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle("Description"),
              Text(clinic.description),
              const SizedBox(height: 20),
              _buildSectionTitle("Location"),
              Text(clinic.address),
              const SizedBox(height: 20),
              _buildSectionTitle("Ratings and Reviews"),
              const Text("No reviews yet."),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

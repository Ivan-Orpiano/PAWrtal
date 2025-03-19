import 'package:flutter/material.dart';
import 'package:capstone_app/mobile/super_admin/WebVersion/vet_clinic_pages/crude_admin_account.dart';
import 'package:capstone_app/mobile/super_admin/WebVersion/vet_clinic_pages/crude_staff_account.dart';

import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class SuperAdminVetClinicPage extends StatefulWidget {
  const SuperAdminVetClinicPage({super.key});

  @override
  State<SuperAdminVetClinicPage> createState() =>
      _SuperAdminVetClinicPageState();
}

class _SuperAdminVetClinicPageState extends State<SuperAdminVetClinicPage> {
  // int _selectedIndex = 0;

  // void _onItemTapped(int index) {
  //   setState(() {
  //     _selectedIndex = index;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    //final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 248, 253, 255),
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        centerTitle: true,
        toolbarHeight: screenHeight * 0.1,
        flexibleSpace: Container(
          margin: const EdgeInsets.only(top: 15.0),
          child: Center(
            child: Image.asset(
              "lib/images/PAWrtal_logo.png",
              height: screenHeight * 0.08,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: constraints.maxWidth > 600 ? 300 : 200,
                    child: Image.asset(
                      'lib/images/sample_vet.png',
                      width: double.infinity,
                      height: constraints.maxWidth > 600 ? 300 : 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Vet Clinic ni Kap Kalbs',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    'Providing the best care for your pets with top-notch facilities and experienced veterinarians.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  RatingBarIndicator(
                    rating: 4.5,
                    itemBuilder: (context, index) =>
                        const Icon(Icons.star, color: Colors.amber),
                    itemCount: 5,
                    itemSize: 24.0,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: constraints.maxWidth > 600 ? 300 : 200,
                    child: Stack(
                      children: [
                        Image.asset(
                          'lib/images/sample_location.png',
                          width: double.infinity,
                          height: constraints.maxWidth > 600 ? 300 : 200,
                          fit: BoxFit.cover,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 50),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildAccountButton(
                            context,
                            'Admin Account',
                            Icons.admin_panel_settings,
                            const CrudeAdminAccount()),
                        _buildAccountButton(context, 'Staff Account',
                            Icons.people, const CrudeStaffAccount()),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: Align(
        alignment: Alignment.centerRight,
        child: FloatingActionButton(
          onPressed: () {},
          backgroundColor: const Color.fromARGB(255, 81, 115, 153),
          child: const Icon(
            Icons.edit,
            color: Color.fromARGB(255, 248, 253, 255),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountButton(
      BuildContext context, String title, IconData icon, Widget screen) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => screen),
        );
      },
      child: Column(
        children: [
          Icon(icon, size: 40, color: const Color.fromARGB(255, 81, 115, 153)),
          const SizedBox(height: 4),
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

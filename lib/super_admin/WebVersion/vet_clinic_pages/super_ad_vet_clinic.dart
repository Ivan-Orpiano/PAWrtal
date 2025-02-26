import 'package:capstone_app/super_admin/WebVersion/sa_dashboard_components/sa_my_tags.dart';
import 'package:capstone_app/super_admin/WebVersion/sa_dashboard_components/sa_search_bar.dart';
import 'package:capstone_app/super_admin/WebVersion/sa_dashboard_components/sa_sort_button.dart';
import 'package:capstone_app/super_admin/WebVersion/sa_dashboard_components/sa_vet_clinic_dash_tile.dart';
import 'package:capstone_app/super_admin/WebVersion/vet_clinic_pages/super_ad_vet_clinic_register.dart';
import 'package:flutter/material.dart';

class SuperAdminVetClinic extends StatefulWidget {
  const SuperAdminVetClinic({super.key});

  @override
  State<SuperAdminVetClinic> createState() => _SuperAdminVetClinic();
}

class _SuperAdminVetClinic extends State<SuperAdminVetClinic> {
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    //final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
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
      backgroundColor: const Color.fromARGB(255, 248, 253, 255),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            // Use Column as the main layout
            children: [
              // Non-scrollable header section
              Container(
                margin: const EdgeInsets.only(top: 30, left: 30, right: 30),
                child: const Column(
                  children: [
                    Row(
                      children:  [
                        Expanded(child: SuperAdminSearchBar()),
                        SizedBox(width: 1),
                        SuperAdminSortButton(),
                      ],
                    ),
                     SizedBox(height: 10), // Add some spacing
                     SuperAdminTags(),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 3;
                      if (constraints.maxWidth < 1000) {
                        crossAxisCount = 2;
                      }
                      if (constraints.maxWidth < 600) {
                        crossAxisCount = 1;
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.only(
                          top: 20,
                          left: 80,
                          right: 80,
                          bottom: 20,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 1.5,
                        ),
                        itemCount: 15,
                        itemBuilder: (context, index) {
                          return const SuperAdminVetClinicTile();
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VetClinicRegister(),
            ),
          );
        },
        backgroundColor: const Color.fromARGB(255, 214, 217, 221),
        child: const Icon(Icons.add),
      ),
    );
  }
}

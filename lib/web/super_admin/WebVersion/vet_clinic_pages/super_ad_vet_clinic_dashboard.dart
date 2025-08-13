// <<<<<<< HEAD:lib/mobile/super_admin/WebVersion/vet_clinic_pages/super_ad_vet_clinic_dashboard.dart
// //import 'package:capstone_app/mobile/super_admin/WebVersion/sa_dashboard_components/sa_my_tags.dart';
// import 'package:capstone_app/mobile/super_admin/WebVersion/sa_dashboard_components/sa_search_bar.dart';
// import 'package:capstone_app/mobile/super_admin/WebVersion/sa_dashboard_components/sa_sort_button.dart';
// import 'package:capstone_app/mobile/super_admin/WebVersion/sa_dashboard_components/sa_vet_clinic_dash_tile.dart';
// import 'package:capstone_app/mobile/super_admin/WebVersion/vet_clinic_pages/super_ad_vet_clinic_page.dart';
// import 'package:capstone_app/mobile/super_admin/WebVersion/vet_clinic_pages/super_ad_vet_clinic_register.dart';
// =======
import 'package:capstone_app/web/super_admin/WebVersion/sa_dashboard_components/sa_sort_button.dart';
import 'package:capstone_app/web/super_admin/WebVersion/sa_dashboard_components/sa_my_tags.dart';
import 'package:capstone_app/web/super_admin/WebVersion/sa_dashboard_components/sa_search_bar.dart';
import 'package:capstone_app/web/super_admin/WebVersion/sa_dashboard_components/sa_vet_clinic_dash_tile.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/super_ad_vet_clinic_page.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/super_ad_vet_clinic_register.dart';
// >>>>>>> a04275dbd2d053555f819a711a0582ae7f1e8cfb:lib/web/super_admin/WebVersion/vet_clinic_pages/super_ad_vet_clinic_dashboard.dart
// import 'package:capstone_app/super_admin/WebVersion/super_ad_main_menu_page.dart';
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
              height: double.infinity,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 248, 253, 255),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 30, left: 30, right: 30),
                child: const Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: SuperAdminSearchBar()),
                        SizedBox(width: 1),
                        SuperAdminSortButton(),
                      ],
                    ),
                    SizedBox(height: 5),
                    // SuperAdminTags(),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      int crossAxisCount = 3;
                      if (constraints.maxWidth < 800) {
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
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const SuperAdminVetClinicPage(),
                                ),
                              );
                            },
                            child: const SuperAdminVetClinicTile(),
                          );
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
        backgroundColor: const Color.fromARGB(255, 81, 115, 153),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VetClinicRegister(),
            ),
          );
        },
        child: const Icon(
          Icons.add,
          color: Color.fromARGB(255, 248, 253, 255),
        ),
      ),
    );
  }
}

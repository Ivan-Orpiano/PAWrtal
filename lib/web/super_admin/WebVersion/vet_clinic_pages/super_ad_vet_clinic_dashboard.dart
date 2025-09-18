import 'package:capstone_app/web/super_admin/desktop/super_admin_desktop_home_page.dart';

import 'package:capstone_app/web/super_admin/WebVersion/sa_dashboard_components/sa_sort_button.dart';
import 'package:capstone_app/web/super_admin/WebVersion/sa_dashboard_components/sa_my_tags.dart';
import 'package:capstone_app/web/super_admin/WebVersion/sa_dashboard_components/sa_search_bar.dart';
import 'package:capstone_app/web/super_admin/WebVersion/sa_dashboard_components/sa_vet_clinic_dash_tile.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/super_ad_vet_clinic_page.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/super_ad_vet_clinic_register.dart';
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
    final screenWidth = MediaQuery.of(context).size.width;

  
    double horizontalPadding = screenWidth * 0.05; 
    double maxHorizontalPadding = 80;
    double minHorizontalPadding = 16;


    horizontalPadding =
        horizontalPadding.clamp(minHorizontalPadding, maxHorizontalPadding);


    double gridHorizontalPadding = screenWidth * 0.08; 
    double maxGridPadding = 80;
    double minGridPadding = 20;

    gridHorizontalPadding =
        gridHorizontalPadding.clamp(minGridPadding, maxGridPadding);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back,
              color: Color.fromARGB(255, 81, 115, 153)),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const SuperAdminDesktopHomePage()),
            );
          },
          tooltip: 'Back',
        ),
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        centerTitle: true,
        toolbarHeight: screenHeight * 0.1,
        flexibleSpace: Container(
          margin: EdgeInsets.only(
            top: screenHeight * 0.02, 
            left: horizontalPadding * 0.5,
            right: horizontalPadding * 0.5,
          ),
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
                margin: EdgeInsets.only(
                  top: screenHeight * 0.03, 
                  left: horizontalPadding,
                  right: horizontalPadding,
                ),
                child: const Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: SuperAdminSearchBar()),
                        SizedBox(width: 8),
                        SuperAdminSortButton(),
                      ],
                    ),
                    SizedBox(height: 8), 
        
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
           
                      int itemCount =
                        15; 
                      int crossAxisCount;
                      double childAspectRatio;

                    
                      if (itemCount == 1) {
                       
                        crossAxisCount = 1;
                        if (constraints.maxWidth > 800) {
                          childAspectRatio =
                              3.0;
                        } else if (constraints.maxWidth > 600) {
                          childAspectRatio = 2.5;
                        } else {
                          childAspectRatio =
                              2.0; 
                        }
                      } else if (itemCount <= 2) {
         
                        if (constraints.maxWidth > 800) {
                          crossAxisCount = 2;
                          childAspectRatio = 2.0; 
                        } else {
                          crossAxisCount = 1;
                          childAspectRatio = 2.0;
                        }
                      } else if (itemCount <= 3){
                       
                        if (constraints.maxWidth > 1000) {
                          crossAxisCount = 3;
                          childAspectRatio = 1.8; 
                          } else if (constraints.maxWidth > 600) {
                          crossAxisCount = 2;
                          childAspectRatio = 1.8;
                        } else {
                          crossAxisCount = 1;
                          childAspectRatio = 2.0;
                        }

                      } else {
                 
                        crossAxisCount = 4;
                        childAspectRatio = 1.5; 

                        if (constraints.maxWidth < 1400) {
                          crossAxisCount = 3;
                        }
                        if (constraints.maxWidth < 1000) {
                          crossAxisCount = 2;
                        }
                        if (constraints.maxWidth < 600) {
                          crossAxisCount = 1;
                          childAspectRatio = 2.0;
                        }
                        if (constraints.maxWidth < 400) {
                          childAspectRatio = 1.8;
                        }
                      }

            
                      double crossAxisSpacing = constraints.maxWidth * 0.02;
                      double mainAxisSpacing = constraints.maxWidth * 0.02;

                      crossAxisSpacing = crossAxisSpacing.clamp(10.0, 30.0);
                      mainAxisSpacing = mainAxisSpacing.clamp(10.0, 30.0);

                      return Container(
                        constraints: BoxConstraints(
                          minHeight: MediaQuery.of(context).size.height * 0.6,
                        ),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.only(
                            top: 20,
                            left: gridHorizontalPadding,
                            right: gridHorizontalPadding,
                            bottom: 20,
                          ),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: crossAxisSpacing,
                            mainAxisSpacing: mainAxisSpacing,
                            childAspectRatio: childAspectRatio,
                          ),
                          itemCount: itemCount,
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
                        ),
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

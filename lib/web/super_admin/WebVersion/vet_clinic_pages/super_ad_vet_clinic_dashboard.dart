import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/super_ad_vet_clinic_detail_page.dart';
import 'package:capstone_app/web/super_admin/desktop/super_admin_desktop_home_page.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/sa_dashboard_components/sa_sort_button.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/sa_dashboard_components/sa_search_bar.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/sa_dashboard_components/sa_vet_clinic_dash_tile.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/super_ad_vet_clinic_register.dart';
import 'package:capstone_app/web/super_admin/mobile/super_admin_mobile_home_page.dart';
import 'package:capstone_app/web/super_admin/tablet/super_admin_tablet_home_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/pages/super_admin_home/super_admin_home_controller.dart';

class SuperAdminVetClinicDashboard extends StatefulWidget {
  const SuperAdminVetClinicDashboard({super.key});

  @override
  State<SuperAdminVetClinicDashboard> createState() =>
      _SuperAdminVetClinicDashboard();
}

class _SuperAdminVetClinicDashboard extends State<SuperAdminVetClinicDashboard> {
  final SuperAdminHomeController controller = Get.find<SuperAdminHomeController>();

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    double horizontalPadding = screenWidth * 0.05;
    double maxHorizontalPadding = 80;
    double minHorizontalPadding = 16;

    horizontalPadding = horizontalPadding.clamp(minHorizontalPadding, maxHorizontalPadding);

    double gridHorizontalPadding = screenWidth * 0.08;
    double maxGridPadding = 80;
    double minGridPadding = 20;

    gridHorizontalPadding = gridHorizontalPadding.clamp(minGridPadding, maxGridPadding);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color.fromARGB(255, 81, 115, 153)),
          onPressed: () {
            final width = MediaQuery.of(context).size.width;
            Widget destination;
            if (width < 600) {
              destination = SuperAdminMobileHomePage();
            } else if (width >= 480 && width < 1000) {
              destination = SuperAdminTabletHomePage();
            } else {
              destination = const SuperAdminDesktopHomePage();
            }
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => destination),
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
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color.fromARGB(255, 81, 115, 153),
            ),
          );
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: controller.fetchAllClinics,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                  ),
                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        }

        final filteredClinics = controller.filteredClinics;

        return Column(
          children: [
            Container(
              margin: EdgeInsets.only(
                top: screenHeight * 0.03,
                left: horizontalPadding,
                right: horizontalPadding,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SuperAdminSearchBar(
                          onChanged: controller.updateSearchQuery,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SuperAdminSortButton(
                        onSortChanged: controller.updateSortBy,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            if (filteredClinics.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        controller.searchQuery.value.isEmpty
                            ? 'No clinics registered yet'
                            : 'No clinics found',
                        style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.fetchAllClinics,
                  color: const Color.fromARGB(255, 81, 115, 153),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        int itemCount = filteredClinics.length;
                        int crossAxisCount;
                        double childAspectRatio;

                        if (itemCount == 1) {
                          crossAxisCount = 1;
                          if (constraints.maxWidth > 800) {
                            childAspectRatio = 3.0;
                          } else if (constraints.maxWidth > 600) {
                            childAspectRatio = 2.5;
                          } else {
                            childAspectRatio = 2.0;
                          }
                        } else if (itemCount <= 2) {
                          if (constraints.maxWidth > 800) {
                            crossAxisCount = 2;
                            childAspectRatio = 2.0;
                          } else {
                            crossAxisCount = 1;
                            childAspectRatio = 2.0;
                          }
                        } else if (itemCount <= 3) {
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
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: crossAxisSpacing,
                              mainAxisSpacing: mainAxisSpacing,
                              childAspectRatio: childAspectRatio,
                            ),
                            itemCount: itemCount,
                            itemBuilder: (context, index) {
                              final clinicData = filteredClinics[index];
                              final clinic = clinicData['clinic'] as Clinic;
                              final settings = clinicData['settings'] as ClinicSettings?;

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SuperAdminVetClinicDetailPage(
                                        clinic: clinic,
                                        settings: settings,
                                      ),
                                    ),
                                  );
                                },
                                child: SuperAdminVetClinicTile(
                                  clinic: clinic,
                                  settings: settings,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color.fromARGB(255, 81, 115, 153),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VetClinicRegister(),
            ),
          ).then((_) => controller.fetchAllClinics());
        },
        child: const Icon(
          Icons.add,
          color: Color.fromARGB(255, 248, 253, 255),
        ),
      ),
    );
  }
}
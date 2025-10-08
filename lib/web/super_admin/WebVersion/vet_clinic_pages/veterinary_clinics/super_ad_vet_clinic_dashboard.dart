import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/veterinary_clinics/super_ad_vet_clinic_detail_page.dart';
import 'package:capstone_app/web/super_admin/desktop/super_admin_desktop_home_page.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/sa_dashboard_components/sa_sort_button.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/sa_dashboard_components/sa_search_bar.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/sa_dashboard_components/sa_vet_clinic_dash_tile.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/veterinary_clinics/super_ad_vet_clinic_register.dart';
import 'package:capstone_app/web/super_admin/mobile/super_admin_mobile_home_page.dart';
import 'package:capstone_app/web/super_admin/tablet/super_admin_tablet_home_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:capstone_app/pages/super_admin_home/super_admin_home_controller.dart';
import 'dart:async';

class SuperAdminVetClinicDashboard extends StatefulWidget {
  const SuperAdminVetClinicDashboard({super.key});

  @override
  State<SuperAdminVetClinicDashboard> createState() =>
      _SuperAdminVetClinicDashboardState();
}

class _SuperAdminVetClinicDashboardState
    extends State<SuperAdminVetClinicDashboard> {
  final SuperAdminHomeController controller =
      Get.find<SuperAdminHomeController>();
  
  StreamSubscription? _clinicSubscription;
  StreamSubscription? _settingsSubscription;

  @override
  void initState() {
    super.initState();
    _setupRealtimeListeners();
  }

  @override
  void dispose() {
    _clinicSubscription?.cancel();
    _settingsSubscription?.cancel();
    super.dispose();
  }

  void _setupRealtimeListeners() {
    // Listen to clinic changes (create, update, delete)
    _clinicSubscription = controller.authRepository
        .subscribeToClinicChanges()
        .listen((event) {
      print('Clinic event: ${event.events}');
      
      if (event.events.contains('databases.*.collections.*.documents.*.create') ||
          event.events.contains('databases.*.collections.*.documents.*.update') ||
          event.events.contains('databases.*.collections.*.documents.*.delete')) {
        // Refresh clinic list
        controller.fetchAllClinics();
      }
    });

    // Listen to settings changes (for real-time status updates)
    _settingsSubscription = controller.authRepository
        .subscribeToClinicSettingsChanges()
        .listen((event) {
      print('Settings event: ${event.events}');
      
      if (event.events.contains('databases.*.collections.*.documents.*.update')) {
        // Refresh to get updated status
        controller.fetchAllClinics();
      }
    });
  }

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
              color: Color.fromRGBO(81, 115, 153, 1)),
          onPressed: () {
            final width = MediaQuery.of(context).size.width;
            Widget destination;
            if (width < 600) {
              destination = const SuperAdminMobileHomePage();
            } else if (width >= 480 && width < 1000) {
              destination = const SuperAdminTabletHomePage();
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
        backgroundColor: const Color(0xFFF8FAFC),
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
      backgroundColor: const Color(0xFFF8FAFC),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              color: Color.fromRGBO(81, 115, 153, 1),
            ),
          );
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, 
                    size: 64, 
                    color: Colors.red[700]),
                const SizedBox(height: 16),
                Text(
                  controller.errorMessage.value,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: controller.fetchAllClinics,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(81, 115, 153, 1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24, 
                      vertical: 12
                    ),
                  ),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final filteredClinics = controller.filteredClinics;

        return Column(
          children: [
            // Header with real-time indicator
            Container(
              margin: EdgeInsets.only(
                top: screenHeight * 0.02,
                left: horizontalPadding,
                right: horizontalPadding,
                bottom: 12,
              ),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(81, 115, 153, 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Veterinary Clinics Management',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color.fromRGBO(81, 115, 153, 1),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Real-time updates active',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(81, 115, 153, 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${filteredClinics.length} Clinics',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(81, 115, 153, 1),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search and filter
            Container(
              margin: EdgeInsets.only(
                left: horizontalPadding,
                right: horizontalPadding,
              ),
              child: Row(
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
            ),
            const SizedBox(height: 16),

            // Clinic grid
            if (filteredClinics.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, 
                          size: 64, 
                          color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        controller.searchQuery.value.isEmpty
                            ? 'No clinics registered yet'
                            : 'No clinics found',
                        style: TextStyle(
                          fontSize: 18, 
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (controller.searchQuery.value.isEmpty) ...[
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const VetClinicRegister(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Add First Clinic'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color.fromRGBO(81, 115, 153, 1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.fetchAllClinics,
                  color: const Color.fromRGBO(81, 115, 153, 1),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        int itemCount = filteredClinics.length;
                        int crossAxisCount;
                        double childAspectRatio;

                        // Responsive grid calculation
                        if (itemCount == 1) {
                          crossAxisCount = 1;
                          childAspectRatio = constraints.maxWidth > 800 ? 3.0 : 2.0;
                        } else if (itemCount <= 2) {
                          crossAxisCount = constraints.maxWidth > 800 ? 2 : 1;
                          childAspectRatio = 2.0;
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
                          // Default for 4+ items
                          crossAxisCount = 4;
                          childAspectRatio = 1.5;

                          if (constraints.maxWidth < 1400) crossAxisCount = 3;
                          if (constraints.maxWidth < 1000) crossAxisCount = 2;
                          if (constraints.maxWidth < 600) {
                            crossAxisCount = 1;
                            childAspectRatio = 2.0;
                          }
                        }

                        double crossAxisSpacing = 
                            (constraints.maxWidth * 0.02).clamp(10.0, 30.0);
                        double mainAxisSpacing = 
                            (constraints.maxWidth * 0.02).clamp(10.0, 30.0);

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
                              final clinicData = filteredClinics[index];
                              final clinic = clinicData['clinic'] as Clinic;
                              final settings =
                                  clinicData['settings'] as ClinicSettings?;

                              return GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          SuperAdminVetClinicDetailPage(
                                        clinic: clinic,
                                        settings: settings,
                                      ),
                                    ),
                                  );
                                  
                                  // Refresh will happen via realtime, 
                                  // but manual refresh if result is true
                                  if (result == true) {
                                    controller.fetchAllClinics();
                                  }
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
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color.fromRGBO(81, 115, 153, 1),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VetClinicRegister(),
            ),
          );
        },
        icon: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        label: const Text(
          'Add Clinic',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
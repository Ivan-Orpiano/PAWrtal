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
    _clinicSubscription = controller.authRepository
        .subscribeToClinicChanges()
        .listen((event) {
      print('Clinic event: ${event.events}');
      
      if (event.events.contains('databases.*.collections.*.documents.*.create') ||
          event.events.contains('databases.*.collections.*.documents.*.update') ||
          event.events.contains('databases.*.collections.*.documents.*.delete')) {
        controller.fetchAllClinics();
      }
    });

    _settingsSubscription = controller.authRepository
        .subscribeToClinicSettingsChanges()
        .listen((event) {
      print('Settings event: ${event.events}');
      
      if (event.events.contains('databases.*.collections.*.documents.*.update')) {
        controller.fetchAllClinics();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Responsive breakpoints
    final isMobile = screenWidth < 600;
    final isTablet = screenWidth >= 600 && screenWidth < 1000;
    final isDesktop = screenWidth >= 1000;

    // Responsive padding
    double horizontalPadding = isMobile 
        ? 16.0 
        : isTablet 
            ? 24.0 
            : (screenWidth * 0.05).clamp(32.0, 80.0);

    double gridHorizontalPadding = isMobile 
        ? 16.0 
        : isTablet 
            ? 24.0 
            : (screenWidth * 0.08).clamp(40.0, 80.0);

    return Scaffold(
      appBar: _buildAppBar(context, screenHeight, horizontalPadding, isMobile),
      backgroundColor: const Color(0xFFF8FAFC),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: const Color.fromRGBO(81, 115, 153, 1),
                  strokeWidth: isMobile ? 3 : 4,
                ),
                SizedBox(height: isMobile ? 16 : 24),
                Text(
                  'Loading clinics...',
                  style: TextStyle(
                    fontSize: isMobile ? 14 : 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        if (controller.errorMessage.value.isNotEmpty) {
          return _buildErrorState(isMobile);
        }

        final filteredClinics = controller.filteredClinics;

        return Column(
          children: [
            // Header section
            _buildHeader(
              context, 
              filteredClinics.length, 
              horizontalPadding, 
              isMobile, 
              isTablet
            ),

            // Search and filter
            _buildSearchBar(
              horizontalPadding, 
              isMobile, 
              isTablet
            ),
            
            SizedBox(height: isMobile ? 12 : 16),

            // Clinic grid
            if (filteredClinics.isEmpty)
              _buildEmptyState(isMobile, isTablet)
            else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.fetchAllClinics,
                  color: const Color.fromRGBO(81, 115, 153, 1),
                  child: _buildClinicGrid(
                    filteredClinics, 
                    gridHorizontalPadding,
                    isMobile,
                    isTablet,
                    isDesktop,
                    screenWidth,
                  ),
                ),
              ),
          ],
        );
      }),
      floatingActionButton: _buildFAB(isMobile, isTablet),
    );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context, 
    double screenHeight, 
    double horizontalPadding,
    bool isMobile,
  ) {
    return AppBar(
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_rounded,
          color: const Color.fromRGBO(81, 115, 153, 1),
          size: isMobile ? 24 : 28,
        ),
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
      toolbarHeight: isMobile ? screenHeight * 0.08 : screenHeight * 0.1,
      flexibleSpace: Container(
        margin: EdgeInsets.only(
          top: isMobile ? screenHeight * 0.015 : screenHeight * 0.02,
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
    );
  }

  Widget _buildHeader(
    BuildContext context,
    int clinicCount,
    double horizontalPadding,
    bool isMobile,
    bool isTablet,
  ) {
    return Container(
      margin: EdgeInsets.only(
        top: isMobile ? 12 : 16,
        left: horizontalPadding,
        right: horizontalPadding,
        bottom: isMobile ? 12 : 16,
      ),
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
        boxShadow: [
          BoxShadow(
            color: const Color.fromRGBO(81, 115, 153, 0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Veterinary Clinics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromRGBO(81, 115, 153, 1),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Management Dashboard',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color.fromRGBO(81, 115, 153, 0.15),
                        const Color.fromRGBO(81, 115, 153, 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color.fromRGBO(81, 115, 153, 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.store_rounded,
                        color: const Color.fromRGBO(81, 115, 153, 1),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$clinicCount Clinics',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color.fromRGBO(81, 115, 153, 1),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Veterinary Clinics Management',
                        style: TextStyle(
                          fontSize: isTablet ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: const Color.fromRGBO(81, 115, 153, 1),
                        ),
                      ),
                      SizedBox(height: isTablet ? 4 : 6),
                      Text(
                        'Registered Veterinary Clinics Dashboard',
                        style: TextStyle(
                          fontSize: isTablet ? 13 : 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isTablet ? 18 : 20,
                    vertical: isTablet ? 10 : 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color.fromRGBO(81, 115, 153, 0.15),
                        const Color.fromRGBO(81, 115, 153, 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color.fromRGBO(81, 115, 153, 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.store_rounded,
                        color: const Color.fromRGBO(81, 115, 153, 1),
                        size: isTablet ? 20 : 24,
                      ),
                      SizedBox(width: isTablet ? 8 : 10),
                      Text(
                        '$clinicCount Clinics',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: const Color.fromRGBO(81, 115, 153, 1),
                          fontSize: isTablet ? 16 : 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchBar(double horizontalPadding, bool isMobile, bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: isMobile
          ? Column(
              children: [
                SuperAdminSearchBar(
                  onChanged: controller.updateSearchQuery,
                ),
                const SizedBox(height: 8),
                SuperAdminSortButton(
                  onSortChanged: controller.updateSortBy,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: SuperAdminSearchBar(
                    onChanged: controller.updateSearchQuery,
                  ),
                ),
                SizedBox(width: isTablet ? 8 : 12),
                SuperAdminSortButton(
                  onSortChanged: controller.updateSortBy,
                ),
              ],
            ),
    );
  }

  Widget _buildClinicGrid(
    List<Map<String, dynamic>> filteredClinics,
    double gridHorizontalPadding,
    bool isMobile,
    bool isTablet,
    bool isDesktop,
    double screenWidth,
  ) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int itemCount = filteredClinics.length;
          int crossAxisCount;
          double childAspectRatio;
          double crossAxisSpacing;
          double mainAxisSpacing;

          if (isMobile) {
            // Mobile: Always 1 column, larger cards
            crossAxisCount = 1;
            childAspectRatio = 0.85; // Taller cards for mobile
            crossAxisSpacing = 0;
            mainAxisSpacing = 16;
          } else if (isTablet) {
            // Tablet: 2 columns
            crossAxisCount = 2;
            childAspectRatio = 0.95;
            crossAxisSpacing = 16;
            mainAxisSpacing = 16;
          } else {
            // Desktop: Responsive based on count
            if (itemCount == 1) {
              crossAxisCount = 1;
              childAspectRatio = 2.5;
            } else if (itemCount == 2) {
              crossAxisCount = 2;
              childAspectRatio = 1.4;
            } else if (itemCount == 3) {
              crossAxisCount = 3;
              childAspectRatio = 1.2;
            } else {
              crossAxisCount = screenWidth > 1400 ? 4 : 3;
              childAspectRatio = 1.15;
            }
            crossAxisSpacing = (screenWidth * 0.02).clamp(16.0, 24.0);
            mainAxisSpacing = (screenWidth * 0.02).clamp(16.0, 24.0);
          }

          return Container(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height * 0.6,
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                top: isMobile ? 8 : 16,
                left: gridHorizontalPadding,
                right: gridHorizontalPadding,
                bottom: isMobile ? 80 : 24, // Extra bottom padding for FAB
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
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SuperAdminVetClinicDetailPage(
                          clinic: clinic,
                          settings: settings,
                        ),
                      ),
                    );
                    
                    if (result == true) {
                      controller.fetchAllClinics();
                    }
                  },
                  child: SuperAdminVetClinicTile(
                    clinic: clinic,
                    settings: settings,
                    isMobile: isMobile,
                    isTablet: isTablet,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isMobile, bool isTablet) {
    return Expanded(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 24 : 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isMobile ? 24 : 32),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(81, 115, 153, 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: isMobile ? 64 : 80,
                  color: const Color.fromRGBO(81, 115, 153, 0.5),
                ),
              ),
              SizedBox(height: isMobile ? 20 : 24),
              Text(
                controller.searchQuery.value.isEmpty
                    ? 'No clinics registered yet'
                    : 'No clinics found',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 22,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isMobile ? 8 : 12),
              Text(
                controller.searchQuery.value.isEmpty
                    ? 'Start by adding your first veterinary clinic'
                    : 'Try adjusting your search terms',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              if (controller.searchQuery.value.isEmpty) ...[
                SizedBox(height: isMobile ? 24 : 32),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const VetClinicRegister(),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.add_rounded,
                    size: isMobile ? 20 : 24,
                  ),
                  label: Text(
                    'Add First Clinic',
                    style: TextStyle(
                      fontSize: isMobile ? 15 : 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromRGBO(81, 115, 153, 1),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 24 : 32,
                      vertical: isMobile ? 14 : 16,
                    ),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(bool isMobile) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 24 : 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 24 : 32),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: isMobile ? 64 : 80,
                color: Colors.red[700],
              ),
            ),
            SizedBox(height: isMobile ? 20 : 24),
            Text(
              'Oops! Something went wrong',
              style: TextStyle(
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: isMobile ? 8 : 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 32),
              child: Text(
                controller.errorMessage.value,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: isMobile ? 24 : 32),
            ElevatedButton.icon(
              onPressed: controller.fetchAllClinics,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(81, 115, 153, 1),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24 : 32,
                  vertical: isMobile ? 14 : 16,
                ),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Icon(
                Icons.refresh_rounded,
                size: isMobile ? 20 : 24,
              ),
              label: Text(
                'Try Again',
                style: TextStyle(
                  fontSize: isMobile ? 15 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAB(bool isMobile, bool isTablet) {
    if (isMobile) {
      return FloatingActionButton(
        backgroundColor: const Color.fromRGBO(81, 115, 153, 1),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const VetClinicRegister(),
            ),
          );
        },
        elevation: 6,
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 28,
        ),
      );
    }

    return FloatingActionButton.extended(
      backgroundColor: const Color.fromRGBO(81, 115, 153, 1),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const VetClinicRegister(),
          ),
        );
      },
      elevation: 6,
      icon: Icon(
        Icons.add_rounded,
        color: Colors.white,
        size: isTablet ? 20 : 24,
      ),
      label: Text(
        'Add Clinic',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: isTablet ? 14 : 16,
        ),
      ),
    );
  }
    }
import 'package:capstone_app/data/models/clinic_model.dart';
import 'package:capstone_app/data/models/clinic_settings_model.dart';
import 'package:capstone_app/web/super_admin/WebVersion/vet_clinic_pages/archive_clinics/archived_clinics_dashboard.dart';
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
import 'package:capstone_app/web/super_admin/WebVersion/view_report/user_app_feedback/app_feedback.dart';
import 'package:capstone_app/web/super_admin/WebVersion/view_report/user_vet_feedback/vet_deletion_reports.dart';
import 'package:capstone_app/web/super_admin/WebVersion/pet_owners_pages/user_page.dart';
import 'package:capstone_app/utils/logout_helper.dart';

class SuperAdminVetClinicDashboard extends StatefulWidget {
  const SuperAdminVetClinicDashboard({super.key});

  @override
  State<SuperAdminVetClinicDashboard> createState() =>
      _SuperAdminVetClinicDashboardState();
}

class _SuperAdminVetClinicDashboardState
    extends State<SuperAdminVetClinicDashboard> {
  final SuperAdminHomeController controller = SuperAdminHomeController.instance;



  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoggingOut = false;

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
        print('🔔 Setting up real-time listeners for clinic updates...');
        
        // Enhanced Clinic Changes Listener
        _clinicSubscription = controller.authRepository
            .subscribeToClinicChanges()
            .listen((event) {
          print('🔔 Clinic real-time event received');
          print('   Events: ${event.events}');
          print('   Payload ID: ${event.payload['\$id']}');
          
          final eventType = event.events.first;
          
          if (eventType.contains('.create')) {
            print('✅ New clinic created - refreshing list');
            _showRealTimeNotification(
              'New clinic added',
              Icons.add_business_rounded,
              Colors.green,
            );
            controller.fetchAllClinics();
          } else if (eventType.contains('.update')) {
            print('🔄 Clinic updated - refreshing list');
            
            // Find the updated clinic name
            final clinicName = event.payload['clinicName'] as String?;
            _showRealTimeNotification(
              'Clinic "${clinicName ?? 'Unknown'}" updated',
              Icons.sync_rounded,
              const Color.fromRGBO(81, 115, 153, 1),
            );
            controller.fetchAllClinics();
          } else if (eventType.contains('.delete')) {
            print('🗑️ Clinic deleted - refreshing list');
            _showRealTimeNotification(
              'Clinic removed',
              Icons.delete_rounded,
              Colors.red,
            );
            controller.fetchAllClinics();
          }
        }, onError: (error) {
          print('❌ Clinic subscription error: $error');
        });

        // Enhanced Settings Changes Listener
        _settingsSubscription = controller.authRepository
            .subscribeToClinicSettingsChanges()
            .listen((event) {
          print('🔔 Settings real-time event received');
          print('   Events: ${event.events}');
          
          final eventType = event.events.first;
          
          if (eventType.contains('.update')) {
            print('🔄 Clinic settings updated - refreshing list');
            
            // Get clinic ID from payload
            final clinicId = event.payload['clinicId'] as String?;
            
            if (clinicId != null) {
              _showRealTimeNotification(
                'Clinic settings updated',
                Icons.settings_rounded,
                Colors.orange,
              );
              controller.fetchAllClinics();
            }
          } else if (eventType.contains('.create')) {
            print('✅ New clinic settings created - refreshing list');
            controller.fetchAllClinics();
          }
        }, onError: (error) {
          print('❌ Settings subscription error: $error');
        });
        
        print('✅ Real-time listeners initialized successfully');
      }

      // Enhanced real-time notification with beautiful UI
      void _showRealTimeNotification(String message, IconData icon, Color color) {
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Real-Time Update',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.wifi_tethering_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
            backgroundColor: const Color.fromRGBO(81, 115, 153, 0.95),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 3),
            elevation: 8,
          ),
        );
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
      key: _scaffoldKey,  
  appBar: _buildAppBar(context, screenHeight, horizontalPadding, isMobile),
  drawer: _buildDrawer(context),  
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
            _buildHeader(context, filteredClinics.length, horizontalPadding,
                isMobile, isTablet),

            // Search and filter
            _buildSearchBar(horizontalPadding, isMobile, isTablet),

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
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: Icon(
              Icons.menu_rounded,
              color: const Color.fromRGBO(81, 115, 153, 1),
              size: isMobile ? 24 : 28,
            ),
            onPressed: () {
              _scaffoldKey.currentState?.openDrawer();
            },
            tooltip: 'Menu',
          ),
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

      Widget _buildDrawer(BuildContext context) {
  return Drawer(
    backgroundColor: const Color.fromRGBO(248, 253, 255, 1),
    child: Column(
      children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromRGBO(81, 115, 153, 1),
                Color.fromRGBO(81, 115, 153, 0.8),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Developer',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Management Panel',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Menu Items
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _buildDrawerItem(
                context,
                icon: Icons.people_rounded,
                title: 'Pet Owner Management',
                subtitle: 'Manage user accounts',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SuperAdminUserManagementScreen(),
                    ),
                  );
                },
              ),
              _buildDrawerItem(
                context,
                icon: Icons.feedback_rounded,
                title: 'System Reports',
                subtitle: 'User feedback & reports',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminFeedbackManagement(),
                    ),
                  );
                },
              ),
              _buildDrawerItem(
                context,
                icon: Icons.delete_forever_rounded,
                title: 'Vet Reports',
                subtitle: 'Deletion requests',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VeterinaryReport(),
                    ),
                  );
                },
              ),
                const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Divider(),
              ),
                const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Divider(),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.archive_rounded,
                title: 'Archived Clinics',
                subtitle: 'View & manage archives',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ArchivedClinicsDashboard(),
                    ),
                  );
                },
              ),      
            ],
          ),
        ),

        // Logout Button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: _isLoggingOut
                ? Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromRGBO(81, 115, 153, 0.7),
                          Color.fromRGBO(81, 115, 153, 0.5),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Logging Out...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                : InkWell(
                    onTap: () async {
                      setState(() => _isLoggingOut = true);
                      try {
                        await LogoutHelper.logout();
                      } catch (e) {
                        if (mounted) {
                          setState(() => _isLoggingOut = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Logout failed: ${e.toString()}'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color.fromRGBO(220, 53, 69, 1),
                            Color.fromRGBO(200, 35, 51, 1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Log Out',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ],
    ),
  );
}

      Widget _buildDrawerItem(
        BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color.fromRGBO(81, 115, 153, 0.2),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromRGBO(81, 115, 153, 0.2),
                          Color.fromRGBO(81, 115, 153, 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: const Color.fromRGBO(81, 115, 153, 1),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color.fromRGBO(81, 115, 153, 1),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Color.fromRGBO(81, 115, 153, 0.5),
                  ),
                ],
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

  Widget _buildSearchBar(
      double horizontalPadding, bool isMobile, bool isTablet) {
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

import 'package:capstone_app/utils/logout_helper.dart';
import 'package:capstone_app/web/pages/web_super_admin_home/web_super_admin_home_controller.dart';
import 'package:capstone_app/web/super_admin/WebVersion/tile_pages/pet_owner_menu_tile.dart';
import 'package:capstone_app/web/super_admin/WebVersion/tile_pages/vet_clinic_menu_tile.dart';
import 'package:capstone_app/web/super_admin/WebVersion/tile_pages/view_report_menu_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SuperAdminTabletHomePage extends GetView<WebSuperAdminHomeController> {
  const SuperAdminTabletHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Define breakpoints for responsiveness
    final isSmallScreen = screenWidth < 768;
    final isMediumScreen = screenWidth >= 768;

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        centerTitle: true,
        toolbarHeight: _getAppBarHeight(screenHeight, isSmallScreen),
        title: Image.asset(
          "lib/images/PAWrtal_logo.png",
          height: _getLogoHeight(isSmallScreen),
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
              icon: Icon(
                Icons.menu,
                color: const Color.fromRGBO(81, 115, 153, 0.8),
                size: _getIconSize(isSmallScreen),
              ),
            ),
          ),
        ],
      ),
      endDrawer: _buildProfileDrawer(context, screenWidth),
      backgroundColor: const Color.fromARGB(255, 248, 253, 255),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            top: _getTopPadding(isSmallScreen),
            bottom: _getBottomPadding(isSmallScreen),
            left: _getHorizontalPadding(screenWidth),
            right: _getHorizontalPadding(screenWidth),
          ),
          child: Column(
            children: [
              _buildMenuTiles(isSmallScreen, isMediumScreen),
              SizedBox(height: _getSpacingBetweenTiles(isSmallScreen)),
              _buildViewReportTile(screenWidth, isSmallScreen),
            ],
          ),
        ),
      ),
    );
  }

  // Responsive helper methods for sizing
  double _getAppBarHeight(double screenHeight, bool isSmallScreen) {
    if (isSmallScreen) return screenHeight * 0.07;
    return screenHeight * 0.08;
  }

  double _getLogoHeight(bool isSmallScreen) {
    return isSmallScreen ? 32 : 40;
  }

  double _getIconSize(bool isSmallScreen) {
    return isSmallScreen ? 24 : 30;
  }

  double _getTopPadding(bool isSmallScreen) {
    return isSmallScreen ? 10 : 20;
  }

  double _getBottomPadding(bool isSmallScreen) {
    return isSmallScreen ? 40 : 60;
  }

  double _getHorizontalPadding(double screenWidth) {
    if (screenWidth < 768) return 10;
    return 20;
  }

  double _getSpacingBetweenTiles(bool isSmallScreen) {
    return isSmallScreen ? 15 : 20;
  }

  // Build menu tiles with responsive layout
  Widget _buildMenuTiles(bool isSmallScreen, bool isMediumScreen) {
    if (isSmallScreen) {
      // Stack tiles vertically on small screens
      return Column(
        children: [
          const VetClinicTile(),
          SizedBox(height: _getSpacingBetweenTiles(isSmallScreen)),
          const PetOwnerTile(),
        ],
      );
    } else {
      // Keep tiles side by side on medium and large screens
      return const Row(
        children: [
          Expanded(child: VetClinicTile()),
          Expanded(child: PetOwnerTile()),
        ],
      );
    }
  }

  // Build view report tile with responsive constraints
  Widget _buildViewReportTile(double screenWidth, bool isSmallScreen) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: isSmallScreen ? double.infinity : 800,
      ),
      child: const ViewReportTile(),
    );
  }

  Widget _buildProfileDrawer(BuildContext context, double screenWidth) {
    final isSmallScreen = screenWidth < 768;

    // Make drawer width responsive for tablet
    double drawerWidth = isSmallScreen ? screenWidth * 0.75 : 350;

    double drawerHeight =
        MediaQuery.of(context).size.height * 0.5; // 50% of screen height

    return Align(
      alignment: Alignment.topRight,
      child: SizedBox(
        width: drawerWidth,
        height: drawerHeight,
        child: Drawer(
          backgroundColor: const Color.fromRGBO(249, 253, 255, 1),
          child: Column(
            children: [
              // Header section with user profile - Fixed height
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  isSmallScreen ? 16 : 20,
                  isSmallScreen ? 40 : 50,
                  isSmallScreen ? 16 : 20,
                  isSmallScreen ? 20 : 25,
                ),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 248, 253, 255),
                  border: Border(
                    bottom: BorderSide(
                      color: Color.fromARGB(50, 81, 115, 153),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                      radius: isSmallScreen ? 30 : 35,
                      child: Text(
                        controller.userName.isNotEmpty
                            ? controller.userName[0].toUpperCase()
                            : 'S',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 18 : 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 12),
                    Text(
                      controller.userName.isNotEmpty
                          ? controller.userName
                          : 'Super Admin',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 81, 115, 153),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isSmallScreen ? 2 : 4),
                    Text(
                      controller.userEmail.isNotEmpty
                          ? controller.userEmail
                          : 'admin@pawrtal.com',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 11 : 13,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Menu items section - Uses remaining space
              Expanded(
                child: Column(
                  children: [
                    // Spacer to push logout button to bottom
                    const Spacer(),
                    // Logout button container - Fixed at bottom
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                      child: Card(
                        elevation: 2,
                        color: Colors.red[50],
                        margin: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Colors.red[300]!,
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 16 : 20,
                            vertical: isSmallScreen ? 8 : 12,
                          ),
                          leading: Icon(
                            Icons.logout,
                            color: Colors.red[600],
                            size: isSmallScreen ? 20 : 24,
                          ),
                          title: Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.red[600],
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.red[600],
                            size: isSmallScreen ? 14 : 16,
                          ),
                          onTap: () {
                            Navigator.pop(context); // Close drawer first
                            _showLogoutDialog(context);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 768;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: const Color.fromARGB(255, 248, 253, 255),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange[600],
                size: isSmallScreen ? 22 : 26,
              ),
              const SizedBox(width: 12),
              Text(
                'Confirm Logout',
                style: TextStyle(
                  fontSize: isSmallScreen ? 16 : 20,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 81, 115, 153),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout from your account?',
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.grey[700],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 14 : 18,
                  vertical: isSmallScreen ? 8 : 10,
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog first
                // Use LogoutHelper which handles its own loading state and navigation
                await LogoutHelper.logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isSmallScreen ? 14 : 18,
                  vertical: isSmallScreen ? 8 : 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Logout',
                style: TextStyle(
                  fontSize: isSmallScreen ? 14 : 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

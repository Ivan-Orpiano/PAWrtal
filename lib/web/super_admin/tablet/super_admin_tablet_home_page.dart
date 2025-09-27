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
    final isSmallScreen = screenWidth < 600;
    final isMediumScreen = screenWidth >= 600 && screenWidth < 1200;
    final isLargeScreen = screenWidth >= 1200;

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
          IconButton(
            onPressed: () {
              _showProfileMenu(context);
            },
            icon: Icon(
              Icons.menu,
              color: const Color.fromRGBO(81, 115, 153, 0.8),
              size: _getIconSize(isSmallScreen),
            ),
          ),
        ],
      ),
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
              _buildMenuTiles(isSmallScreen, isMediumScreen, isLargeScreen),
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
    if (screenWidth < 600) return 10;
    if (screenWidth < 1200) return 20;
    return 40;
  }

  double _getSpacingBetweenTiles(bool isSmallScreen) {
    return isSmallScreen ? 15 : 20;
  }

  // Build menu tiles with responsive layout
  Widget _buildMenuTiles(
      bool isSmallScreen, bool isMediumScreen, bool isLargeScreen) {
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

  void _showProfileMenu(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenWidth < 600;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          color: const Color.fromRGBO(249, 253, 255, 1),
          padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
          constraints: BoxConstraints(
            maxHeight: screenHeight * (isSmallScreen ? 0.35 : 0.3),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar for visual indication
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: CircleAvatar(
                  radius: isSmallScreen ? 20 : 24,
                  backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                  child: Text(
                    controller.userName.isNotEmpty
                        ? controller.userName[0].toUpperCase()
                        : 'D',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 16 : 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  controller.userName,
                  style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
                ),
                subtitle: Text(
                  controller.userEmail,
                  style: TextStyle(fontSize: isSmallScreen ? 12 : 14),
                ),
              ),
              const Divider(),
              _buildMenuTile(
                icon: Icons.logout,
                title: 'Logout',
                isSmallScreen: isSmallScreen,
                textColor: Colors.red,
                iconColor: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog(context);
                },
              ),
              // Add safe area padding at bottom
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    required bool isSmallScreen,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor,
        size: isSmallScreen ? 20 : 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontSize: isSmallScreen ? 14 : 16,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromRGBO(249, 253, 255, 1),
          title: Text(
            'Logout',
            style: TextStyle(fontSize: isSmallScreen ? 18 : 20),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await controller.logout();
              },
              child: Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

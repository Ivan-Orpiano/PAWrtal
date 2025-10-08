import 'package:capstone_app/utils/logout_helper.dart';
import 'package:capstone_app/web/pages/web_super_admin_home/web_super_admin_home_controller.dart';
import 'package:capstone_app/web/super_admin/WebVersion/tile_pages/pet_owner_menu_tile.dart';
import 'package:capstone_app/web/super_admin/WebVersion/tile_pages/vet_clinic_menu_tile.dart';
import 'package:capstone_app/web/super_admin/WebVersion/tile_pages/view_report_menu_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SuperAdminMobileHomePage extends GetView<WebSuperAdminHomeController> {
  const SuperAdminMobileHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height * 0.6;
    final isTablet = screenWidth > 600;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, 
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        centerTitle: true,
        toolbarHeight: isTablet ? 80 : 70,
        title: Image.asset(
          "lib/images/PAWrtal_logo.png",
          height: isTablet ? 45 : 35,
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
            size: isTablet ? 30 : 40,
          ),
        ),
          ),
        ],
      ),
      endDrawer: _buildProfileDrawer(context, screenWidth),
      backgroundColor: const Color.fromARGB(255, 248, 253, 255),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isTablet ? screenWidth * 0.1 : 16,
            vertical: 20,
          ).copyWith(bottom: 60),
          child: _buildMenuTiles(isTablet, isLandscape, screenWidth),
        ),
      ),
    );
  }

  Widget _buildMenuTiles(bool isTablet, bool isLandscape, double screenWidth) {
    const menuTiles = [
      VetClinicTile(),
      PetOwnerTile(),
      ViewReportTile(),
    ];

    // For tablets or landscape mode, use grid layout
    if (isTablet || isLandscape) {
      final crossAxisCount =
          isTablet ? (screenWidth > 900 ? 3 : 2) : (screenWidth > 700 ? 2 : 1);

      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: isTablet ? 1.2 : 1.5,
        children: menuTiles,
      );
    }

    // For mobile portrait, use column layout
    return Column(
      children: menuTiles
          .map((tile) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: tile,
              ))
          .toList(),
    );
  }

  Widget _buildProfileDrawer(BuildContext context, double screenWidth) {
    final isTablet = screenWidth > 600;
    double drawerWidth = isTablet ? 350 : screenWidth * 0.75;
    double drawerHeight = MediaQuery.of(context).size.height * 0.50;

    return Align(
      alignment: Alignment.topRight,
      child: SizedBox(
        width: drawerWidth,
        height: drawerHeight,
        child: Drawer(
          backgroundColor: const Color.fromRGBO(249, 253, 255, 1),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(isTablet ? 24 : 20,
                    isTablet ? 70 : 60, isTablet ? 24 : 20, isTablet ? 35 : 30),
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
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                      radius: isTablet ? 45 : 35,
                      child: Text(
                        controller.userName.isNotEmpty
                            ? controller.userName[0].toUpperCase()
                            : 'S',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 28 : 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(height: isTablet ? 18 : 14),
                    Text(
                      controller.userName.isNotEmpty
                          ? controller.userName
                          : 'Super Admin',
                      style: TextStyle(
                        fontSize: isTablet ? 22 : 18,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 81, 115, 153),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: isTablet ? 6 : 4),
                    Text(
                      controller.userEmail.isNotEmpty
                          ? controller.userEmail
                          : 'admin@pawrtal.com',
                      style: TextStyle(
                        fontSize: isTablet ? 15 : 13,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Menu items section
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: isTablet ? 25 : 20,
                    horizontal: isTablet ? 16 : 12,
                  ),
                  child: Column(
                    children: [
                      const Spacer(),
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: isTablet ? 25 : 20),
                        child: Card(
                          elevation: 2,
                          color: Colors.red[50],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Colors.red[300]!,
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: isTablet ? 20 : 16,
                              vertical: isTablet ? 8 : 4,
                            ),
                            leading: Icon(
                              Icons.logout,
                              color: Colors.red[600],
                              size: isTablet ? 26 : 22,
                            ),
                            title: Text(
                              'Logout',
                              style: TextStyle(
                                color: Colors.red[600],
                                fontSize: isTablet ? 17 : 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: Icon(
                              Icons.arrow_forward_ios,
                              color: Colors.red[600],
                              size: isTablet ? 18 : 16,
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

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
                size: isTablet ? 28 : 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Confirm Logout',
                style: TextStyle(
                  fontSize: isTablet ? 22 : 18,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 81, 115, 153),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout from your account?',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
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
                  horizontal: isTablet ? 20 : 16,
                  vertical: isTablet ? 12 : 8,
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
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
                  horizontal: isTablet ? 20 : 16,
                  vertical: isTablet ? 12 : 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Logout',
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
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

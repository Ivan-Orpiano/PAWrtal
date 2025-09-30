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

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        centerTitle: true,
        toolbarHeight: screenHeight * 0.08,
        title: Image.asset(
          "lib/images/PAWrtal_logo.png",
          height: 40,
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
              icon: const Icon(
                Icons.menu,
                color: Color.fromRGBO(81, 115, 153, 0.8),
                size: 30,
              ),
            ),
          ),
        ],
      ),
      endDrawer: _buildProfileDrawer(context, screenWidth, screenHeight),
      backgroundColor: const Color.fromARGB(255, 248, 253, 255),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(
            top: 20,
            bottom: 60,
            left: 20,
            right: 20,
          ),
          child: Column(
            children: [
              const Row(
                children: [
                  Expanded(child: VetClinicTile()),
                  Expanded(child: PetOwnerTile()),
                ],
              ),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: const ViewReportTile(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileDrawer(
      BuildContext context, double screenWidth, double screenHeight) {
    // Responsive drawer width based on tablet screen size
    double drawerWidth = screenWidth * 0.35; // 35% of screen width
    if (drawerWidth < 300) drawerWidth = 300; // Minimum width
    if (drawerWidth > 400) drawerWidth = 400; // Maximum width

    // Drawer height responsive to screen height
    double drawerHeight = screenHeight * 0.5;

    // Calculate responsive sizing based on drawer dimensions
    double avatarRadius = drawerWidth * 0.1; // 10% of drawer width
    if (avatarRadius < 30) avatarRadius = 30;
    if (avatarRadius > 40) avatarRadius = 40;

    double titleFontSize = drawerWidth * 0.05;
    if (titleFontSize < 16) titleFontSize = 16;
    if (titleFontSize > 20) titleFontSize = 20;

    double emailFontSize = drawerWidth * 0.035;
    if (emailFontSize < 12) emailFontSize = 12;
    if (emailFontSize > 14) emailFontSize = 14;

    return Align(
      alignment: Alignment.topRight,
      child: SizedBox(
        width: drawerWidth,
        height: drawerHeight,
        child: Drawer(
          backgroundColor: const Color.fromRGBO(249, 253, 255, 1),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Column(
                children: [
                  // Header section with user profile
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      drawerWidth * 0.06,
                      drawerHeight * 0.08,
                      drawerWidth * 0.06,
                      drawerHeight * 0.04,
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
                          backgroundColor:
                              const Color.fromARGB(255, 81, 115, 153),
                          radius: avatarRadius,
                          child: Text(
                            controller.userName.isNotEmpty
                                ? controller.userName[0].toUpperCase()
                                : 'S',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: avatarRadius * 0.6,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: drawerHeight * 0.02),
                        Text(
                          controller.userName.isNotEmpty
                              ? controller.userName
                              : 'Super Admin',
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 81, 115, 153),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: drawerHeight * 0.008),
                        Text(
                          controller.userEmail.isNotEmpty
                              ? controller.userEmail
                              : 'admin@pawrtal.com',
                          style: TextStyle(
                            fontSize: emailFontSize,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Spacer to push logout button to bottom
                  const Spacer(),
                  // Logout button container - Fixed at bottom with responsive sizing
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(drawerWidth * 0.05),
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
                          horizontal: drawerWidth * 0.06,
                          vertical: drawerHeight * 0.02,
                        ),
                        leading: Icon(
                          Icons.logout,
                          color: Colors.red[600],
                          size: drawerWidth * 0.065,
                        ),
                        title: Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.red[600],
                            fontSize: drawerWidth * 0.045,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.red[600],
                          size: drawerWidth * 0.045,
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          _showLogoutDialog(context, screenWidth);
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, double screenWidth) {
    // Responsive dialog sizing
    double iconSize = screenWidth * 0.025;
    if (iconSize < 22) iconSize = 22;
    if (iconSize > 28) iconSize = 28;

    double titleFontSize = screenWidth * 0.022;
    if (titleFontSize < 18) titleFontSize = 18;
    if (titleFontSize > 22) titleFontSize = 22;

    double contentFontSize = screenWidth * 0.018;
    if (contentFontSize < 14) contentFontSize = 14;
    if (contentFontSize > 18) contentFontSize = 18;

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
                size: iconSize,
              ),
              const SizedBox(width: 12),
              Text(
                'Confirm Logout',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 81, 115, 153),
                ),
              ),
            ],
          ),
          content: Text(
            'Are you sure you want to logout from your account?',
            style: TextStyle(
              fontSize: contentFontSize,
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
                  horizontal: screenWidth * 0.02,
                  vertical: 10,
                ),
              ),
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: contentFontSize,
                  color: Colors.grey[600],
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await LogoutHelper.logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.02,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Logout',
                style: TextStyle(
                  fontSize: contentFontSize,
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

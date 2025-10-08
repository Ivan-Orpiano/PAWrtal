import 'package:capstone_app/utils/logout_helper.dart';
import 'package:capstone_app/web/pages/web_super_admin_home/web_super_admin_home_controller.dart';
import 'package:capstone_app/web/super_admin/WebVersion/tile_pages/pet_owner_menu_tile.dart';
import 'package:capstone_app/web/super_admin/WebVersion/tile_pages/vet_clinic_menu_tile.dart';
import 'package:capstone_app/web/super_admin/WebVersion/tile_pages/view_report_menu_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SuperAdminDesktopHomePage extends GetView<WebSuperAdminHomeController> {
  const SuperAdminDesktopHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    // Define breakpoints
    final bool isDesktop = screenWidth > 1024;
    final bool isTablet = screenWidth > 600 && screenWidth <= 1024;
    final bool isMobile = screenWidth <= 600;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        centerTitle: true,
        toolbarHeight: isDesktop
            ? screenHeight * 0.1
            : isTablet
                ? screenHeight * 0.09
                : screenHeight * 0.08,
        flexibleSpace: Container(
          margin: EdgeInsets.only(
            top: isDesktop
                ? 15.0
                : isTablet
                    ? 12.0
                    : 10.0,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: isDesktop
                    ? screenHeight * 0.08
                    : isTablet
                        ? screenHeight * 0.07
                        : screenHeight * 0.06,
                maxWidth: isDesktop
                    ? screenWidth * 0.3
                    : isTablet
                        ? screenWidth * 0.4
                        : screenWidth * 0.5,
              ),
              child: Image.asset(
                "lib/images/PAWrtal_logo.png",
                fit: BoxFit.contain,
              ),
            ),
          ),
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
                size: isDesktop
                    ? 24
                    : isTablet
                        ? 22
                        : 20,
              ),
            ),
          ),
        ],
      ),
      endDrawer: _buildProfileDrawer(context, screenWidth, screenHeight),
      backgroundColor: const Color.fromARGB(255, 248, 253, 255),
      body: Container(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop
                      ? constraints.maxWidth * 0.05
                      : isTablet
                          ? constraints.maxWidth * 0.04
                          : constraints.maxWidth * 0.03,
                  vertical: isDesktop
                      ? 20
                      : isTablet
                          ? 16
                          : 12,
                ),
                child: isDesktop
                    ? IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: constraints.maxWidth / 3 - 16,
                                  ),
                                  child: const VetClinicTile(),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: constraints.maxWidth / 3 - 16,
                                  ),
                                  child: const PetOwnerTile(),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: constraints.maxWidth / 3 - 16,
                                  ),
                                  child: const ViewReportTile(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    : isTablet
                        ? IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6.0),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: constraints.maxWidth / 2 - 12,
                                      ),
                                      child: const Column(
                                        children: [
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 6.0),
                                            child: VetClinicTile(),
                                          ),
                                          Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical: 6.0),
                                            child: ViewReportTile(),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6.0),
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: constraints.maxWidth / 2 - 12,
                                      ),
                                      child: const Padding(
                                        padding:
                                            EdgeInsets.symmetric(vertical: 6.0),
                                        child: PetOwnerTile(),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth,
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: VetClinicTile(),
                                ),
                              ),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth,
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: PetOwnerTile(),
                                ),
                              ),
                              ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth,
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: ViewReportTile(),
                                ),
                              ),
                            ],
                          ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileDrawer(
      BuildContext context, double screenWidth, double screenHeight) {
    // Define breakpoints for drawer sizing
    final bool isDesktop = screenWidth > 1024;
    final bool isTablet = screenWidth > 600 && screenWidth <= 1024;
    final bool isMobile = screenWidth <= 600;

    // Responsive drawer dimensions
    double drawerWidth = isDesktop
        ? 340
        : isTablet
            ? 300
            : screenWidth * 0.85;

    // Calculate drawer height dynamically to fit content without hiding
    double avatarRadius = isDesktop
        ? 40
        : isTablet
            ? 35
            : 30;
    double topPadding = isDesktop
        ? 60
        : isTablet
            ? 50
            : 40;
    double bottomPadding = isDesktop
        ? 30
        : isTablet
            ? 25
            : 20;
    double avatarHeight = (avatarRadius * 2) + 16; // Avatar + spacing
    double textHeight = isDesktop
        ? 70
        : isTablet
            ? 65
            : 60; // Name + email
    double listItemHeight = isDesktop
        ? 80
        : isTablet
            ? 70
            : 65; // Logout item
    double paddingSum = topPadding + bottomPadding + 40; // Total padding

    double calculatedHeight =
        avatarHeight + textHeight + listItemHeight + paddingSum;

    // Ensure minimum and maximum heights
    double minHeight = screenHeight * 0.25;
    double maxHeight = screenHeight * 0.4;
    double drawerHeight = calculatedHeight.clamp(minHeight, maxHeight);

    return Align(
      alignment: Alignment.topRight,
      child: SizedBox(
        width: drawerWidth,
        height: drawerHeight,
        child: Drawer(
          backgroundColor: const Color.fromRGBO(249, 253, 255, 1),
          child: Column(
            children: [
              // Header section with user profile
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  isDesktop
                      ? 20
                      : isTablet
                          ? 16
                          : 12,
                  topPadding,
                  isDesktop
                      ? 20
                      : isTablet
                          ? 16
                          : 12,
                  bottomPadding,
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
                  children: [
                    CircleAvatar(
                      backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                      radius: avatarRadius,
                      child: Text(
                        controller.userName.isNotEmpty
                            ? controller.userName[0].toUpperCase()
                            : 'D',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isDesktop
                              ? 24
                              : isTablet
                                  ? 20
                                  : 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(
                        height: isDesktop
                            ? 16
                            : isTablet
                                ? 12
                                : 10),
                    Text(
                      controller.userName,
                      style: TextStyle(
                        fontSize: isDesktop
                            ? 20
                            : isTablet
                                ? 18
                                : 16,
                        fontWeight: FontWeight.bold,
                        color: const Color.fromARGB(255, 81, 115, 153),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      controller.userEmail,
                      style: TextStyle(
                        fontSize: isDesktop
                            ? 14
                            : isTablet
                                ? 13
                                : 12,
                        color: Colors.grey,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: isMobile ? 1 : 2,
                    ),
                  ],
                ),
              ),
              // Menu items section
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    vertical: isDesktop
                        ? 20
                        : isTablet
                            ? 16
                            : 12,
                  ),
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: isDesktop
                            ? 24
                            : isTablet
                                ? 20
                                : 16,
                      ),
                      leading: Icon(
                        Icons.logout,
                        color: Colors.red,
                        size: isDesktop
                            ? 24
                            : isTablet
                                ? 22
                                : 20,
                      ),
                      title: Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: isDesktop
                              ? 16
                              : isTablet
                                  ? 15
                                  : 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context); // Close drawer first
                        _showLogoutDialog(context, isDesktop, isTablet);
                      },
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hoverColor: Colors.red.withOpacity(0.1),
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

  void _showLogoutDialog(BuildContext context, bool isDesktop, bool isTablet) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Logout',
            style: TextStyle(
              fontSize: isDesktop
                  ? 20
                  : isTablet
                      ? 18
                      : 16,
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 248, 253, 255),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontSize: isDesktop
                  ? 16
                  : isTablet
                      ? 15
                      : 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontSize: isDesktop
                      ? 16
                      : isTablet
                          ? 15
                          : 14,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Close the dialog first
                // Use LogoutHelper which handles its own loading state and navigation
                await LogoutHelper.logout();
              },
              child: Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: isDesktop
                      ? 16
                      : isTablet
                          ? 15
                          : 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

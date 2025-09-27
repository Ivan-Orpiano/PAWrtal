import 'package:capstone_app/web/pages/web_super_admin_home/web_super_admin_home_controller.dart';
import 'package:capstone_app/web/super_admin/WebVersion/main_components/pet_owner_menu_tile.dart';
import 'package:capstone_app/web/super_admin/WebVersion/main_components/vet_clinic_menu_tile.dart';
import 'package:capstone_app/web/super_admin/WebVersion/main_components/view_report_menu_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SuperAdminMobileHomePage extends GetView<WebSuperAdminHomeController> {
  const SuperAdminMobileHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth > 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: const Color.fromARGB(255, 248, 253, 255),
        centerTitle: true,
        toolbarHeight: isTablet ? 80 : 70,
        title: Image.asset(
          "lib/images/PAWrtal_logo.png",
          height: isTablet ? 45 : 35,
        ),
        actions: [
          IconButton(
            onPressed: () {
              _showProfileDrawer(context);
            },
            icon: Icon(
              Icons.menu,
              color: const Color.fromRGBO(81, 115, 153, 0.8),
              size: isTablet ? 28 : 24,
            ),
          ),
        ],
      ),
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
      final crossAxisCount = isTablet ? 
        (screenWidth > 900 ? 3 : 2) : 
        (screenWidth > 700 ? 2 : 1);
      
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
      children: menuTiles.map((tile) => 
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: tile,
        )
      ).toList(),
    );
  }

  void _showProfileDrawer(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          color: const Color.fromRGBO(249, 253, 255, 1),
          height: screenHeight * (isTablet ? 0.35 : 0.4),
          padding: EdgeInsets.all(isTablet ? 30 : 20),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: isTablet ? 25 : 20),
              CircleAvatar(
                backgroundColor: const Color.fromARGB(255, 81, 115, 153),
                radius: isTablet ? 50 : 40,
                child: Text(
                  controller.userName.isNotEmpty ? controller.userName[0].toUpperCase() : 'D',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 32 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: isTablet ? 20 : 16),
              Text(
                controller.userName,
                style: TextStyle(
                  fontSize: isTablet ? 24 : 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                controller.userEmail,
                style: TextStyle(
                  fontSize: isTablet ? 16 : 14,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: isTablet ? 30 : 20),
              Expanded(
                child: _buildMenuList(isTablet),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuList(bool isTablet) {
    final menuItems = [
      _buildMenuItem(Icons.logout, 'Logout', () {
        Get.back();
        _showLogoutDialog(Get.context!);
      }, isDestructive: true),
    ];

    return ListView(
      children: menuItems,
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    final screenWidth = MediaQuery.of(Get.context!).size.width;
    final isTablet = screenWidth > 600;
    
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? 20 : 16,
        vertical: isTablet ? 8 : 4,
      ),
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : null,
        size: isTablet ? 28 : 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
          fontSize: isTablet ? 18 : 16,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Logout',
            style: TextStyle(
              fontSize: isTablet ? 22 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontSize: isTablet ? 16 : 14,
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
                  fontSize: isTablet ? 16 : 14,
                ),
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
                  fontSize: isTablet ? 16 : 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
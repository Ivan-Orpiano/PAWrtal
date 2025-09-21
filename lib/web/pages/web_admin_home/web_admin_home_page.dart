import 'package:capstone_app/web/pages/web_admin_home/web_admin_home_controller.dart';
import 'package:capstone_app/web/responsive_layout.dart';
import 'package:capstone_app/web/admin_web/layouts/desktop/admin_desktop_home_page.dart';
import 'package:capstone_app/web/admin_web/layouts/tablet/admin_tablet_home_page.dart';
import 'package:capstone_app/web/admin_web/layouts/mobile/admin_mobile_home_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebAdminHomePage extends GetView<WebAdminHomeController> {
  const WebAdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        desktopBody: () => Obx(() => AdminDesktopHomePage(
          selectedIndex: controller.selectedIndex.value,
          onItemSelected: controller.setSelectedIndex,
          canAccessStaffs: controller.canAccessStaffs.value,
        )),
        tabletBody: () => Obx(() => AdminTabletHomePage(
          selectedIndex: controller.selectedIndex.value,
          onItemSelected: controller.setSelectedIndex,
          canAccessStaffs: controller.canAccessStaffs.value,
        )),
        mobileBody: () => Obx(() => AdminMobileHomePage(
          selectedIndex: controller.selectedIndex.value,
          onItemSelected: controller.setSelectedIndex,
          canAccessStaffs: controller.canAccessStaffs.value,
        )),
      ),
    );
  }
}
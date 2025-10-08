import 'package:capstone_app/web/pages/web_admin_home/web_admin_home_controller.dart';
import 'package:capstone_app/web/responsive_layout.dart';
import 'package:capstone_app/web/admin_web/layouts/desktop/admin_desktop_home_page.dart';
import 'package:capstone_app/web/admin_web/layouts/tablet/admin_tablet_home_page.dart';
import 'package:capstone_app/web/admin_web/layouts/mobile/admin_mobile_home_page.dart';
import 'package:capstone_app/web/admin_web/components/staffs/data/permission_guard.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebAdminHomePage extends GetView<WebAdminHomeController> {
  const WebAdminHomePage({super.key});

  // Wrap a page with permission guard if needed
  Widget _wrapWithPermissionGuard(Widget page, int index) {
    // Home page (index 0) doesn't need permission check
    if (index == 0) return page;

    // Admin has full access to everything
    if (controller.isAdmin) return page;

    // Staff users - check if they have permission for this page
    final pageName = controller.navigationLabels[index];
    final hasPermission = controller.hasAuthority(pageName);

    return PermissionGuard(
      hasPermission: hasPermission,
      requiredPermission: pageName,
      child: page,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug print to verify controller initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.debugPrintState();
    });

    return Scaffold(
      body: ResponsiveLayout(
        desktopBody: () => Obx(() {
          final selectedIndex = controller.selectedIndex.value;

          return AdminDesktopHomePage(
            selectedIndex: selectedIndex,
            onItemSelected: controller.setSelectedIndex,
            canAccessStaffs:
                true, // Always true now, handled by permission guard
          );
        }),
        tabletBody: () => Obx(() {
          final selectedIndex = controller.selectedIndex.value;

          return AdminTabletHomePage(
            selectedIndex: selectedIndex,
            onItemSelected: controller.setSelectedIndex,
            canAccessStaffs:
                true, // Always true now, handled by permission guard
          );
        }),
        mobileBody: () => Obx(() {
          final selectedIndex = controller.selectedIndex.value;

          return AdminMobileHomePage(
            selectedIndex: selectedIndex,
            onItemSelected: controller.setSelectedIndex,
            canAccessStaffs:
                true, // Always true now, handled by permission guard
          );
        }),
      ),
    );
  }
}

import 'package:capstone_app/pages/user_home/user_home_page.dart';
import 'package:capstone_app/web/pages/web_user_home/web_user_home_controller.dart';
import 'package:capstone_app/web/responsive_layout.dart';
import 'package:capstone_app/web/user_web/desktop_web/pages/web_user_home_page.dart' as desktop;
import 'package:capstone_app/web/user_web/tablet_web/pages/web_tablet_user_homepage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WebUserHomePage extends GetView<WebUserHomeController> {
  const WebUserHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        desktopBody: () => Obx(() => desktop.WebUserHomePage(
          selectedIndex: controller.selectedIndex.value,
          onItemSelected: controller.onItemSelected,
        )),
        tabletBody: () => Obx(() => WebTabletUserHomepage(
          selectedIndex: controller.selectedIndex.value,
          onItemSelected: controller.onItemSelected,
        )),
        mobileBody: () => const UserHomePage(
        )
      )
    );
  }
}

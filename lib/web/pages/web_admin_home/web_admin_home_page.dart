// import 'package:capstone_app/web/admin_web/components/dashboard%20appbar/admin_web_notif.dart';
// import 'package:capstone_app/web/admin_web/components/dashboard%20appbar/admin_web_profile.dart';
// import 'package:capstone_app/web/admin_web/pages/admin_web_appointments.dart';
// import 'package:capstone_app/web/admin_web/pages/admin_web_clinicpage.dart';
// import 'package:capstone_app/web/admin_web/pages/admin_web_dashboard.dart';
// import 'package:capstone_app/web/admin_web/pages/admin_web_messages.dart';
// import 'package:capstone_app/web/admin_web/pages/admin_web_staffs.dart';
// import 'package:capstone_app/web/pages/web_admin_home/web_admin_home_controller.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';

// class WebAdminHomePage extends GetView<WebAdminHomeController> {
//   const WebAdminHomePage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Obx(() => Scaffold(
//       appBar: AppBar(
//         scrolledUnderElevation: 0,
//         backgroundColor: Colors.white,
//         centerTitle: true,
//         leadingWidth: 220,
//         toolbarHeight: 80,
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(1.0),
//           child: Container(
//             color: Colors.grey.shade400,
//             height: 1,
//           ),
//         ),
//         leading: Padding(
//           padding: const EdgeInsets.only(left: 75),
//           child: InkWell(
//             onTap: () => controller.setSelectedIndex(0),
//             child: Image.asset(
//               'lib/images/PAWrtal_logo.png',
//             ),
//           ),
//         ),
//         title: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             _buildNavItem("Home", 0),
//             _buildNavItem("Clinic", 1),
//             _buildNavItem("Appointments", 2),
//             _buildNavItem("Messages", 3),
//             if (controller.canAccessStaffs.value) _buildNavItem("Staffs", 4),
//           ],
//         ),
//         actions: const [
//           Padding(
//             padding: EdgeInsets.only(right: 60),
//             child: Row(
//               children: [
//                 AdminWebNotif(),
//                 Padding(
//                   padding: EdgeInsets.only(left: 30),
//                   child: AdminWebProfile(),
//                 ),
//               ],
//             ),
//           )
//         ],
//       ),
//       body: controller.pages[controller.selectedIndex.value],
//     ));
//   }

//   Widget _buildNavItem(String title, int index) {
//     return InkWell(
//       borderRadius: BorderRadius.circular(20),
//       onTap: () => controller.setSelectedIndex(index),
//       child: Container(
//         padding: const EdgeInsets.all(12),
//         child: Obx(() => Text(
//           title,
//           style: TextStyle(
//             fontSize: 18,
//             color: controller.selectedIndex.value == index 
//                 ? Colors.black 
//                 : Colors.grey,
//           ),
//         )),
//       ),
//     );
//   }
// }

// FOR RESPONSIVE LAYOUT (Wrapper)

import 'package:capstone_app/web/pages/web_admin_home/web_admin_home_controller.dart';
import 'package:capstone_app/web/responsive_layout.dart';
import 'package:capstone_app/web/admin_web/desktop/admin_desktop_home_page.dart';
import 'package:capstone_app/web/admin_web/tablet/admin_tablet_home_page.dart';
import 'package:capstone_app/web/admin_web/mobile/admin_mobile_home_page.dart';
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
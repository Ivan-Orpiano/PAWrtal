import 'package:capstone_app/web/admin_web/components/appbar/admin_web_notif.dart';
import 'package:capstone_app/web/admin_web/components/appbar/admin_web_profile.dart';
import 'package:capstone_app/web/admin_web/components/staffs/data/permission_guard.dart';
import 'package:capstone_app/web/pages/web_admin_home/web_admin_home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminTabletHomePage extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final bool canAccessStaffs; // Kept for compatibility

  const AdminTabletHomePage({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.canAccessStaffs,
  });

  @override
  State<AdminTabletHomePage> createState() => _AdminTabletHomePageState();
}

class _AdminTabletHomePageState extends State<AdminTabletHomePage> {
  Widget _wrapWithPermissionGuard(
      Widget page, int index, WebAdminHomeController controller) {
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
    final controller = Get.find<WebAdminHomeController>();

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        toolbarHeight: 80,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey.shade400,
            height: 1,
          ),
        ),
        title: InkWell(
          onTap: () => widget.onItemSelected(0),
          child: Image.asset(
            'lib/images/PAWrtal_logo.png',
            height: 40,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 30),
            child: Row(
              children: [
                AdminWebNotif(),
                AdminWebProfile(),
              ],
            ),
          )
        ],
      ),
      drawer: Obx(() => Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Color.fromARGB(255, 81, 115, 153),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 30,
                        child: Icon(
                          Icons.admin_panel_settings,
                          color: Color.fromARGB(255, 81, 115, 153),
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        controller.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        controller.userRole.value.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                ...List.generate(
                  controller.navigationLabels.length,
                  (index) {
                    final label = controller.navigationLabels[index];
                    final hasPermission =
                        index == 0 || controller.hasAuthority(label);
                    final isViewOnly = !hasPermission && controller.isStaff;

                    return ListTile(
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _getIconForIndex(index),
                          if (isViewOnly) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.lock_outline,
                              size: 14,
                              color: Colors.orange,
                            ),
                          ],
                        ],
                      ),
                      title: Text(label),
                      selected: widget.selectedIndex == index,
                      selectedTileColor: const Color.fromARGB(255, 81, 115, 153)
                          .withOpacity(0.1),
                      trailing: isViewOnly
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'View Only',
                                style: TextStyle(
                                    fontSize: 10, color: Colors.orange),
                              ),
                            )
                          : null,
                      onTap: () {
                        widget.onItemSelected(index);
                        Navigator.pop(context); // Close drawer
                      },
                    );
                  },
                ),
              ],
            ),
          )),
      body: Obx(() {
        if (widget.selectedIndex >= controller.pages.length) {
          return const Center(child: Text('Page not found'));
        }

        // Wrap the current page with permission guard
        return _wrapWithPermissionGuard(
          controller.pages[widget.selectedIndex],
          widget.selectedIndex,
          controller,
        );
      }),
    );
  }

  Icon _getIconForIndex(int index) {
    // Use a flexible approach based on navigation label
    final controller = Get.find<WebAdminHomeController>();
    if (index >= controller.navigationLabels.length) {
      return const Icon(Icons.circle);
    }

    final label = controller.navigationLabels[index];
    switch (label) {
      case 'Home':
        return const Icon(Icons.dashboard);
      case 'Clinic':
        return const Icon(Icons.local_hospital);
      case 'Appointments':
        return const Icon(Icons.calendar_today);
      case 'Messages':
        return const Icon(Icons.message);
      case 'Staffs':
        return const Icon(Icons.people);
      default:
        return const Icon(Icons.circle);
    }
  }
}

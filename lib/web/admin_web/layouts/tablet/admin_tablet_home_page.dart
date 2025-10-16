import 'package:capstone_app/web/admin_web/components/appbar/admin_web_notif.dart';
import 'package:capstone_app/web/admin_web/components/appbar/admin_web_profile.dart';
import 'package:capstone_app/web/admin_web/components/staffs/data/permission_guard.dart';
import 'package:capstone_app/web/pages/web_admin_home/web_admin_home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AdminTabletHomePage extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final bool canAccessStaffs;

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
  late final WebAdminHomeController _controller;

  @override
  void initState() {
    super.initState();
    _controller = Get.find<WebAdminHomeController>();
  }

  Widget _wrapWithPermissionGuard(
      Widget page, int index, WebAdminHomeController controller) {
    if (index == 0) return page;

    if (controller.isAdmin) return page;

    final pageName = controller.navigationLabels[index];
    final hasPermission = controller.hasAuthority(pageName);

    return PermissionGuard(
      hasPermission: hasPermission,
      requiredPermission: pageName,
      child: page,
    );
  }

  Icon _getIconForLabel(String label) {
    switch (label) {
      case 'Home':
        return const Icon(Icons.dashboard, size: 20);
      case 'Clinic':
        return const Icon(Icons.local_hospital, size: 20);
      case 'Appointments':
        return const Icon(Icons.calendar_today, size: 20);
      case 'Messages':
        return const Icon(Icons.message, size: 20);
      case 'Staffs':
        return const Icon(Icons.people, size: 20);
      default:
        return const Icon(Icons.circle, size: 20);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = screenSize.height > screenSize.width;

    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        toolbarHeight: isPortrait ? 70 : 65,
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
            height: isPortrait ? 35 : 30,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isPortrait ? 20 : 15,
            ),
            child: const Row(
              children: [
                AdminWebNotif(),
                SizedBox(width: 12),
                AdminWebProfile(),
              ],
            ),
          )
        ],
      ),
      drawer: SafeArea(
        child: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 81, 115, 153),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 28,
                      child: Icon(
                        Icons.admin_panel_settings,
                        color: Color.fromARGB(255, 81, 115, 153),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Obx(() {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _controller.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _controller.userRole.value.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              Obx(() {
                return Column(
                  children: List.generate(
                    _controller.navigationLabels.length,
                    (index) {
                      final label = _controller.navigationLabels[index];
                      final hasPermission =
                          index == 0 || _controller.hasAuthority(label);
                      final isViewOnly =
                          !hasPermission && _controller.isStaff;

                      return ListTile(
                        leading: _getIconForLabel(label),
                        title: Text(
                          label,
                          style: const TextStyle(fontSize: 13),
                        ),
                        selected: widget.selectedIndex == index,
                        selectedTileColor: const Color.fromARGB(255, 81, 115, 153)
                            .withOpacity(0.1),
                        trailing: isViewOnly
                            ? Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'View Only',
                                  style: TextStyle(
                                      fontSize: 9, color: Colors.orange),
                                ),
                              )
                            : null,
                        onTap: () {
                          Navigator.pop(context);
                          Future.delayed(const Duration(milliseconds: 100), () {
                            widget.onItemSelected(index);
                          });
                        },
                      );
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      body: Obx(() {
        if (widget.selectedIndex >= _controller.pages.length) {
          return const Center(child: Text('Page not found'));
        }

        return _wrapWithPermissionGuard(
          _controller.pages[widget.selectedIndex],
          widget.selectedIndex,
          _controller,
        );
      }),
    );
  }
}
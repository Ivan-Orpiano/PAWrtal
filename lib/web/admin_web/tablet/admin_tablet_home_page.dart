import 'package:capstone_app/web/admin_web/components/dashboard%20appbar/admin_web_notif.dart';
import 'package:capstone_app/web/admin_web/components/dashboard%20appbar/admin_web_profile.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_appointments.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_clinicpage.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_dashboard.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_messages.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_staffs.dart';
import 'package:flutter/material.dart';

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
  List<Widget> get _pages {
    List<Widget> basePages = const [
      AdminWebDashboard(),
      AdminWebClinicpage(),
      AdminWebAppointments(),
      AdminWebMessages(),
      AdminWebStaffs(),
    ];

    // if (widget.canAccessStaffs) {
    //   basePages.add(const AdminWebStaffs());
    // }

    return basePages;
  }

  List<String> get _navigationLabels {
    List<String> baseLabels = ["Home", "Clinic", "Appointments", "Messages"];
    if (widget.canAccessStaffs) {
      baseLabels.add("Staffs");
    }
    return baseLabels;
  }

  @override
  Widget build(BuildContext context) {
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
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 81, 115, 153),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 30,
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: Color.fromARGB(255, 81, 115, 153),
                      size: 30,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Admin Dashboard',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ..._navigationLabels.asMap().entries.map((entry) {
              int index = entry.key;
              String label = entry.value;
              return ListTile(
                leading: _getIconForIndex(index),
                title: Text(label),
                selected: widget.selectedIndex == index,
                onTap: () {
                  widget.onItemSelected(index);
                  Navigator.pop(context); // Close drawer
                },
              );
            }).toList(),
          ],
        ),
      ),
      body: _pages[widget.selectedIndex],
    );
  }

  Icon _getIconForIndex(int index) {
    switch (index) {
      case 0:
        return const Icon(Icons.dashboard);
      case 1:
        return const Icon(Icons.local_hospital);
      case 2:
        return const Icon(Icons.calendar_today);
      case 3:
        return const Icon(Icons.message);
      case 4:
        return const Icon(Icons.people);
      default:
        return const Icon(Icons.circle);
    }
  }
}

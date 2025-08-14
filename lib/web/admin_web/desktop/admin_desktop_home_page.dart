import 'package:capstone_app/web/admin_web/components/dashboard%20appbar/admin_web_notif.dart';
import 'package:capstone_app/web/admin_web/components/dashboard%20appbar/admin_web_profile.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_appointments.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_clinicpage.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_dashboard.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_messages.dart';
import 'package:capstone_app/web/admin_web/pages/admin_web_staffs.dart';
import 'package:flutter/material.dart';

class AdminDesktopHomePage extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final bool canAccessStaffs;

  const AdminDesktopHomePage({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.canAccessStaffs,
  });

  @override
  State<AdminDesktopHomePage> createState() => _AdminDesktopHomePageState();
}

class _AdminDesktopHomePageState extends State<AdminDesktopHomePage> {
  List<Widget> get _pages {
    List<Widget> basePages = const [
      AdminWebDashboard(),
      AdminWebClinicpage(),
      AdminWebAppointments(),
      AdminWebMessages(),
    ];

    // Only add staffs page if user has permission
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
        leadingWidth: 220,
        toolbarHeight: 80,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey.shade400,
            height: 1,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 75),
          child: InkWell(
            onTap: () => widget.onItemSelected(0),
            child: Image.asset(
              'lib/images/PAWrtal_logo.png',
            ),
          ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _navigationLabels.asMap().entries.map((entry) {
            int index = entry.key;
            String label = entry.value;
            return _buildNavItem(label, index);
          }).toList(),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 60),
            child: Row(
              children: [
                AdminWebNotif(),
                Padding(
                  padding: EdgeInsets.only(left: 30),
                  child: AdminWebProfile(),
                ),
              ],
            ),
          )
        ],
      ),
      body: _pages[widget.selectedIndex],
    );
  }

  Widget _buildNavItem(String title, int index) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => widget.onItemSelected(index),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            color: widget.selectedIndex == index ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }
}